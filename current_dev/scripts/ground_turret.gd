class_name GroundTurret
extends RangeTarget

signal missile_requested(origin: Vector3, direction: Vector3)

const ATTACK_RANGE: float = 360.0
const FIRE_INTERVAL: float = 2.8
const WARNING_TIME: float = 0.9

var head: Node3D
var beacon: Node3D
var cooldown: float = WARNING_TIME
var launches: int = 0
var fire_interval: float = FIRE_INTERVAL
var tracking_jammed: float = 0.0
var sector: String = "ignis"

func _ready() -> void:
	transform = FlightState.rail_frame(travel)
	position = (FrontierArt.floor_point(lane.x, travel, sector) if FrontierArt.is_frontier(sector) else XyloArt.floor_point(lane.x, travel) if sector == "xylo" else VesperaArt.floor_point(lane.x, travel) if sector == "vespera" else VectorArt.ground_point(lane.x, travel)) + Vector3.UP * 1.1
	collision_mask = 0
	add_child(FrontierArt.turret_base(sector) if FrontierArt.is_frontier(sector) else XyloArt.spitter_base() if sector == "xylo" else VesperaArt.turret_base() if sector == "vespera" else CryoArt.tank_base() if sector == "cryo" else VectorArt.turret_base())
	head = XyloArt.spitter_head() if sector == "xylo" else VectorArt.turret_head()
	head.position.y = 2.0
	add_child(head)
	beacon = VectorArt.box(Vector3(0.7, 0.18, 0.7), VectorArt.HOSTILE)
	beacon.position = Vector3(0, 0.9, -0.4)
	head.add_child(beacon)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(7.0, 4.2, 8.0 if sector == "cryo" else 7.0)
	collider.position.y = 1.0
	collider.shape = shape
	add_child(collider)
	reset()

func animate(_time: float) -> void:
	pass

func reset() -> void:
	destroyed = false
	armor = ceili(4 * health_scale)
	collision_layer = 3
	cooldown = WARNING_TIME + phase
	launches = 0
	tracking_jammed = 0.0
	show()
	if beacon != null:
		beacon.hide()

func advance(delta: float, pilot: Vector3, pilot_velocity: Vector3 = Vector3.ZERO) -> void:
	if destroyed:
		return
	if tracking_jammed > 0.0:
		var blocked: float = minf(delta, tracking_jammed)
		tracking_jammed -= blocked
		delta -= blocked
		beacon.hide()
		if delta <= 0.0:
			return
	var ahead: float = to_local(pilot).z
	var in_range: bool = ahead > 50.0 and global_position.distance_to(pilot) <= ATTACK_RANGE
	if not in_range:
		beacon.hide()
		return
	var aim: Vector3 = EnemyMissile.aim_direction(head.global_position, pilot, pilot_velocity)
	head.look_at(head.global_position + aim * 100.0, Vector3.UP)
	cooldown -= delta
	beacon.visible = cooldown <= WARNING_TIME
	if cooldown <= 0.0:
		var side: float = -1.0 if launches % 2 == 0 else 1.0
		var origin: Vector3 = head.to_global(Vector3(side * 0.95, 0, -4.6))
		missile_requested.emit(origin, EnemyMissile.aim_direction(origin, pilot, pilot_velocity))
		launches += 1
		cooldown += fire_interval

func jam_tracking(duration: float) -> void:
	tracking_jammed = maxf(tracking_jammed, duration)
	cooldown = maxf(cooldown, WARNING_TIME)
	beacon.hide()
