"""Assemble checked-in dialogue and render only previously unrecorded IDs."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import wave


ROOT = Path(__file__).resolve().parents[1]
ASSETS = Path("current_dev/assets")
CATALOGS = {"lines": ("voice", "voice"), "opening": ("opening", "opening"),
            "arrival": ("arrival", "arrival"), "boarding": ("boarding", "boarding")}
MODEL = "ResembleAI/chatterbox-turbo"
CASTS = {"lines": {"lark": "Chatterbox-Turbo / Lark"},
         "boarding": {"lark": "Chatterbox-Turbo / Lark", "attendant": "Chatterbox-Turbo / stock"}}
STANDARD_CAST = {"lark": CASTS["lines"]["lark"], "vale": "Chatterbox-Turbo / Captain Tomas Vale"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    return json.loads(path.read_bytes().decode("utf-8-sig"))


def write_json(path, obj):
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def reject(path, detail):
    raise ValueError(f"{path}: {detail}. Restore the reviewed WAV and its manifest entry, "
                     "or explicitly regenerate and commit the replacement using the authoring tools.")


def matches(clip, line, wav):
    return (clip["speaker"] == line.get("speaker", "lark")
            and clip["text_sha256"] == sha(line["text"].encode("utf-8"))
            and clip["audio_sha256"] == sha(wav.read_bytes()))


class Catalog:
    def __init__(self, root, name):
        self.name = name
        self.root = root
        folder, index = CATALOGS[name]
        self.voice = root / ASSETS / "voice"
        self.source = self.voice / f"{name}.json"
        self.data = read_json(self.source)
        self.folder = root / ASSETS / folder
        self.index = self.folder / f"generated-{index}.json"
        self.expected_voice = self.data.get("voice", "opening cast")
        cast = CASTS.get(name, STANDARD_CAST)
        if name == "lines":
            if self.expected_voice != cast["lark"]:
                raise ValueError(f"{self.source}: unexpected voice")
            self.lines = [line for section in self.data["sections"] for line in section["lines"]]
        else:
            if {role: value["voice"] for role, value in self.data["cast"].items()} != cast:
                raise ValueError(f"{self.source}: unexpected cast")
            self.lines = self.data["cues"]
        self.manifest = read_json(self.index)
        if (self.manifest["model"] != MODEL or self.manifest["voice"] != self.expected_voice
                or self.manifest["rate"] != 24000 or self.manifest["channels"] != 1):
            reject(self.index, "unexpected model, voice or format")
        self.existing = {clip["id"]: clip for clip in self.manifest["clips"]}
        if len(self.existing) != len(self.manifest["clips"]):
            reject(self.index, "duplicate manifest IDs")
        self.missing = []
        ids = set()
        for line in self.lines:
            key = line["id"]
            if (not re.fullmatch(r"[a-z][a-z0-9_-]*", key) or key in ids
                    or not line["text"].strip() or line.get("speaker", "lark") not in cast):
                raise ValueError(f"{self.source}: invalid or duplicate line {key!r}")
            ids.add(key)
            wav = self.folder / f"{key}.wav"
            clip = self.existing.get(key)
            if not clip and not wav.exists():
                self.missing.append(line)
            elif not clip or not wav.is_file() or not matches(clip, line, wav):
                reject(wav, "a previously recorded ID has missing or mismatched audio, text, or speaker")
        if not ids:
            raise ValueError(f"{self.source}: empty catalog")
        self.dirty = bool(self.missing or self.existing.keys() != ids)

    def recipe(self, line):
        role = line.get("speaker", "lark")
        profile = self.voice / "profiles" / f"{role}.wav"
        return sha(json.dumps([self.name, role, line["text"],
                               sha(profile.read_bytes()) if role != "attendant" else "stock"],
                              ensure_ascii=False).encode("utf-8"))

    def cache_entry(self, cache, line):
        return cache / self.recipe(line)

    def cached(self, cache, line):
        entry = self.cache_entry(cache, line)
        try:
            wav = entry / "clip.wav"
            clip = read_json(entry / "clip.json")
            if not matches(clip, line, wav):
                return None
            with wave.open(str(wav), "rb") as audio:
                if (audio.getnchannels(), audio.getsampwidth(), audio.getframerate()) != (1, 2, 24000):
                    return None
                frames = audio.getnframes()
                if not frames or len(audio.readframes(frames)) != frames * 2:
                    return None
                if clip["seconds"] != round(frames / 24000, 3) or clip["bytes"] != wav.stat().st_size:
                    return None
            return wav, clip
        except (OSError, ValueError, KeyError, TypeError, EOFError, wave.Error):
            return None

    def render(self, lines, cache):
        with tempfile.TemporaryDirectory(prefix="cosmic-voices-") as directory:
            stage = Path(directory)
            source = stage / self.source.name
            data = ({**self.data, "sections": [{"lines": lines}]} if self.name == "lines"
                    else {**self.data, "cues": lines})
            write_json(source, data)
            subprocess.run([sys.executable, str(self.voice / "render_chatterbox.py"),
                            str(source), str(stage / "out"), "--profiles",
                            str(self.voice / "profiles")], check=True)
            records = {clip["id"]: clip for clip in read_json(stage / "out" / self.index.name)["clips"]}
            for line in lines:
                key = line["id"]
                entry = self.cache_entry(cache, line)
                entry.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(stage / "out" / f"{key}.wav", entry / "clip.wav")
                write_json(entry / "clip.json", records[key])
                if not self.cached(cache, line):
                    raise ValueError(f"Renderer produced an invalid WAV for {self.name}/{key}")

    def apply(self, cache, overlay):
        if not self.dirty:
            return
        missing = {self.recipe(line): line for line in self.missing if not self.cached(cache, line)}
        if missing:
            self.render(list(missing.values()), cache)
        records = self.existing.copy()
        for line in self.missing:
            key = line["id"]
            wav, clip = self.cached(cache, line)
            path = self.folder / f"{key}.wav"
            # Exclusive creation protects author-provided takes even if added after planning.
            with path.open("xb") as target, wav.open("rb") as source:
                shutil.copyfileobj(source, target)
            self.copy_to_overlay(path, overlay)
            records[key] = {**clip, "id": key, "event": line.get("event", "")}
        write_json(self.index, {**self.manifest, "catalog_sha256": sha(self.source.read_bytes()),
                               "clips": [records[line["id"]] for line in self.lines]})
        self.copy_to_overlay(self.index, overlay)

    def copy_to_overlay(self, path, overlay):
        target = overlay / path.relative_to(self.root)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["plan", "probe", "prepare", "verify"])
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--cache", type=Path)
    parser.add_argument("--overlay", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    catalogs = [Catalog(root, name) for name in CATALOGS]
    if args.mode == "plan":
        engine = sha(b"".join((root / path).read_bytes() for path in (
            ASSETS / "voice/render_chatterbox.py", "tools/chatterbox-requirements.txt",
            "tools/prepare-build-voices.py")))
        recipes = sorted({cat.recipe(line) for cat in catalogs for line in cat.missing})
        print(f"overlay={str(any(cat.dirty for cat in catalogs)).lower()}")
        print(f"missing={len(recipes)}")
        print(f"scope=cosmic-voices-v1-{engine}-")
        print(f"key=cosmic-voices-v1-{engine}-{sha(''.join(recipes).encode())}")
    elif args.mode == "verify":
        for cat in catalogs:
            if cat.dirty:
                raise ValueError(f"{cat.source}: packaged voice manifest or clips incomplete")
    else:
        if args.cache is None:
            parser.error("--cache is required")
        if args.mode == "probe":
            count = sum(not cat.cached(args.cache, line) for cat in catalogs for line in cat.missing)
            print(f"render={count}")
        else:
            if args.overlay is None:
                parser.error("--overlay is required")
            for cat in catalogs:
                cat.apply(args.cache, args.overlay)
            for cat in catalogs:
                if Catalog(root, cat.name).dirty:
                    raise ValueError(f"{cat.source}: voice preparation did not complete")


if __name__ == "__main__":
    main()
