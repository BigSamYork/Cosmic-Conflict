"""Bake seamless 1K terrain swatches in Blender. All coordinates wrap at the tile edges."""

import bpy
import numpy as np


def bake_tiles(output, sectors=None):
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
        if sectors is not None and sector not in sectors:
            continue
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
        elif sector == "vespera":
            # Resurfaced bitumen has torn edges and fewer exposed stones.
            # Warp the patch contours so they never follow the noise lattice.
            s = np.rint((x + 0.072 * broad + 0.018 * grain) * size).astype(int) % size
            t = np.rint((y - 0.058 * broad + 0.021 * grain) * size).astype(int) % size
            patch_field = 0.64 * broad[t, s] + 0.27 * grain[t, s] + 0.09 * grit
            repair = np.clip((patch_field - 0.09) * 8.0, 0, 1)
            chips = np.maximum(flecks - 0.22, 0) + 0.54 * np.maximum(grit - 0.33, 0)
            asphalt = 0.52 + 0.095 * grain + 0.16 * grit + 0.54 * chips
            bitumen = 0.29 + 0.085 * broad[t, s] + 0.06 * grit
            h = asphalt + (bitumen - asphalt) * repair
        elif sector == "xylo":
            # Warped hummocks collect moss; small rounded pinholes break up
            # the exposed peat. Both displaced coordinates wrap at tile edges.
            s = np.rint(size * (x + 0.068 * broad + 0.015 * grain)).astype(int) % size
            t = np.rint(size * (y + 0.052 * broad - 0.012 * grain)).astype(int) % size
            hummocks = 0.57 * broad[t, s] + 0.31 * grain[t, s] + 0.12 * grit[t, s]
            moss = np.clip(0.50 + 0.91 * hummocks, 0, 1)
            pores = np.maximum(-0.52 - grit[t, s], 0)
            h = 0.24 + 0.42 * moss + 0.36 * micro - 0.21 * pores
        elif sector == "kharon":
            # Coarse iron sand collects in small hollows between softer wind deposits.
            # The flight shader supplies the ripples in a single wind direction.
            s = np.rint(size * (x + 0.061 * broad + 0.016 * grain)).astype(int) % size
            t = np.rint(size * (y + 0.045 * grain - 0.053 * broad)).astype(int) % size
            drift = 0.55 * broad[t, s] + 0.27 * grain[t, s] + 0.18 * grit
            hollows = np.clip((-drift - 0.08) * 2.1, 0, 1)
            dark_grains = np.maximum(-flecks - 0.34, 0)
            quartz = np.maximum(flecks - 0.48, 0)
            h = (0.56 + 0.17 * drift - 0.10 * hollows + 0.08 * grit
                 - (0.12 + 0.31 * hollows) * dark_grains + 0.18 * quartz)
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
            h += 0.11 * np.maximum(0, np.cos(2 * np.pi * (x + y) * 48)) ** 8
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
