"""Build six planetary ground kits from the repository root.

For a standalone gallery with the saved viewport, run in a fresh process:
blender --background --factory-startup -P tools/fleet/build_ground.py -- --gallery
Inside an existing Blender session the generator writes a scene library instead.
"""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from ground_tiles import bake_tiles

OUTPUT = ROOT / "current_dev/assets/ground"
SECTORS = {
    "ignis": "gunmetal",
    "cryo": "cryo",
    "vespera": "nyx",
    "xylo": "hive",
    "thalassa": "tide",
    "kharon": "desert",
}


def lathe(s, profile, finish, n=32, at=(0, 0), stretch=(1, 1), phase=0, smooth=True):
    """Profile is a sequence of (height, radius) stations, bottom to top."""
    s.rows(
        [
            [
                (
                    at[0] + r * stretch[0] * cos(tau * j / n + phase),
                    at[1] + r * stretch[1] * sin(tau * j / n + phase),
                    z,
                )
                for j in range(n)
            ]
            for z, r in profile
        ],
        finish,
        smooth=smooth,
    )


def plate(s, at, size, finish, chamfer=0.13):
    x, y, z = at
    w, d, h = [v / 2 for v in size]
    cut = min(w, d) * chamfer
    edge = min(cut, h * 0.32)
    ring = [
        (w - cut, d),
        (-w + cut, d),
        (-w, d - cut),
        (-w, -d + cut),
        (-w + cut, -d),
        (w - cut, -d),
        (w, -d + cut),
        (w, d - cut),
    ]
    s.rows(
        [
            [(x + a * scale, y + b * scale, z + level) for a, b in ring]
            for level, scale in [(-h, 0.94), (-h + edge, 1), (h - edge, 1), (h, 0.94)]
        ],
        finish,
        smooth=False,
    )


def pipe(s, points, radius, finish="steel", n=10):
    s.tube(points, [radius] * len(points), finish, n)


def crystal(s, x, y, z, radius, height, lean, phase=0):
    """Faceted prism with stepped growth, striations and an asymmetric tip."""
    for i in range(7):
        a, b = phase + i * tau / 7, phase + (i + 1) * tau / 7
        ridge = 1 + 0.08 * sin(i * 4.2)
        levels = [
            (0, 0.78),
            (0.08, 1),
            (0.55, 0.95),
            (0.72 + 0.11 * sin(a + 1), 0.90),
            (0.98 + 0.02 * cos(a), 0.04),
        ]
        rows = [
            [
                (
                    x + radius * r * ridge * cos(t) + lean * f,
                    y + radius * r * sin(t),
                    z + height * f,
                )
                for t in (a, b)
            ]
            for f, r in levels
        ]
        s.rows(
            rows,
            ["paint", "steel", "glass", "stripe"][i % 4],
            False,
            False,
            smooth=False,
        )
        pipe(s, [rows[1][0], rows[2][0], rows[3][0]], radius * 0.022, "ceramic", 5)


def tower(sector):
    s = Skin("tower_" + sector, SECTORS[sector])
    s.palette["green"] = "ffad3e"
    if sector == "xylo":
        s.pod((0, 0, -4.55), (1.58, 1.92, 0.93), "copper", 12, 32)
        for i in range(8):
            a = tau * i / 8
            s.pod(
                (1.30 * cos(a), 1.58 * sin(a), -4.54),
                (0.30, 0.34, 0.43),
                "green",
                8,
                18,
            )
        s.tube(
            [
                (0, 0, -4.6),
                (-0.3, 0.1, -2),
                (0.2, 0, 0.3),
                (0.45, 0.08, 2.6),
                (0.22, 0, 4.1),
            ],
            [1.15, 0.83, 0.68, 0.90, 0.35],
            "paint",
            28,
        )
        for i in range(9):
            a = tau * i / 9
            path = [
                (
                    (0.85 + 0.28 * cos(pi * t)) * cos(a + t * 2.5) + 0.3 * t,
                    (0.87 + 0.24 * cos(pi * t)) * sin(a + t * 2.5),
                    -4 + 8.7 * t,
                )
                for t in [j / 16 for j in range(17)]
            ]
            s.tube(
                path, [0.12 + 0.13 * sin(pi * j / 16) for j in range(17)], "stripe", 9
            )
            s.pod(
                (0.24 + 0.6 * cos(a), 0.67 * sin(a), 3.75 + 0.42 * cos(3 * a)),
                (0.41, 0.45, 1.02),
                "paint",
                10,
                20,
            )
        s.pod((0.2, 0, 4.28), (0.63, 0.61, 0.86), "light", 12, 28)
        return s
    plate(s, (0, 0, -4.9), (3.2, 3.98, 1.17), "frame")
    plate(s, (0, 0, -5.29), (3.18, 3.98, 0.16), "steel")
    for side in [-1, 1]:
        plate(s, (0, side * 1.98, -4.88), (1.98, 0.09, 0.51), "seam")
        for j in range(8):
            plate(
                s,
                (-0.81 + j * 0.23, side * 2.04, -4.86),
                (0.11, 0.09, 0.28),
                "copper" if j % 3 else "steel",
            )
        for x in [-1.20, 1.20]:
            s.pod((x, side * 1.94, -4.89), (0.12, 0.08, 0.12), "steel", 6, 10)
    lathe(
        s,
        [(-4.75, 1.37), (-4.51, 1.48), (-3.74, 1.43), (-3.48, 1.22)],
        "copper",
        24,
        stretch=(1, 1.19),
    )
    for i in range(12):
        a = tau * i / 12
        pipe(
            s,
            [
                (1.43 * cos(a), 1.72 * sin(a), -4.49),
                (1.45 * cos(a + 0.10), 1.74 * sin(a + 0.10), -3.87),
            ],
            0.10,
            "green",
            8,
        )
    if sector == "cryo":
        for x, y, r, h, lean in [
            (0, 0, 0.92, 9.1, 0.24),
            (-0.83, 0.43, 0.53, 5.9, -0.18),
            (0.75, -0.68, 0.48, 4.6, 0.43),
        ]:
            crystal(s, x, y, -3.84, r, h, lean, x)
    elif sector == "ignis":
        lathe(s, [(-3.72, 0.72), (2.5, 0.62), (3.52, 0.46)], "seam")
        for i in range(4):
            a = pi * 0.25 + i * pi / 2
            corner = lambda t, angle: (
                (1.43 - 0.52 * t) * cos(angle),
                (1.68 - 0.55 * t) * sin(angle),
                -3.65 + 7.3 * t,
            )
            pipe(s, [corner(0, a), corner(1, a)], 0.15, "paint")
            for j in range(4):
                pipe(
                    s,
                    [corner(j / 4, a), corner((j + 1) / 4, a + pi / 2)],
                    0.083,
                    "copper",
                    8,
                )
        for j in range(7):
            z = -3 + j * 1.03
            lathe(s, [(z, 0.75), (z + 0.06, 0.91), (z + 0.18, 0.88)], "steel", 24)
        plate(s, (0, 0, 3.77), (2.05, 2.45, 0.52), "paint")
        for x in [-0.49, 0.49]:
            lathe(
                s,
                [(3.9, 0.24), (4.2, 0.34), (4.85, 0.22), (5.08, 0.25)],
                "steel",
                20,
                (x, 0),
            )
            lathe(s, [(4.68, 0.25), (4.78, 0.26)], "light", 20, (x, 0))
    elif sector == "vespera":
        for i in range(3):
            a = tau * i / 3
            x, y = 0.77 * cos(a), 0.82 * sin(a)
            top = 4.95 - 0.56 * i
            lathe(
                s,
                [(-3.7, 0.65), (-1, 0.70), (top - 0.75, 0.53), (top, 0.14)],
                "paint",
                8,
                (x, y),
                phase=a,
                smooth=False,
            )
            pipe(
                s,
                [
                    (x * 1.55, y * 1.55, -3.1),
                    (x * 1.55, y * 1.55, top - 0.72),
                    (x * 1.12, y * 1.12, top),
                ],
                0.082,
                "light",
            )
        for z in [-1.7, 0.5, 2.8]:
            plate(s, (0, 0, z), (2.36, 2.51, 0.32), "steel")
    elif sector == "thalassa":
        lathe(
            s,
            [
                (-3.65, 0.85),
                (-2.83, 1.3),
                (-1.9, 1.26),
                (2.8, 0.85),
                (3.5, 1.12),
                (4.57, 0.91),
                (4.90, 0.32),
            ],
            "paint",
            40,
        )
        for i in range(6):
            a = tau * i / 6
            pts = [
                (r * cos(a), r * sin(a), z)
                for r, z in [
                    (1.04, -3.6),
                    (1.39, -2.9),
                    (1.30, -1.6),
                    (0.99, 2.64),
                    (1.1, 3.55),
                ]
            ]
            pipe(s, pts, 0.14, "copper")
        for z, r in [
            (-2.68, 1.35),
            (-2.27, 1.35),
            (2.93, 1.03),
            (3.72, 1.13),
            (4.12, 1.06),
        ]:
            lathe(s, [(z, r), (z + 0.12, r + 0.02)], "light" if z > 3 else "steel")
    else:
        for i in range(8):
            z = -3.8 + i * 0.93
            r = 1.5 - i * 0.085
            lathe(
                s,
                [
                    (z, r * 0.88),
                    (z + 0.12, r),
                    (z + 0.77, r * 0.95),
                    (z + 0.87, r * 0.85),
                ],
                "paint" if i % 3 else "copper",
                4,
                stretch=(1, 1.16),
                phase=pi / 4,
                smooth=False,
            )
        crystal(s, 0, 0, 3.46, 0.69, 1.93, 0.14)
        for side in [-1, 1]:
            pipe(
                s,
                [
                    (side * 0.57, -1.11, -2.8),
                    (side * 0.34, -0.92, -0.5),
                    (side * 0.48, -0.82, 0.2),
                    (side * 0.16, -0.64, 2.7),
                ],
                0.075,
                "light",
            )
    return s


def mount(sector):
    s = Skin("mount_" + sector, SECTORS[sector])
    if sector == "xylo":
        s.pod((0, 0, 0.14), (2.38, 2.6, 1.32), "paint", 14, 32)
        for i in range(8):
            a = tau * i / 8
            s.tube(
                [
                    (r * cos(a + twist), r * sin(a + twist), z)
                    for r, z, twist in [
                        (1.25, 0.82, 0),
                        (2, 0.48, 0.13),
                        (2.68, -0.49, 0.22),
                        (3.25, -0.85, 0.31),
                    ]
                ],
                [0.51, 0.48, 0.34, 0.105],
                "stripe",
                12,
            )
            s.pod((1.94 * cos(a), 2.05 * sin(a), 0.52), (0.34, 0.38, 0.30), "glass")
        return s
    if sector == "cryo":
        for x in [-2.46, 2.46]:
            plate(s, (x, 0, -0.1), (1.48, 7.34, 1.72), "seam", 0.4)
            for j in range(10):
                y = -3.05 + j * 0.67
                plate(s, (x, y, 0.69), (1.43, 0.48, 0.18), "steel")
            for j in range(5):
                s.pod(
                    (x * 1.27, -2.64 + j * 1.32, -0.12),
                    (0.21, 0.59, 0.59),
                    "paint",
                    8,
                    20,
                )
    elif sector == "thalassa":
        for x in [-2.52, 2.52]:
            s.pod((x, 0, -0.13), (0.91, 3.63, 0.86), "paint", 14, 32)
            for y in [-1.90, 1.90]:
                plate(s, (x, y, 0.45), (1.55, 0.32, 0.38), "copper")
    else:
        count = 3 if sector == "kharon" else 4
        for i in range(count):
            a = tau * i / count + pi / 4
            x, y = 2.66 * cos(a), 2.85 * sin(a)
            plate(s, (x, y, -0.67), (1.82, 1.7, 0.72), "frame")
            pipe(
                s,
                [(x, y, -0.52), (x * 0.78, y * 0.78, 0.50), (x * 0.40, y * 0.40, 0.74)],
                0.35,
                "copper" if sector == "ignis" else "steel",
            )
    n = 6 if sector == "kharon" else 12 if sector == "vespera" else 36
    lathe(
        s,
        [(-0.85, 2.33), (-0.52, 2.78), (0.04, 2.68), (0.60, 2.22), (0.85, 1.68)],
        "paint",
        n,
        smooth=n > 12,
    )
    lathe(
        s,
        [(0.78, 1.42), (0.91, 1.70), (1.12, 1.62), (1.27, 1.31), (1.57, 1.25)],
        "frame",
    )
    for i in range(16):
        a = tau * i / 16
        pipe(
            s,
            [
                (1.66 * cos(a), 1.66 * sin(a), 0.97),
                (1.66 * cos(a + 0.19), 1.66 * sin(a + 0.19), 0.97),
            ],
            0.055,
            "light" if i % 4 == 0 else "steel",
            7,
        )
    return s


def turret_head(bio):
    s = Skin("spitter" if bio else "battery", "hive" if bio else "gunmetal")
    s.pod((0, -0.23, 0.04), (1.87, 1.59, 0.95), "paint", 14, 32)
    if bio:
        s.palette.update(stripe="a77d70", glass="76394e")
        for i in range(7):
            y = -1.1 + i * 0.35
            s.pod((0, y, 0.69), (0.76 - i * 0.045, 0.27, 0.32), "stripe", 8, 20)
    else:
        plate(s, (0, -0.43, 0.81), (1.61, 1.69, 0.43), "seam")
        for j in range(7):
            plate(s, (0, -1.10 + j * 0.21, 1.03), (1.34, 0.105, 0.105), "steel")
        plate(s, (0, 0.73, 0.69), (0.69, 0.52, 0.33), "frame")
        s.pod((0, 0.96, 0.72), (0.24, 0.11, 0.13), "light", 8, 16)
    for side in [-1, 1]:
        x = 0.95 * side
        if bio:
            s.tube(
                [
                    (side * 1.37, -0.76, 0.32),
                    (side * 1.45, 0.54, 0.20),
                    (x, 1.75, 0.02),
                    (x, 3.22, 0.02),
                    (x, 4.20, 0),
                ],
                [0.64, 0.76, 0.52, 0.32, 0.42],
                "stripe",
                24,
            )
            for j in range(7):
                s.pod(
                    (side * (1.78 - 0.075 * j), -0.75 + j * 0.51, 0.29),
                    (0.19, 0.40, 0.27),
                    "paint",
                    7,
                    16,
                )
            s.pod((x, 4.23, 0.02), (0.30, 0.055, 0.30), "seam", 8, 24)
        else:
            s.shell(
                (x, 0, 0),
                [
                    (-1.43, 0.54, 0.58, 0),
                    (-0.83, 0.71, 0.66, 0),
                    (0.65, 0.64, 0.59, 0),
                    (1.59, 0.47, 0.49, 0),
                ],
            )
            pipe(s, [(x, 1, 0), (x, 4.23, 0)], 0.34, "steel", 24)
            for j in range(5):
                y = 1.45 + j * 0.52
                pipe(
                    s,
                    [(x, y, 0), (x, y + 0.16, 0)],
                    0.43,
                    "paint" if j % 2 else "copper",
                    24,
                )
            pipe(s, [(x, 4.20, 0), (x, 4.29, 0)], 0.27, "seam", 24)
            pipe(
                s, [(x, 1.12, 0.45), (x, 3.71, 0.45), (x, 3.91, 0.27)], 0.074, "copper"
            )
            for k in range(6):
                a = tau * k / 6
                pipe(
                    s,
                    [
                        (x + 0.31 * cos(a), 3.86, 0.31 * sin(a)),
                        (x + 0.31 * cos(a), 4.25, 0.31 * sin(a)),
                    ],
                    0.062,
                    "steel",
                    7,
                )
            s.pod((side * 1.65, -0.32, 0.15), (0.23, 0.61, 0.55), "frame", 8, 24)
            s.pod((side * 1.84, -0.32, 0.15), (0.11, 0.37, 0.34), "copper", 8, 20)
        s.pod((side * 0.95, -1.12, 0.46), (0.30, 0.32, 0.21), "glass")
    return s


def landmark(sector):
    s = Skin("landmark_" + sector, SECTORS[sector])
    if sector == "ignis":
        s.palette.update(
            paint="704842", frame="443840", stripe="a66b53", steel="70575b"
        )
        for k, (x, y, r, h) in enumerate(
            [(0, 0, 2.8, 3.4), (1.9, -1.3, 1.65, 2.1), (-1.9, 0.4, 1.25, 1.65)]
        ):

            def rim(level, radius, x=x, y=y, k=k, h=h):
                return [
                    (
                        x
                        + radius * (1 + 0.10 * sin(a * 3 + k)) * cos(a)
                        + 0.26 * level,
                        y + radius * (1.09 + 0.14 * cos(a * 2)) * sin(a),
                        h * level + 0.13 * sin(a * 3 + 0.35 * level),
                    )
                    for a in [j * tau / 19 for j in range(19)]
                ]

            for bottom, top, r1, r2, finish in [
                (-0.24, 0.19, 1.12, 1, "frame"),
                (0.14, 0.37, 1.04, 0.86, "paint"),
                (0.34, 0.44, 0.92, 0.96, "stripe"),
                (0.41, 0.72, 0.95, 0.69, "paint"),
                (0.70, 0.80, 0.74, 0.76, "steel"),
                (0.77, 0.99, 0.77, 0.55, "paint"),
            ]:
                s.rows([rim(bottom, r * r1), rim(top, r * r2)], finish, smooth=False)
    elif sector == "cryo":
        for x, y, r, h, lean in [
            (0, 0, 2.15, 22, 0.67),
            (-2, 0.4, 1.4, 13, -2.5),
            (2, -0.6, 1.61, 16, 2.5),
            (0.4, 2, 1.15, 9, 0.9),
        ]:
            crystal(s, x, y, -1, r, h, lean, x)
    elif sector == "xylo":
        s.palette.update(
            paint="45674e",
            stripe="839761",
            steel="638755",
            glass="334f49",
            ceramic="b2c475",
        )
        s.tube(
            [
                (0, 0, -2),
                (-1, 0, 5),
                (1, 0.7, 16),
                (0.2, 0, 27),
                (-1.4, 1, 36),
                (0, 2, 43),
            ],
            [3.6, 2.8, 2.15, 1.55, 1.10, 0.51],
            "paint",
            18,
        )
        for i in range(7):
            a = tau * i / 7
            s.tube(
                [
                    (r * cos(a + t), r * sin(a + t), z)
                    for r, z, t in [
                        (1, 9, 0),
                        (2.7, 4, 0.2),
                        (4.4, 1.5, 0.28),
                        (7, -0.5, 0.38),
                    ]
                ],
                [0.72, 1.22, 0.85, 0.16],
                "stripe",
                8,
            )
        for i in range(7):
            a = i * 2.39996
            level = 26 + i * 2.4
            reach = 10 - i * 0.65
            center = Vector((cos(a) * reach, sin(a) * reach, level + 5))
            s.tube(
                [(0, 0, level - 4), (cos(a) * 4, sin(a) * 4, level - 1), center],
                [1.2, 0.80, 0.31],
                "paint",
                10,
            )
            for j in range(7):
                az = a + j * tau / 7
                direction = Vector((cos(az), sin(az), 0))
                across = Vector((-sin(az), cos(az), 0))
                rows = []
                for step in range(8):
                    t = step / 7
                    tip = (
                        center
                        + direction * t * (6 + i * 0.16)
                        + Vector((0, 0, 2.6 * sin(t * pi) - 2 * t * t))
                    )
                    w = 0.09 + 1.39 * sin(t * pi) ** 0.73
                    rows.append(
                        [
                            tip - across * w,
                            tip + Vector((0, 0, w * 0.45)),
                            tip + across * w,
                        ]
                    )
                s.rows(rows, "steel" if j % 3 else "stripe", False, False)
                pipe(s, [r[1] for r in rows], 0.055, "ceramic", 5)
            s.pod(center - Vector((0, 0, 0.72)), (0.76, 0.82, 1.23), "glass")
    elif sector == "vespera":
        for x, y, w, d, h in [
            (0, 0, 17, 21, 57),
            (6, -3, 8, 15, 45),
            (-6, 3, 8, 18, 38),
        ]:
            plate(s, (x, y, h * 0.49), (w, d, h), "paint", 0.36)
            plate(s, (x, y, h), (w * 0.84, d * 0.84, 2), "steel", 0.35)
            for z in range(4, h - 2, 4):
                plate(s, (x, y, z), (w * 1.015, d * 1.015, 0.75), "glass", 0.36)
                for side in [-1, 1]:
                    for j in range(5):
                        # Recessed window bays on both street-facing elevations.
                        for axis in [0, 1]:
                            points = []
                            for a, b in [
                                (-0.37, -0.66),
                                (0.37, -0.66),
                                (0.37, 0.66),
                                (-0.37, 0.66),
                            ]:
                                across = (j - 2) * (w if axis == 0 else d) * 0.117 + a
                                points.append(
                                    (
                                        x + across,
                                        y + side * (d * 0.504 + 0.02),
                                        z + 1.58 + b,
                                    )
                                    if axis == 0
                                    else (
                                        x + side * (w * 0.504 + 0.02),
                                        y + across,
                                        z + 1.58 + b,
                                    )
                                )
                            start = len(s.vertices)
                            s.vertices.extend(points)
                            s.face(
                                range(start, start + 4),
                                "ceramic" if (j * 7 + z + axis) % 11 < 3 else "glass",
                                False,
                            )
                    pipe(
                        s,
                        [
                            (x - w * 0.29, y + side * d * 0.506, z),
                            (x + w * 0.26, y + side * d * 0.506, z),
                        ],
                        0.10,
                        "light" if z % 12 else "stripe",
                        6,
                    )
        lathe(s, [(56, 3.2), (58, 2.2), (59, 0.47), (60, 0.27)], "copper", 16)
    elif sector == "thalassa":
        plate(s, (0, 0, 3), (25, 44, 3.2), "frame", 0.18)
        for x in [-9, 9]:
            for y in [-16, 16]:
                lathe(s, [(-11, 1.6), (1, 1.4), (3, 2.3)], "copper", 16, (x, y))
            pipe(s, [(x, -16, -6), (x, 16, 1)], 0.39, "steel")
            pipe(s, [(x, 16, -6), (x, -16, 1)], 0.39, "steel")
        for x in [-11.6, 11.6]:
            for z in [5.26, 5.87]:
                pipe(s, [(x, -18, z), (x, 18, z)], 0.1, "stripe", 8)
            for y in range(-18, 19, 4):
                pipe(s, [(x, y, 4.3), (x, y, 5.88)], 0.1, "steel", 8)
        plate(s, (-2, 4, 9), (14, 19, 10), "paint", 0.24)
        plate(s, (-2, 4, 14), (16, 21, 1.3), "ceramic", 0.24)
        for i in range(8):
            plate(s, (-7 + i * 1.56, -5.55, 10), (1.2, 0.35, 1.7), "glass")
            plate(s, (-7 + i * 1.56, 13.56, 10), (1.2, 0.35, 1.7), "glass")
        for side in [-1, 1]:
            for i in range(6):
                plate(
                    s,
                    (-2 + side * 7, -2.8 + i * 2.55, 10.3),
                    (0.33, 1.73, 1.46),
                    "glass",
                )
        for j in range(7):
            y = 5 + j * 1.5
            pipe(s, [(-9.35, y, 5), (-9.35, y, 12.8)], 0.11, "copper")
        for x in [6, 9]:
            pipe(
                s,
                [(x, 9, 3), (x, 9, 31), (x - 7, 9, 35), (x - 19, 9, 30)],
                0.50,
                "stripe",
            )
        for j in range(8):
            z = 5 + 3 * j
            pipe(s, [(6, 9, z), (9, 9, z + 3), (6, 9, z + 3)], 0.19, "steel")
        pipe(s, [(-12, 9, 30), (-12, 9, 13)], 0.12, "frame")
        for i in range(3):
            lathe(
                s,
                [(4.2, 1.6), (5, 2), (8.3, 2), (9, 1.6)],
                "steel",
                24,
                (-7 + i * 5, -14),
            )
    else:
        s.palette.update(
            paint="b99062", frame="6f5846", stripe="dfb578", light="5fc9c1"
        )
        for j in range(10):
            z = j * 3.7
            r = 8.2 - j * 0.55
            lathe(
                s,
                [
                    (z - 0.8, r),
                    (z + 0.48, r * 1.03),
                    (z + 3.0, r * 0.91),
                    (z + 3.3, r * 0.87),
                ],
                "paint" if j % 3 else "stripe",
                6,
                phase=pi / 6,
                smooth=False,
            )
        crystal(s, 0, 0, 35, 2.6, 8, 0.5)
        for side in [-1, 1]:
            pipe(
                s,
                [
                    (side * 3.8, -6.9, 2),
                    (side * 2.8, -5.7, 11),
                    (side * 1.3, -5.4, 14),
                    (side * 1.8, -4.9, 19),
                    (side * 0.7, -3.1, 31),
                ],
                0.17,
                "light",
            )
    return s


def canyon_substation():
    s = Skin("canyon_substation", "gunmetal")
    plate(s, (0, 0, 0.31), (8, 12, 0.85), "frame")
    for side in [-1, 1]:
        lathe(
            s,
            [(0.63, 0.91), (0.89, 1.04), (2.18, 1.04), (2.50, 0.87), (2.68, 0.52)],
            "paint",
            28,
            (side * 2.18, -2.64),
        )
        pipe(
            s,
            [
                (side * 2.18, -2.64, 2.68),
                (side * 2.18, -2.64, 3.17),
                (side * 0.91, -0.80, 3.17),
            ],
            0.18,
            "copper",
        )
    plate(s, (0, 1.68, 1.71), (5.85, 6.06, 2.33), "paint")
    plate(s, (0, 1.68, 2.92), (5.91, 6.13, 0.19), "steel")
    for x in [-1.45, 1.45]:
        lathe(s, [(2.98, 0.91), (3.10, 1.07), (3.20, 1.04)], "seam", 28, (x, 1.28))
        for j in range(9):
            a = j * tau / 9
            pipe(
                s,
                [
                    (x + 0.2 * cos(a), 1.28 + 0.2 * sin(a), 3.23),
                    (x + 0.64 * cos(a + 0.21), 1.28 + 0.64 * sin(a + 0.21), 3.24),
                    (x + 0.85 * cos(a + 0.43), 1.28 + 0.85 * sin(a + 0.43), 3.22),
                ],
                0.075,
                "steel",
                6,
            )
    for x in [-2.04, -1.36, -0.68, 0, 0.68, 1.36, 2.04]:
        plate(s, (x, 4.73, 1.86), (0.46, 0.12, 0.61), "glass")
    for side in [-1, 1]:
        pipe(s, [(side * 3.55, -4.9, 0.95), (side * 3.55, 4.85, 0.95)], 0.12, "stripe")
    return s


def ruin_arch():
    s = Skin("ruin_arch", "desert")
    for side in [-1, 1]:
        for j in range(6):
            z = j * 4.6
            lathe(
                s,
                [
                    (z - 0.25, 3.65),
                    (z + 0.39, 3.81),
                    (z + 4.22, 3.18),
                    (z + 4.48, 3.25),
                ],
                "paint" if j % 2 else "copper",
                8,
                (side * 12, 0),
                stretch=(0.90, 1.15),
                phase=pi / 8,
                smooth=False,
            )
        for j in range(6):
            # Voussoirs form the two rising sides of the opening.
            a0 = j * pi / 12 + 0.008
            a1 = (j + 1) * pi / 12 - 0.008
            rings = []
            for a in [a0, (a0 + a1) / 2, a1]:
                rings.append(
                    [
                        (side * r * cos(a), y, 27 + r * sin(a))
                        for r, y in [(9.1, -3.15), (15, -3.15), (15, 3.15), (9.1, 3.15)]
                    ]
                )
            s.rows(
                rings,
                "stripe" if j % 3 == 1 else "paint",
                reverse=side < 0,
                smooth=False,
            )
        pipe(
            s,
            [(side * 12, -3.75, 1), (side * 12, -3.75, 20), (side * 11.1, -3.75, 23)],
            0.18,
            "light",
        )
    return s


def main(standalone=False):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    previous = bpy.context.scene
    if standalone and (
        bpy.data.filepath
        or len(bpy.data.scenes) != 1
        or {o.name for o in previous.objects} != {"Cube", "Light", "Camera"}
    ):
        raise RuntimeError("Standalone export requires a fresh Blender factory scene.")
    scene = bpy.data.scenes.new("Planetary installations")
    bpy.context.window.scene = scene
    material = flight_material()
    for i, sector in enumerate(SECTORS):
        for row, skin in enumerate([tower(sector), mount(sector), landmark(sector)]):
            obj = bake(skin, scene, material, OUTPUT)
            if row == 2:
                obj.location = (i * 80, 115, 0)
            else:
                obj.location = (i * 10, -row * 10, 5.5 if row == 0 else 1)
    for i, bio in enumerate([False, True]):
        obj = bake(turret_head(bio), scene, material, OUTPUT)
        obj.location = (30 if bio else 0, -10, 3)
    for i, skin in enumerate([canyon_substation(), ruin_arch()]):
        obj = bake(skin, scene, material, OUTPUT)
        obj.location = (i * 80, 175, 0)
    bake_tiles(OUTPUT)
    bpy.ops.object.select_all(action="DESELECT")
    scene.display.shading.color_type = "MATERIAL"
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.overlay.show_overlays = False
                space.shading.color_type = "MATERIAL"
                space.shading.show_cavity = True
                space.region_3d.view_location = (25, -2, 5)
                space.region_3d.view_distance = 60
                space.region_3d.view_rotation = Vector((0.19, -1, 0.44)).to_track_quat(
                    "Z", "Y"
                )
                space.region_3d.view_perspective = "ORTHO"
    path = str(ROOT / "Art/Planetary Installations.blend")
    if standalone:
        bpy.data.scenes.remove(previous)
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True, copy=True)
    else:
        bpy.data.libraries.write(path, {scene}, compress=True)
    print("GROUND_ART_OK", len(scene.objects), "models")


if __name__ == "__main__":
    main("--gallery" in sys.argv)
