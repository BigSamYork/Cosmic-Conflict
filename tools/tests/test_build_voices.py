"""Exercise the build CLI without requiring Torch, a model, or the network."""

import hashlib
import json
import os
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
if catalog.stem == "bosses":
    requested = set(sys.argv[sys.argv.index("--only") + 1:])
    lines = [dict(id=f"{role}_{event}", speaker=role, text=text)
             for role, events in data.items() for event, text in events.items()
             if f"{role}_{event}" in requested]
else:
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
        for name in ("chatterbox-requirements.txt", SCRIPT.name, "build-story-audio.py"):
            shutil.copy(ROOT / "tools" / name, self.checkout / "tools")
        assets = self.checkout / ASSETS
        voice = assets / "voice"
        (voice / "profiles").mkdir(parents=True)
        (voice / "profiles/lark.wav").write_bytes(b"test profile")
        (voice / "profiles/vale.wav").write_bytes(b"test profile")
        (voice / "render_chatterbox.py").write_text(FAKE_RENDERER, encoding="utf-8")
        lark = "Chatterbox-Turbo / Lark"
        vale = "Chatterbox-Turbo / Captain Tomas Vale"
        for catalog in ("lines", "opening", "arrival", "boarding", "rescues", "bosses"):
            folder = voice if catalog == "lines" else voice / "bosses" if catalog == "bosses" else assets / catalog
            folder.mkdir(exist_ok=True)
            lines = [{"id": key, "speaker": "lark", "text": "This was previously rendered."}
                     for key in ("clearance", "last_car")]
            if catalog == "bosses":
                name = "Boss cast"
                data = {f"{sector}_{stage}": {event: "Recorded boss line." for event in ("arrival", "hurt_1", "hurt_2", "hurt_3")}
                        for sector in ("ignis", "cryo", "vespera", "xylo", "thalassa", "kharon")
                        for stage in ("ground", "orbit")}
                lines = [dict(id=f"{role}_{event}", speaker=role, text=text)
                         for role, events in data.items() for event, text in events.items()]
            elif catalog == "lines":
                name = lark
                data = {"voice": name, "sections": [{"lines": lines}]}
            else:
                cast = {"lark": {"voice": lark}, "vale": {"voice": vale}}
                name = "opening cast"
                if catalog == "boarding":
                    cast = {"lark": {"voice": lark}, "attendant": {"voice": "Chatterbox-Turbo / stock"}}
                    name = "Vespera boarding cast"
                if catalog == "rescues":
                    cast["nurse"] = {"voice": "Chatterbox-Turbo / stock"}
                    name = "Two Knocks Home cast"
                data = {"voice": name, "cast": cast, "cues": lines}
            (voice / f"{catalog}.json").write_text(json.dumps(data), encoding="utf-8")
            proof = {"model": "ResembleAI/chatterbox-turbo", "voice": name,
                     "revision": "749d1c1a46eb10492095d68fbcf55691ccf137cd",
                     "catalog_sha256": hashlib.sha256((voice / f"{catalog}.json").read_bytes()).hexdigest(),
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

    def test_boss_bank_preserves_reviewed_takes_and_only_renders_a_new_id(self):
        folder = self.checkout / ASSETS / "voice/bosses"
        receipt = folder / "generated-bosses.json"
        reviewed = json.loads(receipt.read_bytes())
        missing = reviewed["clips"].pop()["id"]
        (folder / f"{missing}.wav").unlink()
        self.assertIn("previously recorded ID", self.run_cli("verify", success=False).stderr)
        receipt.write_text(json.dumps(reviewed), encoding="utf-8")
        self.assertIn("render=1", self.run_cli("probe").stdout)
        self.assertEqual(self.run_cli("prepare").stdout.count("TEST_RENDER "), 1)
        self.run_cli("verify")
        files = self.overlay / ASSETS / "voice/bosses"
        self.assertEqual({path.name for path in files.iterdir()}, {f"{missing}.wav", receipt.name})

    def test_missing_lines_only_and_cache_across_clean_checkouts(self):
        destinations = {"lines": "voice", "arrival": "arrival", "opening": "opening",
                        "boarding": "boarding", "rescues": "rescues"}
        original = {p.relative_to(self.checkout): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in (self.checkout / ASSETS).glob("*/*.wav")}
        for catalog in destinations:
            self.update(catalog, lambda lines: lines.append(
                {"id": "ci_delta", "text": "The test line is ready.", "speaker": "lark"}))
        self.assertIn("missing=5", self.run_cli("plan").stdout)
        self.assertIn("render=5", self.run_cli("probe").stdout)
        self.assertEqual(self.run_cli("prepare").stdout.count("TEST_RENDER ci_delta"), 5)
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

    def windows_checkout(self):
        for source in (self.checkout / ASSETS / "voice").glob("*.json"):
            source.write_bytes(source.read_bytes().replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))

    def run_package_audio(self, *, verify_only=True):
        return subprocess.run([sys.executable, str(self.checkout / "tools/build-story-audio.py")],
                              env={**os.environ, "COSMIC_VERIFY_VOICES_ONLY": "1" if verify_only else "0",
                                   "COSMIC_TTS_PYTHON": sys.executable},
                              capture_output=True, text=True)

    def test_bootstrap_missing_rescue_bank_once_and_share_across_checkouts(self):
        path = ASSETS / "rescues"
        boarding = {p.name: p.read_bytes() for p in (self.checkout / ASSETS / "boarding").glob("*.wav")}
        self.update("rescues", lambda lines: lines[0].update(speaker="nurse"))
        shutil.rmtree(self.checkout / path)
        self.assertIn("missing=2", self.run_cli("plan").stdout)
        failed = self.run_package_audio()
        self.assertNotEqual(failed.returncode, 0)
        self.assertFalse((self.checkout / path).exists())  # No render fallback on a packager.
        self.assertEqual(self.run_cli("prepare").stdout.count("TEST_RENDER"), 2)
        self.assertEqual({p.name for p in (self.overlay / path).iterdir()},
                         {"clearance.wav", "last_car.wav", "generated-rescues.json"})
        self.assertFalse((self.overlay / ASSETS / "boarding").exists())
        self.assertEqual(boarding, {p.name: p.read_bytes() for p in
                                    (self.checkout / ASSETS / "boarding").glob("*.wav")})

        # Simulate an independent Windows package checkout receiving the one Linux overlay.
        shutil.rmtree(self.checkout)
        self.copy_fixture()
        self.update("rescues", lambda lines: lines[0].update(speaker="nurse"))
        shutil.rmtree(self.checkout / path)
        self.windows_checkout()
        shutil.copytree(self.overlay, self.checkout, dirs_exist_ok=True)
        result = self.run_package_audio()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("TEST_RENDER", result.stdout)
        self.assertEqual(boarding, {p.name: p.read_bytes() for p in
                                    (self.checkout / ASSETS / "boarding").glob("*.wav")})
        self.assertEqual((self.overlay / path / "clearance.wav").read_bytes(),
                         (self.checkout / path / "clearance.wav").read_bytes())

    def test_line_endings_do_not_trigger_local_regeneration(self):
        self.update("boarding", lambda lines: lines.append(
            {"id": "new_line", "text": "Only one new line.", "speaker": "attendant"}))
        path = self.checkout / ASSETS / "voice/boarding.json"
        path.write_bytes(path.read_bytes() + b"\n")
        self.windows_checkout()
        before = self.run_cli("plan").stdout
        self.assertIn("missing=1", before)
        result = self.run_package_audio(verify_only=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("TEST_RENDER new_line"), 1)
        self.assertEqual(result.stdout.count("TEST_RENDER"), 1)
        receipt = self.checkout / ASSETS / "boarding/generated-boarding.json"
        self.assertEqual(json.loads(receipt.read_bytes())["catalog_sha256"],
                         hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest())
        result = self.run_package_audio(verify_only=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("TEST_RENDER", result.stdout)

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
