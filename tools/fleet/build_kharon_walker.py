"""Build the rigid, articulated Kharon pile-driver using the game's weathered fleet finish.

Run from the repository root with Blender --background --python this_file.
Each leg section is five metres long in +Y; the game poses it between the joints.
"""
import sys
from pathlib import Path
from math import cos, sin, tau
import bpy
sys.path.insert(0, str(Path.cwd() / "tools/fleet"))
from build_fleet import Skin, bake, flight_material
from build_ground import OUTPUT, lathe, pipe, plate


def skin(part):
    s = Skin("kharon_driver_" + part, "desert")
    s.palette.update(paint="ae7545", stripe="d5a451", light="ff5332",
                     frame="364047", ceramic="d0c6a1", glass="310e0c")
    return s


def chassis():
    s = skin("chassis")
    # Armored central bridge spans two pontoon-like compressor banks.
    plate(s, (0, 0, 0), (6.3, 8.0, 1.5), "frame", .43)
    for side in [-1, 1]:
        x = side * 2.63
        s.shell((x, 0, .45), [(-4.65,.7,.65,.0),(-3.5,1.10,1.15,.10),
                (-.75,1.18,1.43,.38),(2.55,1.06,1.22,.26),(4.18,.69,.85,.20)],
                "paint", True, .54, 16)
        for i in range(9):
            y = -1.8 + .47*i
            plate(s,(x+side*.16,y,2.13),(.85,.20,.24),"steel",.26)
        # Two isolated, heat-shielded exhaust stacks per side.
        for y,h in [(2.3,4.5),(3.3,3.7)]:
            lathe(s,[(.55,.59),(1.2,.61),(1.3,.49),(h-.24,.47),(h-.14,.55),(h,.55),(h,.32),(h-.22,.29)],"frame",18,(x,y))
            for k in range(4):
                z=1.7+k*.34
                lathe(s,[(z,.50),(z+.09,.54),(z+.13,.50)],"copper",16,(x,y))
        pipe(s,[(x,-3.15,1.6),(x+side*.46,-2.5,2.0),(x+side*.48,1.1,2.0),(x,1.75,1.7)],.12)
        for y in [-2.35,2.35]:
            pipe(s,[(side*2.9,y,0),(side*4.3,y,.1)],.89,"frame",20)
            pipe(s,[(side*3.85,y,0),(side*4.25,y,0)],1.02,"paint",20)
    # Copper coil and ringed hammer sleeve pass through the whole bridge.
    lathe(s,[(-1.8,1.2),(-1.4,1.59),(-.75,1.27),(1.9,1.38),(2.3,1.14),(3.4,.88)],"frame",28)
    for k in range(7):
        z=.36+.38*k
        lathe(s,[(z,1.34),(z+.10,1.51),(z+.19,1.49),(z+.23,1.29)],"copper",24)
    for side in [-1,1]:
        pipe(s,[(side*.93,1.0,2.4),(side*1.27,1.4,3.5),(side*1.78,1.38,3.5),(side*2.3,.75,1.42)],.16,"steel",9)
    # The low cowling carries a bank of narrow red search optics under a visor.
    s.shell((0,-2.9,1.2),[(-1.93,.61,.31,0),(-1.59,1.89,.61,0),(-.8,2.12,.92,.14),(.55,1.54,1.2,.35)],"paint",True,.64,16)
    plate(s,(0,-4.61,1.34),(3.35,.32,.59),"seam",.2)
    plate(s,(0,-4.72,1.76),(3.72,.72,.21),"ceramic",.28)
    for i in range(7):
        x=(i-3)*.42
        plate(s,(x,-4.82,1.38),(.28,.10,.15 if i!=3 else .26),"light",.2)
    for x in [-1.7,-1.1,1.1,1.7]:
        pipe(s,[(x,-2.0,-.28),(x,-2.8,-.76),(x*.63,-3.38,-.76)],.12,"steel",8)
    return s


def leg(lower=False):
    s=skin("shin" if lower else "thigh")
    for y,r in [(0,.68 if lower else .88),(5,.55 if lower else .72)]:
        pipe(s,[(-r*.87,y,0),(r*.87,y,0)],r,"frame",20)
        for side in [-1,1]:
            pipe(s,[(r*.82*side,y,0),(r*.99*side,y,0)],r*.81,"copper",18)
            pipe(s,[(r*.96*side,y,0),(r*1.03*side,y,0)],r*.48,"steel",12)
    # Outer guard plates float over an exposed piston and paired hydraulic hoses.
    for side in [-1,1]:
        x=side*(.46 if lower else .61)
        pipe(s,[(x,.30,0),(x*.96,1.5,.13),(x*.76,3.55,-.06),(x*.75,4.72,0)],.22 if lower else .28,"frame")
        pipe(s,[(x*.92,.5,.32),(x*1.03,1.1,.56),(x*1.02,2.38,.51),(x*.89,3.1,.31)],.088,"copper",8)
    pipe(s,[(0,.36,-.13),(0,2.59,-.13)],.39 if lower else .49,"steel",18)
    pipe(s,[(0,2.43,-.13),(0,4.66,-.13)],.23 if lower else .28,"ceramic",16)
    for i in range(3):
        plate(s,(0,1.12+i*.77,.36),((.93 if lower else 1.51)-.10*i,.80,.52),"paint" if i!=1 else "stripe",.48)
    return s


def foot():
    s=skin("shoe")
    plate(s,(0,0,.39),(2.32,2.55,.66),"frame",.56)
    plate(s,(0,-.03,.71),(1.66,1.85,.6),"paint",.58)
    for x in [-.72,0,.72]:
        for side in [-1,1]:
            s.shell((x,side*1.05,.29),[(-.75,.16,.14,0),(-.43,.28,.20,.05),(.49,.31,.16,0),(.76,.18,.11,-.08)],"steel",False,.55,10)
    return s


def hammer():
    s=skin("ram")
    lathe(s,[(0,.56),(.32,1.19),(.63,1.41),(1.16,1.29),(1.45,.87),(3.0,.78),(6.0,.70),(6.1,.88)],"steel",24)
    for i in range(5):
        z=1.6+i*.72
        lathe(s,[(z,.80),(z+.12,.93),(z+.22,.80)],"frame" if i%2 else "stripe",22)
    for i in range(8):
        a=i*tau/8
        pipe(s,[(cos(a)*1.22,sin(a)*1.22,.77),(cos(a)*1.18,sin(a)*1.18,.28),(cos(a)*1.07,sin(a)*1.07,-.01)],.12,"copper",8)
    return s


if __name__ == "__main__":
    bpy.ops.wm.read_factory_settings(use_empty=True)
    material=flight_material()
    for item in (chassis(),leg(),leg(True),foot(),hammer()):
        bake(item,bpy.context.scene,material,OUTPUT)
