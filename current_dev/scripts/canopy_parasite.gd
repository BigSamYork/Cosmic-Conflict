class_name CanopyParasite
extends Node3D

const LEAP := 0.58
const LATCH := 15.0
const SLIDE := 0.85
const BITES := 5
const HULL_FRACTION := 0.10
const SKIN := preload("res://shaders/canopy_skin.gdshader")
const BREACH_TIME := 1.65 # Seconds after latch.
const BODY_DEPTH := 1.45
const CLOSE_DEPTH := 1.20
const MOUTH := Vector3(0, 0.05, 0.44)
const CENTER_MOUTH := Vector2(0.475, 0.318)
# Local Z of the flattened toe pads on the pilot-facing side of the mesh.
const PAD_PLANE := 0.49

var age := 0.0
var bites := 0
var emergence: Vector3
var lean := 0.0
var pilot: Camera3D
var reduced_motion := false
var body := MeshInstance3D.new()
var tongue := MeshInstance3D.new()
var muscle := ShaderMaterial.new()
var breached := false
var made_hole := false
var wound: MeshInstance3D
var toe_prints := Node3D.new()

func launch(camera: Camera3D, at: Vector3, tilt: float, reduced: bool) -> void:
	pilot = camera
	emergence = at
	lean = tilt
	reduced_motion = reduced
	pilot.add_child(self)
	body.mesh = FleetArt.mesh_for("canopy_parasite", "ground")
	var material := ShaderMaterial.new()
	material.shader = SKIN
	body.material_override = material
	add_child(body)
	add_child(toe_prints)
	var pad := QuadMesh.new()
	pad.size = Vector2(0.39, 0.49)
	var film := ShaderMaterial.new()
	film.shader = preload("res://shaders/canopy_contact.gdshader")
	pad.material = film
	# The eight toe centres come from the ventral mesh in build_walkers.py.
	for side in [-1.0, 1.0]:
		for j in range(4):
			var toe := MeshInstance3D.new()
			toe.mesh = pad
			toe.position = Vector3(side * (1.49 + 0.13*cos(j)), 1.07 - 0.77*j, PAD_PLANE + 0.004)
			if lean < 0.0:
				# The close latch braces the outer feet across the upper windshield.
				toe.position += Vector3(0.345, 0.36, 0.0) * smoothstep(0.52, 1.37, absf(toe.position.x))
			toe.rotation.z = side * (0.48 - 0.24*j)
			toe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			toe_prints.add_child(toe)
	# The shader bends the rings along two curves that share a tangent at
	# the opening in the glass.
	var tube := CylinderMesh.new()
	tube.rings = 60
	tube.radial_segments = 18
	tube.cap_top = false
	tube.cap_bottom = false
	tongue.mesh = tube
	muscle.shader = preload("res://shaders/canopy_tongue.gdshader")
	tongue.material_override = muscle
	tongue.custom_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	add_child(tongue)
	var hook_rings := CylinderMesh.new()
	hook_rings.rings = 11
	hook_rings.radial_segments = 10
	hook_rings.cap_top = false
	hook_rings.cap_bottom = false
	for index in range(4):
		var claw := MeshInstance3D.new()
		claw.mesh = hook_rings
		claw.material_override = muscle
		claw.custom_aabb = tongue.custom_aabb
		claw.set_instance_shader_parameter(&"claw_index", float(index))
		tongue.add_child(claw)
	advance(0.0)

# Return newly due bites, including every crossed boundary on a long physics step.
func advance(delta: float) -> int:
	age += delta
	var attached_time := clampf(age - LEAP, 0.0, LATCH)
	var due := mini(BITES, floori(attached_time * BITES / LATCH + 0.000001))
	var count := due - bites
	bites = due
	var rect := pilot.get_viewport().get_visible_rect()
	var close_latch := lean < 0.0
	var depth := CLOSE_DEPTH if close_latch else BODY_DEPTH
	var half_height := pilot.project_position(rect.get_center(), depth).distance_to(
		pilot.project_position(Vector2(rect.get_center().x, rect.position.y), depth))
	var reach := clampf(age / LEAP, 0, 1)
	var release := clampf((age - LEAP - LATCH) / SLIDE, 0, 1)
	body.set_instance_shader_parameter(&"grip_age", attached_time * (0.3 if reduced_motion else 1.0))
	var pressure := smoothstep(0.83, 1.0, reach) * (1.0 - smoothstep(0.0, 0.25, release))
	body.set_instance_shader_parameter(&"pressure", pressure)
	body.set_instance_shader_parameter(&"wide_grip", pressure if close_latch else 0.0)
	var amplitude := 0.30 if reduced_motion else 1.0
	body.set_instance_shader_parameter(&"left_lobe", _lobe_motion(age - LEAP, -1.0) * amplitude)
	body.set_instance_shader_parameter(&"right_lobe", _lobe_motion(age - LEAP, 1.0) * amplitude)
	var side := -1.0 if lean < 0.0 else 1.0
	# Keep a separate starboard foothold for another simultaneous hatch.
	var seat := pilot.to_local(pilot.project_position(rect.position + rect.size * Vector2(0.705, 0.27), depth))
	var latch_scale := Vector3.ONE * half_height * 0.26
	var roll := lean
	if close_latch:
		var fit := minf(1.0, rect.size.aspect() / (16.0 / 9.0))
		latch_scale = Vector3(0.556, 0.298, 0.395) * half_height * fit
		roll = lean * 0.5
		var mouth_offset := Basis(Vector3.BACK, roll) * (MOUTH * latch_scale)
		var mouth_pixel := rect.position + rect.size * CENTER_MOUTH
		seat = pilot.to_local(pilot.project_position(mouth_pixel, depth - mouth_offset.z)) - mouth_offset
	position = pilot.to_local(emergence).lerp(seat, 1.0 - pow(1.0 - reach, 3))
	position.y += half_height * (sin(reach * PI) * 0.5 + 3.5 * release * release)
	position.x += lean * half_height * release
	position.x += side * half_height * sin(reach * PI) * 0.9
	rotation = Vector3((1 - reach) * 0.95, (1 - reach) * 0.65, roll + release * 0.32)
	scale = (Vector3.ONE * 1.6).lerp(latch_scale, reach)
	toe_prints.visible = reach >= 1.0 and release < 0.025
	if reach >= 1.0:
		_advance_tongue(attached_time, rect, side, half_height, depth)
	else:
		tongue.hide()
	return count

func _lobe_motion(t: float, side: float) -> Vector3:
	# The free ends lag the impact, then pick up the tongue's side-to-side
	# pull. Different periods keep the two lobes from swinging in lockstep.
	var landed := maxf(t, 0.0)
	var rate := 11.0 + 0.9 * side
	var landing := exp(-2.4 * landed) * sin(rate * landed)
	var breach := maxf(t - BREACH_TIME, 0.0)
	var recoil := exp(-2.8 * breach) * sin((rate + 2.0) * breach)
	var pull := smoothstep(0.0, 0.55, breach) * (1.0 - smoothstep(LATCH - 1.0, LATCH, t))
	var swing := 0.034 * sin(t * (3.1 + 0.17 * side) + side * 0.45)
	swing += 0.18 * landing + 0.095 * recoil + pull * 0.105 * sin(2.33 * breach - 0.65 + side * 0.24)
	var stretch := -0.23 * landing + 0.14 * recoil + 0.052 * sin(t * 4.0 + side * 0.65)
	var peel := maxf(t - LATCH, 0.0)
	stretch += 0.21 * exp(-2.3 * peel) * sin(8.5 * peel)
	return Vector3(swing, stretch, 0.10 * landing - 0.13 * recoil + 0.031 * sin(t * 3.8 + side))

func _advance_tongue(t: float, rect: Rect2, side: float, half_height: float, depth: float) -> void:
	var glass_depth := depth - scale.z * PAD_PLANE
	var pane_uv := Vector2(0.545, 0.385) if side < 0.0 else Vector2(0.645, 0.34)
	var pane_point := rect.position + rect.size * pane_uv
	var hole := pilot.to_local(pilot.project_position(pane_point, glass_depth))
	var since := maxf(t - BREACH_TIME, 0.0)
	if not breached and t >= BREACH_TIME:
		breached = true
		_puncture(side)
	if is_instance_valid(wound):
		wound.position = hole
		wound.scale = Vector3.ONE * half_height * glass_depth / depth * 0.72
		if made_hole:
			wound.set_instance_shader_parameter(&"opening", minf(1.0, 0.38 + since * 4.0))
			wound.set_instance_shader_parameter(&"shard_time", minf(0.7, since))
	var retract := 1.0 - smoothstep(LATCH - 1.0, LATCH - 0.1, t)
	var press := smoothstep(BREACH_TIME - 0.68, BREACH_TIME, t) * retract
	tongue.visible = press > 0.005
	if not tongue.visible:
		return
	var grasp := (0.5 + 0.5 * cos(since * 2.6)) * smoothstep(0.0, 0.36, since) * retract
	var sway := 0.38 if reduced_motion else 1.0
	var aim_center := Vector2(0.61, 0.465) if side < 0.0 else Vector2(0.484, 0.421)
	var sweep := Vector2(-side * 0.067 * sin(since * 2.33), 0.031 * cos(since * 2.2))
	var aim := rect.position + rect.size * (aim_center + sweep * sway)
	var tip := pilot.to_local(pilot.project_position(aim, lerpf(0.73, 0.41, grasp)))
	var local := transform.affine_inverse()
	var gate := MOUTH.lerp(local * hole, press)
	var thrust := smoothstep(0.0, 0.34, since) * retract
	var end := gate.lerp(local * tip, thrust * (0.53 + 0.47 * grasp))
	muscle.set_shader_parameter(&"mouth", MOUTH)
	muscle.set_shader_parameter(&"gate", gate)
	muscle.set_shader_parameter(&"tip", end)
	muscle.set_shader_parameter(&"eye", local * Vector3.ZERO)
	muscle.set_shader_parameter(&"opened", thrust)
	muscle.set_shader_parameter(&"sway", sway)
	muscle.set_shader_parameter(&"pulse", t * (0.72 if reduced_motion else 1.0))
	# Hold the four hooks out as the tongue searches, then snap them inward.
	var opening := 0.5 + 0.5 * sin(since * (3.0 if reduced_motion else 4.2) + 0.47*sin(since*2.1))
	muscle.set_shader_parameter(&"aperture", thrust * smoothstep(0.12, 0.74, opening))

func _puncture(side: float) -> void:
	var slot := "PortPuncture" if side < 0.0 else "StarboardPuncture"
	wound = pilot.get_node_or_null(slot) as MeshInstance3D
	if wound != null:
		return
	made_hole = true
	wound = MeshInstance3D.new()
	wound.name = slot
	wound.mesh = QuadMesh.new()
	var glass := ShaderMaterial.new()
	glass.shader = preload("res://shaders/punctured_glass.gdshader")
	glass.set_shader_parameter(&"seed", 5.0 if side < 0.0 else 19.0)
	wound.material_override = glass
	wound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot.add_child(wound)
	wound.add_to_group(&"punctured_canopy")

func gripping() -> bool:
	return age >= LEAP and age < LEAP + LATCH + SLIDE

func finished() -> bool:
	return age >= LEAP + LATCH + SLIDE
