"""Carve and line the open cardiac window in the two Xylo hull meshes."""

from math import cos, pi, sin, tau

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.geometry import barycentric_transform


def _split_polygon(polygon, normal, limit):
    """Keep the clipped pieces on both sides, retaining their original winding."""
    inside, outside = [], []
    a = polygon[-1]
    da = normal.dot(a) - limit
    for b in polygon:
        db = normal.dot(b) - limit
        if (da > 0) != (db > 0):
            edge = a.lerp(b, da / (da - db))
            inside.append(edge)
            outside.append(edge)
        (outside if db > 0 else inside).append(b)
        a, da = b, db
    return inside, outside


def _sealed_patch(skin, center, radius, planes):
    """Retain just the original chest panels with their original smooth shading."""
    mesh = bpy.data.meshes.new("Intact chest reference")
    mesh.from_pydata(skin.vertices, [], skin.faces)
    mesh.polygons.foreach_set("use_smooth", skin.smooth)
    mesh.update()
    mesh.calc_loop_triangles()
    positions = [v.co.copy() for v in mesh.vertices]
    normals = [v.normal.copy() for v in mesh.vertices]
    finishes = skin.finishes
    skin.faces, skin.finishes, skin.smooth, skin.vertices = [], [], [], []
    skin.custom_normals = []
    ids = {}
    origin = Vector(center)
    for tri in mesh.loop_triangles:
        a, b, c = tri.vertices
        points = [positions[a], positions[b], positions[c]]
        if any(all(n.dot(p) > limit for p in points) for n, limit in planes):
            continue
        for normal, limit in planes:
            points, _ = _split_polygon(points, normal, limit)
            if not points:
                break
        face = []
        for p in points:
            normal = tri.normal.copy()
            if tri.use_smooth:
                normal = barycentric_transform(
                    p, positions[a], positions[b], positions[c], normals[a], normals[b], normals[c]
                ).normalized()
            local = (p - origin) / radius
            # The rim overlaps uncut neighboring triangles by a few millimeters.
            local.y -= 0.002
            key = tuple(round(v, 6) for v in (*local, *normal))
            if key not in ids:
                ids[key] = len(skin.vertices)
                skin.vertices.append(tuple(local))
                skin.custom_normals.append(tuple(normal))
            if ids[key] not in face:
                face.append(ids[key])
        if len(face) >= 3:
            skin.face(face, finishes[tri.polygon_index], tri.use_smooth)
    bpy.data.meshes.remove(mesh)
    return skin


def carve_chest(skin, center, radius, sealed=False):
    """Cut through all overlapping armor and tissue up to the pericardial floor.

    center is the heart origin in Blender space. The pilot looks along +Y.
    Keep the new wound walls and ribs on the hull so their render and weapon
    collision triangles agree, including when viewed from off-axis.
    """
    cx, cy, cz = center
    span = radius * (1.42 if sealed else 1.0)
    width, height = 0.57 * span, 0.77 * span
    sides = 20
    angles = [tau * i / sides for i in range(sides)]
    rim = [Vector((cx + width * cos(a), cy, cz + height * sin(a))) for a in angles]
    floor = cy + radius * 0.74
    planes = [(Vector((0, 1, 0)), floor)]
    for i, point in enumerate(rim):
        delta = rim[(i + 1) % sides] - point
        normal = Vector((delta.z, 0, -delta.x)).normalized()
        planes.append((normal, normal.dot(point)))
    if sealed:
        return _sealed_patch(skin, center, radius, planes)

    original = [Vector(p) for p in skin.vertices]
    surface = BVHTree.FromPolygons(original, skin.faces)
    reference = bpy.data.meshes.new("Chest surface normals")
    reference.from_pydata(skin.vertices, [], skin.faces)
    reference.polygons.foreach_set("use_smooth", skin.smooth)
    reference.update()
    original_normals = [v.normal.copy() for v in reference.vertices]
    bpy.data.meshes.remove(reference)
    skin.custom_normals = [tuple(n) for n in original_normals]
    old_faces, old_finishes, old_smooth = skin.faces, skin.finishes, skin.smooth
    skin.faces, skin.finishes, skin.smooth = [], [], []
    vertex_ids = {tuple(round(v, 5) for v in p): i for i, p in enumerate(original)}

    def append_polygon(points, finish, smooth, source_ids):
        indices = []
        for p in points:
            key = tuple(round(v, 5) for v in p)
            if key not in vertex_ids:
                vertex_ids[key] = len(skin.vertices)
                skin.vertices.append(tuple(p))
                weights = [1 / max((p - original[i]).length_squared, 0.000001) for i in source_ids]
                n = sum((original_normals[i] * w for i, w in zip(source_ids, weights)), Vector())
                skin.custom_normals.append(tuple(n.normalized()))
            index = vertex_ids[key]
            if index not in indices:
                indices.append(index)
        if len(indices) >= 3:
            skin.face(indices, finish, smooth)

    for ids, finish, smooth in zip(old_faces, old_finishes, old_smooth):
        points = [original[i] for i in ids]
        if any(all(n.dot(p) > d for p in points) for n, d in planes):
            skin.face(ids, finish, smooth)
            continue
        for normal, limit in planes:
            if not points:
                break
            points, outside = _split_polygon(points, normal, limit)
            if outside:
                append_polygon(outside, finish, smooth, ids)

    skin.palette.update(lining="692d3b", fascia="ae5c58", costal="bdae87")

    def armor_depth(x, z):
        point = surface.ray_cast((x, -120, z), (0, 1, 0))[0]
        if point is None:
            raise RuntimeError(f"Cardiac socket misses {skin.name} hull at {x=}, {z=}")
        return point.y

    def ring(scale, inset):
        row = []
        for a in angles:
            x, z = cx + width * cos(a) * scale, cz + height * sin(a) * scale
            y = armor_depth(x, z) + radius * inset
            row.append((x, y, z))
        return row

    outer = ring(1.13, 0.012)
    lip = ring(1.015, -0.055)
    throat = ring(0.86, 0.025)
    back = [(cx + (x - cx) * 1.04, floor, cz + (z - cz) * 1.04) for x, _, z in throat]
    skin.rows([outer, lip, throat], "fascia", caps=False)
    skin.rows([throat, back], "lining", caps=False)
    skin.face(range(len(skin.vertices) - sides, len(skin.vertices)), "lining", False)
    # Upper and lower ribs still cross the window after the protective scute tears away.
    for level, dip in [(0.43, -0.14), (-0.53, 0.08)]:
        path, thickness = [], []
        span = radius * 0.66
        start = armor_depth(cx - span, cz + radius * (level - 0.05))
        end = armor_depth(cx + span, cz + radius * (level + 0.05))
        for j in range(15):
            t = j / 14
            arch = sin(t * pi)
            x = cx + span * (2 * t - 1)
            z = cz + radius * (level + dip * arch + (t - 0.5) * 0.10)
            y = start * (1 - t) + end * t + radius * (0.15 - 0.33 * arch)
            path.append((x, y, z))
            thickness.append(radius * (0.045 + 0.042 * arch))
        rows = []
        for j, point in enumerate(path):
            axis = (Vector(path[min(j + 1, 14)]) - Vector(path[max(j - 1, 0)])).normalized()
            a = axis.cross(Vector((0, 0, 1))).normalized()
            b = axis.cross(a)
            rows.append(
                [
                    Vector(point) + thickness[j] * (a * cos(tau * k / 12) + b * sin(tau * k / 12))
                    for k in range(12)
                ]
            )
        skin.rows(rows, "costal")
    # Blender calculates the normals on newly modeled wound surfaces.
    skin.custom_normals.extend([(0, 0, 0)] * (len(skin.vertices) - len(skin.custom_normals)))
    return skin
