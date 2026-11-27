extends Node3D

signal cue(id: String)

const ENTRY := 1940.0
const EXIT := ENTRY + 280
var flares: Array[Label3D] = []
var beat := 0
var boarded := 0
var shots_at_handoff := 0
var diverted := false
var entered := false
var divert_mark := 0.0
var prompt := ""

func _ready() -> void:
	var tube := CylinderMesh.new()
	tube.top_radius = 0.24
	tube.bottom_radius = 0.38
	tube.height = 3.0
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color(2.2, 0.95, 0.22)
	for i in 3:
		var flare := Label3D.new()
		flare.text = "FLARE %d" % (i + 1)
		flare.font_size = 84
		flare.pixel_size = 0.055
		flare.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		flare.modulate = Color("#ffb453")
		flare.outline_size = 9
		add_child(flare)
		var wick := MeshInstance3D.new()
		wick.mesh = tube
		wick.material_override = ink
		wick.position.y = -3.0
		flare.add_child(wick)
		flares.append(flare)
	hide()

func advance(distance: float, previous: Vector3, pilot: Vector3, route: GroundRoute, shots: int) -> String:
	if beat == 5 or distance < ENTRY - 510: return ""
	var rail := GroundRoute.frame(ENTRY) if route.selected else FlightState.rail_frame(ENTRY)
	var terminal := GroundRoute.frame(EXIT + 65) if route.selected else FlightState.rail_frame(EXIT + 65)
	for i in 3:
		flares[i].position = terminal * Vector3((i - 1) * 9, 5.0, 0)
	show()
	if beat == 0:
		prompt = "VESPERA TERMINAL / THREE GROUPS WAITING"
		cue.emit("clearance")
		beat = 1
	if beat == 1 and distance >= ENTRY - 345:
		cue.emit("refusal")
		beat = 2
	if beat == 2 and distance >= ENTRY - 120:
		cue.emit("handoff")
		prompt = "QUIET LANE / CENTER YOUR SHIP AND HOLD FIRE"
		shots_at_handoff = shots
		beat = 3
	if beat < 3: return ""
	if not entered and distance >= ENTRY - 4:
		var lane := to_global(rail.origin)
		entered = Geometry3D.get_closest_point_to_segment(lane, previous, pilot).distance_to(lane) <= 6.0
	if not diverted and (shots > shots_at_handoff or (not entered and distance > ENTRY + 8)):
		diverted = true
		divert_mark = distance
		cue.emit("divert")
	elif entered and beat == 3 and not diverted:
		cue.emit("crossing")
	if entered or diverted: beat = 4
	if beat == 4:
		# Each group boards at its own progress mark. Diverting pauses groups still on the platform.
		while boarded < 3 and distance >= ENTRY + 65 + boarded * 96 and (not diverted or distance >= divert_mark + 62):
			flares[boarded].hide()
			boarded += 1
		prompt = "%s / %d OF 3 GROUPS ABOARD" % ["COVERED RAMP" if diverted else "HOLD FIRE", boarded]
		if boarded == 3:
			beat = 5
			prompt = ""
			hide()
			return "covered" if diverted else "quiet"
	return ""
