"""Prepare and verify the two offline story voice banks before Godot imports them."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import venv
import wave

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "current_dev" / "assets"
TOOLS = ROOT / ".tools"
BANKS = ("boarding", "rescues")
REVISION = "749d1c1a46eb10492095d68fbcf55691ccf137cd"


def executable(env):
    return env / ("Scripts/python.exe" if os.name == "nt" else "bin/python")


def verified(bank):
    source = ASSETS / "voice" / (bank + ".json")
    folder = ASSETS / bank
    try:
        receipt = json.loads((folder / f"generated-{bank}.json").read_bytes())
        cues = json.loads(source.read_bytes())["cues"]
        clips = {clip["id"]: clip for clip in receipt["clips"]}
        if (receipt["model"] != "ResembleAI/chatterbox-turbo" or receipt["revision"] != REVISION
                or receipt["catalog_sha256"] != hashlib.sha256(source.read_bytes()).hexdigest()
                or len(clips) != len(cues) or not cues):
            return False
        for cue in cues:
            path = folder / (cue["id"] + ".wav")
            clip = clips[cue["id"]]
            with wave.open(str(path), "rb") as wav:
                if wav.getnchannels() != 1 or wav.getsampwidth() != 2 or wav.getnframes() < wav.getframerate() // 3:
                    return False
            if (clip["speaker"] != cue["speaker"] or clip["text_sha256"] != hashlib.sha256(cue["text"].encode()).hexdigest()
                    or clip["audio_sha256"] != hashlib.sha256(path.read_bytes()).hexdigest()):
                return False
    except (OSError, EOFError, KeyError, ValueError, wave.Error):
        return False
    return True


def authoring_python():
    if "COSMIC_TTS_PYTHON" in os.environ:
        return os.environ["COSMIC_TTS_PYTHON"]
    python = executable(TOOLS / "chatterbox")
    if not python.is_file():
        bootstrap = TOOLS / "story-bootstrap"
        venv.create(bootstrap, with_pip=True)
        boot = executable(bootstrap)
        subprocess.run([boot, "-m", "pip", "install", "uv"], check=True)
        subprocess.run([boot, "-m", "uv", "venv", "--python", "3.11", "--seed", TOOLS / "chatterbox"], check=True)
    subprocess.run([python, "-m", "pip", "install", "--timeout", "120", "-r", ROOT / "tools/chatterbox-requirements.txt"], check=True)
    return python


def main():
    pending = [bank for bank in BANKS if not verified(bank)]
    if pending:
        python = authoring_python()
        for bank in pending:
            args = [python, ASSETS / "voice/render_chatterbox.py", ASSETS / "voice" / (bank + ".json"), ASSETS / bank, "--overwrite"]
            if not os.environ.get("COSMIC_TTS_MODEL") and (TOOLS / "turbo-model/t3_turbo_v1.safetensors").is_file():
                args.extend(["--model", TOOLS / "turbo-model"])
            subprocess.run(args, check=True)
            if not verified(bank):
                raise SystemExit(f"Invalid generated audio for {bank}; refusing to export.")
    print("Story audio verified: boarding and rescues", flush=True)


if __name__ == "__main__":
    main()
