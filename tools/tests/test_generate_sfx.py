"""Exercise cold, warm and partially complete builds without model dependencies."""

from argparse import Namespace
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import generate_sfx as sfx


# A 100 ms, mono 48 kHz Vorbis tone, independent of the game's generated output.
TONE = Path(__file__).parent / "fixtures/tick.ogg"


class IncrementalSoundTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        self.catalog = root / "catalog"
        self.output = root / "output"
        self.cache = root / "cache"
        self.catalog.mkdir()
        self.output.mkdir()
        self.cache.mkdir()
        self.cues = {cue: {"duration": 0.1, "prompt": f"A short {cue} sound"}
                     for cue in ("click", "reward", "dash")}
        self.write_catalog()

    def write_catalog(self):
        (self.catalog / "sfx_test.json").write_text(json.dumps(self.cues), encoding="utf-8")

    def cached(self, cue):
        return self.cache / (sfx.recipe_key(cue, self.cues[cue]) + ".ogg")

    def run_generator(self, command):
        args = Namespace(command=command, catalog_dir=self.catalog, output_dir=self.output,
                         cache_dir=self.cache, model_dir=None)
        stdout = io.StringIO()
        with redirect_stdout(stdout):
            status = sfx.prepare(args)
        return status, json.loads(stdout.getvalue().splitlines()[0])

    def test_partial_cache_generates_only_the_remaining_cue_and_then_skips_all(self):
        shipped = self.output / "click.ogg"
        shutil.copyfile(TONE, shipped)
        original_time = shipped.stat().st_mtime_ns
        shutil.copyfile(TONE, self.cached("reward"))
        status, plan = self.run_generator("plan")
        self.assertEqual(status, 0)
        self.assertEqual(plan["missing_count"], 1)
        self.assertEqual(plan["missing"], ["dash"])
        self.assertEqual(plan["cached"], ["reward"])
        self.assertEqual(self.run_generator("verify")[0], 1)

        def render(pipe, name, spec, destination, seed):
            self.assertEqual(name, "dash")
            shutil.copyfile(TONE, destination)

        with patch.object(sfx, "load_model") as load, patch.object(sfx, "render", side_effect=render) as draw:
            self.assertEqual(self.run_generator("generate")[0], 0)
            self.assertEqual(self.run_generator("generate")[0], 0)
            load.assert_called_once_with(None)
            draw.assert_called_once()
        self.assertEqual(self.cached("dash").read_bytes(), TONE.read_bytes())
        self.assertFalse(self.cached("click").exists())
        self.assertEqual(shipped.stat().st_mtime_ns, original_time)
        self.assertEqual(self.run_generator("verify")[0], 0)

    def test_near_silent_take_retries_only_the_missing_cue(self):
        for cue in ("click", "reward"):
            shutil.copyfile(TONE, self.output / (cue + ".ogg"))
        attempts = []

        def render(pipe, name, spec, destination, seed):
            self.assertEqual(name, "dash")
            attempts.append(seed)
            if len(attempts) == 1:
                raise sfx.InvalidTake("near-silent model output")
            shutil.copyfile(TONE, destination)

        with patch.object(sfx, "load_model") as load, patch.object(sfx, "render", side_effect=render):
            self.assertEqual(self.run_generator("generate")[0], 0)
            self.assertEqual(self.run_generator("generate")[0], 0)
        self.assertEqual(attempts, [attempts[0], (attempts[0] + 1) % (2**32)])
        load.assert_called_once()

    def test_cache_only_cli_repairs_corruption_with_no_site_packages(self):
        for name in self.cues:
            shutil.copyfile(TONE, self.cached(name))
        damaged = bytearray(TONE.read_bytes())
        damaged[-2] ^= 1
        (self.output / "click.ogg").write_bytes(damaged)
        (self.output / "reward.ogg").write_bytes(damaged[:300])
        self.assertEqual(self.run_generator("verify")[0], 1)
        result = subprocess.run(
            [sys.executable, "-S", str(TOOLS / "generate_sfx.py"), "generate",
             "--catalog-dir", str(self.catalog), "--output-dir", str(self.output),
             "--cache-dir", str(self.cache)], check=True, text=True, capture_output=True)
        plan = json.loads(result.stdout)
        self.assertEqual(plan["missing_count"], 0)
        self.assertCountEqual(plan["cached"], self.cues)
        self.assertEqual(self.run_generator("verify")[0], 0)

    def test_changed_prompt_and_damaged_cache_require_fresh_audio(self):
        shutil.copyfile(TONE, self.cached("click"))
        self.cues["click"]["prompt"] = "A different pushbutton"
        self.write_catalog()
        self.cached("reward").write_bytes(b"OggS")
        shutil.copyfile(TONE, self.cached("dash"))
        _, plan = self.run_generator("plan")
        self.assertCountEqual(plan["missing"], ["click", "reward"])
        self.assertEqual(plan["cached"], ["dash"])

    def test_interrupted_render_keeps_completed_cues_for_the_next_attempt(self):
        def interrupted(pipe, name, spec, destination, seed):
            if name == "reward":
                destination.write_bytes(b"incomplete")
                raise RuntimeError("interrupted")
            shutil.copyfile(TONE, destination)

        with patch.object(sfx, "load_model"), patch.object(sfx, "render", side_effect=interrupted):
            with self.assertRaisesRegex(RuntimeError, "interrupted"):
                self.run_generator("generate")
        self.assertEqual(list(self.output.iterdir()), [self.output / "click.ogg"])
        self.assertEqual(list(self.cache.iterdir()), [self.cached("click")])
        (self.output / "click.ogg").unlink()  # a fresh checkout restoring that partial cache
        _, plan = self.run_generator("plan")
        self.assertEqual(plan["cached"], ["click"])
        self.assertCountEqual(plan["missing"], ["reward", "dash"])


if __name__ == "__main__":
    unittest.main()
