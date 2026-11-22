"""Bake a seamless packed map of strata, mineral seams and impact pits."""

from pathlib import Path

import numpy as np
from PIL import Image


def bake():
    size = 512
    rng = np.random.default_rng(82761)
    y, x = np.mgrid[:size, :size] / size

    def noise(u, v, cells):
        grid = rng.random((cells, cells))
        px, py = u * cells, v * cells
        ix, iy = np.floor(px).astype(int), np.floor(py).astype(int)
        fx, fy = px - ix, py - iy
        fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
        top = (
            grid[iy % cells, ix % cells] * (1 - fx)
            + grid[iy % cells, (ix + 1) % cells] * fx
        )
        bottom = (
            grid[(iy + 1) % cells, ix % cells] * (1 - fx)
            + grid[(iy + 1) % cells, (ix + 1) % cells] * fx
        )
        return top * (1 - fy) + bottom * fy

    warp = noise(x, y, 4) + 0.22 * noise(x, y, 12)
    field = noise(x + 0.11 * warp, y - 0.07 * warp, 11)
    fine = noise(x, y, 76)
    veins = np.exp(-np.square((field - 0.52) * 28)) * (0.55 + 0.45 * fine)
    sediment = np.sin(2 * np.pi * (3 * x + 7 * y + 1.4 * warp + 0.10 * field))
    albedo = (
        0.31
        + 0.27 * field
        + 0.18 * fine
        + 0.09 * sediment
        + rng.normal(0, 0.035, x.shape)
    )
    depth = np.zeros_like(x)
    for _ in range(72):
        cx, cy = rng.random(2)
        dx, dy = (x - cx + 0.5) % 1 - 0.5, (y - cy + 0.5) % 1 - 0.5
        r = np.hypot(dx, dy) / rng.uniform(0.008, 0.052)
        depth += 0.23 * np.exp(-np.square((r - 1) / 0.19)) - 0.34 * np.exp(
            -np.power(r / 0.79, 2)
        )
    data = np.stack((albedo + depth, veins, 0.5 + depth + (fine - 0.5) * 0.25), axis=-1)
    output = (
        Path(__file__).resolve().parents[1] / "current_dev/assets/ground/regolith.png"
    )
    Image.fromarray(np.uint8(np.clip(data, 0, 1) * 255)).save(output, optimize=True)


if __name__ == "__main__":
    bake()
