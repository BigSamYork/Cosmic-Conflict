"""Build the six planetary architecture and botany collections in Blender."""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from build_ground import OUTPUT, SECTORS, lathe, pipe, plate


def drum(s, x, y, bottom, height, radius, finish="paint", sides=24):
    lathe(
        s,
        [
            (bottom, radius * 0.96),
            (bottom + height * 0.05, radius),
            (bottom + height * 0.95, radius),
            (bottom + height, radius * 0.95),
        ],
        finish,
        sides,
        (x, y),
    )


def band(s, x, y, z, radius, finish="stripe", width=0.26):
    drum(s, x, y, z, width, radius, finish)


def windows(s, x, y, z, width, count, bright="light"):
    for i in range(count):
        at = x + width * ((i + 0.5) / count - 0.5)
        plate(
            s,
            (at, y, z),
            (width * 0.69 / count, 0.24, 1.15),
            bright if i % 4 != 1 else "glass",
        )


def ribs(s, x, y, z, width, height, depth, count=6):
    """Transverse structural arches around a barrel-vaulted hall."""
    for j in range(count):
        along = y + depth * (j / (count - 1) - 0.5)
        pipe(
            s,
            [
                (x + width * cos(i * pi / 16), along, z + height * sin(i * pi / 16))
                for i in range(17)
            ],
            0.24,
            "stripe",
            8,
        )


def hall(s, x, y, z, width, length, height):
    s.rows(
        [
            [
                (
                    x + width * cos(i * pi / 32),
                    y + side * length / 2,
                    z + height * sin(i * pi / 32),
                )
                for i in range(33)
            ]
            for side in [-1, 1]
        ],
        "paint",
        closed=True,
    )
    ribs(s, x, y, z, width + 0.12, height + 0.18, length)
    windows(s, x, y - length / 2 - 0.1, z + height * 0.32, width * 1.55, 5)


def crucible(s):
    plate(s, (0, 0, 1), (18, 15, 4), "frame")
    lathe(
        s,
        [
            (2, 4.1),
            (5, 4.7),
            (12, 5.1),
            (14, 4.5),
            (16, 3.3),
            (18, 3.3),
            (18.2, 2.7),
            (16.5, 2.6),
        ],
        "copper",
        36,
    )
    for z, r in [(5, 4.8), (9, 5), (12, 5.2), (17, 3.45)]:
        band(s, 0, 0, z, r)
    for side in [-1, 1]:
        for i in range(3):
            x, y = side * 6.8, (i - 1) * 3
            pipe(s, [(x, y, 2), (x, y, 7 + i), (side * 4.0, y, 10 + i)], 0.49, "steel")
        hall(s, side * 7, 1, 2, 2.3, 10, 3.1)
    band(s, 0, 0, 16.45, 2.67, "light")


def kiln_battery(s):
    plate(s, (0, 0, 0.6), (19, 17, 3.4), "frame")
    for x, y, h in [(-5, -3, 8), (4, -3, 11), (-1, 4.6, 15)]:
        lathe(
            s,
            [
                (1, 3.7),
                (3, 3.8),
                (h * 0.68, 2.9),
                (h, 1.55),
                (h + 0.5, 1.70),
                (h + 0.5, 1.25),
                (h - 0.3, 1.2),
            ],
            "paint",
            28,
            (x, y),
        )
        for i in range(6):
            a = i * tau / 6
            pipe(
                s,
                [
                    (x + 3.72 * cos(a), y + 3.72 * sin(a), 2),
                    (x + 2.95 * cos(a), y + 2.95 * sin(a), h * 0.68),
                ],
                0.24,
                "copper",
            )
        band(s, x, y, h - 0.45, 1.75, "light")
        plate(s, (x, y - 3.55, 2.7), (2.5, 0.5, 2.6), "frame")
        for k in range(3):
            plate(s, (x, y - 3.88, 2.1 + 0.58 * k), (1.7, 0.12, 0.18), "light")


def exchange(s):
    plate(s, (0, 0, 2.7), (15, 17, 7.8), "paint")
    for j in range(8):
        x = (j - 3.5) * 1.8
        pipe(
            s,
            [(x, -7, 5), (x, -5, 11), (x, 3, 14), (x, 6, 8), (x, 7, 5)],
            0.65,
            "copper",
        )
        plate(s, (x, -3, 9), (0.37, 9.4, 6), "steel")
    for side in [-1, 1]:
        windows(s, 0, side * 8.56, 4.2, 12, 7)


def observatory(s):
    drum(s, 0, 0, -2, 8, 7.1, "paint")
    band(s, 0, 0, 5, 7.4)
    lathe(
        s,
        [
            (5.6 + 7 * sin(i * pi / 32), 7.0 * cos(i * pi / 32) + 0.08)
            for i in range(17)
        ],
        "glass",
        40,
    )
    for k in range(12):
        a = k * tau / 12
        pipe(
            s,
            [
                (
                    7.12 * cos(a) * cos(i * pi / 24),
                    7.12 * sin(a) * cos(i * pi / 24),
                    5.8 + 7.1 * sin(i * pi / 24),
                )
                for i in range(13)
            ],
            0.14,
            "ceramic",
        )
    s.tube([(0, -1.9, 10.8), (0, -6.4, 15.5)], [1.55, 1.95], "steel", 24)
    s.tube([(0, -6.4, 15.5), (0, -6.65, 15.75)], [1.62, 1.62], "glass", 24)
    hall(s, 7, 0, 0.2, 3.3, 8.5, 4)


def borehead(s):
    plate(s, (0, 0, 1), (17, 13, 4), "frame")
    for side in [-1, 1]:
        hall(s, side * 5, 0, 2, 3.5, 10, 5)
        for y in [-3.8, 3.8]:
            pipe(s, [(side * 4.8, y, 3), (side * 1.8, y * 0.42, 19)], 0.46, "ceramic")
    for z in range(6, 19, 3):
        width = 4.6 - z * 0.14
        for y in [-2.2, 2.2]:
            pipe(s, [(-width, y, z), (width - 0.4, y, z + 3)], 0.22, "stripe")
    plate(s, (0, 0, 19), (5.2, 4.6, 2), "steel")
    lathe(s, [(4, 1.3), (7, 1.3), (7.3, 0.94), (18, 0.94)], "copper", 20)


def greenhouse(s):
    for x, y, r in [(-5, 0, 5), (4, 2.7, 4.4), (1, -5, 3.6)]:
        drum(s, x, y, -1.7, 3.8, r, "ceramic")
        s.pod((x, y, 2.1), (r, r, r * 0.9), "glass", 12, 28)
        for i in range(8):
            a = tau * i / 8
            pipe(
                s,
                [
                    (
                        x + r * 1.02 * cos(a) * cos(j * pi / 16),
                        y + r * 1.02 * sin(a) * cos(j * pi / 16),
                        2.1 + r * 0.93 * sin(j * pi / 16),
                    )
                    for j in range(9)
                ],
                0.16,
                "steel",
            )
        band(s, x, y, 2, r * 1.03, "light", 0.15)


def arcade(s):
    for x in [-6.2, 6.2]:
        plate(s, (x, 0, 6), (4.0, 19, 15), "paint")
        for z in [4, 8, 12]:
            windows(s, x, -9.6, z, 3.6, 3)
    for y in [-7, 0, 7]:
        pipe(
            s,
            [(-7.4, y, 12), (-5, y, 17), (0, y, 20), (5, y, 17), (7.4, y, 12)],
            0.73,
            "steel",
        )
        pipe(
            s,
            [
                (-7.4, y - 0.5, 12),
                (-5, y - 0.5, 17),
                (0, y - 0.5, 20),
                (5, y - 0.5, 17),
                (7.4, y - 0.5, 12),
            ],
            0.15,
            "light",
        )
    plate(s, (0, 0, 19.5), (7, 20, 1.3), "glass")


def lantern_hotel(s):
    drum(s, 0, 0, -1, 8, 4.1, "frame", 12)
    for i, (r, z) in enumerate([(6.4, 7), (7.4, 14), (5.7, 21), (3.9, 28)]):
        lathe(
            s,
            [
                (z - 1, r * 0.65),
                (z, r),
                (z + 1.1, r * 1.03),
                (z + 4.6, r * 0.91),
                (z + 5.1, r * 0.66),
            ],
            "glass",
            16,
            phase=pi / 16,
        )
        band(s, 0, 0, z + 1.1, r * 1.02, "light" if i % 2 == 0 else "stripe", 0.36)
        for j in range(8):
            a = tau * j / 8
            pipe(
                s,
                [
                    (r * cos(a), r * sin(a), z),
                    (r * 0.9 * cos(a), r * 0.9 * sin(a), z + 4.9),
                ],
                0.19,
                "steel",
            )
    pipe(s, [(0, 0, 32), (0, 0, 37)], 0.13, "copper")


def sky_exchange(s):
    for side in [-1, 1]:
        h = 24 if side < 0 else 30
        x = side * 5.8
        plate(s, (x, 0, h / 2 - 1), (5.7, 9, h + 2), "paint")
        for z in range(2, h, 3):
            windows(s, x, -4.6, z, 5.3, 4)
            plate(s, (x, 0, z + 0.9), (6, 9.5, 0.28), "stripe")
    for z in [12, 21]:
        plate(s, (0, 0, z), (8, 3.6, 2.6), "glass")
        plate(s, (0, 0, z + 1.45), (8.7, 4.2, 0.38), "light")


def reed_lodge(s):
    for x, y, h in [(-4, 0, 5.7), (3.8, 2, 7.2), (2, -4.3, 4.6)]:
        for j in range(7):
            a = tau * j / 7
            pipe(
                s,
                [
                    (x + 4 * cos(a), y + 4 * sin(a), -2),
                    (x + 2.9 * cos(a), y + 2.9 * sin(a), h),
                ],
                0.34,
                "frame",
            )
        drum(s, x, y, h - 2.2, 2.5, 3.6, "stripe", 16)
        lathe(
            s,
            [(h, 4.6), (h + 0.45, 4.8), (h + 1.5, 3.8), (h + 3.7, 1.4), (h + 5, 0.18)],
            "paint",
            24,
            (x, y),
        )
        for k in range(4):
            plate(
                s, (x + (k - 1.5) * 0.85, y - 3.4, h - 1.1), (0.48, 0.25, 0.9), "light"
            )


def seed_vault(s):
    s.pod((0, 0, 7.6), (6.8, 6.8, 9), "paint", 18, 32)
    for j in range(12):
        a = tau * j / 12
        s.tube(
            [
                (r * cos(a + f * 0.42), r * sin(a + f * 0.42), z)
                for f, (r, z) in enumerate(
                    [(8, -1), (6.8, 4), (6.7, 9), (4.9, 14), (0.6, 16.4)]
                )
            ],
            [0.94, 0.64, 0.46, 0.38, 0.19],
            "stripe",
            10,
        )
    hall(s, 0, -5.8, 0, 2.8, 5.2, 4.3)


def canopy_clinic(s):
    for x, y, h in [(-4, -1, 11), (4, 2, 14), (0, 5, 9)]:
        s.tube(
            [(x * 1.6, y * 1.5, -2), (x * 1.2, y, 4), (x, y, h)],
            [1.1, 0.75, 0.65],
            "frame",
            12,
        )
        s.pod((x, y, h), (4, 3.6, 2.6), "ceramic", 12, 26)
        band(s, x, y, h, 3.95, "light", 0.2)
        lathe(
            s,
            [(h + 1, 3.8), (h + 1.5, 4.9), (h + 2.7, 3.1), (h + 3.2, 0.4)],
            "paint",
            28,
            (x, y),
        )
    pipe(s, [(-4, -1, 10.4), (0, 0, 10), (4, 2, 13.5)], 0.75, "copper", 14)


def sea_deck(s, w, d):
    for side in [-1, 1]:
        s.pod((side * w * 0.34, 0, -1), (2.4, d * 0.57, 2.9), "frame", 12, 24)
        for y in [-d * 0.31, d * 0.31]:
            drum(s, side * w * 0.34, y, -3.6, 9.0, 1.0, "copper", 18)
    plate(s, (0, 0, 4), (w, d, 2), "paint")
    for side in [-1, 1]:
        x = side * (w / 2 - 0.4)
        pipe(s, [(x, -d * 0.44, 6.6), (x, d * 0.44, 6.6)], 0.13, "stripe", 8)
        for i in range(7):
            y = (i / 6 - 0.5) * d * 0.88
            pipe(s, [(x, y, 5), (x, y, 6.6)], 0.095, "steel", 8)


def wave_station(s):
    sea_deck(s, 18, 20)
    hall(s, 0, 3, 5, 5.3, 9, 4.2)
    for i in range(4):
        x = (i - 1.5) * 4.2
        pipe(s, [(x, -2, 6), (x, -5.8, 8), (x, -10, 4), (x, -13, 1)], 0.48, "stripe")
        s.pod((x, -13, 1), (1.8, 2.8, 1.55), "copper", 12, 20)


def lighthouse(s):
    sea_deck(s, 14, 15)
    lathe(
        s,
        [(5, 3.7), (6, 3.8), (8, 3), (20, 1.7), (21, 2.9), (21.8, 2.9)],
        "ceramic",
        36,
    )
    for z, r in [(9, 2.97), (14.5, 2.42), (19, 1.98)]:
        band(s, 0, 0, z, r, "copper", 1.1)
    drum(s, 0, 0, 21.8, 3.5, 1.95, "light")
    for i in range(8):
        a = tau * i / 8
        pipe(
            s,
            [
                (2.05 * cos(a), 2.05 * sin(a), 21.8),
                (2.05 * cos(a), 2.05 * sin(a), 25.4),
            ],
            0.14,
            "frame",
        )
    lathe(s, [(25.4, 2.9), (25.8, 3.1), (27.9, 0.25)], "steel", 24)


def nursery(s):
    sea_deck(s, 17, 19)
    hall(s, -3.8, 1, 5, 3.3, 12, 3.5)
    for y in [-4.5, 3.0]:
        lathe(
            s,
            [(5, 2.8), (6, 3.2), (7.6, 3.2), (7.6, 2.7), (6.8, 2.6)],
            "stripe",
            28,
            (3.6, y),
        )
        drum(s, 3.6, y, 6.55, 0.2, 2.65, "glass")
    for y in [-5, 5]:
        pipe(s, [(0, y, 5.1), (0, y, 11), (5, y, 11), (5, y, 9.2)], 0.30, "copper")


def windcatcher(s):
    plate(s, (0, 0, 2), (17, 15, 6), "paint")
    for x, y, h in [(-5, -4, 14), (4, 1, 20), (-4, 4, 11)]:
        plate(s, (x, y, h / 2), (4.5, 4.8, h), "ceramic")
        for j in range(4):
            plate(s, (x, y - 2.48, h - 4.2 + j * 0.85), (3.6, 0.35, 0.42), "frame")
        plate(s, (x, y, h + 0.2), (5.4, 5.6, 0.75), "stripe")
    windows(s, 0, -7.6, 2.9, 14, 7, "glass")


def cistern(s):
    for i in range(4):
        drum(s, 0, 0, i - 1.1, 1.4, 8.8 - i * 0.85, "paint", 32)
    for i in range(10):
        a = tau * i / 10
        drum(s, 5.2 * cos(a), 5.2 * sin(a), 2.5, 6.7, 0.65, "stripe", 12)
    lathe(
        s,
        [(9, 6.8), (9.6, 7.1), (10, 6.6), (13, 4.9), (14.8, 2.3), (15.1, 0.15)],
        "copper",
        36,
    )
    drum(s, 0, 0, 2.9, 0.3, 4.4, "glass")


def caravanserai(s):
    for side in [-1, 1]:
        plate(s, (side * 7.4, 0, 3.1), (3.4, 17, 8.4), "paint")
        hall(s, side * 7.4, 0, 6.9, 2.1, 16.2, 2)
    plate(s, (0, 7.1, 2.9), (14, 2.8, 7.5), "paint")
    hall(s, 0, 7.1, 6.2, 4.8, 3.0, 2.8)
    for x in [-4.2, 4.2]:
        drum(s, x, -7, -1.3, 8.6, 1.8, "ceramic", 16)
    pipe(
        s,
        [
            (-4.2, -7, 6.3),
            (-2.5, -7, 8.8),
            (0, -7, 9.8),
            (2.5, -7, 8.8),
            (4.2, -7, 6.3),
        ],
        0.65,
        "stripe",
    )
    for j in range(4):
        plate(s, (-4 + j * 2.6, 7.1, 6.9), (1.45, 2.7, 1.1), "stripe")


def blade(s, origin, angle, reach, rise, arch, width, finish="paint", twist=0.0):
    """A tapering, folded leaf with a midrib and different dorsal/ventral faces."""
    rows, spine = [], []
    for j in range(10):
        t = j / 9
        a = angle + twist * t
        center = Vector(origin) + Vector(
            (reach * t * cos(a), reach * t * sin(a), rise * t + arch * sin(pi * t))
        )
        lateral = Vector((-sin(a), cos(a), 0))
        w = width * (0.016 + sin(pi * t) ** 0.78)
        ridge = center + Vector((0, 0, w * 0.32))
        rows.append(
            [
                center - lateral * w,
                ridge,
                center + lateral * w,
                center - Vector((0, 0, w * 0.12)),
            ]
        )
        spine.append(ridge)
    s.rows(rows, finish)
    s.tube(spine, [width * (0.065 - 0.047 * j / 9) for j in range(10)], "stripe", 5)


def crown(s, origin, count, radius, height, arch, width, turn=0):
    for i in range(count):
        a = i * 2.39996 + turn
        tier = i / count
        blade(
            s,
            origin,
            a,
            radius * (1 - 0.55 * tier),
            height * (0.45 + tier),
            arch,
            width * (1 - 0.36 * tier),
            "paint" if i % 4 else "ceramic",
            0.13 * sin(a),
        )


def limb(s, points, radii):
    s.tube(points, radii, "frame", 12)


def aloe(s):
    for x, y, r in [(0, 0, 1), (-2.2, 1, 0.54), (2, -1.3, 0.49)]:
        crown(s, (x, y, -0.45), 19, 4.1 * r, 6.1 * r, 0.9 * r, 0.92 * r)
    limb(s, [(0, 0, 0), (0.2, 0, 5), (0.6, 0.2, 8.1)], [0.36, 0.18, 0.095])
    for j in range(10):
        a = j * 2.4
        s.pod(
            (0.5 + 0.4 * cos(a), 0.4 * sin(a), 6.4 + 0.16 * j),
            (0.31, 0.26, 0.48),
            "light",
            7,
            12,
        )


def emberbell(s):
    for i in range(8):
        a = i * 2.4
        x, y = (1.0 + i * 0.26) * cos(a), (1.0 + i * 0.26) * sin(a)
        h = 5.5 + 2 * sin(a)
        limb(
            s,
            [
                (x * 0.4, y * 0.4, -0.6),
                (x, y, h * 0.65),
                (x + 0.7, y, h),
                (x + 1.25, y, h - 0.6),
            ],
            [0.31, 0.21, 0.16, 0.10],
        )
        at = (x + 1.25, y)
        lathe(
            s,
            [
                (h - 2, 0.66),
                (h - 2.25, 0.83),
                (h - 1.7, 0.58),
                (h - 1, 0.39),
                (h - 0.55, 0.15),
            ],
            "ceramic",
            18,
            at,
        )
        s.pod((*at, h - 2.18), (0.23, 0.23, 0.32), "light", 7, 12)
        blade(s, (x * 0.7, y * 0.7, h * 0.31), a, 1.5, 1.2, 0.35, 0.52)


def ash_fan(s):
    for k, (x, y, h) in enumerate([(0, 0, 6), (-2, 0.3, 3.8), (2, 0.8, 4.3)]):
        limb(
            s,
            [(x - 0.4, y, -0.7), (x, y, h * 0.40), (x + 0.32, y, h * 0.60)],
            [0.52, 0.32, 0.2],
        )
        root = (x + 0.32, y, h * 0.56)
        for j in range(13):
            theta = (j - 6) * 0.17
            blade(
                s,
                root,
                (0 if theta > 0 else pi) + 0.22 * k,
                h * abs(sin(theta)) * 0.76,
                h * cos(theta) * 0.72,
                0.12,
                0.32,
                "ceramic" if j % 3 == 0 else "paint",
            )


def rime_spruce(s):
    limb(s, [(0, 0, -1.1), (-0.25, 0, 6), (0.4, 0, 14.5)], [0.86, 0.50, 0.10])
    for tier in range(8):
        z = 1.4 + tier * 1.45
        reach = 4.3 * (1 - tier / 9)
        for i in range(8):
            a = i * tau / 8 + tier * 0.61
            blade(
                s,
                (0, 0, z),
                a,
                reach,
                -reach * 0.35,
                reach * 0.23,
                reach * 0.30,
                "ceramic" if (i + tier) % 4 == 0 else "paint",
            )


def frost_cushion(s):
    for i in range(16):
        a = i * 2.4
        r = 0.77 * i**0.5
        x, y = r * cos(a), r * sin(a)
        h = 2.25 - r * 0.38
        s.pod((x, y, 0.1), (1, 0.9, h), "paint", 9, 15)
        for k in range(3):
            blade(s, (x, y, h * 0.60), a + k * 2.09, 0.75, 0.9, 0.20, 0.34, "ceramic")
        s.pod((x, y, h + 0.33), (0.21, 0.21, 0.36), "light", 7, 12)


def willow(s):
    limb(s, [(0, 0, -0.8), (-0.8, 0.2, 3), (0.5, 0, 7.8)], [0.8, 0.55, 0.3])
    for i in range(12):
        a = i * 2.4
        x, y = (3.7 + 0.5 * sin(i)) * cos(a), (3.7 + 0.5 * sin(i)) * sin(a)
        z = 7.7 + 1.5 * cos(i)
        limb(
            s,
            [(0, 0, 5.1), (x * 0.48, y * 0.48, z), (x, y, z - 0.7)],
            [0.28, 0.17, 0.095],
        )
        for j in range(3):
            blade(
                s,
                (x * (0.65 + j * 0.16), y * (0.65 + j * 0.16), z - 0.55),
                a + j,
                0.9,
                -3.4 - 0.5 * j,
                0.3,
                0.35,
                "stripe" if j == 0 else "paint",
                0.36,
            )


def ginkgo(s):
    limb(s, [(0, 0, -1), (0.25, 0, 5), (-0.35, 0.16, 10.2)], [0.75, 0.47, 0.12])
    for j in range(16):
        a = j * 2.4
        z = 4 + j * 0.32
        r = 4.2 - (j / 16) ** 2 * 2.9
        x, y = r * cos(a), r * sin(a)
        limb(
            s,
            [(0, 0, z), (x * 0.5, y * 0.5, z + 0.7), (x, y, z + 1.7)],
            [0.22, 0.14, 0.08],
        )
        for k in range(5):
            blade(
                s,
                (x, y, z + 1.5),
                a + (k - 2) * 0.53,
                1.48,
                0.65 + 0.22 * cos(k),
                0.2,
                0.47,
                "ceramic" if (j + k) % 3 == 0 else "paint",
            )


def wisteria(s):
    for side in [-1, 1]:
        limb(
            s,
            [
                (side * 2.6, 0, -0.8),
                (side * 2.9, 0, 4.2),
                (side * 1.3, 0, 7.0),
                (0, 0.2, 7.5),
            ],
            [0.57, 0.42, 0.32, 0.17],
        )
    for i in range(17):
        a = i * 2.4
        x, y = 3.6 * cos(a), 1.9 * sin(a)
        h = 6.2 + cos(a) * 0.65
        blade(s, (x * 0.5, y * 0.5, h), a, 2.8, 0.6, 0.45, 0.9)
        for j in range(6):
            size = (6.7 - j) * 0.1
            s.pod(
                (x + 0.17 * sin(j), y, h - 0.49 * j),
                (size, size * 0.9, 0.49),
                "ceramic" if j < 4 else "stripe",
                7,
                12,
            )


def cycad(s):
    for level in range(8):
        z = level * 0.47 - 0.5
        lathe(
            s,
            [(z, 1.15), (z + 0.3, 1.4), (z + 0.62, 1.08)],
            "frame",
            14,
            phase=level * 0.18,
        )
    for i in range(11):
        a = i * 2.4
        for j in range(1, 7):
            f = j / 7
            base = (
                4.6 * f * cos(a),
                4.6 * f * sin(a),
                3.3 + 2.2 * sin(pi * f) - 0.4 * f,
            )
            for side in [-1, 1]:
                blade(s, base, a + side * 0.81, 1.3 * (1 - 0.6 * f), 0.17, 0.22, 0.25)
        pipe(
            s,
            [
                (4.6 * f * cos(a), 4.6 * f * sin(a), 3.3 + 2.2 * sin(pi * f) - 0.4 * f)
                for f in [j / 8 for j in range(9)]
            ],
            0.13,
            "stripe",
            6,
        )


def pitchers(s):
    for i in range(7):
        a = i * 2.4
        r = 1.05 * i**0.5
        x, y = r * cos(a), r * sin(a)
        h = 5.8 + 2.3 * cos(a)
        lathe(
            s,
            [
                (-0.8, 0.48),
                (h * 0.32, 0.94),
                (h * 0.78, 0.71),
                (h, 1.20),
                (h + 0.18, 1.33),
                (h + 0.20, 0.97),
                (h * 0.79, 0.54),
            ],
            "paint",
            24,
            (x, y),
            stretch=(0.88, 1),
        )
        rim = [
            (x + 1.01 * cos(tau * k / 32), y + 1.15 * sin(tau * k / 32), h + 0.2)
            for k in range(33)
        ]
        pipe(s, rim, 0.16, "ceramic", 8)
        blade(s, (x, y + 0.56, h), a, 1.65, 0.75, 0.70, 0.93, "stripe")


def shield_fern(s):
    for j in range(11):
        a = j * 2.4
        h = 5 + 2 * cos(a)
        x, y = 2.6 * cos(a), 2.6 * sin(a)
        limb(
            s,
            [(0, 0, -0.6), (x * 0.64, y * 0.64, h * 0.52), (x, y, h)],
            [0.23, 0.17, 0.1],
        )
        blade(
            s, (x, y, h), a, 3.4, -1.0, 0.5, 1.55, "ceramic" if j % 4 == 0 else "paint"
        )
        for k in range(1, 4):
            for side in [-1, 1]:
                blade(
                    s,
                    (x + k * 0.57 * cos(a), y + k * 0.57 * sin(a), h - 0.1 * k),
                    a + side * 0.8,
                    1.15,
                    -0.40,
                    0.17,
                    0.34,
                )


def mangrove(s):
    for i in range(7):
        a = i * tau / 7
        limb(
            s,
            [
                (4.7 * cos(a), 4.7 * sin(a), -1.1),
                (2.7 * cos(a), 2.7 * sin(a), 2.9),
                (0, 0, 4.2),
            ],
            [0.27, 0.60, 0.92],
        )
    limb(s, [(0, 0, 3.4), (0.3, 0, 7.2), (-0.5, 0, 10.1)], [1.28, 0.84, 0.35])
    for j in range(8):
        a = j * 2.4
        x, y = 3.85 * cos(a), 3.85 * sin(a)
        h = 8.8 + 1.4 * sin(a)
        limb(
            s,
            [(0, 0, 6.4), (x * 0.48, y * 0.48, h), (x, y, h + 0.3)],
            [0.48, 0.35, 0.15],
        )
        crown(s, (x, y, h), 5, 2.3, 0.65, 0.53, 0.65, a)
        s.pod((x, y, h - 1.3), (0.72, 0.6, 1.2), "ceramic", 10, 18)


def kelp(s):
    for i in range(13):
        a = i * 2.4
        x, y = 2.05 * cos(a), 2.05 * sin(a)
        h = 4 + 3 * (0.5 + 0.5 * cos(i * 3.7))
        blade(
            s,
            (x, y, -2),
            a,
            2.1,
            h + 2,
            0.8,
            0.68,
            "ceramic" if i % 4 == 0 else "paint",
            1.30,
        )


def bladderwrack(s):
    for i in range(9):
        a = i * 2.4
        x, y = 3.8 * cos(a), 3.8 * sin(a)
        points = [
            (0, 0, -1.2),
            (x * 0.5, y * 0.5, 0.45),
            (x, y, 1.55),
            (x * 1.12, y * 1.12, 2.7),
        ]
        limb(s, points, [0.33, 0.24, 0.17, 0.09])
        for j in [1, 2, 3]:
            p = points[j]
            s.pod(p, (0.59, 0.53, 0.72), "ceramic", 9, 16)
            blade(s, p, a + 0.68, 1.75, 1, 0.4, 0.47)


def lotus(s):
    for x, y, r in [(0, 0, 3.3), (-3.6, 0.8, 2.2), (2.8, 2.3, 2.45), (2.6, -2.4, 1.8)]:
        for j in range(10):
            a = tau * j / 10
            blade(s, (x, y, 0.44), a, r, 0.33, 0.26, r * 0.32, "paint")
        for j in range(9):
            blade(
                s, (x, y, 0.75), j * 2.4, 0.43 * r, 0.56 * r, 0.13, r * 0.13, "ceramic"
            )
        s.pod((x, y, 1.3), (0.42, 0.42, 0.52), "light", 9, 16)


def barrel_bloom(s):
    for j, (x, y, h) in enumerate([(0, 0, 5.6), (-2.6, 0.5, 3.7), (1.9, 1.5, 2.9)]):
        rows = []
        for k in range(17):
            t = k / 16
            row = []
            for i in range(72):
                a = tau * i / 72
                r = (
                    h
                    * (0.04 + 0.35 * sin(pi * (0.06 + 0.92 * t)) ** 0.66)
                    * (0.91 + 0.09 * cos(12 * a))
                )
                row.append((x + r * cos(a), y + r * sin(a), h * t - 0.55))
            rows.append(row)
        s.rows(rows, "paint")
        for i in range(9):
            blade(
                s, (x, y, h - 0.55), i * tau / 9 + j, 0.96, 0.72, 0.15, 0.27, "ceramic"
            )


def yucca(s):
    for i, (x, y, h) in enumerate([(0, 0, 4.2), (-2, 1, 2.3), (1.4, -2, 1.4)]):
        limb(s, [(x, y, -0.7), (x + 0.2, y, h)], [0.65, 0.37])
        crown(s, (x + 0.2, y, h), 18, 3.5, h * 0.8, 0.36, 0.41, i)
    limb(s, [(0, 0, 4), (0.5, 0, 7), (1.2, -0.2, 10.2)], [0.24, 0.16, 0.07])
    for i in range(10):
        a = i * 2.4
        s.pod(
            (0.92 + 0.52 * cos(a), 0.47 * sin(a), 7.9 + i * 0.20),
            (0.31, 0.26, 0.46),
            "ceramic",
            7,
            12,
        )


def acacia(s):
    limb(s, [(0, 0, -1), (-0.75, 0, 4.6), (0.3, 0.2, 7.2)], [1.0, 0.62, 0.39])
    for i in range(9):
        a = i * 2.4
        r = 4.7 + 1.2 * sin(a)
        x, y = r * cos(a), r * sin(a)
        z = 7.2 + 1.3 * sin(i * 3.5)
        limb(
            s,
            [(0, 0, 5.3), (x * 0.56, y * 0.56, z - 1.4), (x, y, z)],
            [0.43, 0.29, 0.13],
        )
        for j in range(5):
            ang = j * 2.4 + a
            s.pod(
                (x + 1.1 * cos(ang), y + 1.1 * sin(ang), z + 0.45),
                (2.0, 1.65, 0.76),
                "paint" if j % 3 else "stripe",
                8,
                16,
            )


# Each row matches the order of the editable objects in the gallery.
COLLECTIONS = {
    "ignis": (crucible, kiln_battery, exchange, aloe, emberbell, ash_fan),
    "cryo": (observatory, borehead, greenhouse, rime_spruce, frost_cushion, willow),
    "vespera": (arcade, lantern_hotel, sky_exchange, ginkgo, wisteria, cycad),
    "xylo": (reed_lodge, seed_vault, canopy_clinic, pitchers, shield_fern, mangrove),
    "thalassa": (wave_station, lighthouse, nursery, kelp, bladderwrack, lotus),
    "kharon": (windcatcher, cistern, caravanserai, barrel_bloom, yucca, acacia),
}
FOLIAGE = {
    "ignis": ("823f42", "f8a55e", "d85735", "4b3338", "ffb85d"),
    "cryo": ("39878c", "9ad3b9", "c7e8e7", "526674", "a9efff"),
    "vespera": ("538e65", "e5a366", "bc86bf", "665150", "fbdca2"),
    "xylo": ("499052", "99b868", "dc9069", "64534d", "d4ee93"),
    "thalassa": ("277f72", "74bba0", "e09f79", "426756", "ffd29b"),
    "kharon": ("859156", "b1ad69", "e88959", "72583a", "ffda88"),
}


def main():
    previous = bpy.context.scene
    factory_scene = not bpy.data.filepath and {o.name for o in previous.objects} == {
        "Camera",
        "Cube",
        "Light",
    }
    scene = bpy.data.scenes.new("Settlements and flora")
    bpy.context.window.scene = scene
    mat = flight_material()
    for row, (sector, models) in enumerate(COLLECTIONS.items()):
        collection = bpy.data.collections.new(sector.title())
        scene.collection.children.link(collection)
        for col, model in enumerate(models):
            skin = Skin(f"{sector}_{model.__name__}", SECTORS[sector])
            if col >= 3:
                skin.palette.update(
                    zip(
                        ("paint", "stripe", "ceramic", "frame", "light"),
                        FOLIAGE[sector],
                    )
                )
            if model is ginkgo:
                skin.palette.update(paint="b98d4c", stripe="e7b564", ceramic="89ab64")
            elif model is kelp:
                skin.palette.update(paint="387e63", ceramic="a7ad4e")
            model(skin)
            obj = bake(skin, scene, mat, OUTPUT)
            scene.collection.objects.unlink(obj)
            collection.objects.link(obj)
            obj.location = (col * 30, row * 36, 0)
    bpy.ops.object.select_all(action="DESELECT")
    scene.display.shading.color_type = "MATERIAL"
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.shading.color_type = "MATERIAL"
                space.shading.show_cavity = True
                space.overlay.show_overlays = False
                space.region_3d.view_location = (75, 90, 4)
                space.region_3d.view_distance = 262
                space.region_3d.view_rotation = Vector((0.22, -1, 0.92)).to_track_quat(
                    "Z", "Y"
                )
    path = str(ROOT / "Art/Settlements and flora.blend")
    if factory_scene:
        bpy.data.scenes.remove(previous)
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
    else:
        bpy.data.libraries.write(path, {scene}, compress=True)
    print("WORLD_GARDENS_BUILT", len(scene.objects))


if __name__ == "__main__":
    main()
