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
	add_child(EncounterArt.radar_mast(mast_height, biological))
	scanner = FleetArt.model("sensory_fan" if biological else "fleet_dish", "ground")
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

