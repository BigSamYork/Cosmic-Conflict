class_name FallingIce
extends RangeTarget

signal landed(ice: FallingIce)

const WARNING_TIME: float = 2.0
const TRIGGER_DISTANCE: float = 140.0
const DROP_HEIGHT: float = 36.0
const GRAVITY: float = 28.0
const RADIUS: float = 2.8
const DAMAGE: float = 14.0
var age: float = 0.0
var started: bool = false
var expired: bool = false
var contacted: bool = false
var marker: Node3D

func support_model() -> Node3D:
	var side: float = signf(lane.x)
	var model := FleetArt.model("ice_cornice", "ground")
	model.scale.x = side
	var origin: Vector3 = FlightState.rail_point(travel)
	model.position = Vector3(origin.x + lane.x, 0, origin.z)
	return model

func falling_model() -> Node3D:
	return FleetArt.model("ice_calving", "ground")

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	guided_lockable = false
	armor = 2
	var origin: Vector3 = FlightState.rail_point(travel)
	position = Vector3(origin.x + lane.x, DROP_HEIGHT, origin.z)
	add_child(falling_model())
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS
	collider.shape = sphere
	add_child(collider)
	var warning := GeometryBatch.new()
	var ring := PackedVector3Array()
	for i in range(32):
		var angle: float = i * TAU / 32
		ring.append(Vector3(cos(angle) * 3.4, 0.15, sin(angle) * 3.4))
	warning.outline(ring, VectorArt.AMBER)
	for side in [-1.0, 1.0]:
		warning.line(Vector3(side * 2, 4, 0), Vector3(0, 1, 0), VectorArt.AMBER)
	marker = warning.build()
	add_child(marker)
	_update_pose()

func animate(_time: float) -> void:
	pass

func warning() -> bool:
	return started and not destroyed and not expired and age < WARNING_TIME

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, pilot_radius: float) -> bool:
	assert(delta >= 0)
	if destroyed or expired or delta == 0:
		return false
	var local_from: Vector3 = get_parent_node_3d().to_local(previous_pilot)
	var local_to: Vector3 = get_parent_node_3d().to_local(pilot)
	var active_delta: float = delta
	if not started:
		var trigger: float = -travel + TRIGGER_DISTANCE
		if local_to.z > trigger:
			return false
		started = true
		if local_from.z > trigger:
			var fraction: float = (local_from.z - trigger) / (local_from.z - local_to.z)
			active_delta *= 1.0 - fraction
	var previous_age: float = age
	age += active_delta
	var hit: bool = false
	var steps: int = maxi(1, ceili(delta * 240))
	for i in range(steps):
		var fraction: float = (i + 0.5) / steps
		var at_time: float = previous_age + maxf(0, fraction * delta - (delta - active_delta))
		if at_time < WARNING_TIME:
			continue
		var height: float = DROP_HEIGHT - 0.5 * GRAVITY * pow(at_time - WARNING_TIME, 2)
		if height < RADIUS:
			continue
		var center := Vector3(position.x, height, position.z)
		if not contacted and center.distance_to(local_from.lerp(local_to, fraction)) <= RADIUS + pilot_radius:
			contacted = true
			hit = true
	_update_pose()
	if position.y <= RADIUS:
		expired = true
		collision_layer = 0
		marker.hide()
		landed.emit(self)
		hide()
	return hit

func _update_pose() -> void:
	position.y = maxf(RADIUS, DROP_HEIGHT - 0.5 * GRAVITY * pow(maxf(0, age - WARNING_TIME), 2))
	marker.position.y = -position.y
	marker.visible = started and not expired and not destroyed
	marker.scale = Vector3.ONE * (1.0 + 0.08 * sin(age * 8))
