class_name PirateSkirmisher
extends RangeTarget

signal missile_requested(origin: Vector3, direction: Vector3)

const BOUNTY: int = 80
const SPEED: float = 50.0
const LIFETIME: float = 14.0
const CLEARANCE_RADIUS: float = 2.4

var course: Transform3D = Transform3D.IDENTITY
var age: float = 0.0
var engaged: bool = false
var expired: bool = false
var cooldown: float = 1.0
var trail: Node3D
var stun_remaining: float = 0.0
var biological: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = ceili(5 * health_scale)
	var model: Node3D = XyloArt.hive_mother() if biological else EncounterArt.pirate_skirmisher()
	if biological:
		model.scale = Vector3.ONE * 0.7
	add_child(model)
	FleetArt.add_pilot_hull(model)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = CLEARANCE_RADIUS
	collider.shape = shape
	add_child(collider)
	var batch := GeometryBatch.new()
	for x in [-0.8, 0.8]:
		batch.line(Vector3(x, 0, 1.4), Vector3(x, 0, 5.0), XyloArt.LEAF if biological else VectorArt.AMBER)
	trail = batch.build()
	add_child(trail)
	_update_pose()

func animate(_time: float) -> void:
	pass

func advance(delta: float, pilot: Vector3, pilot_velocity: Vector3) -> void:
	if destroyed or expired:
		return
	age += delta
	if age >= LIFETIME:
		retire()
		return
	_update_pose()
	if stun_remaining > 0:
		var blocked: float = minf(delta, stun_remaining)
		stun_remaining -= blocked
		delta -= blocked
		if delta <= 0:
			return
	if not engaged or global_position.distance_to(pilot) > 250:
		return
	cooldown -= delta
	if cooldown <= 0.0:
		var origin: Vector3 = to_global(Vector3(0, 0, 2.3))
		missile_requested.emit(origin, EnemyMissile.aim_direction(origin, pilot, pilot_velocity))
		cooldown += 3.8

func stun() -> void:
	stun_remaining = FlightState.EMP_STUN_DURATION
	engaged = true
	cooldown = maxf(cooldown, 1.0)

func _update_pose() -> void:
	var distance: float = travel + age * SPEED
	var frame: Transform3D = FlightDirector.asteroid_frame(distance)
	# Stay inside the existing clear center lane, rather than clipping the rocks.
	frame.origin += frame.basis * Vector3(sin(age * 1.7 + phase) * 0.5, cos(age * 1.3 + phase) * 0.4, 0)
	global_transform = course * frame
	rotate_object_local(Vector3.FORWARD, sin(age * 1.7 + phase) * 0.35)
	trail.scale.z = 0.9 + sin(age * 12) * 0.15

func receive_hit(damage: int = 1) -> bool:
	if expired:
		return false
	engaged = true
	return super.receive_hit(damage)

func retire() -> void:
	expired = true
	collision_layer = 0
	hide()
