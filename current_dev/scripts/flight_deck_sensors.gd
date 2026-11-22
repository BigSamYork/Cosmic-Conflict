class_name FlightDeckSensors
extends RefCounted

const RANGES := [180.0, 360.0, 720.0]
const UPDATE_INTERVAL := 0.10
const MAX_RETURNS := 28
const GUN_RANGE := 490.0

var range_index := 1
var returns: Array[Dictionary] = []
var range_m: float:
	get: return RANGES[range_index]
var intercept_seconds := INF
var collision_seconds := INF
var escape_side := 1.0
var lead_target: EnemyFighter
var lead_world := Vector3.ZERO
var below_horizon := 0.0
var horizon_bank := 0.0
var previous_time := -1.0
var previous_eye := Vector3.ZERO
var flight_id := 0
var last_range_index := -1
var previous_targets: Dictionary[int, Vector3] = {}

func cycle_range() -> void:
	range_index = (range_index + 1) % RANGES.size()

func scan(pilot: Camera3D, state: FlightState, targets: Array[RangeTarget], missiles: Array[EnemyMissile], pickups: Array[MineralPickup], supplies: Array, tracked: EnemyFighter, cursor: Vector2) -> void:
	var now := state.elapsed
	var fresh := flight_id != state.get_instance_id() or now < previous_time
	var dt := now - previous_time
	if not fresh and dt >= 0.0 and dt < UPDATE_INTERVAL and last_range_index == range_index:
		return
	if fresh:
		previous_targets.clear()
	var velocity := -pilot.global_basis.z * state.speed
	if not fresh and dt >= 0.001 and dt < 0.5:
		velocity = (pilot.global_position - previous_eye) / dt
	previous_eye = pilot.global_position
	previous_time = now
	flight_id = state.get_instance_id()
	last_range_index = range_index
	returns.clear()
	intercept_seconds = INF
	collision_seconds = INF
	lead_target = null
	var up := pilot.global_basis.inverse() * Vector3.UP
	horizon_bank = atan2(up.x, up.y)
	below_horizon = clampf(up.z, -1, 1)
	var next_positions: Dictionary[int, Vector3] = {}
	var best_aim_error := INF
	for target in targets:
		if target.destroyed or not target.visible or not target.guided_lockable:
			continue
		if (target is EnemyFighter or target is PirateSkirmisher or target is FallingIce) and target.expired:
			continue
		var relative := target.global_position - pilot.global_position
		if relative.length_squared() > maxf(range_m, GUN_RANGE) ** 2:
			continue
		var local := pilot.global_basis.inverse() * relative
		var kind := target_kind(target)
		_add_return(local, kind, target == tracked)
		if target is EggShip or target is Asteroid:
			var closest_time := relative.dot(velocity) / maxf(1.0, velocity.length_squared())
			if closest_time > 0 and closest_time < minf(collision_seconds, 1.9):
				var clearance := (relative - velocity * closest_time).length()
				if clearance < target.collision_radius() + state.collision_radius + 0.7:
					collision_seconds = closest_time
					escape_side = -1.0 if local.x > 0 else 1.0
		if state.primary_level == 1 and target is EnemyFighter and local.z < -1 and relative.length() < GUN_RANGE:
			var id := target.get_instance_id()
			next_positions[id] = target.global_position
			var aim_error := pilot.unproject_position(target.global_position).distance_squared_to(cursor)
			if aim_error < best_aim_error and previous_targets.has(id) and dt > 0.001 and dt < 0.5:
				var target_velocity := (target.global_position - previous_targets[id]) / dt
				var intercept := plasma_intercept(relative, target_velocity)
				if intercept > 0.0:
					lead_target = target
					lead_world = target.global_position + target_velocity * intercept
					best_aim_error = aim_error
	previous_targets = next_positions
	for missile in missiles:
		if not missile.active or missile.diverted:
			continue
		var relative := missile.global_position - pilot.global_position
		_add_return(pilot.global_basis.inverse() * relative, &"missile")
		var closing := missile.direction * EnemyMissile.SPEED - velocity
		var eta := -relative.dot(closing) / maxf(1.0, closing.length_squared())
		if eta > 0 and eta < minf(intercept_seconds, 4.0) and (relative + closing * eta).length() < state.collision_radius + 5.0:
			intercept_seconds = eta
	for cargo: MineralPickup in pickups:
		if cargo.active:
			_add_return(pilot.to_local(cargo.global_position), &"salvage")
	for supply: SupplyPickup in supplies:
		if supply.active:
			_add_return(pilot.to_local(supply.global_position), &"salvage")
	returns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.priority < b.priority)
	if returns.size() > MAX_RETURNS:
		returns.resize(MAX_RETURNS)

func _add_return(local: Vector3, kind: StringName, selected: bool = false) -> void:
	var distance := local.length()
	if distance > range_m or distance < 0.5:
		return
	var priority := distance / range_m
	if selected or kind == &"missile":
		priority -= 3.0
	elif kind == &"objective" or kind == &"salvage":
		priority -= 1.0
	returns.append({"point": Vector2(local.x, local.z) / range_m, "altitude": local.y, "distance": distance, "kind": kind, "selected": selected, "priority": priority})

static func target_kind(target: RangeTarget) -> StringName:
	if target is BossPart or target is DestructibleTower or target is RadarDish or target is WebNode or target is GateEmitter:
		return &"objective"
	if target is EggShip:
		return &"danger" if target.infested else &"salvage" if target.cargo else &"obstacle"
	if target is Asteroid:
		return &"danger" if target.volatile else &"salvage" if target.mineral else &"obstacle"
	if target is FallingIce:
		return &"obstacle"
	return &"hostile"

static func plasma_intercept(relative: Vector3, velocity: Vector3) -> float:
	# Solve |relative + velocity * t| = projectile_speed * t, then reject
	# intercepts beyond the gun's physical range.
	var a := velocity.length_squared() - PlasmaBolt.SPEED ** 2
	var b := 2.0 * relative.dot(velocity)
	var c := relative.length_squared()
	var t := -1.0
	if absf(a) < 0.001:
		if b < -0.001:
			t = -c / b
	else:
		var discriminant := b * b - 4.0 * a * c
		if discriminant >= 0:
			var first := (-b - sqrt(discriminant)) / (2.0 * a)
			var second := (-b + sqrt(discriminant)) / (2.0 * a)
			t = minf(first, second) if first > 0 and second > 0 else maxf(first, second)
	return t if t > 0 and t <= PlasmaBolt.RANGE / PlasmaBolt.SPEED else -1.0
