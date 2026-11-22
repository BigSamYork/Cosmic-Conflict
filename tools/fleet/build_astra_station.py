"""Author Astra's open docking ring, hangar and landing gear in Blender."""

import sys
from math import cos, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from build_ground import OUTPUT, pipe, plate
from build_surface_life import rigid_assembly


def orbital_ring(s):
    def point(a, r, y):
        return (r * cos(a), y, 4 + r * sin(a))

    for i in range(48):
        a = i * tau / 48
        b = a + tau / 48 - 0.002
        profile = [
            (100.4, -57),
            (99.2, -61),
            (99.2, -79),
            (102.5, -84),
            (124.8, -84),
            (129.2, -78.5),
            (129.2, -61),
            (126.0, -56),
        ]
        s.rows(
            [[point(t, r, y) for r, y in profile] for t in [a, (a + b) / 2, b]],
            "paint" if i % 4 else "frame",
            smooth=False,
        )
        for r, finish, width in [
            (102.3, "light", 0.27),
            (106, "steel", 0.42),
            (123.8, "copper", 0.67),
            (127.4, "stripe", 0.58),
        ]:
            y = -84.25 if r < 125 else -81.6
            pipe(
                s,
                [
                    point(a + 0.007, r, y),
                    point((a + b) / 2, r, y),
                    point(b - 0.007, r, y),
                ],
                width,
                finish,
                8,
            )
        for j in range(4):
            t = a + (0.19 + j * 0.19) * (b - a)
            s.rows(
                [
                    [
                        point(t + offset, r, y)
                        for r, y in [
                            (109, -84.05),
                            (109, -85.1),
                            (118.6, -85.4),
                            (119.1, -84.05),
                        ]
                    ]
                    for offset in [-0.003, 0.003]
                ],
                "glass" if (i + j) % 5 else "light",
                smooth=False,
            )
        if i % 2 == 0:
            t = (a + b) / 2
            for offset in [-0.031, 0.031]:
                pipe(
                    s,
                    [
                        point(t + offset, 103, -72),
                        point(t + offset, 109, -88),
                        point(t + offset, 122, -88),
                        point(t + offset, 128, -75),
                    ],
                    0.67,
                    "steel",
                    10,
                )
        if i % 6 == 0:
            t = (a + b) / 2
            inner = min(58 / max(abs(cos(t)), 0.001), 27 / max(abs(sin(t)), 0.001))
            for offset in [-0.028, 0.028]:
                pipe(
                    s,
                    [point(t + offset, inner, -25), point(t + offset, 100, -62)],
                    1.2,
                    "steel",
                    12,
                )
            for j in range(7):
                a0 = j / 7
                a1 = (j + 1) / 7
                pipe(
                    s,
                    [
                        point(t - 0.028, inner + (100 - inner) * a0, -25 - 37 * a0),
                        point(t + 0.028, inner + (100 - inner) * a1, -25 - 37 * a1),
                    ],
                    0.50,
                    "copper",
                    8,
                )


def terminal():
    s = Skin("astra_terminal", "patrol")
    s.palette.update(
        paint="4b697b", steel="7b8d97", frame="263544", stripe="ce9d5c", glass="214c62"
    )
    orbital_ring(s)
    # A continuous dark pressure hull sits behind individually removable bay plates.
    for side in [-1, 1]:
        plate(s, (side * 54, 2, 4), (12, 166, 46), "frame")
        plate(s, (0, 2, -19 if side < 0 else 27), (96, 166, 6), "frame")
        for j in range(10):
            y = -72 + 16 * j
            for height in [-9, 4, 16]:
                plate(
                    s,
                    (side * 47.8, y, height),
                    (0.8, 14.8, 10),
                    "paint" if (j + height) % 3 else "steel",
                )
                for slot in range(3):
                    plate(
                        s,
                        (side * 47.26, y + (slot - 1) * 2.25, height + 1.4),
                        (0.24, 1.1, 4.1),
                        "glass" if (j + slot) % 3 else "light",
                    )
            for z in [-15.75, 23.7]:
                for x in [9.8, 29]:
                    plate(
                        s,
                        (side * x, y, z),
                        (18.0, 15.7, 0.38),
                        "paint" if (j + int(x)) % 3 else "frame",
                    )
            pipe(
                s,
                [
                    (side * 47.2, y, -15),
                    (side * 47.2, y, 16),
                    (side * 41.2, y, 23.4),
                    (side * 28, y, 23.4),
                ],
                0.54,
                "copper",
            )
            pipe(
                s,
                [(side * 46.6, y + 0.6, -12), (side * 46.6, y + 0.6, 13.8)],
                0.16,
                "light",
                8,
            )
            plate(s, (side * 43, y, 22.9), (3, 7.8, 0.73), "ceramic")
            for x in [25, 40]:
                plate(s, (side * x, y, 23.1), (0.42, 6.8, 0.72), "light")
        for row, (x, y, h) in enumerate(
            [(22, 45, -8.9), (38, 55, -8.9), (22, 72, 2.1), (38, 72, 2.1)]
        ):
            plate(s, (side * x, y, h), (16, 24, 1.05), "steel")
            plate(s, (side * x, y, h + 0.54), (14.9, 22.8, 0.23), "frame")
            for edge in [-1, 1]:
                pipe(
                    s,
                    [
                        (side * x + edge * 7.3, y - 10.8, h + 0.72),
                        (side * x + edge * 7.3, y + 10.8, h + 0.72),
                    ],
                    0.10,
                    "light",
                    6,
                )
                for z in [-7.0, 7.0]:
                    pipe(
                        s,
                        [
                            (side * x + edge * 6.1, y + z, -16),
                            (side * x + edge * 6.1, y + z, h - 0.31),
                        ],
                        0.33,
                        "steel",
                    )
            for j in range(4):
                plate(
                    s,
                    (side * x - 5 + j * 3.1, y + 9, h + 0.71),
                    (1.45, 0.71, 0.1),
                    "stripe",
                )
        for j in range(6):
            x = side * (65 + j * 6)
            plate(s, (x, 8, -1.8), (5.4, 56, 0.85), "frame")
            for k in range(12):
                plate(s, (x, -17 + k * 4.6, -1.26), (4.9, 4.1, 0.29), "glass")
        # The apron leads incoming pilots through the open front of the station.
        pipe(s, [(side * 10, -154, -15.9), (side * 10, 81, -15.9)], 0.34, "frame")
        for y in range(-154, 82, 8):
            plate(
                s,
                (side * 10, y, -15.36),
                (0.69, 3.3, 0.35),
                "light" if y % 3 else "green",
            )
    plate(s, (0, 85, 4), (96, 1.5, 40), "paint")
    for x in [-8.2, 8.2]:
        plate(s, (x, 84, 4), (15.6, 0.8, 19), "frame")
        for z in range(-3, 13, 3):
            plate(s, (x, 83.4, z), (12, 0.4, 0.68), "steel")
    return s


def landing_gear():
    s = Skin("landing_gear", "patrol")
    for x in [-1.2, 1.2]:
        for y in [-1.4, 1.4]:
            pipe(
                s,
                [(x * 0.86, y, -0.85), (x, y, -1.53), (x, y + 0.15, -2.15)],
                0.115,
                "steel",
                12,
            )
            pipe(s, [(x * 0.8, y + 0.51, -1.19), (x, y, -1.91)], 0.081, "copper", 10)
            plate(s, (x, y + 0.12, -2.31), (0.86, 1.12, 0.23), "stripe")
    return s


def cargo_gantry(scene, material):
    s = Skin("cargo_gantry", "rescue")
    joints = []
    for side in [-1, 1]:
        pipe(s, [(-9, side, 0), (9, side, 0)], 0.23, "steel")
        for x in [-7.8, 7.8]:
            plate(s, (x, side, 0.42), (1.4, 0.9, 0.85), "frame")
    for x in range(-8, 9, 2):
        pipe(s, [(x, -1, 0), (x + 0.7, 1, 0)], 0.12, "copper")
    joints.append(("Rail", (0, 0, 0), (0, 1, 0), 0, len(s.vertices), None))
    start = len(s.vertices)
    plate(s, (0, 0, -0.44), (2.4, 2.8, 0.73), "stripe")
    s.tube([(-1.4, 0, -1), (1.4, 0, -1)], [0.51, 0.51], "frame", 20)
    for side in [-1, 1]:
        s.pod((side * 1.04, -1.4, -0.48), (0.20, 0.13, 0.18), "green")
    joints.append(("Carriage", (0, 0, 0), (0, 1, 0), start, len(s.vertices), "Rail"))
    start = len(s.vertices)
    for x in [-0.86, 0.86]:
        pipe(s, [(x, 0, -1), (x, 0, -5)], 0.095, "steel")
    joints.append(("Cable", (0, 0, -1), (0, 1, -1), start, len(s.vertices), "Carriage"))
    start = len(s.vertices)
    plate(s, (0, 0, -5.3), (3.9, 3.1, 0.42), "frame")
    plate(s, (0, 0, -6.7), (3.5, 2.8, 2.5), "paint")
    for side in [-1, 1]:
        for h in [-7.3, -6.4]:
            plate(s, (0, side * 1.43, h), (3.4, 0.18, 0.13), "stripe")
        pipe(s, [(side * 0.86, 0, -5.0), (side * 1.65, 0, -5.45)], 0.10, "copper")
    joints.append(
        ("Container", (0, 0, -5), (0, 1, -5), start, len(s.vertices), "Carriage")
    )

    def transfer(pose, name, phase, frame):
        travel = sin(phase) * 6.8
        payout = (1 - cos(phase * 2)) * 0.95
        if name == "Carriage":
            pose.location.x = travel
            pose.keyframe_insert(data_path="location", frame=frame)
        elif name == "Cable":
            pose.scale.z = 1 + payout / 4
            pose.keyframe_insert(data_path="scale", frame=frame)
        else:
            pose.location.z = -payout
            pose.keyframe_insert(data_path="location", frame=frame)

    return rigid_assembly(scene, material, s, joints, "Transfer", 193, transfer)


def main():
    scene = bpy.context.scene
    if bpy.data.filepath or {o.name for o in scene.objects} != {
        "Cube",
        "Camera",
        "Light",
    }:
        raise RuntimeError("Use a fresh Blender factory scene")
    bpy.data.objects.remove(bpy.data.objects["Cube"], do_unlink=True)
    scene.name = "Astra station"
    material = flight_material()
    bake(terminal(), scene, material, OUTPUT)
    gear = bake(landing_gear(), scene, material, OUTPUT)
    gear.location = (0, 12, 0)
    hoist = cargo_gantry(scene, material)
    hoist.location = (30, 30, 22.5)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.overlay.show_overlays = False
                space.shading.color_type = "MATERIAL"
                space.region_3d.view_location = (0, -28, 3)
                space.region_3d.view_distance = 350
                space.region_3d.view_rotation = Vector((0.28, -1, 0.14)).to_track_quat(
                    "Z", "Y"
                )
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(
        filepath=str(ROOT / "Art/Astra Station.blend"), compress=True, copy=True
    )


if __name__ == "__main__":
    main()
