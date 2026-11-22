class_name BossRadar
extends BossPart

var scanner: Node3D
var spin_rate: float = 0.9
var mast_height: float = 7.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = maximum_armor
	face_offset = Vector3(0, mast_height, 0)
	var mount := GeometryBatch.new()
	mount.box(Vector3(0, 0.3, 0), Vector3(4.5, 0.8, 4.5), EncounterArt.GOLD)
	mount.box(Vector3(0, mast_height * 0.5, 0), Vector3(1.2, mast_height - 1, 1.2), EncounterArt.HULL)
	for side in [-1.0, 1.0]:
		mount.limb(Vector3(side * 2, 0.5, 0), Vector3(0, mast_height - 2, 0), 0.22, 0.18, EncounterArt.GOLD)
	add_child(mount.build())
	scanner = FleetArt.model("boss_scanner")
	scanner.position = face_offset
	add_child(scanner)
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 4.8
	collider.position = face_offset
	collider.shape = sphere
	add_child(collider)

func advance_scanner(time: float) -> void:
	if not destroyed:
		scanner.rotation.y = time * spin_rate + phase

