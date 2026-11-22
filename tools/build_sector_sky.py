"""Bake periodic cloud density, dust filaments and auroral folds for the sky."""

from pathlib import Path

import numpy as np
from PIL import Image


def build():
    w, h = 1024, 512
    y, x = np.mgrid[:h, :w]
    x, y = x / w, y / h
    rng = np.random.default_rng(745103)

    def field(u, v, frequency):
        lattice = rng.random((frequency, frequency))
        s, t = u * frequency, v * frequency
        i, j = np.floor(s).astype(int), np.floor(t).astype(int)
        a, b = s - i, t - j
        a, b = a * a * (3 - 2 * a), b * b * (3 - 2 * b)
        low = (1 - a) * lattice[j % frequency, i % frequency] + a * lattice[
            j % frequency, (i + 1) % frequency
        ]
        high = (1 - a) * lattice[(j + 1) % frequency, i % frequency] + a * lattice[
            (j + 1) % frequency, (i + 1) % frequency
        ]
        return low * (1 - b) + high * b

    warp = field(x, y, 5)
    u = x + 0.10 * warp
    v = y + 0.16 * field(x, y, 4)
    density = sum(field(u, v, 5 * 2**k) * 0.5**k for k in range(6)) / 1.969
    dust = field(x + density * 0.095, y - warp * 0.17, 14)
    strands = 1 - np.minimum(1, abs(dust - 0.5) * 5.3)
    curtains = field(x, y, 8) * 0.34 + 0.66 * field(
        x + 0.023 * warp, 0.1 * np.sin(y * np.pi * 2), 42
    )
    pixels = np.dstack((density, strands * density, curtains))
    out = (
        Path(__file__).resolve().parents[1] / "current_dev/assets/ground/sector_sky.png"
    )
    Image.fromarray(np.uint8(np.clip(pixels, 0, 1) * 255)).save(out)


if __name__ == "__main__":
    build()
