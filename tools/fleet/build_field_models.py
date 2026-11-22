"""Bake the flying ordnance, hive limbs and alternate clutches from a factory scene."""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material


def interceptor():
    s = Skin("interceptor_round", "gunmetal")
    s.tube(
        [(0, y, 0) for y in (-0.82, -0.69, -0.55, 0.28, 0.64, 1.18, 1.47)],
        [0.19, 0.31, 0.27, 0.32, 0.25, 0.13, 0.026],
        "ceramic",
        32,
    )
    for y, r in [(-0.8, 0.23), (-0.53, 0.28), (0.09, 0.324), (0.47, 0.293)]:
        s.tube(
            [(0, y - 0.042, 0), (0, y, 0), (0, y + 0.031, 0)],
            [r, r * 1.06, r],
            "steel",
            32,
        )
    s.pod((0, -0.84, 0), (0.17, 0.08, 0.17), "light", 10, 24)
    s.pod((0, 0.95, 0), (0.21, 0.42, 0.21), "glass", 14, 32)
    for i in range(4):
        a = tau * i / 4 + pi / 4

        def section(y, r, half, angle=a):
            return [
                (
                    r * cos(angle) - side * half * sin(angle),
                    y,
                    r * sin(angle) + side * half * cos(angle),
                )
                for side in (-1, 1)
            ]

        # Thick swept vanes with edge inlays.
        for y, reach, length in [(-0.68, 0.78, 0.77), (0.19, 0.43, 0.33)]:
            s.rows(
                [
                    section(y, 0.20, 0.081),
                    section(y - 0.025, reach, 0.026),
                    section(y + 0.14, reach, 0.020),
                    section(y + length, 0.22, 0.046),
                ],
                "frame",
                False,
                False,
            )
            s.tube(
                [
                    (reach * cos(a), y, reach * sin(a)),
                    (0.24 * cos(a), y + length, 0.24 * sin(a)),
                ],
                [0.027, 0.041],
                "light",
                8,
            )
    return s


def hive_leg():
    s = Skin("hive_flight_leg", "hive")
    joints = [
        (0, 0, 0),
        (0.49, -0.12, -0.11),
        (1.14, -0.22, -0.18),
        (1.34, -0.35, -0.38),
        (1.57, -0.61, -0.70),
        (1.79, -0.82, -0.94),
    ]
    s.tube(joints, [0.16, 0.19, 0.105, 0.139, 0.081, 0.028], "frame", 18)
    for j in range(3):
        a, b = Vector(joints[j]), Vector(joints[j + 1])
        s.tube(
            [a, a.lerp(b, 0.3), a.lerp(b, 0.77), b],
            [0.12, 0.195 - j * 0.02, 0.16 - j * 0.013, 0.075],
            "paint",
            18,
        )
    s.pod(joints[3], (0.168, 0.14, 0.16), "copper", 10, 18)
    for side in (-1, 1):
        s.tube(
            [
                joints[-2],
                joints[-1],
                (1.91, -0.94 + side * 0.1, -1.03),
                (1.87, -1.03 + side * 0.13, -1.09),
            ],
            [0.07, 0.059, 0.032, 0.006],
            "ceramic",
            10,
        )
    return s


def spore():
    s = Skin("living_spore_round", "hive")
    s.pod((0, 0.18, 0), (0.37, 1.22, 0.36), "paint", 18, 28)
    for i in range(7):
        angle = tau * i / 7
        points = []
        for j in range(13):
            t = j / 12
            r = 0.38 * sin(pi * (0.045 + 0.91 * t)) ** 0.65
            a = angle + 0.7 * t
            points.append((r * cos(a), -0.94 + 2.2 * t, r * sin(a)))
        s.tube(
            points, [0.025 + 0.049 * sin(pi * j / 12) for j in range(13)], "stripe", 8
        )
        s.pod(points[4], (0.106, 0.16, 0.106), "light", 8, 16)
    return s


def clutch(variant):
    s = Skin(f"clutch_{variant}", "hive")
    s.palette.update(
        paint=["78875b", "736889", "c29149"][variant],
        stripe=["7eaf84", "a195b0", "eac671"][variant],
        light=["b8ce73", "99b9ec", "ffde65"][variant],
    )
    s.pod((0, 0, 0), (0.77, 0.70, 1.20), "frame", 20, 36)
    # Three overlapping rows of armored valve scales surround the central yolk.
    for row in range(3):
        for i in range(9):
            angle = (i + 0.48 * (row % 2)) * tau / 9
            rows = []
            for j in range(12):
                t = j / 11
                lat = -1.53 + row * 0.92 + t * 1.19
                width = 0.28 * sin(pi * t) ** 0.68 + 0.028
                band = []
                for k in range(9):
                    u = (k - 4) / 4
                    a = angle + width * u + 0.25 * t
                    ridge = 0.033 + 0.061 * sin(pi * t) * (1 - abs(u))
                    band.append(
                        (
                            (0.79 + ridge) * cos(lat) * cos(a),
                            (0.74 + ridge) * cos(lat) * sin(a),
                            1.23 * sin(lat),
                        )
                    )
                rows.append(band)
            s.rows(rows, "paint" if (i + row) % 4 else "stripe", False, False)
            s.tube(
                [r[4] for r in rows],
                [0.009 + 0.014 * sin(pi * j / 11) for j in range(12)],
                "light" if variant == 2 else "copper",
                7,
            )
    return s


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "Ordnance and living clutches"
    material = flight_material()
    for i, skin in enumerate(
        [interceptor(), spore(), hive_leg(), *(clutch(k) for k in range(3))]
    ):
        obj = bake(skin, scene, material)
        obj.location = (3.3 * (i % 3 - 1), 0, 1.65 if i < 3 else -1.65)
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            space = area.spaces.active
            space.overlay.show_overlays = False
            space.shading.color_type = "MATERIAL"
            space.region_3d.view_rotation = Vector((0.32, -1, 0.43)).to_track_quat(
                "Z", "Y"
            )
            space.region_3d.view_distance = 16
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(
        filepath=str(ROOT / "Art/Ordnance and clutches.blend"), compress=True
    )


if __name__ == "__main__":
    main()
