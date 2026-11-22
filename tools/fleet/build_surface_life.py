"""Build the populated surface kit and a skinned survey rover in Blender 4.5.

Run from the repository root with Blender --background --factory-startup -P.
Coordinates are Blender metres, with travel toward +Y and height along +Z.
"""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from build_ground import OUTPUT, SECTORS, crystal, lathe, pipe, plate


def sector_landmark(sector):
    s = Skin("vista_" + sector, SECTORS[sector])
    if sector == "ignis":
        s.palette.update(
            paint="60515b", frame="3c3540", stripe="855b4b", light="ff9937"
        )
        # Stepped basalt chimneys surrounding a hot fumarole.
        for j in range(11):
            a = j * 2.4
            r = 0.58 * j**0.5
            h = 7.4 / (1 + j * 0.19) + 0.35 * sin(j)
            xy = (r * cos(a), r * sin(a))
            for k in range(4):
                z = (k - 0.18) * h / 4
                w = (0.91 - 0.09 * k) * (0.75 + 0.15 * cos(j))
                lathe(
                    s,
                    [(z, w), (z + h * 0.06, w * 1.04), (z + h * 0.25, w * 0.90)],
                    "stripe" if k == 1 else "paint",
                    9,
                    xy,
                    phase=a,
                )
            lathe(s, [(h * 0.93, w * 0.7), (h * 0.95, w * 0.5)], "light", 10, xy)
    elif sector == "cryo":
        # Glacial pressure ridge with a hollow blue throat and secondary shards.
        s.palette.update(
            frame="34576b", paint="7babae", stripe="c7f7e4", steel="5f989f"
        )
        for j in range(9):
            a = j * pi / 8
            x, z = 4.3 * cos(a), 3 + 12 * sin(a)
            crystal(s, x, sin(j * 2) * 0.7, z - 4, 2.05, 6.4, -0.7 * cos(a), a)
        for x, y, h in [(-5, 1.3, 8), (5.2, 0.2, 9), (-6, -1, 5), (6.3, 1, 5)]:
            crystal(s, x, y, -1, 1.1, h, x * 0.17)
    elif sector == "vespera":
        # Offset residential terraces with a facade of alternating dark and occupied flats.
        plate(s, (0, 0, 1), (18, 17, 3), "frame")
        for level, (x, w, d) in enumerate(
            [(0, 17, 16), (-1.2, 14, 14), (-2, 11, 12), (-2.7, 8, 9)]
        ):
            z = 2 + level * 12
            plate(s, (x, 0, z + 5.8), (w, d, 12), "paint")
            for floor in range(4):
                height = z + 1 + floor * 2.8
                plate(s, (x, 0, height), (w + 0.8, d + 0.8, 0.45), "steel")
                for side in [-1, 1]:
                    for k in range(5):
                        plate(
                            s,
                            (x + (k - 2) * w / 5.8, side * (d / 2 + 0.1), height + 1.2),
                            (w / 8.5, 0.3, 1.25),
                            "light" if (level + k * 3 + floor) % 7 < 3 else "glass",
                        )
        lathe(s, [(49, 1.4), (51, 0.8), (57, 0.21), (58, 0.2)], "copper", 16, (-2.7, 0))
    elif sector == "xylo":
        # Hollow parasol caps, luminous gills and intertwined mycelial stems.
        s.palette.update(
            paint="896a85",
            stripe="b7b38a",
            frame="4b5a4c",
            steel="948185",
            light="e6c878",
        )
        for j, (x, y, h, r) in enumerate(
            [(0, 0, 29, 8.9), (-4.8, 2, 14, 4.8), (4.2, -2.7, 9.3, 3.8)]
        ):
            s.tube(
                [
                    (x, y, -1.2),
                    (x + 0.7, y, h * 0.25),
                    (x - 0.8, y + 0.4, h * 0.67),
                    (x, y, h),
                ],
                [2.5, 1.35, 0.91, 1.4],
                "frame",
                18,
            )
            lathe(
                s,
                [
                    (h - 2, 1.2),
                    (h - 1.2, r * 0.74),
                    (h - 0.55, r),
                    (h + 0.3, r * 0.94),
                    (h + 2.4, r * 0.5),
                    (h + 3.1, 0.32),
                ],
                "paint",
                32,
                (x, y),
            )
            for k in range(16):
                a = k * tau / 16 + j
                s.tube(
                    [
                        (x + f * r * cos(a), y + f * r * sin(a), h - 2.14 + 1.48 * f)
                        for f in [0.13, 0.45, 0.70, 0.99]
                    ],
                    [0.17, 0.17, 0.13, 0.045],
                    "light" if k % 4 == 0 else "stripe",
                    6,
                )
    elif sector == "thalassa":
        # A semi-submersible gas holder with catwalks, bell tanks and supply pipes.
        for side in [-1, 1]:
            plate(s, (side * 9.7, 0, -1.8), (4.8, 27, 3.5), "frame")
            for y in [-8, 8]:
                lathe(
                    s, [(-2.5, 2), (0, 2.3), (8.2, 1.7)], "copper", 20, (side * 9.7, y)
                )
        plate(s, (0, 0, 8), (25, 25, 2), "paint")
        for x, y, r in [(-5.4, -3, 5.3), (5.2, 3.1, 4.9)]:
            s.pod((x, y, 14), (r, r, r), "ceramic", 14, 24)
            lathe(s, [(13.5, r * 1.02), (13.9, r * 1.02)], "stripe", 24, (x, y))
            pipe(
                s,
                [(x, y, 17), (x, y, 21), (x, y + 3, 22), (x, y + 5, 22), (x, y + 5, 9)],
                0.39,
                "copper",
                10,
            )
        for side in [-1, 1]:
            for j in range(8):
                pipe(
                    s,
                    [(side * 12, -11 + j * 3, 9), (side * 12, -11 + j * 3, 10.8)],
                    0.11,
                )
            pipe(s, [(side * 12, -11, 10.8), (side * 12, 10, 10.8)], 0.13, "stripe")
    else:
        # Wind-carved funerary spires, banded stone and turquoise inlays.
        for j, (x, y, h, w) in enumerate(
            [(0, 0, 29, 5.7), (-5, 3, 13, 2.8), (4.3, -2.3, 8.2, 2.2)]
        ):
            for k in range(7):
                z = h * k / 7
                radius = w * (1 - k * 0.096)
                lathe(
                    s,
                    [
                        (z - 0.4, radius * 1.08),
                        (z + 0.3, radius * 1.1),
                        (z + h / 7, radius * 0.92),
                    ],
                    "stripe" if k % 3 == 1 else "paint",
                    10,
                    (x, y),
                    phase=0.18 * j,
                )
            lathe(s, [(h - 0.4, w * 0.4), (h + 4.2, 0.15)], "copper", 10, (x, y))
            for k in range(4):
                z = 3 + k * h / 7
                pipe(
                    s,
                    [
                        (x - 0.8, y - w * (1 - k * 0.09), z + 0.35),
                        (x, y - w * (1 - k * 0.09) - 0.18, z),
                        (x + 0.8, y - w * (1 - k * 0.09), z + 0.35),
                    ],
                    0.12,
                    "light",
                    6,
                )
    return s


def instrument_marker(name):
    s = Skin(name, "rescue")
    if name == "patrol_gate":
        # Four segmented race pylons leave the opening entirely unobstructed.
        for quadrant in range(4):
            start = quadrant * pi / 2 + 0.16
            arc = [start + i * (pi / 2 - 0.32) / 12 for i in range(13)]
            points = [(3.45 * cos(a), 0, 3.45 * sin(a)) for a in arc]
            pipe(s, points, 0.136, "frame", 10)
            pipe(s, [(x, -0.15, z) for x, _, z in points], 0.071, "green", 8)
            for a in [arc[0], arc[-1]]:
                s.pod(
                    (3.45 * cos(a), 0, 3.45 * sin(a)),
                    (0.20, 0.33, 0.20),
                    "copper",
                    8,
                    12,
                )
    else:
        s.shell(
            (0, 0, 0),
            [
                (-1.3, 0.27, 0.30, 0),
                (-0.88, 0.73, 0.67, 0),
                (0.54, 0.79, 0.74, 0),
                (1.20, 0.51, 0.55, 0),
                (1.42, 0.20, 0.24, 0),
            ],
        )
        for side in [-1, 1]:
            s.pod((side * 0.47, 0.32, 0.48), (0.22, 0.52, 0.29), "glass", 10, 18)
            pipe(
                s,
                [
                    (side * 0.6, -0.8, 0.55),
                    (side * 0.84, -0.4, 0.35),
                    (side * 0.84, 0.6, 0.31),
                ],
                0.075,
                "ceramic",
            )
            s.pod((side * 0.74, 0.8, 0.28), (0.13, 0.13, 0.15), "green", 8, 12)
        for x in [-0.35, 0.35]:
            pipe(s, [(x, -1.0, 0.28), (x, -1.35, 0.94)], 0.04, "steel", 7)
    return s


def hazard(name):
    icy = name.startswith("ice_")
    s = Skin(name, "cryo" if icy else "desert")
    if name == "ice_calving":
        for x, y, z, r, h in [
            (0, 0, -2.7, 1.25, 5.2),
            (0.72, 0.25, -1.8, 0.76, 3.1),
            (-0.65, 0.2, -0.91, 0.51, 2.8),
        ]:
            crystal(s, x, y, z, r, h, x * 0.35)
    elif name == "ruin_keystone":
        for i in range(5):
            plate(
                s,
                ((i % 2) * 0.12, 0, -1.8 + i * 0.87),
                (3.3 - i * 0.08, 3.1, 0.91),
                "paint" if i % 2 else "copper",
            )
        for y in [-1.53, 1.53]:
            for h in [-0.96, 0, 0.96]:
                pipe(
                    s,
                    [
                        (-1.10, y, h + 0.4),
                        (-0.25, y, h - 0.12),
                        (0.15, y, h + 0.17),
                        (1.04, y, h - 0.10),
                    ],
                    0.06,
                    "light",
                    8,
                )
    elif name == "ice_cornice":
        for j in range(6):
            crystal(
                s,
                15 + j * 0.72,
                sin(j) * 2,
                -2,
                1.9 + 0.2 * j,
                32 + j * 1.9,
                -j * 0.5,
                j,
            )
        s.tube(
            [(17, 0, 28), (13, 0, 34), (7, 0, 37.5), (0, 0, 39)],
            [3.2, 3.7, 3.0, 1.65],
            "paint",
            17,
        )
        for j in range(8):
            x = j * 1.7 + 1
            z = 38.5 - x * 0.32
            s.tube(
                [(x, 0.1, z), (x + 0.2, 0, z - 1.2), (x - 0.2, 0, z - 2.7 - (j % 3))],
                [0.78, 0.53, 0.04],
                "glass",
                10,
            )
    elif name == "ruin_corbel":
        for j in range(10):
            x = 9 if j < 7 else 9 - (j - 6) * 1.9
            plate(
                s,
                (x, 0, 1 + j * 4.0),
                (7 + (j % 3) * 0.7, 7.5, 4.1),
                "stripe" if j % 4 == 1 else "paint",
            )
        for y in [-3, 3]:
            pipe(
                s, [(11, y, 10), (11, y, 27), (7, y, 34), (0, y, 38)], 0.3, "copper", 10
            )
    elif name == "gate_projector":
        for z, w in [(-8.0, 1.4), (-6.5, 1.2), (0, 0.65), (10, 0.64), (12, 1.05)]:
            lathe(s, [(z, w), (z + 0.8, w * 0.94)], "steel", 16)
        lathe(s, [(-8, 0.87), (-5, 0.82), (12, 0.54), (13, 0.19)], "frame", 20)
        for i in range(8):
            z = -6 + i * 2.2
            lathe(s, [(z, 0.91), (z + 0.46, 0.93), (z + 0.59, 0.71)], "light", 20)
    return s


def rover():
    s = Skin("field_rover", "rescue")
    bones = []
    s.shell(
        (0, 0, 1.45),
        [
            (-2.8, 1.32, 0.52, 0),
            (-2.4, 1.93, 0.67, 0),
            (-0.6, 1.98, 0.64, 0.11),
            (1.6, 1.94, 0.55, 0.1),
            (2.68, 1.34, 0.36, 0),
        ],
    )
    plate(s, (0, -0.15, 2.24), (2.8, 2.8, 1.0), "frame")
    s.shell(
        (0, 0.2, 2.52),
        [(-1.2, 1.25, 0.4, 0), (0.2, 1.25, 0.57, 0.12), (1.19, 0.98, 0.27, 0)],
        "glass",
        False,
    )
    plate(s, (0, -1.72, 2.37), (2.4, 1.55, 0.72), "paint")
    for j in range(8):
        plate(s, (-0.95 + j * 0.27, -1.75, 2.78), (0.11, 0.96, 0.17), "steel")
    for x in [-1.63, 1.63]:
        for y in [-1.8, 0, 1.8]:
            pipe(
                s,
                [(x * 0.7, y + 0.65, 1.38), (x, y, 0.78), (x * 1.36, y, 0.78)],
                0.13,
                "steel",
            )
        pipe(
            s,
            [
                (x, -2.4, 1.8),
                (x * 1.12, -1.9, 2.1),
                (x * 1.12, 1.8, 2.1),
                (x, 2.4, 1.75),
            ],
            0.089,
            "ceramic",
        )
    lathe(s, [(2.3, 0.44), (3.3, 0.31), (4.3, 0.21)], "steel", 16, (0, -1.87))
    body_end = len(s.vertices)
    bones.append(("Chassis", (0, 0, 1.2), (0, 1, 1.2), 0, body_end, None))
    for side in [-1, 1]:
        for j, y in enumerate([-1.83, 0, 1.83]):
            x, z = side * 2.08, 0.78
            start = len(s.vertices)
            s.tube(
                [
                    (x - 0.32, y, z),
                    (x - 0.27, y, z),
                    (x + 0.27, y, z),
                    (x + 0.32, y, z),
                ],
                [0.68, 0.79, 0.79, 0.68],
                "frame",
                24,
            )
            s.tube(
                [(x + side * 0.28, y, z), (x + side * 0.37, y, z)],
                [0.51, 0.46],
                "steel",
                18,
            )
            for k in range(12):
                a = k * tau / 12
                pipe(
                    s,
                    [
                        (x - 0.28, y + 0.79 * cos(a), z + 0.79 * sin(a)),
                        (x + 0.28, y + 0.79 * cos(a + 0.1), z + 0.79 * sin(a + 0.1)),
                    ],
                    0.07,
                    "seam",
                    6,
                )
                if k % 2 == 0:
                    pipe(
                        s,
                        [
                            (x + side * 0.38, y + 0.12 * cos(a), z + 0.12 * sin(a)),
                            (x + side * 0.38, y + 0.45 * cos(a), z + 0.45 * sin(a)),
                        ],
                        0.073,
                        "stripe",
                        7,
                    )
            bones.append(
                (
                    f"Wheel_{side}_{j}",
                    (x, y, z),
                    (x, y + 0.5, z),
                    start,
                    len(s.vertices),
                    "Chassis",
                )
            )
    start = len(s.vertices)
    plate(s, (0, -1.85, 4.49), (1.3, 0.69, 0.63), "stripe")
    for side in [-1, 1]:
        s.pod((side * 0.4, -1.53, 4.5), (0.19, 0.13, 0.18), "glass", 10, 18)
    bones.append(
        (
            "Panorama",
            (0, -1.85, 4.34),
            (0, -1.35, 4.34),
            start,
            len(s.vertices),
            "Chassis",
        )
    )
    return s, bones


def rigid_assembly(scene, material, skin, joints, clip_name, frame_end, animate):
    """Give each authored group rigid bone weights, then export one skinned surface."""
    obj = bake(skin, scene, material, OUTPUT)
    arm = bpy.data.armatures.new(skin.name + " linkage")
    rig = bpy.data.objects.new(skin.name + " rig", arm)
    scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, head, tail, start, end, parent in joints:
        bone = arm.edit_bones.new(name)
        bone.head, bone.tail = head, tail
        if parent:
            bone.parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.parent = rig
    modifier = obj.modifiers.new("Moving assembly", "ARMATURE")
    modifier.object = rig
    for name, head, tail, start, end, parent in joints:
        group = obj.vertex_groups.new(name=name)
        group.add(list(range(start, end)), 1.0, "REPLACE")
        if parent is None:
            continue
        pose = rig.pose.bones[name]
        pose.rotation_mode = "XYZ"
        for frame in range(1, frame_end + 1, 12):
            animate(pose, name, (frame - 1) * tau / (frame_end - 1), frame)
    rig.animation_data.action.name = clip_name
    scene.frame_start, scene.frame_end = 1, frame_end
    scene.frame_set(1)
    slots = list(obj.data.materials)
    mat_indices = [p.material_index for p in obj.data.polygons]
    obj.data.materials.clear()
    obj.data.materials.append(material)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT / (skin.name + ".glb")),
        export_format="GLB",
        use_selection=True,
        use_active_scene=True,
        export_animations=True,
        export_skins=True,
        export_vertex_color="ACTIVE",
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
    )
    obj.data.materials.clear()
    for slot in slots:
        obj.data.materials.append(slot)
    obj.data.polygons.foreach_set("material_index", mat_indices)
    return rig


def rig_rover(scene, material):
    def roll(pose, name, phase, frame):
        pose.rotation_euler.x = phase * 2 if name.startswith("Wheel") else 0.0
        pose.rotation_euler.z = sin(phase) * 1.1 if name == "Panorama" else 0.0
        pose.keyframe_insert(data_path="rotation_euler", frame=frame)

    skin, joints = rover()
    return rigid_assembly(scene, material, skin, joints, "Patrol", 97, roll)


def main():
    previous = bpy.context.scene
    scene = bpy.data.scenes.new("Surface patrol")
    bpy.context.window.scene = scene
    mat = flight_material()
    for i, sector in enumerate(SECTORS):
        obj = bake(sector_landmark(sector), scene, mat, OUTPUT)
        obj.location = ((i % 3) * 44, (i // 3) * 52, 0)
    for i, name in enumerate(
        ["ice_calving", "ruin_keystone", "ice_cornice", "ruin_corbel", "gate_projector"]
    ):
        obj = bake(hazard(name), scene, mat, OUTPUT)
        obj.location = (i * 22, -42, 3)
    for i, name in enumerate(["patrol_gate", "survival_pod"]):
        obj = bake(instrument_marker(name), scene, mat, OUTPUT)
        obj.location = (i * 11, -61, 5)
    rig = rig_rover(scene, mat)
    rig.location = (22, -61, 0)
    bpy.ops.object.select_all(action="DESELECT")
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.shading.color_type = "MATERIAL"
                space.shading.show_cavity = True
                space.overlay.show_overlays = False
                space.region_3d.view_location = (38, 0, 14)
                space.region_3d.view_distance = 163
                space.region_3d.view_rotation = Vector((0.4, -1, 0.49)).to_track_quat(
                    "Z", "Y"
                )
    path = str(ROOT / "Art/Surface Patrol.blend")
    if "--gallery" in sys.argv:
        if bpy.data.filepath or {obj.name for obj in previous.objects} != {
            "Camera",
            "Light",
            "Cube",
        }:
            raise RuntimeError("Standalone gallery requires a factory-startup scene")
        bpy.data.scenes.remove(previous)
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True, copy=True)
    else:
        bpy.data.libraries.write(path, {scene}, compress=True)
    print("SURFACE_PATROL_BUILT", len(scene.objects))


if __name__ == "__main__":
    main()
