"""Bake a seamless relief, pigment and pocket mask for the marsh serpent."""

from pathlib import Path

import numpy as np
from PIL import Image


def bake():
    rng = np.random.default_rng(8625)
    rows, columns = 8, 10
    size = 384
    v, u = np.mgrid[:size, :size] / size
    # Stagger and warp the scales so the neck has imbricated rows, not a grid.
    x = u * columns + 0.16 * np.sin(2 * np.pi * (u + v * 2))
    y = v * rows + 0.12 * np.sin(2 * np.pi * (3 * u - v))
    x += 0.055 * np.sin(2 * np.pi * (8 * u + 3 * v))
    y += 0.036 * np.sin(2 * np.pi * (7 * v - 4 * u))
    ix, iy = np.floor(x).astype(int), np.floor(y).astype(int)
    seeds = rng.uniform(-0.16, 0.16, (rows, columns, 2))
    pigment_table = rng.uniform(0.14, 0.94, (rows, columns))
    first = np.full_like(x, 8.0)
    second = first.copy()
    pigment = np.empty_like(x)
    along, across = np.zeros_like(x), np.zeros_like(x)
    for j in (-1, 0, 1):
        for i in (-1, 0, 1):
            col, row = (ix + i) % columns, (iy + j) % rows
            sites = seeds[row, col]
            dx = x - (ix + i + 0.28 + (row % 2) * 0.50 + sites[..., 0])
            dy = y - (iy + j + 0.49 + sites[..., 1])
            distance = dx * dx + dy * dy * 1.26
            closer = distance < first
            pigment = np.where(closer, pigment_table[row, col], pigment)
            along, across = np.where(closer, dy, along), np.where(closer, dx, across)
            second = np.minimum(second, np.maximum(first, distance))
            first = np.minimum(first, distance)
    edge = np.sqrt(second) - np.sqrt(first)
    shoulder = np.clip(edge * 9.8, 0, 1)
    shoulder = shoulder * shoulder * (3 - 2 * shoulder)
    keel = np.exp(-((across - 0.13 * along) ** 2) * 24) * np.clip(0.67 - along, 0, 1)
    relief = 0.06 + shoulder * (0.52 + 0.19 * keel + 0.12 * pigment)
    pocket = np.exp(-edge * 18)
    output = np.uint8(np.rint(np.dstack((relief, pigment, pocket)) * 255))
    path = Path(__file__).resolve().parents[1] / "current_dev/assets/ground/burrow_serpent_scales.png"
    Image.fromarray(output).save(path, optimize=True)


if __name__ == "__main__":
    bake()
