"""Build the Goliath, Tempest Walker and their radar assemblies in Blender.

Run from the repository root. Use --gallery in a fresh --factory-startup
process to save the editable scene with its inspection viewport.
"""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from build_ground import OUTPUT, lathe, pipe, plate
from cardiac_socket import carve_chest


def chitin(name):
    s = Skin(name, "hive")
    s.palette.update(
        paint="4d8874",
        stripe="b8c885",
        frame="313e45",
        copper="97585e",
        steel="80a68d",
        ceramic="e6d3aa",
        glass="422d46",
        light="b6f67c",
    )
    return s


def scute(s, at, size, angle=0, finish="paint"):
    """Convex overlapping leaf-shaped plate with a raised keel and ivory lip."""

    def point(t, u):
        width = (0.04 + 0.96 * sin(pi * t) ** 0.66) * size[0]
        x, y = u * width, (t - 0.5) * size[1]
        z = size[2] * (sin(pi * t) ** 0.75 * (1 - 0.69 * abs(u) ** 1.2) - 0.16 * t)
        return (
            at[0] + x * cos(angle) - y * sin(angle),
            at[1] + x * sin(angle) + y * cos(angle),
            at[2] + z,
        )

    rows = [[point(t / 12, k / 5) for k in range(-5, 6)] for t in range(13)]
    s.rows(rows, finish, False, False)
    for side in [-1, 1]:
        pts = [point(i / 12, side) for i in range(13)]
        s.tube(
            pts,
            [size[0] * (0.018 + 0.032 * sin(pi * i / 12)) for i in range(13)],
            "stripe",
            7,
        )
    pipe(s, [point(i / 12, 0) for i in range(2, 12)], size[0] * 0.028, "steel", 7)


def goliath(sealed=False):
    s = chitin("bio_titan_sealed" if sealed else "bio_titan")
    # Three overlapping body masses keep the shoulder, waist and head readable at flight distance.
    s.pod((0, 3, 5), (10.1, 9.7, 8.1), "frame", 20, 40)
    s.pod((0, 4, 12.6), (10, 8.1, 12), "paint", 20, 42)
    s.pod((0, 1, 23), (5, 5.2, 6.4), "frame", 18, 32)
    s.pod((0, -0.8, 26.1), (6.5, 5.7, 4.25), "paint", 20, 40)
    for row in range(6):
        z = 3 + row * 2.85
        span = 6.8 + 2.4 * sin(row * pi / 6)
        for side in [-1, 1]:
            s.tube(
                [
                    (side * span, 3, z + 1.4),
                    (side * span, -0.7, z + 0.75),
                    (side * span * 0.72, -3.47, z),
                    (side * span * 0.32, -4.52, z - 0.8),
                    (side * 0.5, -4.1, z - 1.25),
                ],
                [1.07, 1.0, 0.85, 0.63, 0.17],
                "steel" if row % 2 == 0 else "paint",
                14,
            )
            s.pod(
                (side * span * 0.82, -2.45, z + 1.02),
                (1.76, 0.71, 0.56),
                "copper",
                9,
                20,
            )
    for side in [-1, 1]:
        scute(s, (side * 4.4, 4.2, 19.8), (4.6, 13.2, 5.5), side * 0.26)
        scute(s, (side * 3.35, -0.8, 28.0), (3.6, 8.7, 2.4), side * 0.33)
        # Horns sweep away from the pilot, leaving the compound eyes exposed.
        s.tube(
            [
                (side * 4.4, 1.2, 27.2),
                (side * 6.8, 2.5, 29.6),
                (side * 8.4, 4.4, 31.3),
                (side * 9.1, 6.8, 32.4),
                (side * 8.8, 8.4, 32.7),
            ],
            [1.08, 0.90, 0.61, 0.30, 0.05],
            "ceramic",
            16,
        )
        for j in range(3):
            x = side * (2.2 + j * 1.18)
            y = -5.66 + j * 0.45
            z = 26.4 + 0.34 * j
            s.pod((x, y, z), (1.01, 0.52, 0.92), "glass", 12, 20)
            s.pod((x, y - 0.40, z + 0.03), (0.64, 0.30, 0.57), "light", 10, 20)
        s.tube(
            [
                (side * 3.6, -3.5, 25),
                (side * 4.8, -5.3, 23.4),
                (side * 4.15, -7.1, 22.6),
                (side * 2.5, -8.4, 23.1),
            ],
            [1.13, 1.02, 0.49, 0.055],
            "ceramic",
            18,
        )
        for j in range(4):
            scute(
                s,
                (side * (6.0 + j * 0.32), 5.7 + j * 1.54, 13.7 - j * 1.30),
                (2.6, 6.3, 2.6),
                side * (0.75 + j * 0.1),
            )
        for row, (x, y, z) in enumerate([(19, -14, 10), (30, 4, 8)]):
            root = (side * 7.6, 3 + row * 3, 15.4 - row * 6.3)
            elbow = (side * (x - 2), -2.0 + row * 8, 14.1 - row * 5.8)
            pad = (side * x, y, z - 1.15)
            s.tube([root, elbow, pad], [3.53, 2.92, 2.15], "frame", 22)
            s.pod(elbow, (3.86, 3.76, 3.06), "paint", 16, 30)
            s.pod(pad, (4.30, 4.1, 1.50), "steel", 14, 32)
            for j in range(3):
                c = Vector(root).lerp(Vector(elbow), (j + 0.7) / 3.8)
                scute(s, (c.x, c.y, c.z + 1.33), (2.9, 6.5, 1.65), side * 1.18)
            for j in range(2):
                c = Vector(elbow).lerp(Vector(pad), (0.31 + j * 0.37))
                scute(
                    s,
                    (c.x, c.y, c.z + 1.6),
                    (2.65, 5.5, 1.64),
                    side * (0.32 if row == 0 else 1.35),
                )
        s.tube(
            [(side * 7.6, 5, 5), (side * 8.5, 4, 0.7), (side * 7.5, 3, -2)],
            [3.2, 3, 2.2],
            "paint",
            20,
        )
        # Tendons anchor the living generator housings below the rib cage.
        s.tube(
            [(side * 7.7, 1.6, 4), (side * 9.7, -3.5, 2.4), (side * 10.9, -8.8, 0.35)],
            [2.88, 2.45, 2.1],
            "copper",
            18,
        )
    return carve_chest(s, (2.8, -1.6, 14), 4.6, sealed=sealed)


def titan_leg():
    s = chitin("titan_leg")
    s.tube(
        [
            (0, 0, 0),
            (1, -0.5, -1.6),
            (2.0, -2.0, -3.7),
            (1.35, -3.3, -5.5),
            (-0.55, -4.70, -8),
        ],
        [2.36, 2.45, 2.02, 1.42, 1.02],
        "frame",
        24,
    )
    s.pod((1.95, -1.88, -3.2), (2.37, 2.13, 2.1), "paint", 15, 30)
    for j in range(3):
        scute(
            s,
            (1.45 - j * 0.54, -2.75 - j * 0.70, -4.44 - j * 1.08),
            (1.48, 3.1, 1.03),
            -0.28,
        )
    s.pod((-0.53, -4.8, -7.96), (1.64, 2.56, 0.88), "paint", 14, 28)
    for j in [-1, 0, 1]:
        s.tube(
            [
                (-0.55 + j * 0.70, -5.1, -7.9),
                (-0.55 + j * 1.03, -6.46, -8.26),
                (-0.55 + j * 1.42, -8.05 + abs(j) * 0.64, -8.59),
            ],
            [0.63, 0.48, 0.045],
            "ceramic",
            12,
        )
    return s


def naval(name):
    s = Skin(name, "tide")
    s.palette.update(
        paint="477c89",
        stripe="eead49",
        ceramic="e2e4d1",
        frame="394a56",
        glass="194e60",
        steel="92acaf",
        copper="b47955",
        light="8ddfd6",
    )
    return s


def tempest():
    s = naval("tempest_walker")
    s.shell(
        (0, 3, 0),
        [
            (-15, 8.5, 2.2, 0),
            (-13, 13.4, 3.9, 0),
            (-7, 15, 4.3, 0),
            (6, 14.7, 4.45, 0),
            (15, 11.9, 3.7, 0),
            (20, 4.15, 1.55, 0.52),
        ],
        sectors=36,
    )
    plate(s, (0, 2.5, 4.23), (25, 25, 1.35), "ceramic", 0.32)
    # Stepped wheelhouse, bevelled panoramic glazing and overhanging storm visor.
    for z, w, d, h, finish in [
        (6.05, 19.7, 17.9, 3.55, "paint"),
        (8.12, 18.2, 16.5, 1.15, "frame"),
        (9.85, 19.3, 17.2, 2.64, "glass"),
        (11.28, 20.8, 18.3, 0.74, "ceramic"),
    ]:
        plate(s, (0, 3.5, z), (w, d, h), finish, 0.30)
    for side in [-1, 1]:
        for j in range(7):
            x = -6.6 + j * 2.2
            pipe(
                s,
                [
                    (x - 0.18, 3.5 + side * 8.37, 8.62),
                    (x + 0.28, 3.5 + side * 8.62, 11.08),
                ],
                0.14,
                "steel",
            )
        for j in range(5):
            y = -1.6 + j * 2.45
            pipe(
                s,
                [(side * 9.45, y, 8.72), (side * 9.60, y + 0.31, 11.01)],
                0.14,
                "steel",
            )
        for j in range(2):
            x = side * (5.7 + j * 2.18)
            lathe(
                s,
                [(10.96, 0.77), (11.7, 0.98), (13.25, 0.79), (13.56, 0.92)],
                "frame",
                26,
                (x, 8.65),
            )
            lathe(s, [(13.26, 0.94), (13.48, 0.95)], "copper", 26, (x, 8.65))
        for j in range(8):
            y = -7 + j * 2.6
            plate(
                s,
                (side * 13.25, y, 1.5),
                (0.75, 1.6, 1.93),
                "stripe" if j % 4 == 0 else "steel",
            )
        for row, (x, y, z) in enumerate([(19, -14, 10), (30, 4, 8)]):
            root = (side * 11.6, y + 4, 2.35)
            knee = (side * (x - 4.7), y + 2.3, z - 3.5)
            pad = (side * x, y, z - 0.98)
            s.tube([root, knee, pad], [2.7, 2.2, 2.05], "paint", 12)
            pipe(
                s,
                [(side * 11, y + 6, -0.5), (side * (x - 1), y + 1, z - 1.65)],
                0.68,
                "steel",
            )
            plate(s, pad, (8.65, 8.65, 1.62), "frame", 0.38)
            plate(s, (side * x, y, z - 0.20), (8.18, 8.18, 0.40), "stripe", 0.38)
        for y in [-10.5, 11.4]:
            s.pod((side * 12.1, y, -0.75), (3.8, 4.14, 3.49), "frame", 16, 32)
            pipe(
                s,
                [(side * 13.1, y, -0.75), (side * 14.76, y, -0.75)],
                2.55,
                "copper",
                32,
            )
        for y in [-7, 0, 7]:
            lathe(
                s,
                [(4.48, 0.79), (4.95, 0.97), (5.13, 0.86)],
                "frame",
                24,
                (side * 10.96, y),
            )
    return s


def tempest_leg():
    s = naval("tempest_leg")
    s.tube(
        [(0, 0, 0), (2.15, 0.4, 0.48), (6.70, 2.45, 1.48), (8.3, 3.2, 0.45)],
        [2.0, 2.16, 1.7, 1.33],
        "ceramic",
        16,
    )
    s.pod((7.35, 2.7, 0.92), (2.32, 2.12, 2.10), "frame", 16, 28)
    pipe(s, [(6.92, 1.14, 1.02), (6.92, 0.53, 1.02)], 1.43, "stripe", 26)
    s.tube(
        [(7.50, 2.74, 0.57), (8.85, 3.24, -2.74), (11.05, 4.40, -7.39)],
        [1.42, 1.74, 1.1],
        "paint",
        14,
    )
    for side in [-1, 1]:
        pipe(
            s,
            [(4.20, 2.0 + side * 1.04, 0.36), (8.81, 3.5 + side * 1.04, -4.9)],
            0.53,
            "frame",
            16,
        )
        pipe(
            s,
            [(8.72, 3.4 + side * 1.04, -4.65), (10.87, 4.35 + side * 1.04, -7.15)],
            0.33,
            "steel",
            16,
        )
    plate(s, (11.08, 4.5, -8.27), (7.78, 10.8, 1.79), "frame", 0.40)
    plate(s, (11.08, 4.5, -7.48), (7.45, 10.46, 0.72), "paint", 0.40)
    for j in range(6):
        plate(
            s,
            (11.1, 1.1 + 1.36 * j, -7.0),
            (5, 0.40, 0.38),
            "stripe" if j in (0, 5) else "steel",
        )
    return s


def reflector(kind):
    living = kind == "sensory_fan"
    s = chitin(kind) if living else naval(kind)
    if not living:
        s.palette.update(paint="99b0ad", ceramic="e2dfc9", light="80ece0")
    count = 13 if living else 20
    width, height = (4.42, 2.75) if kind != "survey_dish" else (4.34, 3.98)

    def surface(r, a, back=0):
        scallop = 1 - (0.12 if living else 0.012) * r**2 * (0.5 + 0.5 * cos(count * a))
        z = r * height * sin(a) * scallop
        return (width * r * cos(a) * scallop, 0.83 - 1.62 * r * r + 0.20 * z + back, z)

    for i in range(count):
        a = tau * i / count
        step = tau / count
        for lo, hi in [(0.095, 0.51), (0.52, 0.995)]:
            rows = [
                [
                    surface(lo + (hi - lo) * k / 7, a + step * (0.012 + 0.976 * j / 5))
                    for j in range(6)
                ]
                for k in range(8)
            ]
            s.rows(
                rows,
                ("copper" if i % 3 == 1 else "paint")
                if living
                else ("ceramic" if (i + (lo > 0.5)) % 4 else "steel"),
                False,
                False,
            )
        spine = [surface(r, a, 0.09) for r in [0.08, 0.22, 0.4, 0.6, 0.8, 1]]
        s.tube(
            spine,
            [0.15, 0.13, 0.11, 0.095, 0.08, 0.05],
            "stripe" if living else "frame",
            9,
        )
        lip = [surface(1, a + step * j / 7) for j in range(8)]
        pipe(s, lip, 0.072 if living else 0.098, "stripe" if living else "copper", 9)
        if living:
            for j in range(3):
                r = 0.36 + 0.21 * j
                pipe(
                    s,
                    [
                        surface(r, a, -0.075),
                        surface(r + 0.10, a + step * 0.22, -0.075),
                        surface(r + 0.14, a + step * 0.48, -0.075),
                    ],
                    0.045,
                    "steel",
                    7,
                )
        else:
            s.tube(
                [surface(0.88, a, 0.10), surface(0.61, a, 0.65), (0, 1.27, 0.04)],
                [0.10, 0.13, 0.19],
                "frame",
                8,
            )
            s.pod(
                surface(0.88, a + step * 0.14, -0.025),
                (0.105, 0.055, 0.105),
                "copper",
                6,
                10,
            )
    for a in [pi / 2, pi * 7 / 6, pi * 11 / 6]:
        s.tube(
            [
                surface(0.81, a, -0.04),
                (1.5 * cos(a), -1.44, 1.4 * sin(a)),
                (0, -2.7, 0.28),
            ],
            [0.135, 0.105, 0.085],
            "steel" if not living else "stripe",
            10,
        )
    s.pod((0, -2.70, 0.26), (0.38, 0.52, 0.42), "light" if living else "glass", 14, 24)
    s.pod((0, 0.72, 0), (0.68, 0.60, 0.64), "glass" if living else "frame", 14, 24)
    for side in [-1, 1]:
        pipe(
            s,
            [
                (side * 1.92, 0.8, -0.1),
                (side * 1.80, 1.49, -1.67),
                (side * 0.62, 0.75, -2.64),
            ],
            0.24,
            "paint" if living else "steel",
            14,
        )
    return s


def pedestal(living):
    s = chitin("sensory_stalk") if living else naval("radar_pedestal")
    if living:
        s.tube(
            [
                (0, 0, -0.4),
                (-0.32, 0.12, 1.1),
                (0.32, 0.34, 3.6),
                (-0.24, 0.60, 6.1),
                (0, 0.85, 8.25),
            ],
            [1.76, 1.3, 0.91, 0.73, 0.55],
            "paint",
            26,
        )
        for i in range(7):
            a = tau * i / 7
            path = [
                (
                    (1.45 - 0.91 * t) * cos(a + t * 2.45),
                    0.73 * t + (1.45 - 0.91 * t) * sin(a + t * 2.45),
                    0.1 + t * 8.1,
                )
                for t in [j / 15 for j in range(16)]
            ]
            s.tube(
                path, [0.14 + 0.12 * sin(pi * j / 15) for j in range(16)], "stripe", 9
            )
        s.pod((0, 0.72, 8.0), (0.83, 0.82, 0.68), "copper")
    else:
        plate(s, (0, 0, 0.06), (4.72, 4.58, 0.83), "frame", 0.29)
        lathe(s, [(0.37, 1.98), (0.58, 2.10), (1.04, 1.91), (1.17, 1.54)], "ceramic")
        lathe(
            s,
            [
                (1.05, 1.19),
                (1.4, 1.37),
                (2.2, 1.13),
                (6.4, 0.78),
                (7.22, 0.82),
                (7.48, 1.08),
                (7.88, 1.06),
                (8.03, 0.78),
            ],
            "paint",
            32,
        )
        for i in range(4):
            a = pi * 0.25 + i * pi / 2
            path = [
                (r * cos(a), r * sin(a), z)
                for r, z in [(1.94, 0.54), (1.6, 1.2), (1.13, 4.9), (0.83, 6.75)]
            ]
            pipe(s, path, 0.17, "steel", 12)
        for z, r in [(1.5, 1.34), (2, 1.25), (5.6, 0.94), (6, 0.93), (7.64, 1.09)]:
            lathe(s, [(z, r), (z + 0.1, r + 0.01)], "copper")
        for j in range(8):
            plate(
                s,
                (0, -1.06 + 0.045 * j, 2.50 + 0.33 * j),
                (0.66, 0.12, 0.105),
                "stripe",
            )
    return s


def brood_egg():
    s = Skin("brood_egg", "hive")
    s.palette.update(paint="af274f", stripe="f0ded0", light="fd4979", glass="3b203f")
    s.pod((0, 0, 0), (0.78, 0.74, 1.22), "paint", 20, 36)
    for j in range(3):
        h = -0.53 + j * 0.47
        pts = []
        for k in range(81):
            a = k * tau / 80
            z = h + 0.14 * cos(4 * a)
            r = (1 - (z / 1.22) ** 2) ** 0.5
            pts.append((0.79 * r * cos(a), 0.75 * r * sin(a), z))
        pipe(s, pts, 0.046, "stripe", 8)
    for i in range(6):
        a = i * tau / 6
        path = [
            (
                0.78 * cos(t) * cos(a + 0.22 * t),
                0.74 * cos(t) * sin(a + 0.22 * t),
                1.24 * sin(t),
            )
            for t in [-1.44 + j * 2.88 / 18 for j in range(19)]
        ]
        s.tube(path, [0.029 + 0.025 * sin(pi * j / 18) for j in range(19)], "glass", 8)
    return s


def parasite():
    # Ventral view faces Blender -Y, toward the pilot when latched.
    s = chitin("canopy_parasite")
    s.palette.update(
        paint="b58c76",
        stripe="dfbf96",
        frame="6c424a",
        glass="633347",
        copper="bc5967",
        steel="d58f80",
        ceramic="ecdcac",
        light="e8b68e",
    )
    s.pod((0, 0.04, 0.04), (0.65, 0.35, 1.02), "frame", 24, 40)
    for side in [-1, 1]:
        s.pod((side * 0.39, -0.15, 0.09), (0.38, 0.26, 0.69), "paint", 18, 30)
        for j in range(4):
            z = 0.76 - j * 0.38
            x = side * (0.47 + 0.06 * sin(j))
            elbow = (side * (0.97 + 0.12 * j), -0.02, z + 0.49 - j * 0.12)
            knuckle = (side * (1.38 + 0.10 * sin(j)), 0.05, z + 0.68 - j * 0.35)
            foot = (side * (1.49 + 0.13 * cos(j)), -0.12, z + 0.31 - j * 0.39)
            s.tube(
                [(x, 0.08, z), elbow, knuckle, foot],
                [0.175, 0.14, 0.078, 0.044],
                "paint",
                16,
            )
            s.pod(elbow, (0.155, 0.16, 0.17), "stripe", 10, 16)
            s.pod(foot, (0.115, 0.046, 0.15), "copper", 10, 16)
            pipe(
                s,
                [(x, -0.08, z), (elbow[0], elbow[1] - 0.12, elbow[2]), knuckle],
                0.036,
                "frame",
                8,
            )
        for j in range(8):
            z = 0.64 - j * 0.15
            s.tube(
                [
                    (side * 0.54, -0.26, z),
                    (side * 0.39, -0.40, z + 0.05),
                    (side * 0.22, -0.47, z - 0.025),
                ],
                [0.065, 0.087, 0.033],
                "steel" if j % 3 else "stripe",
                10,
            )
    # Concentric muscular folds around an inset central sucker and enamel hooks.
    s.pod((0, -0.36, 0.05), (0.29, 0.075, 0.51), "glass", 18, 28)
    for i in range(18):
        a = tau * i / 18
        p = (0.27 * cos(a), -0.415, 0.055 + 0.48 * sin(a))
        q = (0.20 * cos(a + 0.12), -0.51, 0.055 + 0.36 * sin(a + 0.12))
        s.tube(
            [p, q, (q[0] * 0.72, -0.50, q[2] * 0.77)],
            [0.078, 0.060, 0.008],
            "ceramic" if i % 2 else "copper",
            9,
        )
    for side in [-1, 1]:
        s.pod((side * 0.255, -0.17, -0.71), (0.28, 0.27, 0.36), "copper", 18, 28)
    tail = [
        (0, 0.09, -0.76),
        (0.05, 0.17, -1.04),
        (0.38, 0.19, -1.25),
        (0.83, 0.17, -1.31),
        (1.11, 0.13, -1.54),
        (1.08, 0.07, -1.80),
        (0.83, 0.02, -1.90),
        (0.67, -0.04, -1.82),
    ]
    s.tube(tail, [0.25, 0.22, 0.18, 0.147, 0.12, 0.085, 0.05, 0.014], "stripe", 18)
    return s


def main(standalone=False):
    previous = bpy.context.scene
    if standalone and (
        bpy.data.filepath
        or len(bpy.data.scenes) != 1
        or {o.name for o in previous.objects} != {"Cube", "Light", "Camera"}
    ):
        raise RuntimeError("Use a fresh factory scene for the standalone gallery.")
    scene = bpy.data.scenes.new("Walkers, scanners and brood")
    bpy.context.window.scene = scene
    material = flight_material()

    def place(skin, position):
        obj = bake(skin, scene, material, OUTPUT)
        obj.location = position
        return obj

    def copy_at(obj, position, scale):
        copy = obj.copy()
        scene.collection.objects.link(copy)
        copy.location = position
        copy.scale = scale

    place(goliath(), (-42, 0, 10))
    sealed = place(goliath(sealed=True), (-39.2, -1.6, 24))
    sealed.scale = (4.6,) * 3
    sealed.hide_viewport = True
    sealed.hide_render = True
    leg = place(titan_leg(), (-34.5, 3, 8))
    copy_at(leg, (-49.5, 3, 8), (-1, 1, 1))
    place(tempest(), (42, 0, 10))
    leg = place(tempest_leg(), (54.1, 11.4, 9.25))
    for side, fore in [(-1, 1), (1, -1), (-1, -1)]:
        copy_at(
            leg, (42 + side * 12.1, 11.4 if fore == 1 else -10.5, 9.25), (side, fore, 1)
        )
    mast = place(pedestal(False), (-10, -32, 0))
    place(reflector("survey_dish"), (-10, -32, 10))
    copy_at(mast, (0, -32, 0), (1, 1, 1))
    place(reflector("fleet_dish"), (0, -32, 10))
    place(pedestal(True), (10, -32, 0))
    place(reflector("sensory_fan"), (10, -32, 10))
    place(brood_egg(), (0, -40, 1.3))
    place(parasite(), (4, -40, 2))
    bpy.ops.object.select_all(action="DESELECT")
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.overlay.show_overlays = False
                space.shading.color_type = "MATERIAL"
                space.shading.show_cavity = True
                space.region_3d.view_location = (0, 0, 16)
                space.region_3d.view_distance = 153
                space.region_3d.view_rotation = Vector((0.12, -1, 0.37)).to_track_quat(
                    "Z", "Y"
                )
                space.region_3d.view_perspective = "ORTHO"
    path = str(ROOT / "Art/Walkers and Hive.blend")
    if standalone:
        bpy.data.scenes.remove(previous)
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True, copy=True)
    else:
        bpy.data.libraries.write(path, {scene}, compress=True)
    print("WALKERS_OK", len(scene.objects))


if __name__ == "__main__":
    main("--gallery" in sys.argv)
