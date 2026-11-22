"""Bake seamless capillary slopes, foam cells and oil thickness for Thalassa."""

from pathlib import Path

import numpy as np
from PIL import Image


def bake():
    size = 512
    y, x = np.mgrid[:size, :size] / size
    rng = np.random.default_rng(64351)
    tau = 2 * np.pi

    # Integer wave vectors keep every layer periodic at both texture edges.
    warp = np.sin(tau * (2 * x + y)) + 0.55 * np.sin(tau * (x - 3 * y))
    height = np.zeros_like(x)
    for frequency in (4, 8, 16, 29):
        for _ in range(5):
            kx = rng.integers(-frequency, frequency + 1)
            ky = rng.integers(frequency, 2 * frequency)
            phase = tau * (kx * x + ky * y + rng.random()) + warp
            height += np.sin(phase) / frequency**1.28
    slopes = [(np.roll(height, -1, axis) - np.roll(height, 1, axis)) * 5 for axis in (1, 0)]

    # Distance to the boundary between neighboring foam bubbles.
    cells = 18
    px = (x + 0.016 * warp) * cells
    py = (y + 0.012 * np.cos(tau * (3 * x + 2 * y))) * cells
    ix, iy = np.floor(px).astype(int), np.floor(py).astype(int)
    seeds = rng.uniform(0.1, 0.9, (cells, cells, 2))
    distances = []
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            jitter = seeds[(iy + dy) % cells, (ix + dx) % cells]
            distances.append(np.hypot(ix + dx + jitter[..., 0] - px, iy + dy + jitter[..., 1] - py))
    nearest = np.partition(distances, 1, axis=0)
    foam = np.exp(-7.5 * (nearest[1] - nearest[0]))
    film = 0.5 + 0.30 * np.sin(tau * (x + 2 * y) + 2.1 * warp) + 0.19 * np.sin(tau * (4 * x - y) + warp)
    pixels = np.dstack((0.5 + slopes[0], 0.5 + slopes[1], foam, film))
    path = Path(__file__).resolve().parents[1] / "current_dev/assets/ground/sea_detail.png"
    Image.fromarray(np.uint8(np.clip(pixels, 0, 1) * 255)).save(path, optimize=True)


if __name__ == "__main__":
    bake()
