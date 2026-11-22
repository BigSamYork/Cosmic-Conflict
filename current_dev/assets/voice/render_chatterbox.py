"""Render the game's English dialogue with Resemble AI Chatterbox-Turbo."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import textwrap

import numpy as np
import soundfile as sf
import torch
from chatterbox.tts_turbo import ChatterboxTurboTTS
from huggingface_hub import snapshot_download


MODEL = "ResembleAI/chatterbox-turbo"
REVISION = "749d1c1a46eb10492095d68fbcf55691ccf137cd"
LARK = "Chatterbox-Turbo / Lark"
VALE = "Chatterbox-Turbo / Captain Tomas Vale"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def spoken_form(text):
    return (text.replace("0600", "oh six hundred").replace("Aegis-4", "Aegis Four")
            .replace("is free, you know.", "is free. You know?")
            .replace("They used your credentials, Lark, not your intent.",
                     "They used your credentials, Lark. Not your intent.")
            .replace("—", ", ").replace("’", "'"))


def passages(text):
    # Keep long briefings below the model's generation window without cutting a sentence.
    block = ""
    for sentence in re.split(r"(?<=[.!?])\s+", spoken_form(text)):
        for phrase in textwrap.wrap(sentence, width=170, break_on_hyphens=False):
            if block and len(block) + 1 + len(phrase) > 170:
                yield block
                block = ""
            block = (block + " " + phrase).strip()
    if block:
        yield block


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--profiles", type=Path, default=Path(__file__).parent / "profiles")
    parser.add_argument("--model", default=os.environ.get("COSMIC_TTS_MODEL"))
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    source = args.catalog.read_bytes()
    data = json.loads(source.decode("utf-8-sig"))
    opening = "cues" in data
    if opening:
        lines = data["cues"]
        if any(data["cast"][role]["voice"] != name for role, name in (("vale", VALE), ("lark", LARK))):
            raise ValueError("Opening cast does not match the Turbo profiles")
    else:
        if data["voice"] != LARK:
            raise ValueError("This generator requires the Chatterbox-Turbo Lark voice")
        lines = [line for section in data["sections"] for line in section["lines"]]
    ids = set()
    for line in lines:
        key = line["id"]
        if (not re.fullmatch(r"[a-z][a-z0-9_-]*", key) or key in ids
                or not line["text"].strip() or line.get("speaker", "lark") not in ("lark", "vale")):
            raise ValueError(f"Invalid or duplicate voice line: {key}")
        if (args.output / f"{key}.wav").exists() and not args.overwrite:
            raise FileExistsError(f"{key}.wav already exists; use --overwrite")
        ids.add(key)
    if not lines:
        raise ValueError("Empty voice catalog")

    device = os.environ.get("COSMIC_TTS_DEVICE") or ("cuda" if torch.cuda.is_available() else "cpu")
    torch.set_num_threads(min(os.cpu_count() or 1, 8))
    weights = args.model or snapshot_download(
        MODEL, revision=REVISION, allow_patterns=["*.json", "*.txt", "conds.pt",
            "t3_turbo_v1.safetensors", "s3gen_meanflow.safetensors", "ve.safetensors"])
    model = ChatterboxTurboTTS.from_local(weights, device, nano=False)
    profiles = {}
    for role in sorted({line.get("speaker", "lark") for line in lines}):
        model.prepare_conditionals(str(args.profiles / f"{role}.wav"))
        profiles[role] = model.conds

    args.output.mkdir(parents=True, exist_ok=True)
    clips = []
    # Godot skips dot directories when the project is open during a render.
    with tempfile.TemporaryDirectory(prefix=".render-", dir=args.output) as temporary:
        stage = Path(temporary)
        for line in lines:
            key, text = line["id"], line["text"]
            role = line.get("speaker", "lark")
            model.conds = profiles[role]
            parts = []
            for part in passages(text):
                torch.manual_seed(int(digest(part.encode())[:8], 16))
                audio = model.generate(part, temperature=0.68).flatten().numpy()
                active = np.flatnonzero(np.abs(audio) > 0.009)
                if not len(active) or not np.isfinite(audio).all():
                    raise ValueError(f"No valid speech for {key}")
                pad = int(model.sr * 0.045)
                if parts:
                    parts.append(np.zeros(int(model.sr * 0.10), dtype=np.float32))
                parts.append(audio[max(0, active[0] - pad):active[-1] + pad + 1])
            pcm = np.concatenate(parts)
            wav = stage / f"{key}.wav"
            sf.write(wav, pcm, model.sr, subtype="PCM_16")
            clips.append(dict(id=key, speaker=role, event=line.get("event", ""),
                              text_sha256=digest(text.encode()), audio_sha256=digest(wav.read_bytes()),
                              seconds=round(len(pcm) / model.sr, 3), bytes=wav.stat().st_size))
            print(f"VOICE_CLIP {key} {len(pcm) / model.sr:.2f}s", flush=True)
        index = "generated-opening.json" if opening else "generated-voice.json"
        proof = dict(model=MODEL, revision=REVISION, voice=data.get("voice", "opening cast"),
                     catalog_sha256=digest(source), rate=model.sr, channels=1, clips=clips)
        (stage / index).write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")
        if args.catalog.read_bytes() != source:
            raise RuntimeError("Dialogue changed during rendering")
        for line in lines:
            name = line["id"] + ".wav"
            (stage / name).replace(args.output / name)
        (stage / index).replace(args.output / index)
    print(f"VOICE_GENERATION_COMPLETE={len(lines)}")


if __name__ == "__main__":
    main()
