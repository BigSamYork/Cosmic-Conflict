"""Prepare missing dialogue for local builds; CI only verifies shared assets."""

import os
from pathlib import Path
import subprocess
import sys
import venv


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"


def executable(env):
    return env / ("Scripts/python.exe" if os.name == "nt" else "bin/python")


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
    command = [sys.executable, str(ROOT / "tools/prepare-build-voices.py")]
    if os.environ.get("COSMIC_VERIFY_VOICES_ONLY") != "1":
        plan = subprocess.check_output([*command, "probe"], text=True).strip()
        env = os.environ.copy()
        if plan != "render=0":
            env["COSMIC_TTS_PYTHON"] = str(authoring_python())
            model = TOOLS / "turbo-model"
            if not env.get("COSMIC_TTS_MODEL") and (model / "t3_turbo_v1.safetensors").is_file():
                env["COSMIC_TTS_MODEL"] = str(model)
        subprocess.run([*command, "prepare"], env=env, check=True)
    subprocess.run([*command, "verify"], check=True)
    print("All build voice banks verified.", flush=True)


if __name__ == "__main__":
    main()
