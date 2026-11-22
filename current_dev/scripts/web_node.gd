class_name WebNode
extends RangeTarget

signal disabled

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = 2
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, Vector3(2.2, 2.2, 1.4), VectorArt.HOSTILE)
	batch.ring(Vector3(0, 0, 0.8), 1.3, VectorArt.AMBER, 16)
	batch.ring(Vector3(0, 0, 0.82), 0.5, VectorArt.CYAN, 12)
	add_child(batch.build())
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.5
	collider.shape = shape
	add_child(collider)

func animate(_time: float) -> void:
	pass

func receive_hit(damage: int = 1) -> bool:
	if super.receive_hit(damage):
		disabled.emit()
		return true
	return false
