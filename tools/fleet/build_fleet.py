"""Build the editable fleet and the one-draw meshes used by Godot.

Run inside a fresh Blender scene from the repository root. Blender +Y is the
bow and +Z is up. The glTF exporter maps these to Godot -Z and +Y.
"""

from math import cos, sin, pi, tau
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path.cwd()
OUTPUT = ROOT / "current_dev/assets/fleet"
SIDES = (-1, 1)
# Lacquer, contrasting stripe, running lights, smoked glazing.
LIVERIES = {
    "union": ("d3dcd7", "e84a29", "64eaf7", "14445a"),
    "patrol": ("89a8be", "f6b544", "9af6ff", "164255"),
    "gunmetal": ("566d83", "e79143", "6fe7ff", "1b3645"),
    "royal": ("8a82ae", "dcc98f", "9af6ff", "302745"),
    "rescue": ("ef923e", "f1e3c5", "8df8dd", "1b4448"),
    "pirate": ("ab5746", "f4b14c", "ff805c", "2d3544"),
    "web": ("785e85", "ddb890", "ff77bc", "32233b"),
    "cryo": ("e0ece7", "437dc9", "82ffff", "1a3a6c"),
    "nyx": ("515074", "c685bc", "fd74dc", "321b54"),
    "tide": ("418596", "ebe0ba", "65ffe1", "163d50"),
    "desert": ("c79850", "42786f", "84ffe8", "264a4c"),
    "hive": ("677f53", "d19e69", "d3ff57", "46384f"),
}
COMMON = {
    "frame": "36434c",
    "seam": "202c36",
    "steel": "859499",
    "ceramic": "eee8d6",
    "copper": "b88453",
    "red": "ff6250",
    "green": "8af5b5",
}
FINISH = {
    "glass": 0.44,
    "jet": 0.73,
    "light": 0.88,
    "red": 0.91,
    "green": 0.94,
    "steel": 0.29,
    "copper": 0.32,
    "seam": 0.08,
    "frame": 0.18,
    "paint": 0.15,
    "stripe": 0.16,
    "ceramic": 0.12,
}


def mix(a, b, t):
    return a + (b - a) * t


def signed_power(x, p):
    return abs(x) ** p if x >= 0 else -(abs(x) ** p)


def interpolate(stations, t):
    """Linear interpolation between authored cross sections."""
    t = max(0, min(1, t)) * (len(stations) - 1)
    i = min(int(t), len(stations) - 2)
    return [mix(a, b, t - i) for a, b in zip(stations[i], stations[i + 1])]


class Skin:
    def __init__(self, name, livery):
        self.name = name
        self.palette = dict(
            COMMON, **dict(zip(("paint", "stripe", "light", "glass"), LIVERIES[livery]))
        )
        self.palette["jet"] = self.palette["light"]
        self.vertices, self.faces, self.finishes, self.smooth = [], [], [], []
        self.jet_coordinates = {}

    def face(self, ids, finish, smooth=True):
        self.faces.append(tuple(ids))
        self.finishes.append(finish)
        self.smooth.append(smooth)

    def rows(self, rows, finish, closed=True, caps=True, reverse=False, smooth=True):
        start = len(self.vertices)
        width = len(rows[0])
        for row in rows:
            self.vertices.extend(row)
        for i in range(len(rows) - 1):
            for j in range(width if closed else width - 1):
                a = start + i * width + j
                b = start + i * width + (j + 1) % width
                ids = (a, b, b + width, a + width)
                self.face(ids[::-1] if reverse else ids, finish, smooth)
        if caps and closed:
            front = list(range(start, start + width))
            back = [idx + (len(rows) - 1) * width for idx in front]
            self.face(front if reverse else front[::-1], finish, False)
            self.face(back[::-1] if reverse else back, finish, False)

    def patch(self, point, us, vs, finish, reverse=False):
        self.rows([[point(u, v) for v in vs] for u in us], finish, False, False, reverse)

    def tube(self, points, radii, finish, sides=12):
        points = [Vector(p) for p in points]
        rows = []
        for i, p in enumerate(points):
            axis = (points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]).normalized()
            seed = Vector((1, 0, 0)) if abs(axis.x) < 0.85 else Vector((0, 1, 0))
            a = axis.cross(seed).normalized()
            b = axis.cross(a)
            rows.append(
                [
                    p + radii[i] * (a * cos(tau * j / sides) + b * sin(tau * j / sides))
                    for j in range(sides)
                ]
            )
        self.rows(rows, finish)

    def pod(self, at, size, finish, rings=10, sides=24):
        x, y, z = at
        w, l, h = size
        rows = []
        for i in range(rings + 1):
            a = mix(-pi / 2 + 0.014, pi / 2 - 0.014, i / rings)
            rows.append(
                [
                    (
                        x + w * cos(a) * cos(tau * j / sides),
                        y + l * sin(a),
                        z + h * cos(a) * sin(tau * j / sides),
                    )
                    for j in range(sides)
                ]
            )
        self.rows(rows, finish, reverse=True)

    def shell(self, at, stations, finish="paint", plated=True, power=0.77, sectors=24):
        """Armored loft with individual conformal plates over a dark pressure hull.
        Sections run stern to bow as (fore, half-beam, half-height, rise).
        """
        x, y, z = at

        def point(t, a, offset=0):
            fore, w, h, rise = interpolate(stations, t)
            return (
                x + (w + offset) * signed_power(cos(a), power),
                y + fore,
                z + rise + (h + offset) * signed_power(sin(a), power),
            )

        steps = len(stations) - 1
        self.rows(
            [
                [point(i / steps, tau * j / sectors) for j in range(sectors)]
                for i in range(steps + 1)
            ],
            "frame" if plated else finish,
            reverse=True,
        )
        if plated:
            lift = max(s[2] for s in stations) * 0.042
            for i in range(steps):
                for j in range(8):
                    # Separate panels have a bevel lip and a visible recessed gasket.
                    u0, u1 = (i + 0.018) / steps, (i + 0.982) / steps
                    v0, v1 = tau * (j + 0.014) / 8, tau * (j + 0.986) / 8
                    us = [u0, mix(u0, u1, 0.042), mix(u0, u1, 0.96), u1]
                    vs = [mix(v0, v1, k / 4) for k in range(5)]
                    rows = [
                        [
                            point(u, v, lift * (0.18 if p in (0, 3) or q in (0, 4) else 1))
                            for q, v in enumerate(vs)
                        ]
                        for p, u in enumerate(us)
                    ]
                    self.rows(rows, finish, False, False, True)
        return point

    def applique(self, point, u0, u1, a0, a1, mat, lift):
        self.patch(
            lambda u, a: point(u, a, lift),
            [mix(u0, u1, i / 4) for i in range(5)],
            [mix(a0, a1, j / 4) for j in range(5)],
            mat,
            True,
        )

    def wing(self, side, stations, finish="paint", marking=True):
        """Cambered foil. Stations contain span, leading edge, trailing edge, height, thickness."""

        def point(u, c, top=True, lift=0):
            x, lead, trail, z, thick = interpolate(stations, u)
            bulge = max(0, sin(pi * c)) ** 0.62
            return (
                side * x,
                mix(lead, trail, c),
                z + thick * ((0.12 + 0.88 * bulge) if top else -(0.12 + 0.55 * bulge)) + lift,
            )

        cols = 10
        rows = []
        for i in range(2 * len(stations) - 1):
            u = i / (2 * len(stations) - 2)
            rows.append(
                [point(u, j / cols) for j in range(cols + 1)]
                + [point(u, j / cols, False) for j in range(cols, -1, -1)]
            )
        self.rows(rows, finish, reverse=side < 0)
        if marking:
            for u0, u1, mat in [
                (0.57, 0.73, "stripe"),
                (0.755, 0.78, "ceramic"),
                (0.84, 0.852, "frame"),
            ]:
                self.patch(
                    lambda u, c: point(u, c, lift=0.009 * max(s[4] for s in stations) + 0.003),
                    [u0, (u0 + u1) / 2, u1],
                    [j / cols for j in range(1, 10)],
                    mat,
                    side < 0,
                )
            for frac in [0.26, 0.49, 0.82]:
                self.patch(
                    lambda u, c: point(u, c, lift=0.005),
                    [frac, frac + 0.009],
                    [j / cols for j in range(2, 10)],
                    "frame",
                    side < 0,
                )
        return point

    def engine(self, at, r, length, finish="paint"):
        """Bell, recessed ion disk, heat shields, intake, and external expansion rings."""
        x, y, z = at

        def radial(t, k, a):
            return (x + r * k * cos(a), y + t * length, z + r * k * sin(a))

        def lathe(profile, mat):
            self.rows(
                [[radial(t, k, tau * j / 28) for j in range(28)] for t, k in profile],
                mat,
                reverse=True,
            )

        lathe(
            [(-0.51, 0.72), (-0.39, 0.85), (-0.29, 0.96), (0.13, 1), (0.39, 0.86), (0.5, 0.58)],
            "frame",
        )
        for t in [-0.34, -0.23, 0.10, 0.37]:
            lathe(
                [(t - 0.026, 0.89), (t - 0.017, 1.01), (t + 0.017, 1.01), (t + 0.024, 0.9)], "steel"
            )
        for j in range(10):
            a = tau * j / 10
            self.rows(
                [
                    [radial(t, k, a + v) for v in [0.01, 0.1, 0.31, 0.48, 0.54]]
                    for t, k in [(-0.19, 0.96), (-0.16, 1.04), (0.27, 1.02), (0.32, 0.92)]
                ],
                finish,
                False,
                False,
                True,
            )
        lathe([(-0.525, 0.72), (-0.56, 0.75), (-0.566, 0.62), (-0.50, 0.52)], "copper")
        lathe([(-0.505, 0.53), (-0.509, 0.44)], "light")
        lathe([(-0.511, 0.31), (-0.516, 0.25)], "seam")
        lathe([(-0.518, 0.22), (-0.524, 0.135)], "ceramic")
        lathe([(0.505, 0.56), (0.512, 0.43)], "seam")
        # Turbine spinner, overlapping inlet vanes and external coolant pipes.
        for j in range(9):
            a = tau * j / 9
            self.rows(
                [
                    [radial(0.518, 0.17, a), radial(0.518, 0.17, a + 0.41)],
                    [radial(0.517, 0.49, a + 0.37), radial(0.519, 0.49, a + 0.49)],
                ],
                "steel",
                False,
                False,
            )
        self.pod((x, y + length * 0.522, z), (r * 0.17, length * 0.040, r * 0.17), "copper", 6, 14)
        for j in [1, 4, 6, 9]:
            a = tau * j / 10
            self.tube(
                [
                    radial(t, k, a)
                    for t, k in [(-0.28, 1.0), (-0.20, 1.09), (0.17, 1.09), (0.24, 1.00)]
                ],
                [r * 0.055] * 4,
                "copper" if j % 2 else "frame",
                7,
            )
        tail = y - length * 0.52
        start = len(self.vertices)
        for row, t in enumerate([0, 0.30, 0.63, 0.96, 1.55]):
            for j in range(20):
                self.jet_coordinates[start + row * 20 + j] = t / 1.55
        # Several nested shock cells keep the exhaust luminous from side and stern views.
        self.rows(
            [
                [
                    (x + r * k * cos(tau * j / 20), tail - r * t, z + r * k * sin(tau * j / 20))
                    for j in range(20)
                ]
                for t, k in [(0, 0.48), (0.30, 0.45), (0.63, 0.27), (0.96, 0.29), (1.55, 0.018)]
            ],
            "jet",
        )
        for j in range(6):
            a = j * pi / 3
            self.tube(
                [radial(0.514, 0.12, a), radial(0.514, 0.49, a + 0.24)],
                [r * 0.037, r * 0.022],
                "steel",
                6,
            )

    def canopy(self, x, y, z, w, l, h):
        self.pod((x, y, z), (w * 1.09, l * 1.03, h * 0.89), "frame")
        self.pod((x, y, z + 0.04 * h), (w, l, h), "glass", 14, 28)
        for fore in [-0.62, 0.22]:
            rr = (1 - fore**2) ** 0.5
            path = [
                (
                    x + w * rr * cos(pi * j / 14) * 1.016,
                    y + l * fore,
                    z + h * (0.04 + rr * sin(pi * j / 14) * 1.025),
                )
                for j in range(15)
            ]
            self.tube(path, [w * 0.039] * 15, "steel", 6)

    def fin(self, side, x, y, z, width, height, lean):
        self.wing(
            side,
            [
                (x, y + 0.55 * width, y - 0.46 * width, z, 0.08 * width),
                (
                    x + lean * 0.55,
                    y + 0.03 * width,
                    y - 0.55 * width,
                    z + height * 0.66,
                    0.055 * width,
                ),
                (x + lean, y - 0.34 * width, y - 0.58 * width, z + height, 0.025 * width),
            ],
            "paint",
            False,
        )

    def registry(self, side, wing, bars=3):
        # A squadron flash and small serial strokes on the inboard wing.
        # Stenciled numerals follow the camber, with gaps around the removable panels.
        digits = {
            "rook": "03",
            "hawk": "07",
            "strike": "21",
            "delta": "46",
            "engine_scout": "31",
            "pirate": "52",
            "range": "18",
            "tide": "24",
            "tide_heavy": "29",
        }
        segments = {
            "0": "abcdef",
            "1": "bc",
            "2": "abdeg",
            "3": "abcdg",
            "4": "bcfg",
            "5": "acdfg",
            "6": "acdefg",
            "7": "abc",
            "8": "abcdefg",
            "9": "abcdfg",
        }
        strokes = {
            "a": (0.12, 0, 0.86, 0.12),
            "b": (0.80, 0.12, 0.96, 0.47),
            "c": (0.80, 0.54, 0.96, 0.89),
            "d": (0.12, 0.88, 0.86, 1),
            "e": (0.02, 0.54, 0.18, 0.89),
            "f": (0.02, 0.12, 0.18, 0.47),
            "g": (0.12, 0.44, 0.86, 0.56),
        }
        for index, digit in enumerate(digits.get(self.name, "")):
            for seg in segments[digit]:
                x1, y1, x2, y2 = strokes[seg]
                u = 0.27 + index * 0.115
                self.patch(
                    lambda a, c: wing(a, c, lift=0.021),
                    [u + x1 * 0.092, u + x2 * 0.092],
                    [0.22 + y1 * 0.46, 0.22 + y2 * 0.46],
                    "frame" if self.name in ("rook", "strike") else "ceramic",
                    side < 0,
                )
        for j in range(bars):
            self.patch(
                lambda u, c: wing(u, c, lift=0.018),
                [0.28 + j * 0.028, 0.294 + j * 0.028],
                [0.75, 0.83, 0.89 if j == 0 else 0.86],
                "ceramic",
                side < 0,
            )

    def vent(self, at, w, l):
        x, y, z = at
        self.pod((x, y, z), (w, l, 0.11 * w), "seam", 6, 16)
        for j in range(5):
            dy = (j - 2) * l * 0.29
            span = w * (0.75 - 0.065 * abs(j - 2))
            self.tube(
                [
                    (x - span, y + dy - 0.05 * l, z + 0.10 * w),
                    (x + span, y + dy + 0.05 * l, z + 0.10 * w),
                ],
                [w * 0.045] * 2,
                "steel",
                6,
            )


def keel(s, at, w, l, h, blunt=0.13, finish="paint"):
    sections = [
        (-1, 0.62, 0.58, 0),
        (-0.82, 0.91, 0.84, 0.03),
        (-0.42, 1, 1, 0.06),
        (0.02, 0.95, 0.97, 0.08),
        (0.46, 0.74, 0.78, 0.03),
        (0.78, 0.44, 0.47, -0.04),
        (1, blunt, 0.18, -0.12),
    ]
    surface = s.shell(at, [(y * l, a * w, b * h, r * h) for y, a, b, r in sections], finish)
    # Spine inlays, contrasting shoulder panels and service hatches follow the loft.
    for side in SIDES:
        shoulder = pi / 2 + side * 0.69
        s.applique(surface, 0.35, 0.68, shoulder - 0.17, shoulder + 0.17, "stripe", h * 0.061)
        s.applique(surface, 0.71, 0.81, shoulder - 0.17, shoulder + 0.17, "steel", h * 0.061)
        s.applique(surface, 0.18, 0.31, shoulder - 0.25, shoulder + 0.23, "seam", h * 0.061)
        for j in range(4):
            t = 0.19 + 0.031 * j
            s.applique(surface, t, t + 0.012, shoulder - 0.22, shoulder + 0.20, "steel", h * 0.078)
        s.applique(
            surface, 0.49, 0.63, shoulder + side * 0.31, shoulder + side * 0.35, "light", h * 0.061
        )
    s.applique(surface, 0.76, 0.98, 1.51, 1.63, "frame", h * 0.059)
    return surface


def boom(s, side, x, y, z, r, l):
    at = (side * x, y, z)
    s.engine(at, r, l)
    s.tube(
        [(side * x, y + l * 0.45, z), (side * x, y + l * 0.85, z), (side * x, y + l * 0.95, z)],
        [r * 0.23, r * 0.16, r * 0.09],
        "frame",
        14,
    )
    s.tube(
        [(side * x, y + l * 0.88, z), (side * x, y + l * 0.95, z)],
        [r * 0.18, r * 0.13],
        "copper",
        14,
    )


def fighter(name, livery, style, span, length, w, h):
    s = Skin(name, livery)
    # Wing stations are fractions of half-span and half-length, independent of the fuselage.
    wings = {
        "swept": [
            (0.12, 0.34, -0.65, 0),
            (0.45, 0.12, -0.71, 0.04),
            (0.72, -0.18, -0.82, -0.06),
            (1, -0.46, -0.80, 0.08),
        ],
        "hawk": [
            (0.15, 0.22, -0.78, 0),
            (0.53, 0.38, -0.40, -0.12),
            (0.86, 0.61, 0.05, -0.15),
            (1, 0.69, 0.36, -0.11),
        ],
        "delta": [
            (0.10, 0.95, -0.75, 0),
            (0.42, 0.44, -0.80, 0.03),
            (0.74, -0.02, -0.84, 0.03),
            (1, -0.53, -0.72, -0.04),
        ],
        "nyx": [
            (0.10, 0.82, -0.44, 0.10),
            (0.49, 0.49, -0.88, 0.02),
            (0.76, 0.25, -0.36, -0.32),
            (1, 0.06, -0.06, -0.38),
        ],
        "tide": [
            (0.10, 0.88, -0.82, 0),
            (0.37, 0.72, -0.67, 0.12),
            (0.70, 0.32, -0.77, -0.04),
            (1, -0.17, -0.12, 0.18),
        ],
        "scout": [
            (0.12, 0.18, -0.44, 0),
            (0.48, 0.12, -0.25, -0.06),
            (0.78, 0.17, -0.21, 0.04),
            (1, 0.12, -0.16, 0.25),
        ],
        "runner": [
            (0.15, 0.18, -0.44, 0),
            (0.47, 0.24, -0.18, -0.05),
            (0.78, 0.11, -0.34, -0.15),
            (1, 0.02, -0.19, -0.23),
        ],
        "web": [
            (0.10, 0.31, -0.36, 0),
            (0.43, 0.06, -0.55, 0.1),
            (0.79, 0.34, -0.25, 0.3),
            (1, 0.70, 0.24, 0.46),
        ],
        "pirate": [
            (0.12, 0.13, -0.60, 0),
            (0.43, 0.03, -0.63, 0),
            (0.80, 0.38, -0.29, -0.10),
            (1, 0.53, 0.14, -0.2),
        ],
    }
    body_len = length * (0.8 if style in ("scout", "runner", "web") else 1)
    keel(s, (0, 0, 0), w, body_len, h, 0.11 if style in ("hawk", "delta", "nyx") else 0.36)
    s.canopy(0, body_len * 0.19, h * 0.85, w * 0.61, body_len * 0.39, h * 0.83)
    for side in SIDES:
        stations = [
            (u * span, le * length, tr * length, rise * h, h * (0.33 - 0.24 * u))
            for u, le, tr, rise in wings[style]
        ]
        surf = s.wing(side, stations)
        s.registry(side, surf, 2 if side < 0 else 4)
        ex = {
            "scout": 0.73,
            "runner": 0.78,
            "web": 0.67,
            "delta": 0.32,
            "nyx": 0.51,
            "hawk": 0.18,
            "swept": 0.32,
            "pirate": 0.43,
            "tide": 0.26,
        }[style] * span
        r = min(w * 0.62, h * 0.93)
        if style in ("runner", "web"):
            keel(s, (side * ex, 0.08 * length, -0.16 * h), r * 1.1, length * 0.92, r, 0.16)
        s.engine(
            (
                side * ex,
                -length * (0.24 if style in ("runner", "web", "scout") else 0.50),
                -0.03 * h,
            ),
            r,
            length * (1.34 if style in ("runner", "web", "scout") else 0.80),
        )
        if style in ("swept", "scout", "hawk", "runner"):
            s.fin(
                side,
                ex,
                -length * 0.55,
                h * 0.51,
                length * 0.57,
                h * (1.75 if style != "hawk" else 2.25),
                span * 0.13,
            )
        if style in ("swept", "delta", "scout", "pirate", "web"):
            boom(
                s,
                side,
                span * (0.78 if style == "pirate" and side > 0 else 0.48),
                0.06 * length,
                -0.22 * h,
                r * 0.28,
                length * 0.77,
            )
        pos = surf(0.94, 0.42)
        s.pod(pos, (span * 0.027, length * 0.10, h * 0.12), "red" if side < 0 else "green", 6, 12)
        s.vent((side * w * 0.53, -body_len * 0.46, h * 0.88), w * 0.23, body_len * 0.20)
    if style in ("scout", "hawk"):
        s.engine((0, -length * 0.56, -h * 0.07), h * 0.78, length * 0.66)
    if name == "tide_heavy":
        for side in SIDES:
            keel(s, (side * span * 0.58, 0.02 * length, 0), w * 0.57, length * 0.77, h * 0.9)
            s.fin(side, span * 0.58, -length * 0.40, h * 0.57, length * 0.58, h * 2.4, span * 0.17)
    if style == "pirate":
        keel(s, (-w * 1.05, 0.03, -h * 0.52), w * 0.50, length * 0.55, h * 0.60, 0.55, "stripe")
    return s


def cutter(name, livery, kind):
    s = Skin(name, livery)
    if kind == "rook":
        # Short utility wings carry two long exposed drive booms. The central
        # pressure cabin and orange equipment shoulders sit above the through-gap.
        keel(s, (0, 0.18, 0.06), 1.14, 2.86, 0.69, 0.48)
        s.canopy(0, 0.74, 0.68, 0.68, 1.05, 0.55)
        for side in SIDES:
            wing = s.wing(
                side,
                [
                    (0.63, 0.92, -1.40, 0.04, 0.20),
                    (1.56, 0.54, -1.19, -0.02, 0.22),
                    (2.69, 0.74, -0.71, 0.12, 0.15),
                ],
                "frame",
                False,
            )
            s.registry(side, wing)
            keel(s, (side * 2.47, -0.23, 0.08), 0.57, 1.50, 0.54, 0.30, "stripe")
            s.engine((side * 2.47, -1.10, 0.08), 0.55, 2.12)
            s.pod((side * 2.48, 0.69, 0.52), (0.28, 0.43, 0.18), "ceramic")
            s.tube(
                [(side * 1.04, 0.30, 0.21), (side * 1.84, 0.49, 0.29), (side * 2.20, 0.52, 0.33)],
                [0.10, 0.088, 0.083],
                "copper",
                9,
            )
        return s
    if kind == "skiff":
        keel(s, (0, -0.15, -0.35), 1.62, 2.15, 0.4, 0.76, "frame")
        keel(s, (-0.69, 0.25, 0.06), 0.76, 2.11, 0.69, 0.48)
        s.canopy(-0.69, 0.86, 0.51, 0.59, 0.86, 0.50)
        s.pod((0.76, 0.16, 0.27), (0.67, 1.68, 0.67), "ceramic")
        for y in [-0.83, 0.56, 1.06]:
            s.shell(
                (0.76, y, 0.27),
                [(-0.065, 0.68, 0.68, 0), (0.065, 0.68, 0.68, 0)],
                "stripe",
                False,
                power=1,
            )
        for side in SIDES:
            s.engine((side * 1.04, -1.68, -0.13), 0.43, 1.1)
        # Rescue cross on the capsule's exposed crown.
        for w, l in [(0.22, 0.075), (0.075, 0.24)]:
            s.patch(lambda u, v: (0.76 + u, v + 0.13, 0.954), [-w, w], [-l, l], "stripe")
        return s
    w, l, h = {
        "titan": (1.75, 4.65, 0.91),
        "bastion": (2.30, 3.83, 0.83),
        "gunship": (3.32, 7.60, 1.15),
        "traffic": (1.66, 3.45, 0.85),
    }[kind]
    if kind == "gunship":
        # An offset command island leaves the starboard recovery deck open.
        keel(s, (0, 0, -0.38), 3.54, 7.70, 1.11, 0.60)
        keel(s, (-1.27, -1.44, 0.65), 1.29, 3.62, 1.03, 0.50)
        s.canopy(-1.32, -0.48, 1.56, 0.96, 1.63, 0.51)
        for side in SIDES:
            s.engine((side * 2.28, -4.81, -0.20), 1.05, 3.93)
            for i in range(5):
                yy = -4.6 + i * 1.64
                keel(s, (side * (2.94 - 0.16 * i), yy, -0.32), 0.65, 0.74, 0.66, 0.68, "frame")
        s.shell(
            (1.22, -1.43, 0.62),
            [
                (-3.03, 1.16, 0.22, 0),
                (-2.82, 1.26, 0.24, 0),
                (1.63, 1.17, 0.23, 0),
                (2.63, 0.75, 0.22, 0),
            ],
            "frame",
            False,
            power=0.24,
        )
        for i in range(8):
            for x in [0.42, 2.02]:
                s.pod((x, -3.8 + i * 0.49, 0.87), (0.08, 0.18, 0.038), "light", 4, 8)
        for yy in [2.66, 4.70]:
            s.pod((0, yy, 0.65), (0.80, 1.07, 0.46), "frame")
            for side in SIDES:
                boom(s, side, 0.43, yy + 0.62, 1.06, 0.20, 1.78)
        s.tube([(-1.27, -2.8, 1.23), (-1.27, -3.12, 3.27)], [0.12, 0.05], "steel")
        return s
    if kind == "traffic":
        keel(s, (0, 0, 0), w, l, h, 0.65)
        s.canopy(0, 0.10, l * 0.15, w * 0.83, l * 0.68, h * 0.95)
        for side in SIDES:
            s.engine((side * w * 0.90, -l * 0.42, -0.19), w * 0.24, l * 1.03)
        return s
    if kind == "bastion":
        keel(s, (0, -1.32, 0.02), w, 2.09, h, 0.66)
    else:
        keel(s, (0, 0, 0), w, l, h, 0.23 if kind == "titan" else 0.46)
    for side in SIDES:
        x = w * (0.87 if kind != "bastion" else 0.94)
        py = 0 if kind == "bastion" else -l * 0.28
        pl = l * (1.01 if kind == "bastion" else 0.57)
        keel(s, (side * x, py, -h * 0.12), w * 0.42, pl, h * 0.86, 0.20)
        s.engine((side * x, py - pl * 0.73, -h * 0.12), h * 0.72, pl * 0.68)
        for i in range(4):
            yy = py + pl * (-0.43 + i * 0.25)
            s.vent((side * x, yy, h * 0.71), w * 0.28, pl * 0.10)
    offset = 0
    keel(s, (offset, -l * 0.28, h * 0.83), w * 0.55, l * 0.39, h * 0.70, 0.58, "frame")
    s.canopy(offset, -l * 0.32, h * 1.42, w * 0.49, l * 0.24, h * 0.57)
    if kind == "bastion":
        s.fin(1, 0.16, -1.70, 1.1, 1.5, 1.22, 0.48)
    for i in range(2 if kind != "bastion" else 1):
        y = l * (0.10 + 0.37 * i) if kind != "bastion" else -0.25
        for side in SIDES:
            x = side * (w * 0.38 if kind != "bastion" else w * 0.94)
            s.pod((x, y, h * 0.91), (w * 0.23, l * 0.115, h * 0.40), "frame")
            boom(s, side, abs(x), y + l * 0.10, h * 1.06, w * 0.084, l * 0.28)
    return s


def scarab(name, heavy):
    s = Skin(name, "desert")
    keel(s, (0, 0, 0), 2.06, 3.80, 1.12, 0.24, "frame")
    for side in SIDES:
        keel(s, (side * 0.96, -0.36, 0.35), 1.13, 3.45, 0.99, 0.15)
        for i in range(3):
            y = 2.02 - i * 1.83
            x = 4.52 if heavy else 4.18
            s.wing(
                side,
                [
                    (1.12, y + 0.80, y - 0.50, 0.20, 0.26),
                    (3.10, y + 0.52, y - 0.54, 0.05, 0.24),
                    (x, y + 0.85, y + 0.03, -0.30, 0.15),
                    (x + 0.17, y + 1.06, y + 0.82, -0.60, 0.06),
                ],
                "stripe",
                False,
            )
        s.engine((side * (2.55 if heavy else 1.37), -1.48, -0.32), 0.72 if heavy else 0.48, 3.89)
        s.pod((side * 0.75, 2.65, 0.64), (0.31, 0.52, 0.19), "light")
    s.canopy(0, 2.31, 0.53, 0.72, 0.99, 0.51)
    if heavy:
        for side in SIDES:
            keel(s, (side * 2.44, 0, 0.22), 0.76, 3.15, 1.01, 0.21)
    return s


def command_ship(name, livery, kind):
    s = Skin(name, livery)
    siege = kind == "siege"
    half_l = 16 if siege else 38
    half_w = 15
    height = 5.5 if siege else 6.0
    keel(s, (0, 3, 0), half_w, half_l, height, 0.60)
    for side in SIDES:
        if kind == "cruiser":
            keel(s, (side * 8, 27, 0.1), 6.9, 28, 5.4, 0.15)
        if kind == "ark":
            keel(s, (side * 25, 4, -0.5), 7, 33, 6.3, 0.34)
            for j in range(6):
                fore = -23 + j * 10
                s.wing(
                    side,
                    [
                        (17, fore + 6, fore - 4, 1, 2.1),
                        (30, fore + 3, fore - 4, 3, 1.7),
                        (48, fore - 3, fore - 6, 5, 0.69),
                    ],
                    "ceramic",
                    False,
                )
        if kind == "nyx":
            s.wing(
                side,
                [
                    (10, 30, -21, 0, 3.6),
                    (23, 33, -29, 5.1, 2.7),
                    (40, 34, -8, 9, 2.2),
                    (60, 29, 19, 13, 1.3),
                ],
                "paint",
            )
        for row in range(2 if siege else 3):
            # These saddles sit directly beneath the game's independently destructible turrets.
            if siege:
                x, y, z = [(19, -14, 10), (30, 4, 8)][row]
            else:
                x, y, z = 22 + 16 * row, -27 + 22 * row, 9 + 4 * row
            s.wing(
                side,
                [
                    (11, y + 7, y - 5, 3, 1.8),
                    (x * 0.8, y + 4, y - 4, z * 0.72, 1.2),
                    (x, y + 3, y - 3, z - 2, 0.73),
                ],
                "frame",
                False,
            )
            s.pod((side * x, y, z - 2.5), (4.4, 4.9, 1.95), "paint", 8, 18)
            if kind == "hydra":
                keel(s, (side * x, y + 2, z - 5.7), 5.8, 11.5, 3.7, 0.51)
                s.engine((side * x, y - 6, z - 5.6), 2.9, 9.4)
                for j in range(4):
                    s.vent((side * x, y - 3 + j * 2.4, z - 2.1), 3.1, 0.88)
            if kind == "sovereign":
                # Canted crystalline pinnacles behind each weapons platform.
                p = (side * x, y + 4, z - 5)
                s.tube(
                    [p, (side * (x + 1), y + 4, z + 5), (side * (x + 3), y + 6, z + 14 + row * 3)],
                    [4.5, 3.9, 0.16],
                    "stripe",
                    6,
                )
                s.tube(
                    [(side * x, y + 2, z + 1), (side * (x + 2), y + 4, z + 10 + row * 2)],
                    [0.62, 0.08],
                    "light",
                    6,
                )
            if kind in ("cruiser", "siege"):
                for d in [-2.3, 2.3]:
                    s.tube(
                        [(side * 12, y + d, 3), (side * x, y + d, z - 2)], [0.75, 0.55], "copper", 8
                    )
        # Sponsons, segmented side armor and window ribbons.
        for j in range(8):
            fore = half_l * (-0.70 + j * 0.19)
            x = side * half_w * (0.92 - 0.24 * max(0, fore / half_l))
            keel(s, (x, fore, -0.7), 2.1, half_l * 0.104, 2.25, 0.65, "paint")
            for m in range(3):
                s.pod(
                    (x + side * 2.02, fore + (m - 1) * half_l * 0.039, -0.30),
                    (0.10, half_l * 0.012, 0.28),
                    "light",
                    4,
                    8,
                )
        s.engine(
            (side * (22 if siege else 12), -half_l * 0.68, -0.3),
            2.35 if siege else 3.05,
            half_l * 0.54,
        )
        s.vent((side * 6.5, -half_l * 0.40, height * 0.90), 2.5, half_l * 0.20)
    if kind == "nyx":
        keel(s, (0, 7, 4), 8.2, 24, 5.5, 0.14, "frame")
        s.canopy(0, 1, 8, 4, 7, 1.5)
    elif kind == "sovereign":
        for i in range(3):
            s.tube(
                [(0, 13 + i * 1.4, 4 + i * 5), (0, 14 + i * 1.4, 12 + i * 5)],
                [6.2 - i * 1.7, 4.8 - i * 1.7],
                "paint",
                5,
            )
        s.pod((0, 17, 22), (2.2, 2.8, 4), "light")
    else:
        cy = 2 if siege else -2
        for i in range(3):
            keel(
                s,
                (0, cy + i * 1.25, height + i * 2.5),
                9.2 - i * 2.0,
                half_l * (0.52 - i * 0.10),
                2.5 - i * 0.3,
                0.6,
                "frame" if i == 1 else "paint",
            )
        bridge = s.shell(
            (0, cy + 2.6, height + 6.0),
            [(-4.3, 4.2, 1.15, 0), (-2.7, 5.7, 1.65, 0), (2.8, 5.2, 1.51, 0), (4.6, 3.8, 1.16, 0)],
            "frame",
            False,
            power=0.40,
        )
        for j in range(12):
            a = tau * j / 12
            s.applique(bridge, 0.21, 0.86, a + 0.04, a + 0.36, "light" if j % 4 else "glass", 0.08)
        keel(s, (0, cy + 2.6, height + 7.48), 4.6, 4.9, 0.45, 0.60, "paint")
        for x in [-3, 1.8]:
            s.tube(
                [(x, cy - 1, height + 7), (x, cy - 1, height + 13 - abs(x))],
                [0.35, 0.09],
                "steel",
                8,
            )
            s.pod((x, cy - 1, height + 13 - abs(x)), (0.27, 0.27, 0.31), "red", 5, 8)
    return s


def bio(name, kind, variant=0, distant=False):
    s = Skin(name, "hive")
    if kind == "egg":
        mat = ["paint", "glass", "copper"][variant]
        ribs = 6 if distant else 9
        s.pod((0, 0, 0), (0.78, 0.72, 1.22), mat, 6 if distant else 14, 12 if distant else 24)
        for i in range(ribs):
            a = tau * i / ribs
            line = []
            for j in range(9 if distant else 15):
                t = j / (8 if distant else 14)
                v = mix(-1.42, 1.42, t)
                line.append(
                    (
                        0.81 * cos(v) * cos(a + 0.8 * t),
                        0.78 * cos(v) * sin(a + 0.8 * t),
                        1.26 * sin(v),
                    )
                )
            s.tube(
                line,
                [0.025 + 0.055 * sin(pi * j / (len(line) - 1)) for j in range(len(line))],
                "light" if variant == 2 else "stripe",
                4 if distant else 7,
            )
        return s
    if kind == "leviathan":
        s.pod((0, -9, 0), (17.3, 19.2, 14.5), "glass", 18, 32)
        for i in range(6):
            at = (sin(i * 0.36) * 18, 18 + i * 14, 10 + i * 7)
            r = 13 - i * 1.3
            s.pod(at, (r, 12, 11 - i), "paint", 12, 24)
            for side in SIDES:
                x, y, z = at
                s.tube(
                    [
                        (x + side * r * 0.8, y - 5, z + 1),
                        (x + side * r * 1.13, y + 3, z + 5),
                        (x + side * r * 1.37, y + 7, z + 8),
                    ],
                    [1.75, 1.1, 0.10],
                    "stripe",
                    12,
                )
        for side in SIDES:
            for i in range(3):
                x, y, z = side * (22 + 16 * i), -27 + 22 * i, 9 + 4 * i
                s.tube(
                    [(side * 6, y + 5, 0), (x * 0.7, y + 2, z - 5), (x, y, z - 2)],
                    [4.8, 2.9, 2.1],
                    "paint",
                )
                s.pod((x, y, z - 2), (5, 5, 2.1), "stripe")
            for j in range(5):
                x = side * (4 + j * 2)
                s.pod((x, -23 + j * 0.8, 6 - j * 0.8), (1.35, 2.4, 1.28), "light")
            s.tube(
                [
                    (side * 9, -17, -4),
                    (side * 15, -24, -9),
                    (side * 13, -32, -12),
                    (side * 10, -36, -11),
                ],
                [3, 1.6, 0.81, 0.12],
                "stripe",
            )
        return s
    mother = kind == "mother"
    k = 0.49 if mother else 1
    ysign = -1 if mother else 1
    s.pod(
        (0, -0.48 * ysign * k, 0.12 * k),
        (1.12 * k, 2.42 * k, 0.83 * k),
        "glass",
        8 if distant else 14,
        16 if distant else 24,
    )
    for j in range(5):
        r = (1 - j * 0.11) * k
        s.pod(
            (0, (-0.14 - j * 0.63) * ysign * k, (0.22 + j * 0.10) * k),
            (r, 0.78 * k, r * 0.85),
            "paint",
            6 if distant else 10,
            12 if distant else 20,
        )
    s.pod((0, 1.52 * ysign * k, 0.08 * k), (1.04 * k, 1.12 * k, 0.78 * k), "stripe", 8, 18)
    for side in SIDES:
        for i in range(3):
            s.pod(
                (
                    side * (0.54 + i * 0.13) * k,
                    (2.40 - i * 0.27) * ysign * k,
                    (0.23 + i * 0.11) * k,
                ),
                (0.17 * k, 0.25 * k, 0.16 * k),
                "light",
                5,
                10,
            )
        s.tube(
            [
                (side * 0.53 * k, 2.04 * ysign * k, 0),
                (side * 1.13 * k, 2.85 * ysign * k, -0.26 * k),
                (side * 0.85 * k, 3.56 * ysign * k, 0.13 * k),
            ],
            [0.23 * k, 0.13 * k, 0.025 * k],
            "stripe",
            9,
        )
        for i in range(2):
            fore = (1 - i * 1.92) * k
            span = (3.2 if mother else 4.15 - i * 0.85) * k
            stations = [
                (0.64 * k, fore + 0.51 * k, fore - 0.6 * k, 0.25 * k, 0.16 * k),
                (span * 0.65, fore + (0.20 - i * 0.50) * k, fore - 1.3 * k, 1.07 * k, 0.21 * k),
                (span, fore + (0.74 - i) * k, fore - 0.26 * k, 0.64 * k, 0.07 * k),
            ]
            membrane = s.wing(side, stations, "paint" if mother else "glass", False)
            for j in range(4):
                a = 0.22 + j * 0.12
                path = [
                    membrane(a + u * 0.14, 0.12 + u * 0.69, lift=0.035 * k)
                    for u in [0, 0.25, 0.50, 0.75, 1]
                ]
                s.tube(path, [k * x for x in [0.04, 0.035, 0.03, 0.019, 0.006]], "stripe", 6)
            s.tube(
                [(side * x, le, z) for x, le, tr, z, h in stations],
                [0.11 * k, 0.095 * k, 0.022 * k],
                "stripe",
                7,
            )
            for j in range(2 if distant else 5):
                u = 0.27 + j * 0.11
                x, le, tr, z, h = interpolate(stations, u)
                s.tube(
                    [
                        (side * x, le, z + 0.05 * k),
                        (side * (x + 0.27 * k), mix(le, tr, 0.72), z + h),
                    ],
                    [0.027 * k, 0.012 * k],
                    "light",
                    5,
                )
    return s


def all_ships():
    yield cutter("rook", "union", "rook")
    yield fighter("hawk", "patrol", "hawk", 3.48, 4.20, 0.80, 0.55)
    yield cutter("titan", "gunmetal", "titan")
    yield cutter("bastion", "royal", "bastion")
    yield cutter("emergency", "rescue", "skiff")
    yield fighter("range", "patrol", "swept", 3.12, 2.72, 0.90, 0.60)
    yield fighter("engine_scout", "patrol", "scout", 4.02, 3.33, 1.42, 0.87)
    yield fighter("strike", "union", "swept", 6.14, 5.31, 1.37, 1.0)
    yield fighter("delta", "gunmetal", "delta", 4.53, 5.49, 1.10, 0.70)
    yield cutter("escort", "gunmetal", "gunship")
    yield fighter("web_drone", "web", "web", 3.66, 3.1, 1.48, 0.87)
    yield fighter("pirate", "pirate", "pirate", 1.64, 1.98, 0.73, 0.51)
    yield fighter("cryo", "cryo", "runner", 3.95, 3.59, 1.20, 0.83)
    yield fighter("vespera", "nyx", "nyx", 4.12, 4.18, 1.03, 0.65)
    yield cutter("traffic", "nyx", "traffic")
    for heavy in (False, True):
        yield fighter("tide_heavy" if heavy else "tide", "tide", "tide", 6.92, 4.82, 1.56, 0.80)
        yield scarab("scarab_heavy" if heavy else "scarab", heavy)
    for name, livery, kind in [
        ("siege", "rescue", "siege"),
        ("cruiser", "gunmetal", "cruiser"),
        ("hydra", "cryo", "hydra"),
        ("nyx", "nyx", "nyx"),
        ("ark", "tide", "ark"),
        ("sovereign", "desert", "sovereign"),
    ]:
        yield command_ship(name, livery, kind)
    armor = Skin("heavy_armor", "gunmetal")
    for side in SIDES:
        keel(armor, (side * 1.30, 0.10, 0.47), 0.54, 1.68, 0.54, 0.26, "frame")
        armor.vent((side * 1.30, -0.26, 1.01), 0.31, 0.61)
        armor.engine((side * 1.30, -0.80, 0.43), 0.42, 1.48, "stripe")
    yield armor
    yield bio("leviathan", "leviathan")
    yield bio("insect", "insect")
    yield bio("hive_mother", "mother")
    yield bio("hive_mother_far", "mother", distant=True)
    for i in range(3):
        yield bio("egg_" + str(i), "egg", i)
        yield bio("egg_" + str(i) + "_far", "egg", i, True)


def linear_color(hexcode):
    rgb = [int(hexcode[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c < 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb) + (1,)


def author_material(kind, hexcode):
    name = kind.title() + " / " + hexcode
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    color = linear_color(hexcode)
    mat.diffuse_color = color
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Metallic"].default_value = 0.72 if kind in ("copper", "steel", "frame") else 0.32
    shader.inputs["Roughness"].default_value = 0.14 if kind == "glass" else 0.34
    if FINISH[kind] > 0.70:
        shader.inputs["Emission Color"].default_value = color
        shader.inputs["Emission Strength"].default_value = 2.4
    return mat


def bake(s, scene, game_material, output=OUTPUT):
    mesh = bpy.data.meshes.new(s.name)
    mesh.from_pydata(s.vertices, [], s.faces)
    mesh.update()
    obj = bpy.data.objects.new(s.name, mesh)
    scene.collection.objects.link(obj)
    # The runtime gets a single surface. Color is the paint swatch and UV.x
    # identifies the finish, including glazing and animated ion emitters.
    paint = mesh.color_attributes.new(name="Livery", type="BYTE_COLOR", domain="CORNER")
    mesh.color_attributes.active_color = paint
    uv = mesh.uv_layers.new(name="Finish")
    colors = {k: linear_color(v) for k, v in s.palette.items()}
    from array import array

    samples, coords = array("f"), array("f")
    for polygon, kind, smooth in zip(mesh.polygons, s.finishes, s.smooth):
        polygon.use_smooth = smooth
        samples.extend(colors[kind] * polygon.loop_total)
        if kind == "jet":
            for vertex in polygon.vertices:
                coords.extend((FINISH[kind], 1 - s.jet_coordinates[vertex]))
        else:
            coords.extend((FINISH[kind], 0.5) * polygon.loop_total)
    paint.data.foreach_set("color", samples)
    uv.data.foreach_set("uv", coords)
    mesh.materials.append(game_material)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(output / (s.name + ".glb")),
        export_format="GLB",
        use_selection=True,
        use_active_scene=True,
        export_animations=False,
        export_cameras=False,
        export_lights=False,
        export_tangents=False,
        export_vertex_color="ACTIVE",
    )
    mesh.materials.clear()
    slots = list(dict.fromkeys(s.finishes))
    for kind in slots:
        mesh.materials.append(author_material(kind, s.palette[kind]))
    mesh.polygons.foreach_set("material_index", [slots.index(k) for k in s.finishes])
    return obj


def flight_material():
    game_material = bpy.data.materials.new("Flight livery")
    game_material.use_nodes = True
    nodes = game_material.node_tree
    pigment = nodes.nodes.new("ShaderNodeVertexColor")
    pigment.layer_name = "Livery"
    nodes.links.new(pigment.outputs["Color"], nodes.nodes["Principled BSDF"].inputs["Base Color"])
    return game_material


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    scene = bpy.data.scenes.new("Cosmic Conflict Fleet")
    bpy.context.window.scene = scene
    game_material = flight_material()
    # Build on the origin, export at gameplay scale, then arrange the editable lineup.
    positions = []
    for s in all_ships():
        obj = bake(s, scene, game_material)
        positions.append(obj)
    # Keep the native library in real units with room to inspect each vessel.
    small = [obj for obj in positions if max(obj.dimensions) < 35]
    large = [obj for obj in positions if max(obj.dimensions) >= 35]
    for i, obj in enumerate(small):
        obj.location = ((i % 5) * 18, -(i // 5) * 20, 0)
    for i, obj in enumerate(large):
        obj.location = ((i % 3) * 142, 106 + (i // 3) * 153, 0)
    bpy.ops.object.select_all(action="DESELECT")
    scene.display.shading.color_type = "MATERIAL"
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.shading.color_type = "MATERIAL"
                area.spaces.active.overlay.show_floor = False
                area.spaces.active.region_3d.view_location = (32, -20, 0)
                area.spaces.active.region_3d.view_distance = 85
    # Write only this scene and its dependencies into the source library.
    bpy.data.libraries.write(
        str(ROOT / "Art/Cosmic Conflict Fleet.blend"), {scene}, fake_user=True, compress=True
    )
    print(
        "FLEET_OK",
        len(positions),
        "meshes",
        sum(len(o.data.polygons) for o in positions),
        "polygons",
    )


if __name__ == "__main__":
    main()
