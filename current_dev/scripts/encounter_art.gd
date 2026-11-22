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
	var cached: Node3D = VectorArt.cached_model("station")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 54, 4, -2), Vector3(12, 46, 166), HULL)
		batch.box(Vector3(0, -19 if side < 0 else 27, -2), Vector3(96, 6, 166), HULL)
		for z in range(-72, 81, 16):
			batch.box(Vector3(side * 47.8, 4, z), Vector3(0.3, 40, 1.2), VectorArt.CYAN)
			batch.box(Vector3(0, -15.8 if side < 0 else 23.8, z), Vector3(94, 0.3, 1.2), GOLD)
			batch.line(Vector3(side * 14, -15.7, z), Vector3(side * 44, -15.7, z), TRIM)
		for bay: Vector3 in PARKING_BAYS:
			var at := Vector3(side * bay.x, bay.y - 2.9, bay.z)
			batch.box(at, Vector3(16, 1, 24), TRIM, Color("#162c39"))
			batch.outline(PackedVector3Array([at + Vector3(-7.5, 0.6, -11), at + Vector3(7.5, 0.6, -11), at + Vector3(7.5, 0.6, 11), at + Vector3(-7.5, 0.6, 11)]), VectorArt.CYAN)
			var height: float = at.y + 16
			for x in [-7.0, 7.0]:
				batch.box(Vector3(at.x + x, -16 + height * 0.5, at.z), Vector3(0.7, height, 1.0), GOLD)
			batch.box(Vector3(side * 44, at.y, at.z), Vector3(6, 1, 24), TRIM)
		for i in range(6):
			batch.box(Vector3(side * (65 + i * 6), -2, -8), Vector3(5, 0.5, 55), Color("#446d94"))
	batch.box(Vector3(0, 4, -85), Vector3(96, 40, 1), TRIM)
	batch.box(Vector3(0, 4, -84.4), Vector3(22, 18, 0.3), VectorArt.CYAN, Color("#102532"))
	for i in range(64):
		var a: float = i * TAU / 64
		var b: float = (i + 1) * TAU / 64
		var points := PackedVector3Array()
		for z in [82.0, 58.0]:
			for entry in [Vector2(a, 100), Vector2(a, 128), Vector2(b, 128), Vector2(b, 100)]:
				points.append(Vector3(cos(entry.x) * entry.y, 4 + sin(entry.x) * entry.y, z))
		batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3, 4, 7, 6, 4, 6, 5, 1, 5, 6, 1, 6, 2, 0, 3, 7, 0, 7, 4]), Color("#172a34") if i % 2 == 0 else Color("#11212d"))
		batch.outline(PackedVector3Array([points[0], points[1], points[2], points[3]]), TRIM)
	for radius in [100.0, 104.0, 124.0, 128.0]:
		batch.ring(Vector3(0, 4, 82.1), radius, VectorArt.CYAN if radius < 110 else GOLD, 96)
		batch.ring(Vector3(0, 4, 57.9), radius, TRIM, 96)
	for i in range(24):
		var angle: float = (i + 0.5) * TAU / 24
		var rotation := Basis(Vector3.BACK, angle - PI * 0.5)
		var at := Vector3(cos(angle) * 114, 4 + sin(angle) * 114, 84)
		batch.box(at, Vector3(14, 12, 4), HULL, Color("#243641"), rotation)
		batch.box(at + Vector3.BACK * 2.2, Vector3(9, 7, 0.4), GOLD, Color("#0c1720"), rotation)
		for slot in range(4):
			var panel: Vector3 = at + rotation * Vector3(-4.5 + slot * 3, 0, 2.6)
			batch.box(panel, Vector3(0.9, 4.5, 0.3), VectorArt.CYAN if slot != 3 else VectorArt.AMBER, Color("#122a36"), rotation)
		for side in [-1.0, 1.0]:
			batch.box(at + rotation * Vector3(side * 9, 0, 0), Vector3(2.2, 8, 8), TRIM, Color("#111c25"), rotation)
		if i % 3 == 0:
			var attachment: float = minf(60.0 / maxf(0.001, absf(cos(angle))), 26.0 / maxf(0.001, absf(sin(angle))))
			var inner := Vector3(cos(angle) * attachment, 4 + sin(angle) * attachment, 25)
			var outer := Vector3(cos(angle) * 100, 4 + sin(angle) * 100, 58)
			batch.truss(inner, outer, 3.5, HULL, 8)
	# The central opening and interior have no front wall.
	for z in range(-72, 155, 12):
		for side in [-1.0, 1.0]:
			batch.box(Vector3(side * 10, -15.4, z), Vector3(0.5, 0.5, 4), VectorArt.CYAN)
	return VectorArt.remember_model("station", batch.build())
