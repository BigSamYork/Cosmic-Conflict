"""Bake the modular player guns. Run in Blender from the repository root."""

import sys
from math import cos, sin, tau
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import ROOT, Skin, bake, flight_material


def ring(s, x, z, profile, finish, sides=32):
    # Profiles can turn back into the muzzle to form a genuinely recessed face.
    s.rows([[(x + radius * cos(tau * i / sides), y, z + radius * sin(tau * i / sides))
             for i in range(sides)] for y, radius in profile], finish, reverse=True, caps=False)


def receiver(name):
    s = Skin(name, "gunmetal")
    s.palette.update(paint="364956", stripe="6598a5", light="39cce6")
    s.shell((0, 0, -0.12), [(-0.61, 0.14, 0.13, 0), (-0.46, 0.23, 0.21, 0),
            (0.08, 0.22, 0.20, 0), (0.23, 0.16, 0.12, 0)], power=0.42)
    return s


def pulse():
    s = receiver("twin_pulse")
    ring(s, 0, 0.14, [(-0.72, 0.04), (-0.66, 0.23), (-0.38, 0.26),
         (0.11, 0.235), (1.37, 0.155), (1.45, 0.16), (1.47, 0.112), (1.30, 0.10)], "frame")
    for i in range(5):
        y = -0.30 + i * 0.34
        r = 0.254 - i * 0.017
        ring(s, 0, 0.14, [(y, r), (y + 0.02, r + 0.012), (y + 0.17, r),
             (y + 0.20, r - 0.012)], "paint")
        ring(s, 0, 0.14, [(y + 0.205, r - 0.008), (y + 0.231, r - 0.010)], "light")
    ring(s, 0, 0.14, [(1.415, 0.165), (1.46, 0.164), (1.465, 0.115)], "steel")
    s.pod((0, 1.31, 0.14), (0.10, 0.018, 0.10), "light")
    return s


def plasma():
    s = receiver("quad_plasma")
    s.shell((0, 0, 0.13), [(-0.77, 0.17, 0.16, 0), (-0.54, 0.31, 0.25, 0),
            (0.45, 0.32, 0.25, 0), (0.60, 0.25, 0.22, 0)], power=0.40)
    for i in range(6):
        y = -0.42 + i * 0.135
        s.shell((0, y, 0.35), [(-0.035, 0.23, 0.035, 0), (0.025, 0.21, 0.055, 0)],
                "steel", False, power=0.45)
    ring(s, 0, 0.14, [(0.52, 0.28), (0.58, 0.335), (0.72, 0.335), (0.74, 0.267)], "copper")
    for i in range(6):
        x, z = 0.174 * cos(i * tau / 6), 0.14 + 0.174 * sin(i * tau / 6)
        ring(s, x, z, [(0.59, 0.085), (1.29, 0.085), (1.37, 0.10),
             (1.42, 0.095), (1.425, 0.062), (1.34, 0.060)], "steel", 18)
        s.pod((x, 1.345, z), (0.059, 0.012, 0.059), "glass", 6, 18)
    ring(s, 0, 0.14, [(0.97, 0.275), (1.00, 0.285), (1.10, 0.285), (1.12, 0.26)], "frame")
    return s


def tachyon():
    s = receiver("tachyon_beam")
    s.shell((0, 0, 0.12), [(-0.77, 0.17, 0.14, 0), (-0.52, 0.265, 0.21, 0),
            (0.30, 0.25, 0.18, 0), (0.50, 0.20, 0.13, 0)], power=0.38)
    for side in (-1, 1):
        x = side * 0.157
        s.shell((x, 0, 0.13), [(0.24, 0.095, 0.14, 0), (0.54, 0.09, 0.106, 0),
                (1.68, 0.066, 0.075, 0.04), (1.99, 0.013, 0.013, 0.08)], "steel", False, power=0.45)
        s.tube([(x, 0.42, 0.244), (x, 1.66, 0.251), (x, 1.90, 0.226)],
               [0.033, 0.024, 0.007], "light")
    for y in (0.56, 0.89, 1.22, 1.55):
        s.tube([(-0.19, y, 0.14), (0.19, y, 0.14)], [0.028, 0.028], "stripe")
    return s


if __name__ == "__main__":
    bpy.ops.wm.read_factory_settings(use_empty=True)
    material = flight_material()
    output = ROOT / "current_dev/assets/guns"
    for i, weapon in enumerate((pulse(), plasma(), tachyon())):
        obj = bake(weapon, bpy.context.scene, material, output)
        obj.location.x = 1.35 * (i - 1)
    for area in bpy.context.screen.areas:
        if area.type == "VIEW_3D":
            space = area.spaces.active
            space.overlay.show_overlays = False
            space.shading.color_type = "MATERIAL"
            space.region_3d.view_rotation = Vector((0.42, 1, 0.76)).to_track_quat("Z", "Y")
            space.region_3d.view_distance = 7
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "Art/Player gun mounts.blend"), compress=True)
