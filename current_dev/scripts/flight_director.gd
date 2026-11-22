class_name FlightDirector
extends RefCounted

const TURN_RATE: float = 0.7
const DOGFIGHT_SPEED: float = 24.0
const BOSS_TURN_DURATION: float = 1.0
const UNDOCK_DURATION: float = 4.0
const ALIGN_DURATION: float = 4.0
const DESCENT_DURATION: float = 11.0
const VICTORY_DURATION: float = 1.0
const ASCENT_DURATION: float = 6.0
const BELT_TRANSFER_DURATION: float = 14.0
const STATION_APPROACH_DURATION: float = 4.0
const DOCK_DURATION: float = 4.0
const ASTEROID_SPEED: float = 48.0
const ASTEROID_DURATION: float = 60.0
const BELT_COAST_DURATION: float = 3.0
const BELT_CLIMB_DURATION: float = 10.0
const RADAR_RANGE: float = 220.0

var frame: Transform3D = FlightState.rail_frame(0)
var origin: Transform3D = frame
var tracked: EnemyFighter
var transition_time: float = 0.0
var transition_duration: float = 0.0
var transition_end: Transform3D
var control_points := PackedVector3Array()
var ground_course: Transform3D = Transform3D.IDENTITY
var ground_route: GroundRoute
var rotating: bool = false
var rotation_start: Quaternion
var follow_transition_path: bool = true

func begin_phase(phase: String, entry: Transform3D, canyon_distance: float = 0.0) -> void:
	origin = entry
	frame = entry
	tracked = null
	if phase.begins_with("ground"):
		frame = ground_course * FlightState.rail_frame(canyon_distance)
	elif phase == "asteroids":
		origin = entry * Transform3D(asteroid_frame(0).basis.inverse(), Vector3.ZERO)

func advance(phase: String, delta: float, distance: float, elapsed: float, targets: Array[RangeTarget]) -> void:
	match phase:
		"ground", "ground_boss":
			frame = ground_course * (GroundRoute.frame(distance) if ground_route != null and ground_route.selected else FlightState.rail_frame(distance))
		"orbit":
			if not is_instance_valid(tracked) or tracked.destroyed or tracked.expired:
				tracked = select_target(frame, targets)
			if is_instance_valid(tracked):
				var direction: Vector3 = tracked.global_position - frame.origin
				if direction.length_squared() > 0.01:
					var horizontal: float = Vector2(direction.x, direction.z).length()
					direction.y = clampf(direction.y, -horizontal * 0.7, horizontal * 0.7)
					if direction.length_squared() < 0.0001:
						direction = -frame.basis.z
					var desired: Quaternion = Basis.looking_at(direction.normalized(), Vector3.UP).get_rotation_quaternion()
					var current: Quaternion = frame.basis.get_rotation_quaternion()
					var angle: float = current.angle_to(desired)
					frame.basis = Basis(current.slerp(desired, minf(1.0, TURN_RATE * delta / maxf(angle, 0.0001))))
			frame.origin -= frame.basis.z * DOGFIGHT_SPEED * delta
		"orbit_boss":
			frame = origin * Transform3D(Basis.IDENTITY, Vector3(0, 0, -elapsed * FlightState.SPEED))
		"asteroids":
			frame = origin * asteroid_frame(distance)

static func select_target(pilot: Transform3D, targets: Array[RangeTarget]) -> EnemyFighter:
	var best: EnemyFighter
	var score: float = INF
	for target in targets:
		if not target is EnemyFighter or not target.dogfight or target.destroyed or target.expired:
			continue
		var relative: Vector3 = target.global_position - pilot.origin
		var candidate: float = relative.length() + 55.0 * (1.0 - (-pilot.basis.z).dot(relative.normalized()))
		if candidate < score:
			best = target
			score = candidate
	return best

static func radar_position(pilot: Transform3D, location: Vector3) -> Vector2:
	var local: Vector3 = pilot.basis.inverse() * (location - pilot.origin)
	return (Vector2(local.x, local.z) / RADAR_RANGE).limit_length(1.0)

static func orbital_boss_entry(start: Transform3D) -> Transform3D:
	var forward: Vector3 = -start.basis.z
	var heading := Vector3(forward.x, 0, forward.z).normalized().rotated(Vector3.UP, -PI * 0.5)
	var intercept_leg: float = 30.0 * BOSS_TURN_DURATION
	return Transform3D(Basis.looking_at(heading), start.origin + (forward + heading) * intercept_leg)

static func asteroid_point(distance: float) -> Vector3:
	return Vector3(10.0 * sin(distance * 0.012), 5.0 * sin(distance * 0.017), -distance)

static func asteroid_frame(distance: float) -> Transform3D:
	var tangent: Vector3 = (asteroid_point(distance + 0.5) - asteroid_point(distance - 0.5)).normalized()
	return Transform3D(Basis.looking_at(tangent), asteroid_point(distance))

static func asteroid_station(course: Transform3D, distance: float) -> Transform3D:
	var coast_end: Transform3D = course * asteroid_frame(distance + ASTEROID_SPEED * BELT_COAST_DURATION)
	var station: Transform3D = coast_end * Transform3D(Basis.IDENTITY, Vector3(0, 0, -850))
	station.origin.y = coast_end.origin.y + 520
	return station

static func transition_path(start: Transform3D, end: Transform3D, duration: float, start_speed: float, end_speed: float) -> PackedVector3Array:
	var transit := FlightDirector.new()
	transit.frame = start
	transit.begin_transition(end, duration, start_speed, end_speed)
	var points := PackedVector3Array([start.origin])
	for _i in range(90):
		transit.advance_transition(duration / 90)
		points.append(transit.frame.origin)
	return points

func begin_transition(end: Transform3D, duration: float, start_speed: float, end_speed: float, follow_path: bool = true) -> void:
	rotating = false
	follow_transition_path = follow_path
	rotation_start = frame.basis.get_rotation_quaternion()
	transition_time = 0.0
	transition_duration = duration
	transition_end = end
	control_points = PackedVector3Array([
		frame.origin,
		frame.origin - frame.basis.z * start_speed * duration / 3.0,
		end.origin + end.basis.z * end_speed * duration / 3.0,
		end.origin])

func begin_turn(end_basis: Basis, duration: float) -> void:
	rotating = true
	transition_time = 0
	transition_duration = duration
	transition_end = Transform3D(end_basis, frame.origin)
	rotation_start = frame.basis.get_rotation_quaternion()

func advance_transition(delta: float) -> bool:
	transition_time = minf(transition_duration, transition_time + delta)
	var t: float = transition_time / transition_duration
	if rotating:
		frame.basis = Basis(rotation_start.slerp(transition_end.basis.get_rotation_quaternion(), smoothstep(0, 1, t)))
		if transition_time >= transition_duration:
			frame = transition_end
			return true
		return false
	var a: Vector3 = control_points[0].lerp(control_points[1], t)
	var b: Vector3 = control_points[1].lerp(control_points[2], t)
	var c: Vector3 = control_points[2].lerp(control_points[3], t)
	var d: Vector3 = a.lerp(b, t)
	var e: Vector3 = b.lerp(c, t)
	frame.origin = d.lerp(e, t)
	if not follow_transition_path:
		frame.basis = Basis(rotation_start.slerp(transition_end.basis.get_rotation_quaternion(), smoothstep(0, 1, t)))
	elif d.distance_squared_to(e) > 0.000001:
		frame.basis = Basis.looking_at((e - d).normalized(), Vector3.UP)
	if transition_time >= transition_duration:
		frame = transition_end
		return true
	return false
