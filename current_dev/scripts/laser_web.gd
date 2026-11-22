class_name LaserWeb
extends Node3D

const WARNING_TIME: float = 1.2
const LIFETIME: float = 7.0
const HALF_WIDTH: float = 8.5
const BEAM_RADIUS: float = 0.45
const DAMAGE: float = 22.0

var nodes: Array[WebNode] = []
var age: float = 0.0
var disabled: bool = false
var beam: MeshInstance3D
var warning: MeshInstance3D

func _ready() -> void:
	for side in [-1.0, 1.0]:
		var node := WebNode.new()
		node.position.x = side * HALF_WIDTH
		node.disabled.connect(disarm)
		add_child(node)
		nodes.append(node)
	var line := PackedVector3Array([Vector3.LEFT * HALF_WIDTH, Vector3.RIGHT * HALF_WIDTH])
	beam = VectorArt.lines(line, VectorArt.HOSTILE)
	add_child(beam)
	var dashes := PackedVector3Array()
	for i in range(12):
		var x: float = -HALF_WIDTH + i * HALF_WIDTH / 6.0
		dashes.append_array(PackedVector3Array([Vector3(x, 0, 0), Vector3(x + 0.7, 0, 0)]))
	warning = VectorArt.lines(dashes, VectorArt.AMBER)
	add_child(warning)
	beam.hide()

func disarm() -> void:
	disabled = true
	beam.hide()
	warning.hide()
	for node in nodes:
		node.destroyed = true
		node.collision_layer = 0
		node.hide()

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, pilot_radius: float) -> bool:
	var before: float = age
	age += delta
	if disabled:
		return false
	if before < LIFETIME and age >= WARNING_TIME and delta > 0.0:
		var start: float = clampf((WARNING_TIME - before) / delta, 0, 1)
		var end: float = clampf((LIFETIME - before) / delta, 0, 1)
		var closest: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
			previous_pilot.lerp(pilot, start), previous_pilot.lerp(pilot, end),
			nodes[0].global_position, nodes[1].global_position)
		if closest[0].distance_to(closest[1]) <= pilot_radius + BEAM_RADIUS:
			disarm()
			return true
	if age >= LIFETIME:
		disarm()
		return false
	beam.visible = age >= WARNING_TIME
	warning.visible = age < WARNING_TIME and fmod(age, 0.25) < 0.18
	return false

func complete() -> bool:
	return disabled or age >= LIFETIME
