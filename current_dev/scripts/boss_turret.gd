class_name BossTurret
extends BossPart

signal missile_requested(origin: Vector3, direction: Vector3)

var head: Node3D
var beacon: Node3D
var cooldown: float = 1.0
var interval: float = 5.6
var launches: int = 0
var interval_multiplier: float = 1.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = maximum_armor
	add_child(XyloArt.spitter_base() if biological else FleetArt.model("boss_turret_base"))
	head = XyloArt.spitter_head() if biological else EncounterArt.missile_turret()
	head.position.y = 1.8
	add_child(head)
	if biological:
		var glands := GeometryBatch.new()
		for side in [-1.0, 1.0]:
			glands.ellipsoid(Vector3(side * 1.4, 0.2, -3.82), Vector3(0.48, 0.48, 0.32), XyloArt.ACID, 8, 16)
		beacon = glands.build()
	else:
		beacon = FleetArt.model("boss_launch_warning")
	head.add_child(beacon)
	beacon.hide()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8, 7, 9)
	collider.position.y = 1.5
	collider.shape = shape
	add_child(collider)

func advance(delta: float, pilot: Vector3, pilot_velocity: Vector3) -> void:
	if destroyed or not unlocked:
		beacon.hide()
		return
	var direction: Vector3 = EnemyMissile.aim_direction(head.global_position, pilot, pilot_velocity)
	head.look_at(head.global_position + direction, Vector3.UP)
	cooldown -= delta
	beacon.visible = cooldown <= GroundTurret.WARNING_TIME
	if cooldown <= 0.0:
		var port := Vector3((launches % 3 - 1) * 2.0, -0.75 if launches % 2 == 0 else 0.75, -4.1)
		var origin: Vector3 = head.to_global(port)
		missile_requested.emit(origin, EnemyMissile.aim_direction(origin, pilot, pilot_velocity))
		launches += 1
		cooldown += interval * interval_multiplier

func aim_point() -> Vector3:
	return head.global_position
