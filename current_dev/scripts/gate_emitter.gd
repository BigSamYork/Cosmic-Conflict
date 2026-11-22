class_name GateEmitter
extends RangeTarget

signal disabled
var jam_remaining: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = 4
	add_child(VesperaArt.gate_emitter())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 22, 3.2)
	collider.position.y = 2
	collider.shape = shape
	add_child(collider)

func animate(_time: float) -> void:
	pass

func jam() -> void:
	jam_remaining = FlightState.EMP_STUN_DURATION

func receive_hit(damage: int = 1) -> bool:
	if super.receive_hit(damage):
		disabled.emit()
		return true
	return false

func aim_point() -> Vector3:
	return to_global(Vector3(0, 2, 1.6))
