class_name BossPart
extends RangeTarget

var core: bool = false
var armored_interlock := false
var unlocked: bool = true:
	set(value):
		unlocked = value
		if shield_cover != null:
			shield_cover.visible = not value
var maximum_armor: int = 14
var nacelle_radius: float = 0.0
var nacelle_length: float = 0.0
var face_offset: Vector3 = Vector3.ZERO
var biological: bool = false
var target_face: Node3D
var shield_cover: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var dimensions := Vector3(8, 5, 3) if core else Vector3(5, 5, 3)
	var radius := nacelle_radius if nacelle_radius > 0 else 2.3
	if nacelle_radius > 0:
		var housing := FleetArt.model("boss_organ_body" if biological else "boss_reactor_body")
		housing.scale = Vector3(radius, radius, nacelle_length)
		add_child(housing)
		face_offset.z = nacelle_length * 0.5 + radius * 0.7
	var face_id := "boss_core" if core else "boss_generator"
	if biological:
		face_id = "boss_heart" if core else "boss_spore"
	target_face = FleetArt.model(face_id)
	target_face.position = face_offset
	target_face.scale = Vector3.ONE * radius
	add_child(target_face)
	if core or armored_interlock:
		shield_cover = FleetArt.model("boss_membrane" if biological else "boss_iris")
		shield_cover.position = face_offset
		shield_cover.scale = Vector3.ONE * radius
		shield_cover.visible = not unlocked
		add_child(shield_cover)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(nacelle_radius * 2.3, nacelle_radius * 2.3, nacelle_length + nacelle_radius * 2.0) if nacelle_radius > 0 else dimensions
	collider.position.z = 1.5 if nacelle_radius > 0 else 0.0
	collider.shape = shape
	add_child(collider)
	armor = maximum_armor

func animate(_time: float) -> void:
	pass

func animate_reactor(time: float) -> void:
	if destroyed:
		return
	if biological:
		var beat := 1.0 + 0.055 * pow(0.5 + 0.5 * sin(time * 3.4 + position.x), 4.0)
		target_face.scale = Vector3(beat, beat, 1.0 / beat) * nacelle_radius
	else:
		target_face.rotation.z = fposmod(time * (0.50 if core else -0.85), TAU)

func aim_point() -> Vector3:
	return to_global(face_offset)

func receive_hit(damage: int = 1) -> bool:
	if not unlocked:
		return false
	return super.receive_hit(damage)
