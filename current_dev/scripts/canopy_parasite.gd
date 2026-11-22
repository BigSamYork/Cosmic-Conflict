class_name CanopyParasite
extends Node3D

const LEAP := 0.58
const LATCH := 15.0
const SLIDE := 0.85
const BITES := 5
const HULL_FRACTION := 0.10
const SKIN := preload("res://shaders/canopy_skin.gdshader")

var age := 0.0
var bites := 0
var emergence: Vector3
var lean := 0.0
var pilot: Camera3D
var reduced_motion := false
var body := MeshInstance3D.new()

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
	advance(0.0)

# Return newly due bites, including every crossed boundary on a long physics step.
func advance(delta: float) -> int:
	age += delta
	var attached_time := clampf(age - LEAP, 0.0, LATCH)
	var due := mini(BITES, floori(attached_time * BITES / LATCH + 0.000001))
	var count := due - bites
	bites = due
	var depth := 2.65
	var rect := pilot.get_viewport().get_visible_rect()
	var half_height := pilot.project_position(rect.get_center(), depth).distance_to(
		pilot.project_position(Vector2(rect.get_center().x, rect.position.y), depth))
	var reach := clampf(age / LEAP, 0, 1)
	var release := clampf((age - LEAP - LATCH) / SLIDE, 0, 1)
	var breath := sin(attached_time * 3.8) * (0.010 if reduced_motion else 0.031)
	body.set_instance_shader_parameter(&"grip_age", attached_time * (0.3 if reduced_motion else 1.0))
	var seat := Vector3(lean * half_height * 0.65, half_height * 0.18, -depth)
	position = pilot.to_local(emergence).lerp(seat, 1.0 - pow(1.0 - reach, 3))
	position.y += half_height * (sin(reach * PI) * 0.5 - 3.5 * release * release)
	position.x += lean * half_height * release
	rotation = Vector3((1 - reach) * 0.95, (1 - reach) * 0.65, lean + release * 0.32)
	scale = Vector3(1.0 + breath, 1.0 - breath * 0.55, 1.0 + breath) * lerpf(1.6, half_height * 0.77, reach)
	return count

func gripping() -> bool:
	return age >= LEAP and age < LEAP + LATCH + SLIDE

func finished() -> bool:
	return age >= LEAP + LATCH + SLIDE
