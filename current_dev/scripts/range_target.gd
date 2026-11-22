class_name RangeTarget
extends StaticBody3D

var travel: float = 0.0
var lane: Vector2 = Vector2.ZERO
var armor: int = 2
var health_scale: float = 1.0
var destroyed: bool = false
var phase: float = 0.0
var guided_lockable: bool = true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_child(create_model())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.4, 2.1, 5.5)
	collider.shape = shape
	add_child(collider)
	animate(0.0)

func animate(time: float) -> void:
	if destroyed:
		return
	transform = FlightState.rail_frame(travel)
	position += basis * Vector3(lane.x + sin(time * 0.9 + phase) * 1.3, lane.y + sin(time * 1.2 + phase) * 0.45, 0)
	rotate_object_local(Vector3.FORWARD, sin(time + phase) * 0.18)

func receive_hit(damage: int = 1) -> bool:
	if destroyed:
		return false
	armor -= damage
	if armor <= 0:
		destroyed = true
		hide()
		collision_layer = 0
	return destroyed

func reset() -> void:
	destroyed = false
	armor = 2
	collision_layer = 2
	show()
	animate(0.0)

func create_model() -> Node3D:
	return VectorArt.ship()

func aim_point() -> Vector3:
	return global_position
