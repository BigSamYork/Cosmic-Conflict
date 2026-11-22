"""Bake seamless 1K terrain swatches in Blender. All coordinates wrap at the tile edges."""

import bpy
import numpy as np


def bake_tiles(output):
    size = 1024
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    rng = np.random.default_rng(39719)

    def noise(freq):
        table = rng.uniform(-1, 1, (freq, freq)).astype(np.float32)
        u, v = x * freq, y * freq
        i, j = u.astype(int), v.astype(int)
        a, b = u - i, v - j
        a, b = a * a * (3 - 2 * a), b * b * (3 - 2 * b)
        return ((1 - a) * table[j, i] + a * table[j, (i + 1) % freq]) * (1 - b) + (
            (1 - a) * table[(j + 1) % freq, i]
            + a * table[(j + 1) % freq, (i + 1) % freq]
        ) * b

    broad, grain, grit, flecks = noise(5), noise(26), noise(124), noise(390)
    micro = 0.50 * grain + 0.32 * grit + 0.18 * flecks
    vein = np.abs(np.sin(np.pi * (5 * x + 3 * y + broad * 1.4 + grain * 0.14)))
    n = 8
    sites = rng.uniform(0.12, 0.88, (n, n, 2))
    ix, iy = (x * n).astype(int), (y * n).astype(int)
    best = np.full_like(x, 8)
    second = best.copy()
    for a in [-1, 0, 1]:
        for b in [-1, 0, 1]:
            site = sites[(iy + b) % n, (ix + a) % n]
            dist = np.hypot(
                ix + a + site[:, :, 0] - x * n, iy + b + site[:, :, 1] - y * n
            )
            second = np.minimum(second, np.maximum(best, dist))
            best = np.minimum(best, dist)
    cracks = np.exp(-np.maximum(0, second - best + micro * 0.039) * 23)
    lamina = np.sin(np.pi * 2 * (y * 10 + x * 2 + broad * 0.62 + grain * 0.065))
    for sector, low, high in [
        ("ignis", (47, 39, 45), (147, 98, 79)),
        ("cryo", (56, 107, 139), (193, 226, 232)),
        ("vespera", (32, 37, 56), (105, 104, 133)),
        ("xylo", (29, 53, 44), (108, 132, 74)),
        ("kharon", (114, 79, 56), (211, 170, 103)),
        ("thalassa", (40, 59, 67), (121, 145, 142)),
    ]:
        if sector == "ignis":
            h = 0.51 + 0.24 * broad + 0.16 * lamina + 0.30 * micro - 0.37 * cracks
        elif sector == "cryo":
            h = (
                0.52
                + 0.23 * broad
                + 0.15 * grain
                + 0.14 * micro
                - 0.53 * cracks
                + 0.14 * np.exp(-vein * 16)
            )
        elif sector == "xylo":
            h = (
                0.46
                + 0.24 * broad
                + 0.40 * micro
                + 0.27 * np.exp(-vein * 10)
                - 0.16 * cracks
            )
        elif sector == "kharon":
            ripple = np.sin(2 * np.pi * (y * 24 + x * 4 + broad * 0.4 + grain * 0.045))
            h = 0.48 + 0.19 * broad + 0.17 * ripple + 0.22 * micro
        else:
            u = (x * 4 + (np.floor(y * 4) % 2) * 0.5) % 1
            v = (y * 4) % 1
            seam = np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v))
            bolt = np.hypot(np.minimum(u, 1 - u) - 0.065, np.minimum(v, 1 - v) - 0.067)
            h = (
                0.56
                + 0.19 * broad
                + 0.15 * micro
                - 0.48 * np.exp(-seam * 96)
                - 0.42 * np.exp(-(bolt**2) * 1500)
            )
            if sector == "thalassa":
                h += 0.11 * np.maximum(0, np.cos(2 * np.pi * (x + y) * 48)) ** 8
            else:
                h -= 0.13 * np.exp(-np.abs(v - 0.23) * 92) * (u > 0.23) * (u < 0.78)
        shade = np.clip(
            (np.roll(h, 1, axis=1) - np.roll(h, -1, axis=1)) * 1.3
            + (np.roll(h, 1, axis=0) - np.roll(h, -1, axis=0)) * 0.85,
            -0.22,
            0.22,
        )
        albedo = (
            np.array(low)
            + (np.array(high) - low) * np.clip(h + shade, 0, 1)[:, :, None]
        )
        rgba = np.ones((size, size, 4), dtype=np.float32)
        rgba[:, :, :3] = albedo / 255
        image = bpy.data.images.new(sector + " surface", size, size, alpha=False)
        image.colorspace_settings.name = "Non-Color"
        image.pixels.foreach_set(rgba.ravel())
        image.file_format = "PNG"
        image.filepath_raw = str(output / (sector + "_surface.png"))
        image.save()
        bpy.data.images.remove(image)
