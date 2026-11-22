class_name EncounterArt
extends RefCounted

const HULL := Color("#829aa4")
const TRIM := Color("#536b77")
const GOLD := Color("#d49c60")
const PARKING_BAYS := [Vector3(22, -6, -45), Vector3(38, -6, -55), Vector3(22, 5, -72), Vector3(38, 5, -72)]

static func warm_cache() -> void:
	for factory in [light_fighter, strike_fighter, delta_fighter, escort_gunship, web_drone, radar_dish, pirate_skirmisher, heat_plume, thermal_emitter, siege_runner, battleship, missile_turret, station]:
		var model: Node3D = factory.call()
		model.free()

static func heat_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("ignis_heat_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for blade in range(8):
		var angle: float = blade * TAU / 8
		for section in range(6):
			var a: float = section / 6.0
			var b: float = (section + 1) / 6.0
			var start := Vector3(cos(angle) * (0.7 + (1 - a) * 1.5), a, sin(angle) * (0.7 + (1 - a) * 1.5))
			var end := Vector3(cos(angle + 0.18 * sin(section + blade)) * (0.7 + (1 - b) * 1.5), b, sin(angle + 0.18 * sin(section + blade)) * (0.7 + (1 - b) * 1.5))
			var edge := Vector3(-sin(angle), 0, cos(angle)) * (0.45 - a * 0.3)
			batch.surface(PackedVector3Array([start - edge, start + edge, end + edge * 0.6, end - edge * 0.6]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#d84c25") if blade % 2 == 0 else Color("#ff9d38"))
			batch.line(start, end, Color("#ffd986"))
	return VectorArt.remember_model("ignis_heat_plume", batch.build())

static func thermal_emitter() -> Node3D:
	return FleetArt.model("boss_thermal_lens")

static func web_drone() -> Node3D:
	return FleetArt.model("web_drone")

static func pirate_skirmisher() -> Node3D:
	return FleetArt.model("pirate")

static func radar_dish(biological: bool = false) -> Node3D:
	return FleetArt.model("sensory_fan" if biological else "survey_dish", "ground")

static func radar_mast(height: float, biological: bool) -> Node3D:
	var mast := FleetArt.model("sensory_stalk" if biological else "radar_pedestal", "ground")
	mast.scale.y = (height - 2.35) / 8.0
	return mast

static func missile_turret() -> Node3D:
	return FleetArt.model("boss_launcher")

static func light_fighter() -> Node3D:
	return FleetArt.model("engine_scout")

static func strike_fighter() -> Node3D:
	return FleetArt.model("strike")

static func delta_fighter() -> Node3D:
	return FleetArt.model("delta")

static func siege_runner() -> Node3D:
	return FleetArt.model("siege")

static func escort_gunship() -> Node3D:
	return FleetArt.model("escort")

static func battleship() -> Node3D:
	return FleetArt.model("cruiser")

static func station() -> Node3D:
	return FleetArt.model("astra_terminal", "ground")
