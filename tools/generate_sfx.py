"""Plan, render, or verify the game's missing sound effects."""

import argparse
import binascii
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import struct
import tempfile


ROOT = Path(__file__).resolve().parents[1]
MODEL = "OpenMOSS-Team/MOSS-SoundEffect-v2.0"
REVISION = "e35df4d82fbe87fcd5d14e5d100e349c0c3c076d"
STEPS = 32
LOOPS = {"engine_surface", "engine_space"}
RATE = 48000
# Ogg uses the same polynomial as crc32 with the opposite bit order.
REVERSE_BITS = bytes(int(f"{value:08b}"[::-1], 2) for value in range(256))


def unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate key: {key}")
        result[key] = value
    return result


def read_catalog(directory):
    cues = {}
    for path in sorted(directory.glob("sfx_*.json")):
        catalog = json.loads(path.read_text("utf-8"), object_pairs_hook=unique_keys)
        for name, spec in catalog.items():
            if name in cues or not re.fullmatch(r"[a-z][a-z0-9_]*", name):
                raise ValueError(f"{path}: invalid or duplicate cue {name!r}")
            duration = spec["duration"]
            if not isinstance(spec["prompt"], str) or not spec["prompt"].strip():
                raise ValueError(f"{path}: {name} needs a sound description")
            if type(duration) not in (int, float) or not 0.05 <= duration <= 29:
                raise ValueError(f"{path}: {name} has an unsupported duration")
            cues[name] = spec
    if not cues:
        raise ValueError(f"No SFX catalog entries in {directory}")
    return cues


def valid_clip(path, seconds):
    """Check the Vorbis header, page boundaries and final PCM sample count without ML dependencies."""
    if not path.is_file():
        return False
    with path.open("rb") as stream:
        sequence = 0
        while header := stream.read(27):
            if len(header) != 27 or header[:5] != b"OggS\0":
                return False
            if int.from_bytes(header[18:22], "little") != sequence:
                return False
            lengths = stream.read(header[26])
            size = sum(lengths)
            payload = stream.read(size)
            if len(lengths) != header[26] or len(payload) != size:
                return False
            page = header[:22] + bytes(4) + header[26:] + lengths + payload
            crc = binascii.crc32(page.translate(REVERSE_BITS), 0xffffffff) ^ 0xffffffff
            if crc.to_bytes(4, "big").translate(REVERSE_BITS) != header[22:26]:
                return False
            if sequence == 0:
                if not payload.startswith(b"\x01vorbis") or len(payload) < 16:
                    return False
                if struct.unpack_from("<IBI", payload, 7) != (0, 1, RATE):
                    return False
            if header[5] & 4:
                frames = int.from_bytes(header[6:14], "little")
                return sequence > 0 and frames == round(seconds * RATE) and not stream.read(1)
            sequence += 1
    return False


def recipe_key(name, spec):
    recipe = [MODEL, REVISION, STEPS, "edit-v2", name, spec]
    return hashlib.sha256(json.dumps(recipe, sort_keys=True).encode()).hexdigest()


def load_model(local_dir):
    # The upstream Triton graph compiler is optional. Eager inference also runs
    # on CPU release runners and Windows GPUs without a separate compiler.
    os.environ.setdefault("TORCHDYNAMO_DISABLE", "1")
    import torch
    from moss_soundeffect_v2 import MossSoundEffectPipeline

    pipe = MossSoundEffectPipeline.from_pretrained(
        local_dir or MODEL, revision=REVISION, device="cpu", torch_dtype=torch.bfloat16
    )
    # Autocast uses bfloat16 for these projections anyway. Store them in
    # that format so inference doesn't keep a second multi-GB weight copy.
    for layer in pipe.transformer.blocks.modules():
        if isinstance(layer, torch.nn.Linear):
            layer.to(dtype=torch.bfloat16)
    if torch.cuda.is_available():
        # Move each of the text encoder, diffusion network and decoder onto the
        # card only for its own stage. This also fits consumer 8 GB GPUs.
        pipe.engine.device = torch.device("cuda")
        pipe.engine.enable_cpu_offload()
    return pipe


def render(pipe, name, spec, destination, seed):
    import numpy as np
    import soundfile as sf
    from scipy.signal import butter, sosfilt

    seconds = spec["duration"]
    count = round(seconds * RATE)
    loop = name in LOOPS
    # Render some headroom so a delayed transient can be aligned to the action.
    window = min(30, math.ceil(seconds + 0.6))
    # The model was trained with a fixed 30 s latent window. Ask for the
    # short event via duration conditioning, leaving the denoising window intact.
    audio = pipe(prompt=spec["prompt"], seconds=window,
                 num_inference_steps=STEPS, seed=seed, progress_bar_cmd=iter)
    audio = audio[0, 0].float().cpu().numpy()
    audio = sosfilt(butter(2, 28, "highpass", fs=RATE, output="sos"), audio)
    if not np.isfinite(audio).all() or np.max(np.abs(audio)) < 0.0001:
        raise ValueError(f"{name}: model returned silent or non-finite audio")
    if loop:
        blend = min(RATE // 8, count // 4)
        clip = audio[blend:blend + count].copy()
        ramp = np.linspace(0, 1, blend, dtype=np.float32)
        clip[-blend:] = clip[-blend:] * (1 - ramp) + audio[:blend] * ramp
    else:
        # Find the most energetic target-length interval, then remove leading
        # silence within it. A few ms of preroll preserves the attack.
        energy = np.concatenate(([0.0], np.cumsum(np.square(audio), dtype=np.float64)))
        starts = np.arange(0, len(audio) - count + 1, max(1, RATE // 500))
        start = starts[np.argmax(energy[starts + count] - energy[starts])]
        active = np.flatnonzero(np.abs(audio[start:start + count]) > np.max(np.abs(audio)) * 0.025)
        if active.size:
            start = min(len(audio) - count, start + max(0, active[0] - RATE // 500))
        clip = audio[start:start + count].copy()
        attack = min(48, count // 8)
        release = min(RATE // 40, count // 5)
        clip[:attack] *= np.linspace(0, 1, attack)
        clip[-release:] *= np.linspace(1, 0, release)
    peak = float(np.max(np.abs(clip)))
    if peak < 0.0001 or len(clip) != count:
        raise ValueError(f"{name}: empty or short edit")
    # Keep dense sweeps below dialogue and preserve the crest of short clicks.
    # Headroom also accommodates reconstruction peaks in Vorbis decoding.
    rms = float(np.sqrt(np.mean(clip ** 2)))
    clip *= min(0.50 / peak, 0.14 / rms)
    sf.write(destination, clip, RATE, format="OGG", subtype="VORBIS", compression_level=0.7)


def prepare(args):
    cues = read_catalog(args.catalog_dir)
    missing = []
    cached = {}
    for name, spec in cues.items():
        if valid_clip(args.output_dir / f"{name}.ogg", spec["duration"]):
            continue
        source = args.cache_dir / (recipe_key(name, spec) + ".ogg") if args.cache_dir else None
        if args.command != "verify" and source and valid_clip(source, spec["duration"]):
            cached[name] = source
        else:
            missing.append(name)
    print(json.dumps({"total": len(cues), "missing_count": len(missing), "missing": missing,
                      "cached": list(cached)}), flush=True)
    if args.command == "verify":
        return int(bool(missing))
    if args.command == "plan" or not (missing or cached):
        return 0

    args.output_dir.mkdir(parents=True, exist_ok=True)
    pipe = None
    for name in [*cached, *missing]:
        spec = cues[name]
        output = args.output_dir / f"{name}.ogg"
        if valid_clip(output, spec["duration"]):
            continue
        with tempfile.TemporaryDirectory(dir=args.output_dir) as staging:
            temp = Path(staging) / "render.ogg"
            if name in cached:
                shutil.copyfile(cached[name], temp)
            else:
                if pipe is None:
                    pipe = load_model(args.model_dir)
                print(f"Rendering {name}", flush=True)
                render(pipe, name, spec, temp, int(recipe_key(name, spec)[:8], 16))
            if not valid_clip(temp, spec["duration"]):
                raise ValueError(f"{name}: invalid render")
            os.replace(temp, output)
        if args.cache_dir and name not in cached:
            args.cache_dir.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(dir=args.cache_dir) as staging:
                temp = Path(staging) / "copy.ogg"
                shutil.copyfile(output, temp)
                os.replace(temp, args.cache_dir / (recipe_key(name, spec) + ".ogg"))
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "generate", "verify"))
    parser.add_argument("--catalog-dir", type=Path, default=ROOT / "current_dev/data")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "current_dev/audio/generated_sfx")
    parser.add_argument("--cache-dir", type=Path)
    parser.add_argument("--model-dir", type=Path, help="Local copy of the pinned Hugging Face snapshot")
    raise SystemExit(prepare(parser.parse_args()))
