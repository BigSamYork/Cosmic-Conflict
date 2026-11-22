class_name CockpitInstruments
extends Control

const SOURCE_SIZE := Vector2(1376, 768)
const ATLAS_SIZE := Vector2(1024, 512)
const PANELS: Dictionary = {
	"combiner": {"rect": Rect2(0, 0, 512, 128), "corners": [Vector2(504, 98), Vector2(871, 98), Vector2(847, 188), Vector2(528, 188)]},
	"left": {"rect": Rect2(0, 128, 256, 224), "corners": [Vector2(243, 628), Vector2(361, 578), Vector2(410, 692), Vector2(292, 742)]},
	"right": {"rect": Rect2(256, 128, 256, 224), "corners": [Vector2(1014, 578), Vector2(1132, 628), Vector2(1083, 742), Vector2(965, 692)]},
	"radar": {"rect": Rect2(512, 128, 256, 224), "corners": [Vector2(616, 633), Vector2(759, 633), Vector2(775, 764), Vector2(600, 764)]},
	"shield_gauges": {"rect": Rect2(512, 0, 256, 128), "corners": [Vector2(446, 616), Vector2(584, 616), Vector2(584, 698), Vector2(446, 698)]},
	"ammo_gauges": {"rect": Rect2(768, 0, 256, 128), "corners": [Vector2(791, 616), Vector2(929, 616), Vector2(929, 698), Vector2(791, 698)]}
}
const CYAN := Color("#77eaf2")
const WHITE := Color("#dcf9ff")
const MUTED := Color("#789ca8")
const AMBER := Color("#ffb568")

var flight: FlightState
var campaign: CampaignState
var phase_title: String = ""
var objective: String = ""
var incoming_count: int = 0
var boss_fraction: float = -1.0
var radar_contacts: Array[Dictionary] = []
var scope_range := 360.0
var intercept_seconds := INF
var collision_seconds := INF
var escape_side := 1.0
var fps: float = 60.0
var blast_warning: bool = false
var tractor_active: bool = false
var web_warning: bool = false
var radar_jam: float = 0.0
var thermal_warning: bool = false
var vent_warning: bool = false
var frost_warning: bool = false
var gate_warning: bool = false
var acid_warning: bool = false
var autopilot: bool = false
var transit_seconds: int = 0
var font: Font = ThemeDB.fallback_font

static func artwork_transform(viewport_size: Vector2) -> Transform2D:
	var factor: float = maxf(viewport_size.x / SOURCE_SIZE.x, viewport_size.y / SOURCE_SIZE.y)
	return Transform2D(Vector2(factor, 0), Vector2(0, factor), (viewport_size - SOURCE_SIZE * factor) * 0.5)

static func inverse_projection(corners: PackedVector2Array) -> Basis:
	assert(corners.size() == 4)
	var p: Vector2 = corners[0]
	var q: Vector2 = corners[1]
	var r: Vector2 = corners[2]
	var s: Vector2 = corners[3]
	var difference: Vector2 = p - q + r - s
	var g: float = 0.0
	var h: float = 0.0
	if difference.length_squared() > 0.00001:
		var a: Vector2 = q - r
		var b: Vector2 = s - r
		var determinant: float = a.cross(b)
		assert(absf(determinant) > 0.00001)
		g = difference.cross(b) / determinant
		h = a.cross(difference) / determinant
	var matrix := Basis(
		Vector3(q.x - p.x + g * q.x, q.y - p.y + g * q.y, g),
		Vector3(s.x - p.x + h * s.x, s.y - p.y + h * s.y, h),
		Vector3(p.x, p.y, 1.0))
	return matrix.inverse()

func _text(at: Vector2, text: String, pixels: int = 20, color: Color = WHITE) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)

func _draw() -> void:
	if flight == null:
		return
	for kind: String in PANELS:
		var rect: Rect2 = PANELS[kind]["rect"]
		draw_set_transform(rect.position)
		match kind:
			"combiner": _combiner()
			"left": _left_mfd()
			"right": _right_mfd()
			"radar": _radar()
			"shield_gauges": _gauges(flight.shields / flight.max_shields, CYAN)
			"ammo_gauges": _gauges(flight.heat / 100.0, VectorArt.HOSTILE if flight.overheat_remaining > 0 else AMBER)
	draw_set_transform(Vector2.ZERO)

func _combiner() -> void:
	_text(Vector2(40, 27), phase_title, 18, CYAN)
	_text(Vector2(40, 52), objective, 12, MUTED)
	var seconds: int = transit_seconds if autopilot else int(flight.elapsed)
	_text(Vector2(40, 92), "%02d:%02d" % [seconds / 60, seconds % 60], 29)
	if autopilot:
		_text(Vector2(146, 88), "AUTOPILOT / TIME TO ARRIVAL", 14, CYAN)
	elif flight.roll_remaining > 0:
		_text(Vector2(146, 88), "BARREL ROLL / DEFLECTING", 16, CYAN)
	elif intercept_seconds < 2.5:
		_text(Vector2(146, 88), "MISSILE %.1fs / BREAK OR ROLL [B]" % intercept_seconds, 15, VectorArt.HOSTILE)
	elif collision_seconds < 1.9:
		_text(Vector2(146, 88), "PULL %s / IMPACT %.1fs" % ["LEFT" if escape_side < 0 else "RIGHT", collision_seconds], 15, AMBER)
	elif blast_warning:
		_text(Vector2(146, 88), "VOLATILE BLAST / CLEAR THE AREA", 15, Color("#f3a2ee"))
	elif thermal_warning:
		_text(Vector2(146, 88), "THERMAL SWEEP / DODGE UP OR DOWN", 14, VectorArt.HOSTILE)
	elif acid_warning:
		_text(Vector2(146, 88), "CORROSIVE GEYSER / KEEP CLEAR", 14, AMBER)
	elif flight.frost_remaining > 0:
		_text(Vector2(146, 88), ("FROST / STEERING 65%% / %.1fs" if flight.frost_slowdown else "ICE IMPACT / %.1fs") % flight.frost_remaining, 14, CYAN)
	elif frost_warning:
		_text(Vector2(146, 88), "FROST FISSURE / KEEP CLEAR", 14, CYAN)
	elif gate_warning:
		_text(Vector2(146, 88), "SIDE LASER GATES / CENTER LANE CLEAR", 14, AMBER)
	elif web_warning:
		_text(Vector2(146, 88), "LASER WEB / SHOOT A NODE OR DODGE", 14, AMBER)
	elif tractor_active:
		_text(Vector2(146, 88), "TRACTOR LOCK / RECOVERING MINERALS", 14, CYAN)
	elif flight.evade_remaining > 0:
		_text(Vector2(146, 88), "EVASIVE SHIFT / DEFLECTING", 16, CYAN)
	elif incoming_count > 0:
		_text(Vector2(146, 88), "%02d INCOMING / SHOOT OR EVADE" % incoming_count, 16, VectorArt.HOSTILE)
	elif flight.overheat_remaining > 0:
		_text(Vector2(150, 88), "OVERHEAT / VENTING %.1fs" % flight.overheat_remaining, 16, VectorArt.HOSTILE)
	elif radar_jam > 0:
		_text(Vector2(146, 88), "TURRET TRACKING JAMMED / %.1fs" % radar_jam, 14, CYAN)
	elif vent_warning:
		_text(Vector2(146, 88), "HEAT VENT / KEEP CLEAR OF THE PLUME", 14, AMBER)
	elif flight.precision_hold:
		_text(Vector2(146, 88), "LINE HELD / GUNS FREE", 16, CYAN)
	else:
		_text(Vector2(150, 88), "FLIGHT DIRECTOR / PILOT CONTROL", 13, MUTED)
	var progress: float = boss_fraction if boss_fraction >= 0.0 else flight.elapsed / flight.duration
	draw_rect(Rect2(42, 108, 438, 4), Color("#264653"))
	draw_rect(Rect2(42, 108, 438 * progress, 4), AMBER)

func _left_mfd() -> void:
	_text(Vector2(17, 33), "TRAINING SHIELD" if flight.training else "DEFLECTOR", 22, CYAN)
	_text(Vector2(17, 79), "%03d / %03d" % [int(flight.shields), int(flight.max_shields)], 30)
	draw_line(Vector2(18, 98), Vector2(232, 98), MUTED, 1)
	_text(Vector2(17, 133), "HULL / SAFE" if flight.training else "HULL %03d / %03d" % [int(flight.hull), int(flight.max_hull)], 21)
	var has_flares: bool = campaign != null and campaign.countermeasures and not flight.training
	var reserve := "SURGE [X] READY" if flight.surge_remaining <= 0 else "SURGE %.0fs" % ceilf(flight.surge_remaining)
	if flight.training:
		reserve = "%02d SHIELD HITS" % flight.impacts
	elif flight.recharge_delay > 0.0 and flight.shields < flight.max_shields:
		reserve = "DEFLECTOR RESTART %.1fs" % flight.recharge_delay
	elif flight.shields < flight.max_shields:
		reserve = "CHARGING / " + reserve
	_text(Vector2(17, 170), reserve, 15, MUTED)
	var evasion: String = "SHIFT / B READY" if flight.evade_cooldown <= 0 else "SHIFT / B %.1fs" % flight.evade_cooldown
	if has_flares:
		evasion += (" / C ×%d" % campaign.flares if flight.countermeasure_cooldown <= 0 else " / C %.1f" % flight.countermeasure_cooldown)
	_text(Vector2(17, 201), evasion, 16, CYAN)

func _right_mfd() -> void:
	var primary: String = ["PULSE", "PLASMA", "TACHYON"][flight.primary_level]
	_text(Vector2(17, 30), primary + (" / VENTING" if flight.overheat_remaining > 0 else " / BURST" if flight.heat_governor else " / ONLINE"), 21, CYAN)
	_text(Vector2(17, 61), flight.primary_damage_label(), 24)
	_text(Vector2(17, 90), "HEAT %02d%% / %.1fs" % [int(flight.heat), flight.overheat_remaining] if not flight.training else "TRAINING / NO HEAT", 17, VectorArt.HOSTILE if flight.overheat_remaining > 0 else AMBER)
	var weapon: String = campaign.selected_secondary if campaign != null and not flight.training else "concussion"
	var label: String = "SWARM" if weapon == "swarm" else "EMP" if weapon == "emp" else "CONC"
	var ammo_cost: int = CampaignState.SECONDARIES[weapon]["ammo"]
	var launches := floori(float(flight.ammo) / ammo_cost)
	_text(Vector2(17, 119), "%s ×%d / %02d AMMO" % [label, launches, flight.ammo], 17, AMBER if launches <= 1 else WHITE)
	_text(Vector2(17, 149), "POWER / " + flight.power_mode.to_upper(), 16, CYAN)
	var credits: int = campaign.credits if campaign != null and not flight.training else 0
	_text(Vector2(17, 178), "%d CR" % credits, 20)
	_text(Vector2(17, 208), "%02d m/s   %03d FPS" % [int(flight.speed), int(fps)], 16, MUTED)

func _radar() -> void:
	var center := Vector2(128, 121)
	var radii := Vector2(94, 62)
	_text(Vector2(17, 29), "TAC / %dm" % roundi(scope_range), 22, CYAN)
	_text(Vector2(195, 27), "[R]", 15, MUTED)
	for i in range(1, 4):
		var line := PackedVector2Array()
		for j in range(49):
			line.append(center + Vector2.from_angle(j * TAU / 48) * radii * (float(i) / 3.0))
		draw_polyline(line, Color("#315462"), 1.2, true)
	draw_line(center - Vector2(radii.x, 0), center + Vector2(radii.x, 0), Color("#315462"))
	draw_line(center - Vector2(0, radii.y), center + Vector2(0, radii.y), Color("#315462"))
	_text(Vector2(108, 49), "FWD", 12, MUTED)
	var direction := Vector2.from_angle(fmod(flight.elapsed * 1.7, TAU))
	draw_line(center, center + direction * radii, Color(CYAN, 0.3), 1.6, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -5), center + Vector2(4, 4), center + Vector2(-4, 4)]), WHITE)
	if flight.radar_static_remaining > 0:
		var tick: float = floorf(flight.elapsed * 12)
		for i in range(28):
			var x: float = 26 + fposmod(sin(i * 31.7 + tick) * 1371, 198)
			var y: float = 51 + fposmod(sin(i * 13.9 - tick) * 913, 132)
			draw_line(Vector2(x, y), Vector2(x + 5, y), Color("#80ad53"), 1.3)
		_text(Vector2(17, 212), "SPORE STATIC / %.1fs" % flight.radar_static_remaining, 15, AMBER)
		return
	for i in range(radar_contacts.size() - 1, -1, -1):
		var contact := radar_contacts[i]
		var point: Vector2 = contact.point
		var at := center + point * radii
		var kind: StringName = contact.get("kind", &"hostile")
		var tint: Color = AMBER
		match kind:
			&"missile", &"hostile", &"danger":
				tint = VectorArt.HOSTILE
				draw_colored_polygon(PackedVector2Array([at + Vector2(0, -4), at + Vector2(4, 3), at + Vector2(-4, 3)]), tint)
				if kind == &"missile":
					draw_arc(at, 6, 0, TAU, 12, tint, 1.3, true)
			&"salvage":
				tint = Color("#81e7aa")
				draw_line(at - Vector2(4, 0), at + Vector2(4, 0), tint, 1.8)
				draw_line(at - Vector2(0, 4), at + Vector2(0, 4), tint, 1.8)
			&"objective":
				draw_rect(Rect2(at - Vector2(3.5, 3.5), Vector2(7, 7)), tint, false, 1.5)
			_:
				tint = MUTED
				draw_circle(at, 2.5, tint)
		if absf(contact.get("altitude", 0.0)) > 18.0:
			draw_line(at + Vector2(4, 0), at + Vector2(4, -5 * signf(contact.altitude)), tint, 1.3)
		if contact.get("selected", false):
			draw_arc(at, 8, 0, TAU, 20, WHITE, 1.4, true)
	var summary := "CLEAR"
	if not radar_contacts.is_empty():
		var first := radar_contacts[0]
		summary = "%s %dm" % [String(first.get("kind", "TRACK")).to_upper(), roundi(first.get("distance", 0.0))]
	_text(Vector2(17, 211), summary, 15, WHITE)
	_text(Vector2(192, 211), "%02d" % radar_contacts.size(), 16, CYAN)

func _gauges(fraction: float, tint: Color) -> void:
	for i in range(5):
		var level: float = clampf(fraction * 5.0 - i, 0.0, 1.0)
		var slot := Rect2((i + 0.5) * 256.0 / 5.0 - 8.0, 6, 16, 116)
		if level > 0.0:
			var fill := Rect2(slot.position.x, slot.end.y - slot.size.y * level, slot.size.x, slot.size.y * level)
			draw_rect(fill, Color(tint, 0.6))
			draw_line(Vector2(fill.get_center().x, fill.position.y), Vector2(fill.get_center().x, fill.end.y), tint, 3)
