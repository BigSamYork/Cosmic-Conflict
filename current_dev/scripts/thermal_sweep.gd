class_name ThermalSweep
extends Node3D

const WARNING: float = 1.6
const DURATION: float = 3.0
const RANGE: float = 330.0
const HALF_ANGLE: float = 0.18
const DAMAGE: float = 26.0
const HEAT: float = 30.0

var emitter: ThermalEmitter
var aim: Basis
var age: float = 0.0
var hit_pilot: bool = false
var previous_origin: Vector3
var beam: Node3D
var warning_fan: Node3D

func _ready() -> void:
	previous_origin = emitter.global_position
	var batch := GeometryBatch.new()
	for x in [-0.3, 0.0, 0.3]:
		batch.line(Vector3(x, 0, 0), Vector3(x, 0, -RANGE), VectorArt.HOSTILE if x != 0 else VectorArt.AMBER)
	beam = batch.build()
	add_child(beam)
	var fan := GeometryBatch.new()
	for angle in [-HALF_ANGLE, 0.0, HALF_ANGLE]:
		var direction: Vector3 = Basis(Vector3.UP, angle) * Vector3.FORWARD
		for distance in range(0, int(RANGE), 16):
			fan.line(direction * distance, direction * (distance + 7), Color("#e6a14e"))
	warning_fan = fan.build()
	add_child(warning_fan)
	_update_visual()

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, pilot_radius: float) -> bool:
	var before: float = age
	age += delta
	if not is_instance_valid(emitter) or emitter.destroyed:
		hide()
		return false
	var origin: Vector3 = emitter.global_position
	var struck: bool = false
	if not hit_pilot and delta > 0.0 and before < WARNING + DURATION and age >= WARNING:
		var start: float = maxf(before, WARNING)
		var end: float = minf(age, WARNING + DURATION)
		var samples: int = maxi(1, ceili((end - start) * 240.0))
		for i in range(samples + 1):
			var time: float = lerpf(start, end, float(i) / samples)
			var fraction: float = clampf((time - before) / delta, 0, 1)
			var at: Vector3 = previous_origin.lerp(origin, fraction)
			var direction: Vector3 = aim * (Basis(Vector3.UP, sweep_angle(time)) * Vector3.FORWARD)
			var ship: Vector3 = previous_pilot.lerp(pilot, fraction)
			var closest: Vector3 = Geometry3D.get_closest_point_to_segment(ship, at, at + direction * RANGE)
			if closest.distance_to(ship) <= pilot_radius + 0.65:
				hit_pilot = true
				struck = true
				break
	previous_origin = origin
	_update_visual()
	return struck

func sweep_angle(time: float) -> float:
	return lerpf(-HALF_ANGLE, HALF_ANGLE, clampf((time - WARNING) / DURATION, 0, 1))

func complete() -> bool:
	return age >= WARNING + DURATION or not is_instance_valid(emitter) or emitter.destroyed

func _update_visual() -> void:
	global_transform = Transform3D(aim, emitter.global_position)
	beam.rotation.y = sweep_angle(age)
	beam.visible = age >= WARNING and age < WARNING + DURATION
	warning_fan.visible = age < WARNING and fmod(age, 0.3) < 0.22
