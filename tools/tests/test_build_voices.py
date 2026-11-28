"""Exercise the build CLI without requiring Torch, a model, or the network."""

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import wave


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools/prepare-build-voices.py"
ASSETS = Path("current_dev/assets")
FAKE_RENDERER = """
import json, pathlib, sys, wave
from hashlib import sha256

catalog, output = map(pathlib.Path, sys.argv[1:3])
output.mkdir()
data = json.loads(catalog.read_text(encoding="utf-8"))
lines = data["cues"] if "cues" in data else data["sections"][0]["lines"]
records = []
for line in lines:
    key = line["id"]
    wav = output / (key + ".wav")
    with wave.open(str(wav), "wb") as f:
        f.setparams((1, 2, 24000, 240, "NONE", "not compressed"))
        f.writeframes(b"AB" * 240)
    records.append(dict(id=key, speaker=line.get("speaker", "lark"),
                        text_sha256=sha256(line["text"].encode()).hexdigest(),
                        audio_sha256=sha256(wav.read_bytes()).hexdigest(),
                        seconds=0.01, bytes=wav.stat().st_size))
    print("TEST_RENDER " + key)
name = catalog.stem if catalog.stem != "lines" else "voice"
(output / ("generated-" + name + ".json")).write_text(json.dumps({"clips": records}))
"""


class BuildVoiceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        directory = Path(self.temp.name)
        self.checkout = directory / "checkout"
        self.cache = directory / "cache"
        self.overlay = directory / "overlay"
        self.copy_fixture()

    def copy_fixture(self):
        self.checkout.mkdir()
        (self.checkout / "tools").mkdir()
        for name in ("chatterbox-requirements.txt", SCRIPT.name):
            shutil.copy(ROOT / "tools" / name, self.checkout / "tools")
        assets = self.checkout / ASSETS
        voice = assets / "voice"
        (voice / "profiles").mkdir(parents=True)
        (voice / "profiles/lark.wav").write_bytes(b"test profile")
        (voice / "profiles/vale.wav").write_bytes(b"test profile")
        (voice / "render_chatterbox.py").write_text(FAKE_RENDERER, encoding="utf-8")
        lark = "Chatterbox-Turbo / Lark"
        vale = "Chatterbox-Turbo / Captain Tomas Vale"
        for catalog in ("lines", "opening", "arrival", "boarding"):
            folder = voice if catalog == "lines" else assets / catalog
            folder.mkdir(exist_ok=True)
            lines = [{"id": key, "speaker": "lark", "text": "This was previously rendered."}
                     for key in ("clearance", "last_car")]
            if catalog == "lines":
                name = lark
                data = {"voice": name, "sections": [{"lines": lines}]}
            else:
                cast = {"lark": {"voice": lark}, "vale": {"voice": vale}}
                name = "opening cast"
                if catalog == "boarding":
                    cast = {"lark": {"voice": lark}, "attendant": {"voice": "Chatterbox-Turbo / stock"}}
                    name = "Vespera boarding cast"
                data = {"voice": name, "cast": cast, "cues": lines}
            (voice / f"{catalog}.json").write_text(json.dumps(data), encoding="utf-8")
            proof = {"model": "ResembleAI/chatterbox-turbo", "voice": name,
                     "rate": 24000, "channels": 1, "clips": []}
            for line in lines:
                wav = folder / (line["id"] + ".wav")
                with wave.open(str(wav), "wb") as audio:
                    audio.setparams((1, 2, 24000, 240, "NONE", "not compressed"))
                    audio.writeframes(b"OK" * 240)
                proof["clips"].append(dict(id=line["id"], speaker=line["speaker"],
                    text_sha256=hashlib.sha256(line["text"].encode()).hexdigest(),
                    audio_sha256=hashlib.sha256(wav.read_bytes()).hexdigest()))
            (folder / f"generated-{folder.name}.json").write_text(json.dumps(proof), encoding="utf-8")

    def run_cli(self, mode, success=True):
        result = subprocess.run([sys.executable, str(SCRIPT), mode, "--root", str(self.checkout),
                                 "--cache", str(self.cache), "--overlay", str(self.overlay)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return result

    def update(self, name, change):
        path = self.checkout / ASSETS / f"voice/{name}.json"
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        change(data["sections"][0]["lines"] if name == "lines" else data["cues"])
        path.write_text(json.dumps(data), encoding="utf-8")

    def test_no_op(self):
        self.assertIn("overlay=false", self.run_cli("plan").stdout)
        self.assertIn("render=0", self.run_cli("probe").stdout)
        self.assertNotIn("TEST_RENDER", self.run_cli("prepare").stdout)
        self.assertFalse(self.overlay.exists())
        self.run_cli("verify")

    def test_missing_lines_only_and_cache_across_clean_checkouts(self):
        destinations = {"lines": "voice", "arrival": "arrival", "opening": "opening", "boarding": "boarding"}
        original = {p.relative_to(self.checkout): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in (self.checkout / ASSETS).glob("*/*.wav")}
        for catalog in destinations:
            self.update(catalog, lambda lines: lines.append(
                {"id": "ci_delta", "text": "The test line is ready.", "speaker": "lark"}))
        self.assertIn("missing=4", self.run_cli("plan").stdout)
        self.assertIn("render=4", self.run_cli("probe").stdout)
        self.assertEqual(self.run_cli("prepare").stdout.count("TEST_RENDER ci_delta"), 4)
        self.run_cli("verify")
        for folder in destinations.values():
            self.assertTrue((self.overlay / ASSETS / folder / "ci_delta.wav").is_file())
            self.assertTrue((self.overlay / ASSETS / folder / f"generated-{folder}.json").is_file())
        for path, digest in original.items():
            self.assertEqual(hashlib.sha256((self.checkout / path).read_bytes()).hexdigest(), digest)

        shutil.rmtree(self.checkout)
        shutil.rmtree(self.overlay)
        self.copy_fixture()
        self.update("boarding", lambda lines: lines.append(
            {"id": "ci_renamed", "text": "The test line is ready.", "speaker": "lark"}))
        self.assertIn("render=0", self.run_cli("probe").stdout)
        self.assertNotIn("TEST_RENDER", self.run_cli("prepare").stdout)
        self.run_cli("verify")

    def test_changed_text_or_missing_reviewed_audio_fails(self):
        original = (self.checkout / ASSETS / "voice/boarding.json").read_bytes()
        self.update("boarding", lambda lines: lines[0].update(text="Different words."))
        self.assertIn("previously recorded ID", self.run_cli("plan", success=False).stderr)
        (self.checkout / ASSETS / "voice/boarding.json").write_bytes(original)
        (self.checkout / ASSETS / "boarding/clearance.wav").unlink()
        self.assertIn("previously recorded ID", self.run_cli("prepare", success=False).stderr)
        self.assertFalse(self.overlay.exists())

    def test_removing_line_does_not_regenerate(self):
        self.update("boarding", lambda lines: lines.pop())
        result = self.run_cli("plan").stdout
        self.assertIn("overlay=true", result)
        self.assertIn("missing=0", result)
        self.assertNotIn("TEST_RENDER", self.run_cli("prepare").stdout)
        self.assertEqual([p.name for p in self.overlay.rglob("*") if p.is_file()],
                         ["generated-boarding.json"])
        self.assertTrue((self.checkout / ASSETS / "boarding/last_car.wav").is_file())
        self.run_cli("verify")


if __name__ == "__main__":
    unittest.main()
