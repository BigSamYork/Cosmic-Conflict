"""Author the three remaining siege hulls, their rigid animation rigs and tower wrecks.

Run in a factory-startup Blender from the repository root.
"""

import sys
from math import cos, pi, sin, tau
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material
from build_ground import OUTPUT, SECTORS, lathe, pipe, plate, tower


def weapon_bridges(s):
    for side in (-1, 1):
        for x, y, z in ((19, -14, 10), (30, 4, 8)):
            root = (side * 10.5, y + 4, 2.2)
            foot = (side * x, y, z - 1.6)
            s.tube([root, foot], [2.8, 1.85], "frame", 12)
            for offset in (-1, 1):
                pipe(
                    s,
                    [
                        (root[0], root[1] + offset * 2, root[2] + 3),
                        (foot[0], foot[1] + offset, foot[2]),
                    ],
                    0.46,
                    "steel",
                )
            lathe(
                s,
                [(z - 2.6, 3.1), (z - 1.8, 4.4), (z - 0.7, 4.25)],
                "paint",
                24,
                (side * x, y),
            )


def bore():
    s = Skin("glacier_bore", "cryo")
    s.shell(
        (0, 3, 0),
        [
            (-17, 8, 3, 0),
            (-12, 14, 4.2, 0),
            (7, 14.5, 4.8, 0),
            (14, 12, 4.2, 0),
            (18, 8, 2.6, 0),
        ],
        sectors=28,
    )
    for side in (-1, 1):
        # Twin full-length track shoes, segmented cleats and wheel hubs.
        x = side * 15
        plate(s, (x, 2, -4.0), (7.1, 34.5, 7.2), "frame", 0.42)
        for j in range(8):
            y = -11.5 + 3.9 * j
            s.tube([(x, y, -4.1), (x + side * 4.0, y, -4.1)], [2.75, 2.60], "seam", 32)
            s.tube(
                [(x + side * 4, y, -4.1), (x + side * 4.35, y, -4.1)],
                [1.90, 1.55],
                "steel",
                28,
            )
            s.tube(
                [(x + side * 4.35, y, -4.1), (x + side * 4.50, y, -4.1)],
                [0.88, 0.80],
                "stripe",
                24,
            )
        for j in range(17):
            y = -13.7 + j * 1.95
            plate(s, (x, y, -7.5), (7.7, 1.45, 0.62), "steel")
            plate(s, (x, y, -0.57), (7.55, 1.45, 0.62), "paint")
        for j in range(5):
            y = -5.5 + j * 3.45
            s.tube(
                [(side * 8.2, y, 4.2), (side * 8.2, y, 8.3)], [1.42, 1.25], "stripe", 24
            )
            for h in (5.1, 6.1, 7.1):
                lathe(s, [(h, 1.42), (h + 0.24, 1.43)], "steel", 24, (side * 8.2, y))
    plate(s, (0, 4.2, 6.4), (15.5, 16, 6.5), "paint", 0.50)
    plate(s, (0, -3.3, 8.1), (12.1, 1.5, 3.4), "glass", 0.27)
    for x in (-4, 0, 4):
        plate(s, (x, -4.14, 8.2), (0.38, 0.36, 3.6), "steel")
    lathe(s, [(3.9, 5), (4.9, 4.5), (7.5, 4.2)], "frame", 40, (0, -8.1))
    weapon_bridges(s)
    return s


def auger():
    s = Skin("ice_auger", "cryo")
    s.tube(
        [(0, 6, 0), (0, 2, 0), (0, -8, 0), (0, -12, 0)],
        [3.7, 3.3, 1.5, 0.07],
        "frame",
        40,
    )
    for arm in range(3):
        rows = []
        for i in range(65):
            t = i / 64
            a = t * tau * 1.8 + arm * tau / 3
            r = (1 - t) * 3.5 + 0.12
            y = 4.2 - 15.8 * t
            rows.append(
                [
                    (cos(a) * r * 0.65, y + 0.30, sin(a) * r * 0.65),
                    (cos(a) * r * 1.28, y + 0.46, sin(a) * r * 1.28),
                    (cos(a) * r * 1.42, y, sin(a) * r * 1.42),
                    (cos(a) * r * 0.68, y - 0.23, sin(a) * r * 0.68),
                ]
            )
        s.rows(rows, "steel" if arm != 1 else "stripe")
        for j in range(2, 58, 7):
            p = Vector(rows[j][2])
            q = Vector(rows[j + 1][2])
            tip = p + Vector((p.x * 0.15, -0.65, p.z * 0.15))
            s.tube([q, p, tip], [0.34, 0.53, 0.045], "ceramic", 10)
    return s


def overlord():
    s = Skin("overlord_spire", "nyx")
    lathe(
        s,
        [(-4, 10), (-2.9, 16.7), (0, 16.3), (1.5, 12.6)],
        "frame",
        48,
        (0, 4),
        stretch=(1.1, 1.17),
    )
    lathe(
        s,
        [(0, 9.6), (3, 10.6), (8, 9.1), (15, 8.6), (22, 7.7), (25, 6.3), (26, 3.4)],
        "paint",
        48,
        (0, 4),
    )
    for j in range(12):
        a = tau * j / 12
        for h, r in [(3, 9.9), (10, 9.0), (17, 8.1)]:
            x = r * cos(a)
            y = 4 + r * sin(a)
            s.pod((x, y, h + 1.8), (1.45, 1.4, 3.2), "glass", 12, 20)
            pipe(
                s,
                [
                    (x * 1.06, 4 + (y - 4) * 1.06, h),
                    (x * 1.10, 4 + (y - 4) * 1.10, h + 3.2),
                ],
                0.17,
                "light",
            )
        pipe(
            s,
            [
                (11.7 * cos(a), 4 + 11.7 * sin(a), 1),
                (9.0 * cos(a + 0.22), 4 + 9.0 * sin(a + 0.22), 12),
                (7.8 * cos(a + 0.42), 4 + 7.8 * sin(a + 0.42), 24),
            ],
            0.39,
            "steel",
        )
    lathe(s, [(23.8, 7.4), (24.5, 7.95), (25, 7.75)], "stripe", 48, (0, 4))
    weapon_bridges(s)
    return s


def inducer():
    s = Skin("induction_carousel", "nyx")
    for r in (10.9, 13.2):
        path = [(cos(tau * j / 64) * r, sin(tau * j / 64) * r, 0) for j in range(65)]
        pipe(s, path, 0.23 if r < 12 else 0.37, "copper", 10)
    for j in range(12):
        a = tau * j / 12
        p = (10.8 * cos(a), 10.8 * sin(a), 0)
        q = (13.6 * cos(a), 13.6 * sin(a), 0)
        s.tube([p, q], [0.55, 0.92], "paint", 16)
        s.pod(q, (0.90, 0.90, 0.48), "light", 10, 20)
    return s


def colossus():
    s = Skin("sunforge_colossus", "desert")
    for z, w, d, h in [
        (-2, 31, 30, 7),
        (2.6, 24, 24, 4.5),
        (6.1, 17.5, 17.5, 3.4),
        (8.8, 11, 11, 3.0),
    ]:
        plate(s, (0, 4, z), (w, d, h), "paint", 0.41)
        plate(s, (0, 4, z + h * 0.4), (w + 0.38, d + 0.38, 0.42), "copper", 0.40)
        for side in (-1, 1):
            for j in range(7):
                x = w * (j - 3) * 0.095
                plate(
                    s,
                    (x, 4 + side * d * 0.485, z + 0.18),
                    (0.61, 0.39, h * 0.44),
                    "glass",
                )
    for side in (-1, 1):
        x = side * 16
        s.shell(
            (x, 1, -4),
            [
                (-19, 2.4, 1.5, 0),
                (-13, 4.7, 3.6, 0),
                (9, 4.9, 3.8, 0),
                (16, 4.4, 2.7, 0),
                (20, 1.4, 1.4, 0),
            ],
            sectors=24,
        )
        for j in range(9):
            y = -11.5 + j * 3.5
            plate(
                s, (x, y, -0.5), (7.8, 2.3, 0.78), "stripe" if j % 3 == 0 else "paint"
            )
            pipe(
                s,
                [
                    (x + side * 2.9, y, -1),
                    (x + side * 4.6, y, -4),
                    (x + side * 3.2, y, -6),
                ],
                0.33,
                "steel",
            )
        lathe(
            s,
            [(4, 2.4), (5.2, 3.2), (7.2, 2.7), (9.9, 1.8)],
            "steel",
            32,
            (side * 11.3, 11),
        )
    weapon_bridges(s)
    return s


def collector():
    s = Skin("solar_collector", "desert")
    lathe(s, [(-1.3, 1.35), (0, 1.8), (1.4, 1.2)], "frame", 28)
    # Split copper petals surround an emissive focusing prism.
    for j in range(5):
        a = tau * j / 5
        rows = []
        for i in range(9):
            t = i / 8
            r = 1.0 + 3.8 * t
            w = 1.32 * sin(pi * t) ** 0.68 + 0.14
            z = 0.1 + t * 4.0
            rows.append(
                [
                    (
                        r * cos(a) - off * w * sin(a),
                        r * sin(a) + off * w * cos(a),
                        z + 0.42 * (1 - abs(off)),
                    )
                    for off in (-1, 0, 1)
                ]
            )
        s.rows(rows, "copper", False, False)
    lathe(s, [(0, 0.8), (1.1, 1.08), (4.8, 0.62), (6, 0.03)], "light", 8)
    return s


def clip_at(polygon, level, above):
    result = []
    for p, q in zip(polygon, polygon[1:] + polygon[:1]):
        inside = (p.z >= level) if above else (p.z <= level)
        other = (q.z >= level) if above else (q.z <= level)
        if inside:
            result.append(p)
        if inside != other:
            result.append(p.lerp(q, (level - p.z) / (q.z - p.z)))
    return result


def tower_slice(source, sector, band, low, high):
    s = Skin(f"wreck_{sector}_{band}", SECTORS[sector])
    s.palette = source.palette.copy()
    ids = {}
    for face, finish, smooth in zip(source.faces, source.finishes, source.smooth):
        points = [Vector(source.vertices[i]) for i in face]
        points = clip_at(clip_at(points, low, True), high, False)
        face_ids = []
        for p in points:
            key = tuple(round(v, 6) for v in p)
            if key not in ids:
                ids[key] = len(s.vertices)
                s.vertices.append(key)
            if not face_ids or face_ids[-1] != ids[key]:
                face_ids.append(ids[key])
        if len(set(face_ids)) >= 3:
            s.face(face_ids, finish, smooth)
    return s


def rig(scene, name, chassis, attachments):
    data = bpy.data.armatures.new(name)
    arm = bpy.data.objects.new(name, data)
    scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    root = data.edit_bones.new("Chassis")
    root.head = (0, 0, 0)
    root.tail = (0, 0, 4)
    for joint, _, offset, _ in attachments:
        bone = data.edit_bones.new(joint)
        bone.head = offset
        bone.tail = Vector(offset) + Vector((0, 0, 2))
        bone.parent = root
    bpy.ops.object.mode_set(mode="OBJECT")
    chassis.parent = arm
    for joint, obj, offset, speed in attachments:
        obj.parent = arm
        obj.parent_type = "BONE"
        obj.parent_bone = joint
        bpy.context.view_layer.update()
        obj.matrix_world = Matrix.Translation(Vector(offset))
        # In Blender a bone's local Y follows its length (+Z in the model).
        bone = arm.pose.bones[joint]
        bone.rotation_mode = "XYZ"
        axis = 2 if joint == "Auger" else 1
        for frame, value in ((1, 0), (121, speed * tau)):
            bone.rotation_euler[axis] = value
            bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    arm.animation_data.action.name = name + " | operating cycle"
    for curve in arm.animation_data.action.fcurves:
        for key in curve.keyframe_points:
            key.interpolation = "LINEAR"
    arm.show_in_front = False
    data.display_type = "STICK"
    return arm


def main():
    scene = bpy.context.scene
    if bpy.data.filepath or {o.name for o in scene.objects} != {
        "Cube",
        "Camera",
        "Light",
    }:
        raise RuntimeError("Use --factory-startup for the siege gallery.")
    for obj in list(scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    material = flight_material()

    def make(skin):
        return bake(skin, scene, material, OUTPUT)

    for sector in SECTORS:
        source = tower(sector)
        for i, (lo, hi) in enumerate(((-10, -2.6), (-2.6, 1.55), (1.55, 10))):
            part = make(tower_slice(source, sector, i, lo, hi))
            bpy.data.objects.remove(part, do_unlink=True)
    glacier = rig(
        scene, "Glacier drive", make(bore()), [("Auger", make(auger()), (0, -14, 8), 4)]
    )
    glacier.location.x = -85
    spire = make(overlord())
    ring = make(inducer())
    rings = [ring, ring.copy(), ring.copy()]
    for obj in rings[1:]:
        scene.collection.objects.link(obj)
    rig(
        scene,
        "Induction carousel",
        spire,
        [
            (f"Ring{i + 1}", obj, (0, 4, 6 + 7 * i), 1 if i % 2 == 0 else -1)
            for i, obj in enumerate(rings)
        ],
    )
    fortress = make(colossus())
    lens = make(collector())
    other = lens.copy()
    scene.collection.objects.link(other)
    solar = rig(
        scene,
        "Solar concentrators",
        fortress,
        [("Port", lens, (-11.3, 11, 10), 1), ("Starboard", other, (11.3, 11, 10), -1)],
    )
    solar.location.x = 85
    scene.name = "Siege works"
    scene.frame_end = 120
    scene.frame_set(1)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.overlay.show_overlays = False
                space.shading.color_type = "MATERIAL"
                space.shading.show_cavity = True
                space.region_3d.view_location = (0, 0, 7)
                space.region_3d.view_distance = 210
                space.region_3d.view_rotation = Vector((0.18, -1, 0.44)).to_track_quat(
                    "Z", "Y"
                )
                space.region_3d.view_perspective = "ORTHO"
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(
        filepath=str(ROOT / "Art/Siege Works.blend"), compress=True
    )


if __name__ == "__main__":
    main()
