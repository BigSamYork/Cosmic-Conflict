"""Build destructible boss modules in Blender. Run from the repository root."""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material


def polar(radius, angle, depth):
    """Positive depth projects out of a rear-facing target toward the chasing pilot."""
    return (radius * cos(angle), -depth, radius * sin(angle))


def turn(skin, profile, finish, segments=48):
    """Revolve a machined section around the reactor axis."""
    skin.rows(
        [[polar(r, tau * j / segments, d) for j in range(segments)] for r, d in profile],
        finish,
        caps=False,
    )


def segment(skin, angle, sweep, profile, finish, steps=6):
    rows = [
        [polar(r, angle + offset + sweep * j / steps, d) for j in range(steps + 1)]
        for r, d, offset in profile
    ]
    skin.rows(rows, finish, closed=False, caps=False)


def housing(bio):
    s = Skin("boss_organ_body" if bio else "boss_reactor_body", "hive" if bio else "gunmetal")
    if bio:
        s.pod((0, 0, 0), (0.96, 0.54, 0.94), "paint", 16, 32)
        for i in range(9):
            a = i * tau / 9
            path = [
                polar(0.36 + 0.65 * sin(pi * t), a + 0.62 * t, t - 0.5)
                for t in [j / 12 for j in range(13)]
            ]
            s.tube(path, [0.041 + 0.044 * sin(j * pi / 12) for j in range(13)], "stripe", 9)
    else:
        turn(
            s,
            [(0.01, -0.5), (0.80, -0.5), (0.94, -0.42), (0.98, 0.32), (0.91, 0.49), (0.01, 0.5)],
            "frame",
        )
        for i in range(12):
            a = tau * i / 12
            segment(
                s,
                a,
                0.39,
                [(0.91, -0.40, 0), (1, -0.32, 0), (1, 0.25, 0.04), (0.92, 0.38, 0.04)],
                "paint",
            )
            s.tube(
                [
                    polar(0.94, a - 0.04, -0.38),
                    polar(1.02, a - 0.04, -0.24),
                    polar(1.02, a + 0.01, 0.22),
                    polar(0.93, a + 0.02, 0.40),
                ],
                [0.035] * 4,
                "copper",
                10,
            )
        for d in [-0.33, 0.24, 0.40]:
            turn(
                s,
                [(0.94, d - 0.026), (1.025, d - 0.018), (1.025, d + 0.012), (0.94, d + 0.026)],
                "steel",
            )
    return s


def reactor(core):
    s = Skin("boss_core" if core else "boss_generator", "gunmetal")
    s.palette["light"] = "55f5ff" if core else "ffac30"
    turn(
        s,
        [
            (0.01, -0.72),
            (0.89, -0.72),
            (1, -0.53),
            (1.04, -0.20),
            (0.96, -0.02),
            (0.76, 0.08),
            (0.71, -0.10),
            (0.01, -0.11),
        ],
        "frame",
    )
    turn(s, [(0.97, -0.28), (1.045, -0.25), (1.045, -0.19), (0.98, -0.16)], "copper")
    for i in range(12):
        a = tau * i / 12
        segment(
            s,
            a,
            0.43,
            [
                (0.98, -0.17, 0),
                (1.015, -0.11, 0),
                (0.94, 0.045, 0),
                (0.81, 0.085, 0.05),
                (0.77, 0.028, 0.08),
            ],
            "steel" if i % 3 else "ceramic",
        )
        segment(s, a + 0.06, 0.30, [(0.88, 0.072, 0.025), (0.92, 0.058, 0.01)], "light")
    if core:
        # A bright central plasma sphere suspended between three curved pole shoes.
        s.pod((0, -0.02, 0), (0.42, 0.29, 0.42), "light", 16, 36)
        turn(s, [(0.68, 0), (0.71, 0.085), (0.66, 0.12), (0.62, 0.06)], "copper")
        for i in range(3):
            a = tau * i / 3
            path = [
                polar(0.72 - 0.27 * sin(pi * t), a + 0.96 * t, 0.07 + 0.16 * sin(pi * t))
                for t in [j / 12 for j in range(13)]
            ]
            s.tube(path, [0.055] * 13, "ceramic", 10)
    else:
        for i in range(9):
            a = tau * i / 9
            segment(
                s,
                a,
                0.31,
                [(0.28, 0.04, 0), (0.43, 0.13, 0.10), (0.71, 0.065, 0.31), (0.75, 0, 0.34)],
                "copper",
            )
            segment(
                s,
                a + 0.04,
                0.12,
                [(0.37, 0.09, 0.04), (0.43, 0.15, 0.10), (0.69, 0.089, 0.30)],
                "light",
            )
        s.pod((0, -0.04, 0), (0.27, 0.20, 0.27), "steel", 12, 32)
        s.pod((0, -0.192, 0), (0.16, 0.065, 0.16), "light", 8, 20)
    return s


def iris(bio):
    s = Skin("boss_membrane" if bio else "boss_iris", "hive" if bio else "gunmetal")
    if bio:
        s.pod((0, -0.24, 0), (0.74, 0.18, 0.73), "paint", 14, 32)
        for side in (-1, 1):
            points = [
                (x, -0.31 - 0.14 * (1 - x * x), side * (0.04 + 0.16 * x * x))
                for x in [j * 0.07 for j in range(-10, 11)]
            ]
            s.tube(points, [0.035 + 0.04 * sin(pi * j / 20) for j in range(21)], "stripe", 9)
        return s
    s.pod((0, -0.25, 0), (0.76, 0.12, 0.76), "seam", 12, 36)
    for i in range(7):
        a = tau * i / 7
        segment(
            s,
            a,
            0.82,
            [(0.035, 0.41, 0.78), (0.38, 0.40, 0.44), (0.64, 0.35, 0.15), (0.775, 0.255, 0)],
            "paint" if i % 2 else "frame",
        )
        segment(
            s,
            a + 0.05,
            0.09,
            [(0.20, 0.415, 0.67), (0.38, 0.412, 0.44), (0.63, 0.363, 0.15)],
            "copper",
        )
    return s


def heart():
    s = Skin("boss_heart", "hive")
    s.palette.update(
        paint="bc4140",
        stripe="e26a53",
        frame="893745",
        steel="68719a",
        copper="db635b",
        ceramic="ecc098",
        seam="6a2f42",
    )
    # Anterior view. The thick left ventricle sweeps to the viewer's right at the apex.
    rings = [
        (-1.02, 0.33, 0.02, 0.03),
        (-0.9, 0.26, 0.23, 0.21),
        (-0.68, 0.18, 0.43, 0.32),
        (-0.38, 0.10, 0.59, 0.41),
        (-0.05, 0.03, 0.69, 0.46),
        (0.23, -0.02, 0.68, 0.42),
        (0.41, -0.02, 0.49, 0.34),
        (0.51, -0.03, 0.26, 0.20),
    ]
    s.rows(
        [
            [(x + w * cos(tau * j / 36), d * sin(tau * j / 36), z) for j in range(36)]
            for z, x, w, d in rings
        ],
        "paint",
    )
    s.pod((-0.43, 0.01, 0.32), (0.34, 0.33, 0.36), "frame", 14, 24)
    s.pod((0.39, 0.02, 0.36), (0.31, 0.27, 0.26), "frame", 14, 24)
    # Ascending aorta, arch and descending limb, with the three great arterial branches.
    s.tube(
        [
            (-0.15, -0.06, 0.30),
            (-0.24, -0.02, 0.55),
            (-0.24, 0.01, 0.78),
            (-0.16, 0.05, 0.91),
            (0.01, 0.10, 0.95),
            (0.21, 0.17, 0.90),
            (0.33, 0.25, 0.70),
            (0.36, 0.38, 0.36),
        ],
        [0.20, 0.18, 0.17, 0.165, 0.16, 0.15, 0.14, 0.13],
        "copper",
        20,
    )
    for x, z, dx in [(-0.18, 0.86, -0.09), (-0.015, 0.94, -0.025), (0.14, 0.90, 0.10)]:
        s.tube(
            [(x, 0.08, z), (x + dx, 0.10, 1.13), (x + dx * 1.5, 0.25, 1.24)],
            [0.085, 0.07, 0.06],
            "stripe",
            14,
        )
    # The pulmonary trunk crosses the ascending aorta. The caval trunks enter the right atrium.
    s.tube(
        [
            (-0.10, -0.32, 0.23),
            (-0.03, -0.34, 0.47),
            (0.09, -0.30, 0.62),
            (0.26, -0.20, 0.72),
            (0.53, 0.02, 0.74),
            (0.73, 0.30, 0.70),
        ],
        [0.16, 0.16, 0.15, 0.14, 0.12, 0.11],
        "steel",
        18,
    )
    s.tube(
        [(-0.49, 0, 0.36), (-0.52, 0.01, 0.61), (-0.54, 0.08, 0.87), (-0.59, 0.28, 1.01)],
        [0.15, 0.14, 0.135, 0.12],
        "steel",
        16,
    )
    s.tube(
        [(-0.49, 0.01, 0.28), (-0.59, 0.18, 0.05), (-0.64, 0.42, -0.10)],
        [0.125, 0.12, 0.10],
        "steel",
        14,
    )
    # Coronary branches follow the interventricular groove down toward the apex.
    vessels = [
        (
            [
                (-0.40, -0.31, 0.28),
                (-0.23, -0.41, 0.19),
                (0.01, -0.46, 0.12),
                (0.14, -0.46, -0.10),
                (0.18, -0.42, -0.34),
                (0.20, -0.35, -0.59),
                (0.25, -0.21, -0.82),
            ],
            0.054,
            "ceramic",
        ),
        (
            [(0.04, -0.46, 0.12), (0.23, -0.4, 0.19), (0.43, -0.29, 0.23), (0.61, -0.13, 0.22)],
            0.048,
            "stripe",
        ),
        (
            [
                (0.14, -0.45, -0.13),
                (0.31, -0.39, -0.20),
                (0.44, -0.32, -0.38),
                (0.49, -0.20, -0.53),
            ],
            0.040,
            "ceramic",
        ),
        ([(0.18, -0.42, -0.32), (-0.01, -0.40, -0.39), (-0.14, -0.32, -0.53)], 0.035, "stripe"),
        (
            [
                (-0.55, -0.19, 0.15),
                (-0.39, -0.37, 0.12),
                (-0.16, -0.45, 0.04),
                (0.04, -0.47, -0.07),
                (0.10, -0.42, -0.29),
                (0.14, -0.34, -0.55),
            ],
            0.046,
            "frame",
        ),
    ]
    for path, radius, finish in vessels:
        s.tube(
            path, [radius * (1 - 0.82 * i / (len(path) - 1)) for i in range(len(path))], finish, 9
        )
    return s


def systole(point, _index):
    # Twist and shorten the contracting ventricles while the great vessels stay attached.
    weight = max(0, min(1, (0.53 - point.z) / 1.42))
    weight = weight * weight * (3 - 2 * weight)
    twist = weight * 0.18
    x = (point.x * cos(twist) - point.y * sin(twist)) * (1 - 0.15 * weight)
    y = (point.x * sin(twist) + point.y * cos(twist)) * (1 + 0.15 * weight)
    return Vector((x - 0.06 * weight, y, point.z + 0.22 * weight))


def spore():
    s = Skin("boss_spore", "hive")
    s.palette["light"] = "ffb43f"
    s.pod((0, 0.46, 0), (0.95, 0.49, 0.93), "glass", 18, 36)
    for i in range(3):
        a = tau * i / 3
        s.pod(polar(0.32, a, 0.08), (0.32, 0.23, 0.33), "light", 12, 24)
    for i in range(5):
        a = tau * i / 5
        path = [
            polar(0.83 - 0.38 * t, a + 0.55 * t, -0.48 + 0.67 * t)
            for t in [j / 12 for j in range(13)]
        ]
        s.tube(path, [0.16 - 0.11 * j / 12 for j in range(13)], "paint", 12)
        for j in range(3):
            pos = polar(0.72 - j * 0.08, a + 0.23 + j * 0.11, -0.08 + j * 0.11)
            s.pod(pos, (0.10, 0.09, 0.11), "stripe", 6, 12)
    return s


def casting(s, center, width, depth, height, finish, bevel=0.08):
    """Bevel the corners of a rectangular casting seen from the attack run."""
    x, y, z = center
    outline = [
        (-width + bevel, -height),
        (width - bevel, -height),
        (width, -height + bevel),
        (width, height - bevel),
        (width - bevel, height),
        (-width + bevel, height),
        (-width, height - bevel),
        (-width, -height + bevel),
    ]
    s.rows(
        [
            [(x + a * k, y + offset, z + b * k) for a, b in outline]
            for offset, k in [
                (-depth, 0.94),
                (-depth + 0.035, 1),
                (depth - 0.035, 1),
                (depth, 0.94),
            ]
        ],
        finish,
        reverse=True,
        smooth=False,
    )


def exchanger(furnace):
    s = Skin("boss_furnace" if furnace else "boss_heat_exchanger", "gunmetal")
    s.palette["light"] = "ff833e" if furnace else "ffc453"
    if furnace:
        # Refractory tiles frame a deep, hexagonal crucible.
        turn(
            s,
            [
                (0.02, -0.75),
                (0.92, -0.73),
                (1.04, -0.38),
                (0.96, 0.12),
                (0.64, 0.17),
                (0.48, -0.08),
                (0.03, -0.08),
            ],
            "copper",
            6,
        )
        turn(s, [(0.50, -0.055), (0.43, -0.03), (0.015, -0.03)], "light", 6)
        for i in range(6):
            a = tau * i / 6
            segment(
                s,
                a + 0.04,
                0.92,
                [(0.97, -0.22, 0), (1, 0.05, 0), (0.86, 0.21, 0), (0.72, 0.20, 0)],
                "ceramic",
                1,
            )
    else:
        casting(s, (0, 0.02, 0), 0.88, 0.52, 0.82, "frame")
        for i in range(6):
            z = -0.66 + i * 0.26
            casting(s, (0, -0.51, z), 0.96, 0.15, 0.075, "copper", 0.04)
            casting(s, (0, -0.47, z + 0.10), 0.68, 0.055, 0.035, "light", 0.02)
        for side in (-1, 1):
            s.tube(
                [
                    (side * 0.86, -0.18, -0.69),
                    (side * 1.03, -0.31, -0.57),
                    (side * 1.03, -0.31, 0.56),
                    (side * 0.86, -0.18, 0.70),
                ],
                [0.09] * 4,
                "steel",
                10,
            )
    return s


def coolant(vent):
    s = Skin("boss_cold_vent" if vent else "boss_coolant", "cryo")
    s.palette["light"] = "64eaff"
    if vent:
        casting(s, (0, 0.05, 0), 1.02, 0.48, 0.80, "paint")
        casting(s, (0, -0.45, 0), 0.83, 0.06, 0.65, "seam")
        for i in range(5):
            z = -0.50 + 0.25 * i
            casting(s, (0, -0.50, z + 0.075), 0.75, 0.06, 0.07, "light", 0.02)
            casting(s, (0, -0.55, z), 0.86, 0.14, 0.06, "steel", 0.04)
    else:
        for x in (-0.46, 0.46):
            s.tube(
                [
                    (x, 0, -0.91),
                    (x, 0, -0.79),
                    (x, 0, -0.66),
                    (x, 0, 0.53),
                    (x, 0, 0.68),
                    (x, 0, 0.83),
                ],
                [0.19, 0.36, 0.39, 0.39, 0.25, 0.17],
                "stripe",
                24,
            )
            for z in (-0.59, -0.42, 0.28, 0.45):
                s.tube([(x, 0, z), (x, 0, z + 0.075)], [0.41, 0.41], "ceramic", 24)
            s.tube([(x, -0.38, -0.33), (x, -0.38, 0.23)], [0.07, 0.07], "light", 10)
        s.tube(
            [
                (-0.46, 0, 0.76),
                (-0.46, 0, 0.93),
                (-0.35, 0, 1.01),
                (0.35, 0, 1.01),
                (0.46, 0, 0.93),
                (0.46, 0, 0.76),
            ],
            [0.105] * 6,
            "steel",
            12,
        )
    return s


def phase_prism():
    s = Skin("boss_phase_prism", "nyx")
    s.palette.update(glass="c15de6", light="ffa2f8", paint="8f80ad")
    # Four bevels hold alternating purple facets around a bright, narrow seam.
    for k in range(6):
        a = tau * k / 6
        facing = "glass" if k % 2 else "paint"
        for end in (-1, 1):
            s.rows(
                [
                    [(r * cos(a + t), 0.07 + r * 0.67 * sin(a + t), end * z) for t in (0, tau / 6)]
                    for r, z in [(0.52, 0), (0.52, 0.34), (0.09, 0.96)]
                ],
                facing,
                closed=False,
                caps=False,
                reverse=end < 0,
                smooth=False,
            )
        s.tube(
            [
                (0.52 * cos(a), 0.07 + 0.35 * sin(a), -0.30),
                (0.52 * cos(a), 0.07 + 0.35 * sin(a), 0.30),
            ],
            [0.027, 0.027],
            "light",
            7,
        )
    for side in (-1, 1):
        s.tube(
            [
                (0, 0.32, -0.88),
                (side * 0.56, 0.16, -0.73),
                (side * 0.85, 0, -0.36),
                (side * 0.89, -0.06, 0.34),
                (side * 0.72, -0.14, 0.64),
            ],
            [0.15, 0.14, 0.13, 0.095, 0.045],
            "steel",
            8,
        )
    return s


def capacitor():
    s = Skin("boss_capacitor", "nyx")
    s.palette.update(ceramic="efcfed", light="e794f8")
    casting(s, (0, 0.14, -0.69), 0.99, 0.38, 0.20, "frame")
    for x, height in [(-0.61, 0.64), (0, 0.95), (0.61, 0.64)]:
        s.tube([(x, 0, -0.58), (x, 0, height)], [0.13, 0.13], "copper", 12)
        for i in range(5):
            z = -0.47 + (height + 0.32) * i / 4
            s.tube(
                [(x, 0, z - 0.04), (x, 0, z), (x, 0, z + 0.08)], [0.18, 0.28, 0.17], "ceramic", 18
            )
        s.pod((x, 0, height), (0.20, 0.2, 0.115), "light", 8, 16)
    return s


def ballast(bridge):
    s = Skin("boss_bridge" if bridge else "boss_ballast", "tide")
    if bridge:
        casting(s, (0, 0.1, 0), 1.14, 0.6, 0.64, "paint", 0.24)
        casting(s, (0, -0.51, 0.08), 1.03, 0.07, 0.29, "frame", 0.18)
        for x in (-0.59, 0, 0.59):
            casting(s, (x, -0.58, 0.10), 0.25, 0.06, 0.15, "light", 0.07)
        casting(s, (0, -0.42, -0.46), 0.96, 0.27, 0.10, "ceramic")
    else:
        s.pod((0, 0.04, 0), (1.03, 0.56, 0.72), "paint", 16, 32)
        for x in (-0.54, 0.54):
            s.tube(
                [
                    (x, 0.01, 0.64),
                    (x, -0.33, 0.55),
                    (x, -0.48, 0.28),
                    (x, -0.49, -0.23),
                    (x, -0.36, -0.53),
                    (x, 0.01, -0.65),
                ],
                [0.09] * 6,
                "ceramic",
                10,
            )
        s.tube([(0, -0.42, 0), (0, -0.64, 0)], [0.26, 0.27], "frame", 18)
        turn(s, [(0.27, 0.65), (0.29, 0.68), (0.25, 0.72), (0.21, 0.70)], "copper", 12)
        for i in range(3):
            s.tube(
                [polar(0.04, tau * i / 3, 0.70), polar(0.24, tau * i / 3, 0.70)],
                [0.045, 0.035],
                "copper",
                8,
            )
    return s


def tidal_turbine():
    s = Skin("boss_tide_turbine", "tide")
    turn(
        s,
        [
            (0.02, -0.65),
            (0.80, -0.61),
            (0.98, -0.32),
            (1, 0.04),
            (0.92, 0.14),
            (0.77, 0.09),
            (0.69, -0.27),
            (0.02, -0.27),
        ],
        "paint",
    )
    for i in range(5):
        segment(
            s,
            tau * i / 5,
            0.39,
            [(0.19, 0.16, 0), (0.40, 0.17, -0.15), (0.68, 0.08, -0.43), (0.77, -0.07, -0.68)],
            "ceramic",
        )
    s.pod((0, -0.13, 0), (0.23, 0.20, 0.23), "light", 12, 20)
    return s


def bus_relay():
    s = Skin("boss_bus_relay", "desert")
    s.palette["light"] = "ffbb55"
    casting(s, (0, 0.02, 0), 0.91, 0.45, 0.80, "ceramic")
    for side in (-1, 1):
        casting(s, (side * 0.53, -0.43, 0), 0.20, 0.16, 0.63, "copper")
        for z in (-0.43, 0.43):
            s.tube([(side * 0.53, -0.47, z), (side * 0.53, -0.72, z)], [0.18, 0.16], "steel", 8)
        casting(s, (side * 0.53, -0.63, 0), 0.085, 0.055, 0.32, "light", 0.025)
    casting(s, (0, -0.44, 0), 0.21, 0.12, 0.35, "frame")
    return s


def solar_receiver():
    s = Skin("boss_solar_receiver", "desert")
    s.palette.update(light="fff19b", glass="e4a653")
    # Gold mirrors angled into a square central receiver.
    for i in range(4):
        a = pi / 4 + i * pi / 2
        segment(
            s,
            a + 0.05,
            pi / 2 - 0.10,
            [(0.21, -0.16, 0), (0.78, -0.03, 0), (1.06, 0.26, 0)],
            "glass",
            3,
        )
        segment(
            s,
            a + 0.05,
            pi / 2 - 0.10,
            [(1.06, 0.26, 0), (1.07, 0.18, 0), (1, -0.21, 0)],
            "steel",
            3,
        )
    casting(s, (0, -0.06, 0), 0.25, 0.16, 0.25, "light")
    return s


def moving_internals(skin):
    if skin.name == "boss_heart":
        return {"Systole": systole}
    if skin.name == "boss_phase_prism":
        crystal = {
            v for face, finish in zip(skin.faces, skin.finishes) if finish != "steel" for v in face
        }

        def refract(p, index):
            if index in crystal:
                x, y = p.x, p.y - 0.07
                p.x = x * cos(0.76) - y * sin(0.76)
                p.y = x * sin(0.76) + y * cos(0.76) + 0.07
            return p

        return {"Refract": refract}
    if skin.name == "boss_cold_vent":
        louvers = {
            v for face, finish in zip(skin.faces, skin.finishes) if finish == "steel" for v in face
        }

        def vent(p, index):
            if index in louvers:
                hinge_z = round((p.z + 0.50) / 0.25) * 0.25 - 0.50
                y, z = p.y + 0.42, p.z - hinge_z
                p.y = y * cos(0.92) - z * sin(0.92) - 0.42
                p.z = y * sin(0.92) + z * cos(0.92) + hinge_z
            return p

        return {"Vent": vent}
    return None


def turret_base():
    s = Skin("boss_turret_base", "gunmetal")
    s.tube(
        [(0, 0, -0.48), (0, 0, -0.32), (0, 0, 0.10), (0, 0, 0.41)],
        [3.72, 3.98, 3.60, 2.77],
        "frame",
        48,
    )
    s.tube([(0, 0, 0.35), (0, 0, 0.56)], [2.88, 2.88], "steel", 48)
    for i in range(12):
        a = tau * i / 12
        s.pod((3.07 * cos(a), 3.07 * sin(a), 0.18), (0.26, 0.26, 0.16), "copper", 6, 10)
    return s


def launcher(warning=False):
    s = Skin("boss_launch_warning" if warning else "boss_launcher", "gunmetal")
    s.palette["light"] = "ff553e" if warning else "e58942"
    if not warning:
        s.shell(
            (0, 0, 0),
            [
                (-2.55, 1.65, 1.02, 0),
                (-2.1, 2.83, 1.47, 0),
                (-0.65, 3.32, 1.62, 0),
                (1.45, 3.13, 1.46, 0),
                (2.12, 2.77, 1.23, 0),
            ],
        )
        for x in [-3.05, 3.05]:
            s.pod((x, -0.18, 0), (0.63, 1.43, 1.21), "steel")
    for x in [-2, 0, 2]:
        for z in [-0.75, 0.75]:
            if warning:
                s.tube([(x, 3.92, z), (x, 3.96, z)], [0.47, 0.45], "light", 24)
            else:
                s.tube(
                    [(x, 1.5, z), (x, 2.28, z), (x, 3.51, z), (x, 3.88, z)],
                    [0.82, 0.86, 0.70, 0.68],
                    "frame",
                    28,
                )
                s.tube([(x, 3.59, z), (x, 3.82, z), (x, 3.91, z)], [0.73, 0.76, 0.67], "copper", 28)
                s.tube([(x, 3.915, z), (x, 3.93, z)], [0.48, 0.47], "seam", 24)
    return s


def dish():
    s = Skin("boss_scanner", "patrol")
    # Shallow oval reflector with separate panels and a tripod feed horn.
    for i in range(14):
        a = tau * i / 14
        rows = []
        for j in range(6):
            r = 0.08 + 0.92 * j / 5
            rows.append(
                [
                    (
                        4.55 * r * cos(a + 0.433 * k / 5),
                        -0.74 * r * r,
                        2.16 * r * sin(a + 0.433 * k / 5),
                    )
                    for k in range(6)
                ]
            )
        s.rows(rows, "paint" if i % 2 else "steel", False, False)
    edge = [(4.55 * cos(tau * j / 48), -0.74, 2.16 * sin(tau * j / 48)) for j in range(49)]
    s.tube(edge, [0.10] * 49, "copper", 8)
    for a in [pi / 2, pi * 7 / 6, pi * 11 / 6]:
        s.tube([(3.85 * cos(a), -0.55, 1.8 * sin(a)), (0, -1.85, 0)], [0.075, 0.08], "frame", 9)
    s.pod((0, -1.85, 0), (0.30, 0.38, 0.30), "light", 8, 16)
    return s


def thermal_lens():
    s = Skin("boss_thermal_lens", "gunmetal")
    s.palette["light"] = "ff7140"
    turn(
        s,
        [
            (0.01, -3.9),
            (2.3, -3.9),
            (2.98, -2.9),
            (2.69, 2.8),
            (2.94, 3.4),
            (2.65, 3.8),
            (1.85, 3.65),
            (1.1, 2.9),
            (0.01, 2.9),
        ],
        "frame",
    )
    for i in range(10):
        a = tau * i / 10
        segment(
            s,
            a,
            0.40,
            [(2.8, -2.4, 0), (3.36, -1.6, 0), (3.30, 2.35, 0), (2.91, 3.42, 0.06)],
            "copper",
        )
        segment(s, a + 0.06, 0.28, [(2.54, 3.83, 0), (1.89, 3.72, 0), (1.46, 3.26, 0.14)], "light")
    s.pod((0, -3.04, 0), (1.31, 0.53, 1.31), "light")
    return s


def drone_hangar():
    s = Skin("boss_drone_hangar", "cryo")
    for x in [-2.03, 2.03]:
        s.shell(
            (x, 0, 0),
            [
                (-3.35, 1.68, 1.96, 0),
                (-3.04, 1.94, 2.10, 0),
                (-1.35, 1.95, 2.25, 0),
                (2.40, 1.76, 1.96, 0),
                (3.22, 1.4, 1.48, 0),
            ],
        )
        s.pod((x, -3.36, 0), (1.49, 0.16, 1.61), "seam")
        for z in [-0.71, -0.24, 0.23, 0.70]:
            s.tube([(x - 1.10, -3.49, z), (x + 1.10, -3.49, z)], [0.061, 0.061], "steel", 8)
        for side in [-1, 1]:
            s.tube(
                [
                    (x + side * 1.19, -3.46, -0.84),
                    (x + side * 1.31, -3.45, 0.7),
                    (x + side * 0.90, -3.46, 1.15),
                ],
                [0.12, 0.12, 0.10],
                "light",
                10,
            )
    return s


def main():
    scene = bpy.data.scenes.new("Boss modules")
    bpy.context.window.scene = scene
    material = flight_material()
    designs = [
        housing(False),
        housing(True),
        reactor(False),
        reactor(True),
        iris(False),
        spore(),
        heart(),
        iris(True),
        exchanger(False),
        exchanger(True),
        coolant(False),
        coolant(True),
        phase_prism(),
        capacitor(),
        ballast(False),
        ballast(True),
        tidal_turbine(),
        bus_relay(),
        solar_receiver(),
        turret_base(),
        launcher(),
        launcher(True),
        dish(),
        thermal_lens(),
        drone_hangar(),
    ]
    for i, skin in enumerate(designs):
        obj = bake(skin, scene, material, shape_keys=moving_internals(skin))
        obj.location = ((i % 5) * 11, -(i // 5) * 11, 0)
    bpy.data.libraries.write(str(ROOT / "Art/Boss Modules.blend"), {scene}, compress=True)
    print("FLEET_OK", len(designs), "boss module meshes")


if __name__ == "__main__":
    main()
