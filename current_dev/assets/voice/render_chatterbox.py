"""Render the game's English dialogue with Resemble AI Chatterbox-Turbo."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
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

# Synthetic reference, pitch in semitones, pace, and final signal treatment.
# Shifting pitch and resonances together gives each hull a different throat.
BOSS_CAST = {
    "ignis_ground": ("vale", -4.0, 0.98, "equalizer=f=225:t=o:w=1:g=4,acompressor=threshold=0.12:ratio=4"),
    "ignis_orbit": ("stock", 1.6, 0.95, "equalizer=f=2100:t=o:w=1:g=3,aecho=0.95:0.75:64:0.13"),
    "cryo_ground": ("stock", -3.0, 0.87, "lowpass=f=4000,equalizer=f=470:t=o:w=1:g=3"),
    "cryo_orbit": ("lark", 2.1, 1.08, "chorus=0.88:0.87:23|37:0.17|0.13:0.50|0.67:0.7|0.9"),
    "vespera_ground": ("lark", -0.9, 1.04, "highpass=f=360,lowpass=f=4200,acompressor=threshold=0.12:ratio=3"),
    "vespera_orbit": ("lark", -4.3, 0.91, "highpass=f=165,aecho=0.95:0.82:98|154:0.15|0.07"),
    "xylo_ground": ("vale", -5.2, 0.92, "tremolo=f=32:d=0.18,equalizer=f=840:t=o:w=0.85:g=3"),
    "xylo_orbit": ("lark", -2.5, 0.94, "chorus=0.9:0.85:29|41:0.27|0.13:1.2|0.32:1.8|0.9"),
    "thalassa_ground": ("vale", 1.5, 1.07, "highpass=f=300,lowpass=f=3400,tremolo=f=13:d=0.08"),
    "thalassa_orbit": ("stock", -1.1, 0.94, "equalizer=f=320:t=o:w=1.2:g=3,aecho=0.92:0.83:116:0.20"),
    "kharon_ground": ("vale", -1.5, 0.89, "equalizer=f=750:t=o:w=0.8:g=4,aecho=0.94:0.82:78:0.09"),
    "kharon_orbit": ("stock", 3.0, 1.05, "highpass=f=230,equalizer=f=1850:t=o:w=1:g=3"),
}


def boss_voice(pcm, sr, speaker):
    _, semitones, pace, treatment = BOSS_CAST[speaker]
    pitch = 2 ** (semitones / 12)
    filters = f"asetrate={round(sr * pitch)},aresample={sr},atempo={pace / pitch:.5f},{treatment}"
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(sr), "-ac", "1", "-i", "pipe:0",
         "-af", filters, "-f", "f32le", "-ar", str(sr), "-ac", "1", "pipe:1"],
        input=pcm.astype("<f4").tobytes(), stdout=subprocess.PIPE, check=True,
    )
    wave = np.frombuffer(result.stdout, dtype="<f4")
    if len(wave) < sr / 4 or not np.isfinite(wave).all() or np.max(np.abs(wave)) < 0.025:
        raise ValueError(f"Invalid recording for {speaker}")
    # Maintain dialogue intelligibility at matched level, leaving headroom
    # for the mixer and concurrent weapon audio.
    audible = wave[np.abs(wave) > 0.012]
    gain = min(0.89 / np.max(np.abs(wave)), 0.135 / np.sqrt(np.mean(audible ** 2)))
    return wave * gain


def digest(value):
    return hashlib.sha256(value).hexdigest()


def spoken_form(text):
    return (text.replace("0600", "oh six hundred").replace("Aegis-4", "Aegis Four")
            .replace("is free, you know.", "is free. You know?")
            .replace("They used your credentials, Lark, not your intent.",
                     "They used your credentials, Lark. Not your intent.")
            .replace("â€”", ", ").replace("â€™", "'"))


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


def render_speech(model, text):
    parts = []
    for phrase in passages(text):
        torch.manual_seed(int(digest(phrase.encode())[:8], 16))
        audio = model.generate(phrase, temperature=0.68).flatten().numpy()
        active = np.flatnonzero(np.abs(audio) > 0.009)
        if not len(active) or not np.isfinite(audio).all():
            raise ValueError(f"No valid speech for {phrase}")
        pad = int(model.sr * 0.045)
        if parts:
            parts.append(np.zeros(int(model.sr * 0.10), dtype=np.float32))
        parts.append(audio[max(0, active[0] - pad):active[-1] + pad + 1])
    return np.concatenate(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalog", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--profiles", type=Path, default=Path(__file__).parent / "profiles")
    parser.add_argument("--model", default=os.environ.get("COSMIC_TTS_MODEL"))
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--only", nargs="+", metavar="ID", help="Render only the requested new dialogue IDs")
    args = parser.parse_args()
    source = args.catalog.read_bytes()
    data = json.loads(source.decode("utf-8-sig"))
    bosses = args.catalog.stem == "bosses"
    opening = "cues" in data
    if bosses:
        if set(data) != set(BOSS_CAST) or any(set(cues) != {"arrival", "hurt_1", "hurt_2", "hurt_3"} for cues in data.values()):
            raise ValueError("The boss cast requires all twelve hulls and four lines per hull")
        lines = [dict(id=f"{role}_{event}", speaker=role, event=event, text=text)
                 for role, cues in data.items() for event, text in cues.items()]
        cast = BOSS_CAST
    elif opening:
        lines = data["cues"]
        cast = {role: (LARK if role == "lark" else VALE if role == "vale" else "Chatterbox-Turbo / stock") for role in data["cast"]}
        if any(data["cast"][role]["voice"] != name for role, name in cast.items()):
            raise ValueError("Dialogue cast does not match the Turbo profiles")
    else:
        if data["voice"] != LARK:
            raise ValueError("This generator requires the Chatterbox-Turbo Lark voice")
        lines = [line for section in data["sections"] for line in section["lines"]]
    if args.only:
        if args.output.exists() and any(args.output.iterdir()):
            raise ValueError("A partial render requires an empty staging directory")
        selected = set(args.only)
        lines = [line for line in lines if line["id"] in selected]
        if {line["id"] for line in lines} != selected:
            raise ValueError("Unknown dialogue ID in --only")
    ids = set()
    for line in lines:
        key = line["id"]
        if (not re.fullmatch(r"[a-z][a-z0-9_-]*", key) or key in ids
                or not line["text"].strip() or line.get("speaker", "lark") not in (cast if opening or bosses else ("lark",))):
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
    stock_voice = model.conds
    profiles = {}
    for role in sorted({line.get("speaker", "lark") for line in lines}):
        reference = BOSS_CAST[role][0] if bosses else role
        if reference not in ("lark", "vale"):
            if stock_voice is None:
                raise ValueError("Stock attendant voice requires the model's conds.pt")
            profiles[role] = stock_voice
            continue
        model.prepare_conditionals(str(args.profiles / f"{reference}.wav"))
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
            pcm = render_speech(model, text)
            if bosses:
                pcm = boss_voice(pcm, model.sr, role)
            wav = stage / f"{key}.wav"
            sf.write(wav, pcm, model.sr, subtype="PCM_16")
            clips.append(dict(id=key, speaker=role, event=line.get("event", ""),
                              text_sha256=digest(text.encode()), audio_sha256=digest(wav.read_bytes()),
                              seconds=round(len(pcm) / model.sr, 3), bytes=wav.stat().st_size))
            print(f"VOICE_CLIP {key} {len(pcm) / model.sr:.2f}s", flush=True)
        index = f"generated-{args.catalog.stem}.json" if opening or bosses else "generated-voice.json"
        proof = dict(model=MODEL, revision=REVISION, voice="Boss cast" if bosses else data.get("voice", "opening cast"),
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
