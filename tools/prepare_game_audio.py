"""Prepare the owner-supplied Music/ and SFX/ recordings with FFmpeg."""

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "current_dev" / "assets"


def encode(source, output, filters, options):
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", source, "-vn", "-af", filters,
         "-map_metadata", "-1", *options, output],
        check=True,
    )


def prepare():
    destination = ASSETS / "music" / "licensed"
    destination.mkdir(exist_ok=True)
    for name in ("Fanfare for Space", "Look Busy", "Five Armies", "Constancy Part Three",
                 "Clenched Teeth", "Grave Matters", "Mighty and Meek", "Americana", "Evening Melodrama"):
        source = ROOT / "Music" / f"Kevin MacLeod - {name}.mp3"
        meter = subprocess.run(
            ["ffmpeg", "-hide_banner", "-nostats", "-i", source, "-vn", "-af",
             "loudnorm=print_format=json", "-f", "null", "-"],
            capture_output=True, text=True, check=True,
        ).stderr
        levels = json.loads(meter[meter.rindex("{"):meter.rindex("}") + 1])
        # One constant gain preserves the dynamics of each performance.
        gain = min(-19 - float(levels["input_i"]), -2 - float(levels["input_tp"]))
        encode(source, destination / f"{name}.ogg", f"volume={gain:.2f}dB",
               ["-c:a", "libvorbis", "-q:a", "5", "-metadata", f"title={name}",
                "-metadata", "artist=Kevin MacLeod"])

    # Isolate one complete transient and its decay from each effects reel.
    for source, name, start, duration, gain in (
        ("YouTube Audio Library - Water Splash on Cement Series.mp3", "organic_rupture", 2.75, 0.76, 12.0),
        ("Gun Powder Ignite.mp3", "target_ignition", 0.16, 0.78, 0.0),
    ):
        cut = (f"atrim=start={start}:duration={duration},asetpts=PTS-STARTPTS,"
               f"volume={gain}dB,afade=t=in:d=0.004,afade=t=out:st={duration - 0.055}:d=0.055")
        encode(ROOT / "SFX" / source, ASSETS / "sfx" / f"{name}.wav", cut,
               ["-ac", "1", "-ar", "44100", "-c:a", "pcm_s16le"])


if __name__ == "__main__":
    prepare()
