"""Bake a wrapping fracture, relief and vesicle map for the Ignis canyon."""

from pathlib import Path

import numpy as np
from PIL import Image


def bake():
    rng = np.random.default_rng(90831)
    size = 768
    v, u = np.mgrid[:size, :size].astype(np.float32) / size

    def noise(x, y, nx, ny):
        table = rng.random((ny, nx))
        x, y = x * nx, y * ny
        col, row = np.floor(x).astype(int), np.floor(y).astype(int)
        a, b = x - col, y - row
        a, b = a*a*(3-2*a), b*b*(3-2*b)
        top = table[row % ny, col % nx]*(1-a) + table[row % ny, (col+1) % nx]*a
        bot = table[(row+1) % ny, col % nx]*(1-a) + table[(row+1) % ny, (col+1) % nx]*a
        return (1-b)*top + b*bot

    def unit_ramp(value):
        value = np.clip(value, 0, 1)
        return value * value * (3 - 2 * value)

    x = u + 0.095*noise(u, v, 6, 7) + 0.019*noise(u, v, 22, 29)
    y = v + 0.065*noise(u, v, 5, 5) + 0.012*noise(u, v, 16, 18)
    tau = 2*np.pi
    grain = noise(u, v, 139, 139)
    broken = noise(u, v, 25, 25)
    width = 0.004 + 0.012*noise(u, v, 6, 8) + 0.004*broken
    openings = np.zeros_like(x)
    cuts = np.zeros_like(x)
    for bank, phase in [(0.14, 0.12), (0.68, 0.55)]:
        center = bank + y + 0.13*np.sin(tau*(y + phase)) + 0.045*np.sin(tau*(3*y - phase))
        center += 0.021*np.sin(tau*(5*y + phase)) + 0.007*np.sin(tau*(11*y + phase))
        distance = np.abs((x - center + 0.5) % 1 - 0.5)
        cut = np.exp(-(distance / width)**1.35)
        # Overlapping tongues of cooled rock bridge short sections of the vent.
        bridge = unit_ramp((noise(u, v, 10, 9) + 0.23*broken - 0.26) * 3.4)
        openings = np.maximum(openings, cut*bridge)
        cuts = np.maximum(cuts, cut)
        for index, start in enumerate(sorted(rng.uniform(0, 1, 5))):
            run = rng.uniform(0.12, 0.24)
            age = (y - start) % 1 / run
            side = (-1)**index
            branch = side * rng.uniform(0.07, 0.15)*age**1.15
            branch += 0.013*np.sin(age*6.2)*np.minimum(age*3, 1)
            taper = np.clip(1 - age, 0, 1)
            d = np.abs((x - center - branch + 0.5) % 1 - 0.5)
            finger = np.exp(-(d / (0.0006 + width*0.72*taper))**1.35) * unit_ramp(taper*6)
            openings = np.maximum(openings, finger*bridge)
            cuts = np.maximum(cuts, finger)

    # Pitted clinker breaks up the glass and the edges of the open fissures.
    pores = np.clip((noise(u, v, 170, 170) - 0.65)*4.5, 0, 1)
    elevation = 0.53 + 0.16*noise(x, y, 12, 14) - 0.30*cuts - 0.07*pores
    lighting = 0.54 + 0.7*(elevation - 0.5)
    lighting += 2.4*(np.roll(elevation, 1, 1) - np.roll(elevation, -1, 1))
    lighting += 1.3*(np.roll(elevation, 1, 0) - np.roll(elevation, -1, 0))
    aggregate = 0.49*broken + 0.26*grain + 0.25*noise(u, v, 5, 6) - 0.25*pores
    packed = np.dstack((openings, lighting, aggregate))
    target = Path(__file__).resolve().parents[1] / "current_dev/assets/ground/ignis_basalt.png"
    Image.fromarray(np.rint(255*np.clip(packed, 0, 1)).astype("uint8")).save(target, optimize=True)


if __name__ == "__main__":
    bake()
