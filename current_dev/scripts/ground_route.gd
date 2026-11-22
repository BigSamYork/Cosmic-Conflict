class_name GroundRoute
extends RefCounted

const FORK: float = 1260.0
const REJOIN: float = 2940.0
const TURN_LENGTH: float = 420.0
const OFFSET: float = 84.0

var selected: bool = false
var locked: bool = false
var completed: bool = false

func advance(distance: float, lateral: float) -> bool:
	if locked or distance < FORK:
		return false
	selected = lateral > 0.0
	locked = true
	return true

func finish_hazard(distance: float, alive: bool) -> bool:
	if not selected or completed or not alive or distance < REJOIN:
		return false
	completed = true
	return true

static func lateral_offset(distance: float) -> float:
	var t: float = clampf(minf(distance - FORK, REJOIN - distance) / TURN_LENGTH, 0, 1)
	return OFFSET * t * t * t * (10.0 + t * (-15.0 + 6.0 * t))

static func point(distance: float) -> Vector3:
	return FlightState.rail_point(distance) + Vector3.RIGHT * lateral_offset(distance)

static func frame(distance: float) -> Transform3D:
	if distance <= FORK or distance >= REJOIN:
		return FlightState.rail_frame(distance)
	return Transform3D(Basis.looking_at((point(distance + 2.0) - point(distance)).normalized()), point(distance))
