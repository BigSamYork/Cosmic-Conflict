"""Build destructible boss modules in Blender. Run from the repository root."""

from math import cos, pi, sin, tau
from pathlib import Path
import sys

import bpy

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
        for side in [-1, 1]:
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


def organ(core):
    s = Skin("boss_heart" if core else "boss_spore", "hive")
    s.palette["light"] = "74fff0" if core else "ffb43f"
    s.pod((0, 0.46, 0), (0.95, 0.49, 0.93), "glass", 18, 36)
    if core:
        s.pod((0, -0.04, 0), (0.61, 0.26, 0.60), "light", 16, 32)
        s.pod((0, -0.275, 0), (0.12, 0.055, 0.32), "glass", 10, 18)
    else:
        for i in range(3):
            a = tau * i / 3
            s.pod(polar(0.32, a, 0.08), (0.32, 0.23, 0.33), "light", 12, 24)
    for i in range(7 if core else 5):
        a = tau * i / (7 if core else 5)
        path = [
            polar(0.83 - 0.38 * t, a + 0.55 * t, -0.48 + 0.67 * t)
            for t in [j / 12 for j in range(13)]
        ]
        s.tube(path, [0.16 - 0.11 * j / 12 for j in range(13)], "paint", 12)
        for j in range(3):
            pos = polar(0.72 - j * 0.08, a + 0.23 + j * 0.11, -0.08 + j * 0.11)
            s.pod(pos, (0.10, 0.09, 0.11), "stripe", 6, 12)
    return s


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
        organ(False),
        organ(True),
        iris(True),
        turret_base(),
        launcher(),
        launcher(True),
        dish(),
        thermal_lens(),
        drone_hangar(),
    ]
    for i, skin in enumerate(designs):
        obj = bake(skin, scene, material)
        obj.location = ((i % 5) * 11, -(i // 5) * 11, 0)
    bpy.data.libraries.write(str(ROOT / "Art/Boss Modules.blend"), {scene}, compress=True)
    print("FLEET_OK", len(designs), "boss module meshes")


if __name__ == "__main__":
    main()
