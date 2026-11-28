"""Bake seamless wind-carved snow relief, accumulation and loose spindrift."""

from pathlib import Path

import numpy as np
from PIL import Image


def bake():
    size = 512
    y, x = np.mgrid[:size, :size] / size
    rng = np.random.default_rng(44091)

    def noise(u, v, columns, rows):
        grid = rng.random((rows, columns))
        u, v = u * columns, v * rows
        i, j = np.floor(u).astype(int), np.floor(v).astype(int)
        a, b = u - i, v - j
        a, b = a * a * (3 - 2 * a), b * b * (3 - 2 * b)
        top = (1 - a) * grid[j % rows, i % columns] + a * grid[j % rows, (i + 1) % columns]
        bottom = (1 - a) * grid[(j + 1) % rows, i % columns] + a * grid[(j + 1) % rows, (i + 1) % columns]
        return top * (1 - b) + bottom * b

    # Long, tapered drifts have a steep cut edge and a softer leeward face.
    bend = 0.11 * noise(x, y, 3, 4) + 0.032 * noise(x, y, 7, 7)
    drift = noise(x, y + bend, 5, 19)
    height = drift**1.7 + 0.19 * noise(x, y + bend, 11, 38)
    relief = 0.57 + 0.30 * height + 6.8 * (np.roll(height, -1, 0) - np.roll(height, 1, 0))
    pack = 0.70 * noise(x, y + bend, 4, 7) + 0.30 * noise(x, y, 11, 13)

    # Roll trailing powder ribbons back into the lee of scattered eddies.
    # Wrap distances first so eddies crossing the tile's edge join exactly.
    u, v = x.copy(), y.copy()
    for cx, cy, radius, twist in [
        (0.12, 0.81, 0.19, 3.0), (0.46, 0.53, 0.15, -3.3),
        (0.79, 0.08, 0.18, 3.4), (0.99, 0.31, 0.11, -2.6),
    ]:
        dx, dy = (u - cx + 0.5) % 1 - 0.5, (v - cy + 0.5) % 1 - 0.5
        weight = np.clip(1 - (dx * dx + dy * dy) / radius**2, 0, 1)
        angle = twist * weight**2
        u = u + dx * (np.cos(angle) - 1) - dy * np.sin(angle)
        v = v + dx * np.sin(angle) + dy * (np.cos(angle) - 1)
    v += 0.085 * noise(u, v, 4, 5)
    mist = noise(u, v, 7, 24)
    strands = noise(u, v, 10, 58)
    envelope = noise(u, v, 5, 7)
    spindrift = np.clip((mist * 0.55 + strands * 0.45 - 0.32) * 2.25, 0, 1)
    spindrift *= np.clip((envelope - 0.20) * 1.8, 0, 1)
    packed = np.dstack((relief, pack, spindrift))
    target = Path(__file__).resolve().parents[1] / "current_dev/assets/ground/cryo_snow.png"
    Image.fromarray(np.rint(np.clip(packed, 0, 1) * 255).astype("uint8")).save(target, optimize=True)


if __name__ == "__main__":
    bake()
