class_name ThermalEmitter
extends BossPart

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = maximum_armor
	add_child(EncounterArt.thermal_emitter())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 6, 8)
	collider.shape = shape
	add_child(collider)
