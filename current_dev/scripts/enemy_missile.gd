class_name EnemyMissile
extends Area3D

signal hit_pilot

const SPEED: float = 80.0
const MAX_AGE: float = 7.0
const HOMING_TIME: float = 0.9
const HIT_RADIUS: float = 1.3
const DAMAGE: float = 14.0

var direction: Vector3 = Vector3.FORWARD
var age: float = 0.0
var active: bool = true
var diverted: bool = false
var diversion_age: float = 0.0
var frost: bool = false
var biological: bool = false
var boss_fire_control: WeakRef
var wake: EngineWake

func guidance_strength() -> float:
	if boss_fire_control == null:
		return 1.0
	var source := boss_fire_control.get_ref() as BossEncounter
	return source.radar_guidance() if source != null and source.death_time < 0 else 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	add_child(XyloArt.spore_bolt() if biological else VectorArt.enemy_missile(CryoArt.ICE if frost else VectorArt.HOSTILE))
	wake = EngineWake.new()
	wake.mount(self, XyloArt.ACID if biological else CryoArt.ICE if frost else Color("#ff7e32"))
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	collider.shape = shape
	add_child(collider)
	basis = Basis.looking_at(direction)

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, pilot_radius: float = 0.6, dangerous: bool = true) -> void:
	assert(delta > 0.0)
	if not active:
		return
	age += delta
	wake.advance(age)
	if diverted:
		diversion_age += delta
	if age >= MAX_AGE or diversion_age >= 2.0:
		retire()
		return
	var guidance := guidance_strength() if age < HOMING_TIME else 0.0
	if age < HOMING_TIME * guidance and not diverted and dangerous:
		var desired: Vector3 = aim_direction(position, pilot, (pilot - previous_pilot) / delta)
		if desired.length_squared() > 0.0:
			direction = direction.slerp(desired, 1.0 - exp(-1.4 * guidance * delta)).normalized()
	var previous: Vector3 = position
	var next: Vector3 = previous + direction * SPEED * delta
	var query := PhysicsRayQueryParameters3D.create(previous, next, 1)
	var cover: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var covered_fraction: float = 1.0
	if not cover.is_empty():
		var contact: Vector3 = cover["position"]
		covered_fraction = previous.distance_to(contact) / maxf(previous.distance_to(next), 0.0001)
		next = contact
	# Sweep relative motion so a fast missile cannot step through a moving pilot.
	var pilot_at_end: Vector3 = previous_pilot.lerp(pilot, covered_fraction)
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3.ZERO, previous - previous_pilot, next - pilot_at_end)
	position = next
	basis = Basis.looking_at(direction)
	if dangerous and closest.length() <= 0.7 + pilot_radius:
		retire()
		hit_pilot.emit()
	elif not cover.is_empty():
		var obstacle: Object = cover["collider"]
		if dangerous and obstacle is DestructibleTower:
			obstacle.receive_hit_at(3, cover["position"], direction)
		retire()

func divert(pilot: Vector3, escape: Vector3) -> bool:
	if not active or diverted:
		return false
	var away: Vector3 = (global_position - pilot).normalized()
	direction = (away * 0.65 + escape.normalized() * 1.5).normalized()
	diverted = true
	basis = Basis.looking_at(direction)
	return true

func receive_hit() -> bool:
	if not active:
		return false
	retire()
	return true

func retire() -> void:
	active = false
	collision_layer = 0
	hide()

static func aim_direction(origin: Vector3, pilot: Vector3, pilot_velocity: Vector3) -> Vector3:
	var relative: Vector3 = pilot - origin
	var a: float = pilot_velocity.length_squared() - SPEED * SPEED
	var b: float = 2.0 * relative.dot(pilot_velocity)
	var c: float = relative.length_squared()
	var intercept_time: float = 0.0
	if absf(a) < 0.0001:
		if absf(b) > 0.0001:
			intercept_time = maxf(0.0, -c / b)
	else:
		var discriminant: float = b * b - 4.0 * a * c
		if discriminant >= 0.0:
			var root: float = sqrt(discriminant)
			for solution in [(-b - root) / (2.0 * a), (-b + root) / (2.0 * a)]:
				if solution > 0.0 and (intercept_time == 0.0 or solution < intercept_time):
					intercept_time = solution
	# Lead the rail motion; a direct shot at the old position passes beneath the ship.
	return (pilot + pilot_velocity * minf(intercept_time, MAX_AGE) - origin).normalized()
