extends Node3D

const Art := preload("res://scripts/glacier_mauler_art.gd")
const COAT := preload("res://shaders/glacier_mauler_coat.gdshader")
const DUST := preload("res://shaders/frontier_hazard_dust.gdshader")
const CONTACT := 2.5
const PELTS: MeshLibrary = preload("res://assets/ground/glacier_mauler.res")

var fur := ShaderMaterial.new()
var torso := Node3D.new()
var head := Node3D.new()
var jaw := Node3D.new()
var hind_legs: Array[Node3D] = []
var upper_arms: Array[Node3D] = []
var lower_arms: Array[Node3D] = []
var wrists: Array[Node3D] = []
var breath := MultiMeshInstance3D.new()
var approach_side := 1.0

func _pelt(parent: Node3D, key: String, at: Vector3) -> MeshInstance3D:
	var patch := MeshInstance3D.new()
	patch.mesh = PELTS.get_item_mesh(PELTS.find_item_by_name(key))
	patch.material_override = fur
	patch.position = at
	parent.add_child(patch)
	return patch

func _leather(color: Color, wet: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.19 if wet else 0.76
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.85 if wet else 0.52
	return m

func _ready() -> void:
	fur.shader = COAT
	add_child(torso)
	_pelt(torso, "haunch", Vector3(0, 0.2, -0.91))
	var mantle := _pelt(torso, "mane", Vector3(0, 1.66, 1.23))
	mantle.rotation.x = -0.26
	torso.add_child(head)
	head.position = Vector3(0, 2.34, 2.85)
	_pelt(head, "skull", Vector3(0, 0.32, 0))
	var pad := _leather(Color("#454348"))
	var wet := _leather(Color("#24232a"), true)
	var dark := _leather(Color("#30262a"))
	var enamel := _leather(Color("#d8bd91"))
	var eye := _leather(Color("#d6a24e"), true)
	var glint := _leather(Color("#f9efc7"), true)
	var muzzle := _leather(Color("#81817b"))
	var gum := _leather(Color("#693d42"))
	head.add_child(jaw)
	jaw.position = Vector3(0, -0.39, 0.80)
	Art.skin(jaw, Vector3(0, -0.22, 0.62), Vector3(1.12, 0.57, 0.98), pad)
	Art.skin(jaw, Vector3(0, 0.04, 0.75), Vector3(0.93, 0.24, 0.91), gum)
	Art.skin(head, Vector3(0, -0.34, 1.22), Vector3(1.16, 0.54, 1.08), dark)
	Art.skin(head, Vector3(0, 0.04, 1.39), Vector3(0.97, 0.68, 1.12), muzzle)
	Art.skin(head, Vector3(0, 0.25, 2.33), Vector3(0.76, 0.36, 0.34), wet)
	for side: float in [-1, 1]:
		Art.skin(head, Vector3(side * 0.39, 0.24, 2.63), Vector3(0.20, 0.135, 0.068), dark)
		var ear := _pelt(head, "ear", Vector3(side * 1.38, 1.29, -0.02))
		ear.rotation.z = -side * 0.47
		Art.skin(head, Vector3(side * 1.46, 1.31, 0.26), Vector3(0.245, 0.29, 0.12), pad)
		var cheek := _pelt(head, "ruff", Vector3(side * 1.30, -0.11, 0.74))
		cheek.rotation.z = side * 0.20
		Art.skin(head, Vector3(side * 0.93, 0.67, 1.31), Vector3(0.63, 0.46, 0.395), pad)
		Art.skin(head, Vector3(side * 0.91, 0.63, 1.65), Vector3(0.20, 0.179, 0.118), eye)
		Art.skin(head, Vector3(side * 0.91, 0.63, 1.74), Vector3(0.085, 0.133, 0.054), wet)
		Art.skin(head, Vector3(side * 0.91 - 0.042, 0.687, 1.79), Vector3.ONE * 0.045, glint)
		var brow := Art.skin(head, Vector3(side * 0.90, 0.96, 1.42), Vector3(0.735, 0.245, 0.25), muzzle)
		brow.rotation.z = side * 0.23
		Art.tooth(head, Vector3(side * 0.86, -0.26, 1.80), Vector3(side * 0.92, -0.80, 1.86), 0.175, 0.095, enamel)
		Art.tooth(head, Vector3(side * 0.92, -0.80, 1.86), Vector3(side * 0.90, -1.09, 1.98), 0.10, 0.018, enamel)
		for i in range(3):
			Art.tooth(jaw, Vector3(side * (0.22 + i * 0.20), 0.15, 1.39 - 0.06 * i), Vector3(side * (0.22 + i * 0.20), 0.36, 1.44 - 0.06 * i), 0.086, 0.014, enamel)
		var hip := Node3D.new()
		torso.add_child(hip)
		hip.position = Vector3(side * 2.0, -0.70, -1.9)
		hind_legs.append(hip)
		var thigh := _pelt(hip, "thigh", Vector3(0, -0.8, 0.12))
		thigh.rotation.x = -0.39
		_pelt(hip, "calf", Vector3(0, -2.12, -0.12))
		_pelt(hip, "paw", Vector3(0, -2.88, 0.38))
		var upper := Node3D.new()
		var lower := Node3D.new()
		var wrist := Node3D.new()
		for joint in [upper, lower, wrist]: add_child(joint)
		upper_arms.append(upper)
		lower_arms.append(lower)
		wrists.append(wrist)
		_pelt(upper, "upper", Vector3.ZERO)
		_pelt(lower, "lower", Vector3.ZERO)
		_pelt(wrist, "paw", Vector3(0, 0.12, 0.14))
		Art.skin(wrist, Vector3(0, -0.06, 0.48), Vector3(0.82, 0.38, 0.74), pad)
		for i in range(4):
			var x: float = (i - 1.5) * 0.36
			var z: float = 1.02 - 0.11 * absf(i - 1.5)
			Art.skin(wrist, Vector3(x, -0.18, z), Vector3(0.21, 0.27, 0.47), muzzle)
			Art.tooth(wrist, Vector3(x, -0.18, z + 0.27), Vector3(x, -0.39, z + 0.81), 0.132, 0.018, wet)
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = 8
	breath.multimesh = mm
	var vapor := ShaderMaterial.new()
	vapor.shader = DUST
	breath.material_override = vapor
	breath.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	breath.custom_aabb = AABB(Vector3(-12, -5, -4), Vector3(24, 23, 30))
	head.add_child(breath)
	advance_event(0, false)

func _place_limb(joint: Node3D, a: Vector3, b: Vector3, rest_length: float) -> void:
	var towards := a - b
	var attitude := Basis(Quaternion(Vector3.UP, towards.normalized()))
	joint.transform = Transform3D(attitude * Basis.from_scale(Vector3(1, towards.length() / rest_length, 1)), (a + b) * 0.5)

func advance_event(age: float, reduced: bool) -> void:
	var step := smoothstep(0, 1.45, age)
	var lift := smoothstep(0.88, 2.09, age)
	var slam := smoothstep(2.08, CONTACT, age)
	var retreat := smoothstep(3.20, 5.5, age)
	var brace := smoothstep(2.85, 3.63, age)
	var stride := sin(age * 12) * ((1 - step) * 0.48 + retreat * 0.90)
	var shake := sin((age - CONTACT) * 18) * exp(-maxf(0, age - CONTACT) * 8) if age >= CONTACT else 0.0
	# Set the feet against the surface while the spine and shoulders heave.
	position = Vector3(approach_side * (1.0 - step) * 8 + approach_side * retreat * 25, 0, -6.05 - (1 - step) * 17 - retreat * 33)
	rotation.y = approach_side * ((step - 1) * 0.42 + retreat * 2.43)
	torso.position = Vector3(0, 4.07 + lift * 0.72 - slam * 0.77 + 0.39 * brace + stride * 0.30 + 0.13 * shake, -0.06)
	torso.rotation.x = -0.26 * lift + 0.43 * slam - 0.14 * brace + 0.032 * stride
	head.rotation.x = 0.10 - 0.27 * lift + 0.29 * slam - 0.14 * brace
	head.rotation.y = sin(age * 2.34) * 0.10
	jaw.rotation.x = 0.06 + 0.67 * (lift - 0.76 * slam) + 0.15 * brace
	for i in range(2):
		var side: float = -1 if i == 0 else 1
		hind_legs[i].rotation.x = 0.11 - side * stride * 0.56 + 0.12 * lift - 0.10 * slam
		var shoulder := torso.transform * Vector3(side * 3.04, 1.95, 1.40)
		var walk := Vector3(side * 3.27, 1.12 + maxf(0.0, side * stride) * 1.15, 3.40 + side * stride * 1.20)
		var overhead := Vector3(side * 3.0, 12.1, 1.48)
		var hit := Vector3(side * 1.45, 0.62, 6.05)
		var wrist := walk.lerp(overhead, lift).lerp(hit, slam).lerp(walk, brace)
		var shoulder_to_hand := wrist - shoulder
		var length := maxf(shoulder_to_hand.length(), 0.01)
		var axis := shoulder_to_hand / length
		var fold := Vector3(side * 0.84, 0.18, -1.0)
		fold = (fold - axis * fold.dot(axis)).normalized()
		var upper_length := 3.95
		var lower_length := 4.16
		var chord: float = clampf((upper_length * upper_length - lower_length * lower_length + length * length) / (2 * length), 0, upper_length)
		var elbow := shoulder + axis * chord + fold * sqrt(maxf(0, upper_length * upper_length - chord * chord))
		_place_limb(upper_arms[i], shoulder, elbow, 3.36)
		_place_limb(lower_arms[i], elbow, wrist, 4.20)
		wrists[i].position = wrist
		wrists[i].rotation = Vector3(-0.68 * lift + 0.86 * slam - 0.14 * brace, -side * 0.14, side * 0.19 * (lift - slam))
	fur.set_shader_parameter("age", age)
	fur.set_shader_parameter("wind", 0.25 if reduced else 1.0)
	var mm := breath.multimesh
	mm.visible_instance_count = 3 if reduced else 8
	for i in range(mm.visible_instance_count):
		var u := fposmod(age * 1.08 + i * 0.125, 1.0)
		var radius := 0.13 + u * (0.93 + 0.69 * lift)
		var mag := 0.5 + 0.5 * sin(age * 4.6)
		var offset := Vector3(sin(i * 2.39) * u * 0.73, 0.05 + u * 0.79, 2.65 + u * (1.9 + lift * 2.5))
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * radius), offset))
		mm.set_instance_color(i, Color(0.82, 0.88, 0.91, sin(u * PI) * (0.17 + 0.25 * mag)))
