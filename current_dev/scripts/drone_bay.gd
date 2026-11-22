class_name DroneBay
extends BossPart

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = maximum_armor
	add_child(CryoArt.drone_bay())
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 5, 7)
	collider.shape = shape
	add_child(collider)
