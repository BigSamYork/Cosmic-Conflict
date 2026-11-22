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
	else:
		_text(Vector2(150, 88), "WEAPONS READY / FLIGHT CORRIDOR ACTIVE", 12, MUTED)
	var progress: float = boss_fraction if boss_fraction >= 0.0 else flight.elapsed / flight.duration
	draw_rect(Rect2(42, 108, 438, 4), Color("#264653"))
	draw_rect(Rect2(42, 108, 438 * progress, 4), AMBER)

func _left_mfd() -> void:
	_text(Vector2(17, 33), "TRAINING SHIELD" if flight.training else "DEFLECTOR", 22, CYAN)
	_text(Vector2(17, 79), "%03d / %03d" % [int(flight.shields), int(flight.max_shields)], 30)
	draw_line(Vector2(18, 98), Vector2(232, 98), MUTED, 1)
	_text(Vector2(17, 133), "HULL / SAFE" if flight.training else "HULL %03d / %03d" % [int(flight.hull), int(flight.max_hull)], 21)
	var has_flares: bool = campaign != null and campaign.countermeasures and not flight.training
	_text(Vector2(17, 170), "HITS %02d / FLARES %d" % [flight.impacts, campaign.flares] if has_flares else "%02d SHIELD HITS" % flight.impacts, 17, MUTED)
	var evasion: String = "SHIFT / READY" if flight.evade_cooldown <= 0 else "SHIFT / %.1fs" % flight.evade_cooldown
	if has_flares:
		evasion = ("SHIFT RDY" if flight.evade_cooldown <= 0 else "SHIFT %.1f" % flight.evade_cooldown) + (" / C RDY" if flight.countermeasure_cooldown <= 0 else " / C %.1f" % flight.countermeasure_cooldown)
	_text(Vector2(17, 201), evasion, 16, CYAN)

func _right_mfd() -> void:
	var primary: String = ["PULSE", "PLASMA", "TACHYON"][flight.primary_level]
	_text(Vector2(17, 30), primary + (" / VENTING" if flight.overheat_remaining > 0 else " / ONLINE"), 21, CYAN)
	_text(Vector2(17, 61), flight.primary_damage_label(), 24)
	_text(Vector2(17, 90), "HEAT %02d%% / %.1fs" % [int(flight.heat), flight.overheat_remaining] if not flight.training else "TRAINING / NO HEAT", 17, VectorArt.HOSTILE if flight.overheat_remaining > 0 else AMBER)
	var weapon: String = campaign.selected_secondary if campaign != null and not flight.training else "concussion"
	var label: String = "SWARM" if weapon == "swarm" else "EMP" if weapon == "emp" else "CONC"
	_text(Vector2(17, 119), "%s %02d / COST %d [SPACE]" % [label, flight.ammo, CampaignState.SECONDARIES[weapon]["ammo"]], 16)
	_text(Vector2(17, 149), "POWER / " + flight.power_mode.to_upper(), 16, CYAN)
	var credits: int = campaign.credits if campaign != null and not flight.training else 0
	_text(Vector2(17, 178), "%d CR" % credits, 20)
	_text(Vector2(17, 208), "%02d m/s   %03d FPS" % [int(flight.speed), int(fps)], 16, MUTED)

func _radar() -> void:
	_text(Vector2(22, 30), "FLIGHT VECTOR", 21, CYAN)
	var rect := Rect2(24, 48, 208, 140)
	draw_rect(rect, Color("#315968"), false, 1.5)
	draw_line(Vector2(128, 48), Vector2(128, 188), Color("#315968"))
	draw_line(Vector2(24, 118), Vector2(232, 118), Color("#315968"))
	for radius in [30.0, 55.0]:
		draw_arc(rect.get_center(), radius, 0, TAU, 48, Color("#25434f"), 1, true)
	var marker: Vector2 = rect.get_center() + Vector2(clampf(flight.offset.x / flight.lateral_limit, -1, 1) * 95, -flight.offset.y / FlightState.CORRIDOR.y * 62)
	draw_colored_polygon(PackedVector2Array([marker + Vector2(0, -7), marker + Vector2(6, 5), marker + Vector2(-6, 5)]), CYAN)
	if flight.radar_static_remaining > 0:
		var tick: float = floorf(flight.elapsed * 12)
		for i in range(28):
			var x: float = 26 + fposmod(sin(i * 31.7 + tick) * 1371, 198)
			var y: float = 51 + fposmod(sin(i * 13.9 - tick) * 913, 132)
			draw_line(Vector2(x, y), Vector2(x + 5, y), Color("#80ad53"), 1.3)
		_text(Vector2(23, 212), "RADAR / SPORE STATIC %.1fs" % flight.radar_static_remaining, 12, AMBER)
		return
	for contact in radar_contacts:
		var point: Vector2 = contact["point"]
		var at: Vector2 = rect.get_center() + point * Vector2(94, 60)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(4, 4), at + Vector2(-4, 4)]), Color("#ff465d"))
		if contact["selected"]:
			draw_arc(at, 8, 0, TAU, 20, AMBER, 1.2, true)
	_text(Vector2(23, 212), "RED / HOSTILES  GOLD / LOCK" if not radar_contacts.is_empty() else "BOUNDED X / Y CONTROL", 12, MUTED)

func _gauges(fraction: float, tint: Color) -> void:
	for i in range(5):
		var level: float = clampf(fraction * 5.0 - i, 0.0, 1.0)
		var slot := Rect2((i + 0.5) * 256.0 / 5.0 - 8.0, 6, 16, 116)
		if level > 0.0:
			var fill := Rect2(slot.position.x, slot.end.y - slot.size.y * level, slot.size.x, slot.size.y * level)
			draw_rect(fill, Color(tint, 0.6))
			draw_line(Vector2(fill.get_center().x, fill.position.y), Vector2(fill.get_center().x, fill.end.y), tint, 3)
