"""Prepare the supplied canopy and lightning recordings for the in-game audio mix."""

from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "current_dev/assets/sfx"


def convert(source, output, filters):
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-i", str(ROOT / "SFX" / source),
        "-af", filters, "-ar", "32000", "-c:a", "pcm_s16le", str(OUTPUT / output)
    ], check=True)


if __name__ == "__main__":
    convert("Monster Alien Growl Tense.mp3", "canopy_parasite.wav",
            "afade=t=in:d=0.032,afade=t=out:st=11.99:d=0.22")
    convert("Thunder Crack.mp3", "thunder_crack.wav", "afade=t=out:st=3.32:d=0.08")
    convert("Small Glass Pane Shatter.mp3", "canopy_fracture.wav",
            "atrim=end=1.31,afade=t=out:st=1.21:d=0.10")
