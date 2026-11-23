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
	var half_height := pilot.project_position(rect.get_center(), BODY_DEPTH).distance_to(
		pilot.project_position(Vector2(rect.get_center().x, rect.position.y), BODY_DEPTH))
	var reach := clampf(age / LEAP, 0, 1)
	var release := clampf((age - LEAP - LATCH) / SLIDE, 0, 1)
	body.set_instance_shader_parameter(&"grip_age", attached_time * (0.3 if reduced_motion else 1.0))
	body.set_instance_shader_parameter(&"pressure", smoothstep(0.83, 1.0, reach) * (1.0 - smoothstep(0.0, 0.25, release)))
	var side := -1.0 if lean < 0.0 else 1.0
	# Both upper side panes are inside the external gun muzzles. Leave the
	# sight line between the two gun barrels open.
	var seat := pilot.to_local(pilot.project_position(rect.position + rect.size * Vector2(0.5 + side * 0.205, 0.27), BODY_DEPTH))
	position = pilot.to_local(emergence).lerp(seat, 1.0 - pow(1.0 - reach, 3))
	position.y += half_height * (sin(reach * PI) * 0.5 + 3.5 * release * release)
	position.x += lean * half_height * release
	position.x += side * half_height * sin(reach * PI) * 0.9
	rotation = Vector3((1 - reach) * 0.95, (1 - reach) * 0.65, lean + release * 0.32)
	scale = Vector3.ONE * lerpf(1.6, half_height * 0.26, reach)
	toe_prints.visible = reach >= 1.0 and release < 0.025
	if reach >= 1.0:
		_advance_tongue(attached_time, rect, side, half_height)
	else:
		tongue.hide()
	return count

func _advance_tongue(t: float, rect: Rect2, side: float, half_height: float) -> void:
	var glass_depth := BODY_DEPTH - scale.z * PAD_PLANE
	var pane_point := rect.position + rect.size * Vector2(0.5 + side * 0.145, 0.34)
	var hole := pilot.to_local(pilot.project_position(pane_point, glass_depth))
	var since := maxf(t - BREACH_TIME, 0.0)
	if not breached and t >= BREACH_TIME:
		breached = true
		_puncture(side)
	if is_instance_valid(wound):
		wound.position = hole
		wound.scale = Vector3.ONE * half_height * glass_depth / BODY_DEPTH * 0.72
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
	var aim := rect.position + rect.size * Vector2(0.5 - side * (0.016 + 0.067 * sin(since * 2.33) * sway), 0.421 + 0.031 * cos(since * 2.2) * sway)
	var tip := pilot.to_local(pilot.project_position(aim, lerpf(0.73, 0.41, grasp)))
	var local := transform.affine_inverse()
	var root := Vector3(0, 0.05, 0.44)
	var gate := root.lerp(local * hole, press)
	var thrust := smoothstep(0.0, 0.34, since) * retract
	var end := gate.lerp(local * tip, thrust * (0.53 + 0.47 * grasp))
	muscle.set_shader_parameter(&"mouth", root)
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
