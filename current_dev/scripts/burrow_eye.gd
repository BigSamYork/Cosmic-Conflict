class_name BurrowEye
extends RangeTarget

signal blinded

func _ready() -> void:
	armor = 2
	collision_layer = 0
	collision_mask = 0
	var hitbox := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.62
	hitbox.shape = sphere
	add_child(hitbox)

func animate(_time: float) -> void:
	pass # The articulated skull supplies the eye's pose.

func receive_hit(damage: int = 1) -> bool:
	if destroyed or collision_layer == 0:
		return false
	if super.receive_hit(damage):
		blinded.emit()
	return destroyed
