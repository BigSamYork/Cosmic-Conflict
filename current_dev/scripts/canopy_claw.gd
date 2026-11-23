extends Node3D

const Art = preload("res://scripts/canopy_claw_art.gd")
const CONTACT := 2.5
# Plane of Xylo's swamp beneath the impact point, expressed in course-local metres.
var floor_offset := 0.0
var upper: MeshInstance3D
var forearm: MeshInstance3D
var palm: MeshInstance3D
var shadow := MeshInstance3D.new()
var shadow_ink := ShaderMaterial.new()
var knuckles: Array[Node3D] = []
var second_joints: Array[Node3D] = []
var talons: Array[Node3D] = []
var hold := Vector3.ZERO
var eclipse := 0.0

func _ready() -> void:
	upper = Art.part("upper")
	forearm = Art.part("fore")
	palm = Art.part("palm")
	add_child(upper)
	add_child(forearm)
	add_child(palm)
	# Four hooked digits and one broad, opposable dewclaw.
	for i in 5:
		var socket := Node3D.new()
		var azimuth: float = [-1.40, -0.64, 0.03, 0.77, 2.48][i]
		var size: float = [0.87, 1.05, 1.11, 0.97, 1.12][i]
		socket.position = Vector3(sin(azimuth) * 4.10, -0.15, cos(azimuth) * 4.05)
		socket.rotation.y = azimuth
		socket.scale = Vector3.ONE * size
		palm.add_child(socket)
		var root := Art.part("root")
		socket.add_child(root)
		knuckles.append(root)
		var joint := Art.part("medial")
		joint.position.y = -4.9
		root.add_child(joint)
		second_joints.append(joint)
		var claw := Art.part("unguis")
		claw.position.y = -3.7
		joint.add_child(claw)
		talons.append(claw)
	var surface := PlaneMesh.new()
	surface.size = Vector2(72, 68)
	shadow.mesh = surface
	shadow_ink.shader = preload("res://shaders/canopy_shadow.gdshader")
	shadow.material_override = shadow_ink
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	advance_event(0, false)

func advance_event(age: float, reduced: bool) -> void:
	# The wrist glides into view, hangs while the fingers open, then lunges.
	var entering := smoothstep(0.0, 1.20, age)
	var reaching := smoothstep(1.18, CONTACT, age)
	var lifting := smoothstep(2.62, 5.38, age)
	var ready_at := Vector3(-15, 27, -8)
	var approach := Vector3(-44, 57, -29).lerp(ready_at, entering)
	var grip := approach.lerp(Vector3.ZERO, reaching)
	hold = grip + Vector3(-46 * lifting, 82 * lifting, -18 * lifting)
	var curl := smoothstep(2.16, CONTACT, age)
	var roll := lerpf(-0.24, 0.0, reaching) - 0.48 * lifting
	palm.position = hold + Vector3.UP * 6.8
	palm.rotation = Vector3(-0.13 * (1.0 - reaching) - lifting * 0.30, -0.10 + 0.20 * entering - 0.6 * lifting, roll)
	var wrist := palm.transform * Vector3(0, 1.35, 0)
	var elbow := wrist + Vector3(-23.0 - 9.0 * reaching, 28.0 - 5.0 * entering, -8.0)
	var shoulder := elbow + Vector3(-225, 108, -25)
	_align(upper, elbow, shoulder)
	_align(forearm, elbow, wrist)
	for i in knuckles.size():
		var flick := 0.0 if reduced else sin(age * 4.3 + i * 1.41) * 0.065 * (1.0 - curl)
		knuckles[i].rotation.x = lerpf(-0.92, -0.19, curl) + flick
		second_joints[i].rotation.x = lerpf(-0.05, 0.84, curl) - flick
		talons[i].rotation.x = lerpf(0.31, 0.91, curl)
	var overhead := entering * (1.0 - lifting)
	eclipse = smoothstep(0.12, 1.85, age) * (1.0 - smoothstep(2.95, 5.24, age)) * (0.53 if reduced else 1.0)
	shadow.position = Vector3(lerpf(-22, 0, reaching) - lifting * 17, -floor_offset + 0.13, lerpf(-10, 0, reaching))
	shadow.scale = Vector3.ONE * (1.0 - 0.4 * reaching)
	shadow_ink.set_shader_parameter("density", overhead * (0.44 if reduced else 0.71))
	shadow_ink.set_shader_parameter("spread", lerpf(1.1, 0.52, curl))
	visible = age >= 0 and age < 5.5

func _align(segment: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var axis := end.direction_to(start)
	var side := axis.cross(Vector3.BACK).normalized()
	segment.transform = Transform3D(Basis(side, axis * (start.distance_to(end) / 36.0), side.cross(axis).normalized()), start)

func grasp_point() -> Vector3:
	return to_global(hold)

# Maximum shadow lies under the reaching forearm. Pilots well outside its
# footprint retain their local daylight; HUD and instruments are handled by
# their normal cockpit path.
func eclipse_strength(viewer_global: Vector3) -> float:
	var point := to_local(viewer_global)
	var nearest := Geometry3D.get_closest_point_to_segment(Vector3(point.x, 0, point.z), Vector3(-90, 0, -17), Vector3(4, 0, 3))
	var range_m := Vector2(point.x - nearest.x, point.z - nearest.z).length()
	return eclipse * (1.0 - smoothstep(38.0, 228.0, range_m)) * (1.0 - smoothstep(70.0, 150.0, absf(point.y)))
