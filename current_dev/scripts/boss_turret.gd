class_name BossTurret
extends BossPart

signal missile_requested(origin: Vector3, direction: Vector3)

var head: Node3D
var beacon: Node3D
var cooldown: float = 1.0
var interval: float = 5.6
var launches: int = 0
var interval_multiplier: float = 1.0
var lead_fraction := 1.0
var emergency_power := false
var interrupted := false
var recoil := 0.0
var barrel: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = maximum_armor
	add_child(XyloArt.spitter_base() if biological else FleetArt.model("boss_turret_base"))
	head = Node3D.new()
	barrel = XyloArt.spitter_head() if biological else EncounterArt.missile_turret()
	head.add_child(barrel)
	head.position.y = 1.8
	add_child(head)
	if biological:
		var glands := GeometryBatch.new()
		for side in [-1.0, 1.0]:
			glands.ellipsoid(Vector3(side * 1.4, 0.2, -3.82), Vector3(0.48, 0.48, 0.32), XyloArt.ACID, 8, 16)
		beacon = glands.build()
	else:
		beacon = FleetArt.model("boss_launch_warning")
	barrel.add_child(beacon)
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
	recoil = maxf(0, recoil - delta * 3.8)
	barrel.position.z = 0.8 * recoil
	var tracked_velocity := pilot_velocity * lead_fraction
	var direction: Vector3 = EnemyMissile.aim_direction(head.global_position, pilot, tracked_velocity)
	head.look_at(head.global_position + direction, Vector3.UP)
	cooldown -= delta
	beacon.visible = cooldown <= GroundTurret.WARNING_TIME
	if beacon.visible:
		var pulse := clampf(1.0 - cooldown / GroundTurret.WARNING_TIME, 0.0, 1.0)
		beacon.scale = Vector3.ONE * (1.0 + pulse * 0.36)
	if cooldown <= 0.0:
		var port := Vector3((launches % 3 - 1) * 2.0, -0.75 if launches % 2 == 0 else 0.75, -4.1)
		var origin: Vector3 = head.to_global(port)
		missile_requested.emit(origin, EnemyMissile.aim_direction(origin, pilot, tracked_velocity))
		launches += 1
		recoil = 1.0
		barrel.position.z = 0.8
		interrupted = false
		cooldown += interval * interval_multiplier * (0.67 if emergency_power else 1.0)

func receive_hit(damage: int = 1) -> bool:
	var can_interrupt := unlocked and not destroyed and not interrupted and cooldown > 0 and cooldown <= 0.38
	var killed := super.receive_hit(damage)
	if can_interrupt and not killed and damage > 0:
		cooldown += 1.45
		interrupted = true
		beacon.hide()
	return killed

func aim_point() -> Vector3:
	return head.global_position
