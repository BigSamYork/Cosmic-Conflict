class_name BossPart
extends RangeTarget

var core: bool = false
var unlocked: bool = true
var maximum_armor: int = 14
var nacelle_radius: float = 0.0
var nacelle_length: float = 0.0
var face_offset: Vector3 = Vector3.ZERO
var biological: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var dimensions := Vector3(8, 5, 3) if core else Vector3(5, 5, 3)
	if nacelle_radius > 0:
		add_child(XyloArt.organ_sac(nacelle_radius, nacelle_length, core) if biological else EncounterArt.reactor_nacelle(nacelle_radius, nacelle_length))
		face_offset.z = nacelle_length * 0.5 + nacelle_radius * 0.7
	if not biological:
		var face: Node3D = VectorArt.box(dimensions, VectorArt.CYAN if core else VectorArt.AMBER)
		face.position = face_offset
		add_child(face)
		var detail := GeometryBatch.new()
		detail.ring(Vector3(0, 0, 1.55), 1.8, VectorArt.HOSTILE, 16)
		detail.ring(Vector3(0, 0, 1.57), 0.85, VectorArt.CYAN, 12)
		var rings: Node3D = detail.build()
		rings.position = face_offset
		add_child(rings)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(nacelle_radius * 2.3, nacelle_radius * 2.3, nacelle_length + nacelle_radius * 2.0) if nacelle_radius > 0 else dimensions
	collider.position.z = 1.5 if nacelle_radius > 0 else 0.0
	collider.shape = shape
	add_child(collider)
	armor = maximum_armor

func animate(_time: float) -> void:
	pass

func aim_point() -> Vector3:
	return to_global(face_offset)

func receive_hit(damage: int = 1) -> bool:
	if not unlocked:
		return false
	return super.receive_hit(damage)
