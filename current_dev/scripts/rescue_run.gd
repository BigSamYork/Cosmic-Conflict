extends Node3D

## Middle surface encounter on a colony's first rescue. Its result travels
## with the sortie; only a successful docking adds it to Astra's manifest.
signal cue(id: String)
signal sound_requested(id: String)
const OUTCOME_SOUNDS := {
	"mold": "rescue_mold", "converter": "rescue_converter", "pallet": "rescue_reeds",
	"cradle": "rescue_tow", "relay": "rescue_relay", "courier": "patrol_freight",
	"backup": "patrol_failed",
}
const ENTRY := 1940.0
const END := ENTRY + 260.0
const INTRO := {
	"ignis": ["ignis_ready", "ignis_short", "ignis_mold"],
	"cryo": ["cryo_transport", "cryo_socket", "cryo_tender"],
	"xylo": ["xylo_plants", "xylo_reeds", "xylo_pods"],
	"thalassa": ["thalassa_tug", "thalassa_empty", "thalassa_listen", "thalassa_line"],
	"kharon": ["kharon_wire", "kharon_stay", "kharon_fork"],
}
const OBJECTIVES := {
	"ignis": "APPRENTICE'S CARRIER / CLEAR THE MARKED BATTERY",
	"cryo": "HOLD AT TENDER LIGHT / TRANSFER POWER UNIT",
	"xylo": "SCOOP THE GREEN REED PALLET",
	"thalassa": "HOLD TUG WING LIGHT / GUIDE THE TOW CRADLE",
	"kharon": "FLY COVER AT THE COURIER'S WING LIGHT"
}
var beat := 0
var prompt := ""
var cargo: Node3D
var marker: Label3D
var battery: GroundTurret
var walker_effect: Node3D
var formation := 0.0
var knock_count := 0
signal knock

func _label(parent: Node3D, text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 4.5
	label.pixel_size = 0.035
	label.font_size = 45
	label.modulate = Color("#99f8ce")
	parent.add_child(label)
	return label

func advance(delta: float, previous: Vector3, pilot: Vector3, state: CampaignState, flight: FlightState, route: GroundRoute) -> String:
	var sector := state.sector
	var distance := flight.distance
	if flight.hull <= 0 or delta <= 0: return ""
	var marks: Array = [ENTRY - 800, ENTRY - 570, ENTRY - 330, ENTRY - 95]
	if sector == "kharon": marks = [740.0, 960.0, 1170.0]
	while beat < INTRO[sector].size() and distance >= marks[beat]:
		cue.emit(INTRO[sector][beat])
		beat += 1
	if sector == "thalassa" and beat >= 3:
		while knock_count < 3 and distance >= ENTRY - 170 + knock_count * 18:
			knock.emit()
			knock_count += 1
	if distance < ENTRY - 330: return ""
	var rail := GroundRoute.frame(ENTRY) if route.selected else FlightState.rail_frame(ENTRY)
	var walker_route := sector == "kharon" and route.selected
	if cargo == null:
		prompt = OBJECTIVES[sector] if not walker_route else "RELAY / DISABLE THE SIEGE WALKER"
		cargo = Node3D.new()
		add_child(cargo)
		cargo.add_child(FleetArt.model("survival_pod", "ground") if sector == "xylo" else FleetArt.model("traffic"))
		marker = _label(cargo, {"ignis":"MOLD CARRIER", "cryo":"POWER TENDER", "xylo":"AIR REEDS", "thalassa":"TOW CRADLE", "kharon":"PAD COURIER"}.get(sector))
		if sector == "ignis":
			battery = GroundTurret.new()
			battery.sector = sector
			battery.travel = ENTRY
			add_child(battery)
			battery.transform = rail.translated_local(Vector3(-10, -2, 0))
			_label(battery, "DISABLE")
		if walker_route:
			walker_effect = preload("res://scripts/igneous_hazard.gd").new()
			walker_effect.sector = sector
			walker_effect.walker_encounter = true
			add_child(walker_effect)
			var at := rail.translated_local(Vector3(9, 0, 0)).origin
			at.y = FrontierArt.floor_point(at.x - FlightState.rail_point(-at.z).x, -at.z, sector).y
			walker_effect.position = at
			marker.text = "HARDWIRE RELAY"
	var traveled := clampf(distance - ENTRY + 12, 0, 215)
	var along := ENTRY if sector == "xylo" or walker_route else ENTRY + traveled
	var frame := GroundRoute.frame(along) if route.selected else FlightState.rail_frame(along)
	cargo.transform = frame.translated_local(Vector3(6, 2, 0))
	if walker_route:
		walker_effect.advance_event(clampf((distance - ENTRY + 330) / 90, 0, 5.5), false)
		if walker_effect.walker.destroyed and walker_effect.walker.last_age >= walker_effect.walker.disabled_at + 0.7:
			return _resolve("relay", "kharon_relay")
	elif sector == "ignis":
		if not battery.destroyed: battery.advance(delta, pilot, (pilot - previous) / delta)
		if battery.destroyed: return _resolve("mold", "ignis_clear")
	elif sector == "xylo":
		var contact := Geometry3D.get_closest_point_to_segment(cargo.global_position, previous, pilot)
		if contact.distance_to(cargo.global_position) < 4.2: return _resolve("pallet", "xylo_loaded")
	else:
		var local := cargo.to_local(pilot)
		if Vector2(local.x + 5.0, local.y).length() < 4.5 and absf(local.z) < 20.0:
			formation += delta
		else:
			formation = maxf(0, formation - delta * 0.5)
		marker.text = "%s / %d%%" % [prompt, mini(100, roundi(formation * 50))]
		if formation >= 2.0:
			match sector:
				"cryo": return _resolve("converter", "cryo_test")
				"thalassa": return _resolve("cradle", "thalassa_coupled")
				"kharon": return _resolve("courier", "kharon_pad")
	if distance > END:
		return _resolve("backup", sector + "_backup")
	return ""

func _resolve(outcome: String, line: String) -> String:
	prompt = ""
	cue.emit(line)
	sound_requested.emit(OUTCOME_SOUNDS[outcome])
	hide()
	queue_free()
	return outcome
