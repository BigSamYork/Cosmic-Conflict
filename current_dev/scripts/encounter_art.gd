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
	for dimensions in [Vector2(4.6, 18), Vector2(4.3, 12)]:
		var model: Node3D = reactor_nacelle(dimensions.x, dimensions.y)
		model.free()

static func reactor_nacelle(radius: float, length: float) -> Node3D:
	var key: String = "reactor-nacelle:%s:%s" % [radius, length]
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	engine(batch, Vector3.ZERO, radius, length)
	return VectorArt.remember_model(key, batch.build())

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
	var cached: Node3D = VectorArt.cached_model("thermal_emitter")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, Vector3(7, 5, 6), HULL, Color("#33231e"))
	for z in [-2.5, -1.0, 0.5, 2.0, 3.5]:
		batch.ring(Vector3(0, 0, z), 2.5, VectorArt.AMBER, 20)
		batch.ring(Vector3(0, 0, z), 1.7, VectorArt.HOSTILE, 20)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 4, 0, 0), Vector3(1, 4, 5), GOLD)
	batch.ring(Vector3(0, 0, 3.7), 0.8, VectorArt.CYAN, 16)
	return VectorArt.remember_model("thermal_emitter", batch.build())

static func web_drone() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("web_drone")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ship_hull(Vector3.ZERO, [Vector3(1.25, 0.65, -2), Vector3(1.7, 0.9, 0), Vector3(0.85, 0.5, 1.8)], HULL, Color("#332d42"))
	batch.ring(Vector3(0, 0, -2.05), 1.1, VectorArt.HOSTILE, 16)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 3.2, 0, 1), 0.6, 3.2)
		batch.truss(Vector3(side * 1.4, 0, -0.5), Vector3(side * 3.2, 0, -0.5), 0.6, GOLD, 3)
		batch.ship_hull(Vector3(side * 2.5, 0.8, 0), [Vector3(0.18, 0.15, -3.3), Vector3(0.72, 0.55, -0.6), Vector3(0.52, 0.54, 1.1)], VectorArt.HOSTILE, Color("#42303c"))
		for i in range(3):
			batch.ring(Vector3(side * 2.5, 1, 0.7 - i * 0.7), 0.5, VectorArt.AMBER, 12)
		batch.outline(PackedVector3Array([Vector3(side * 1.1, 0.8, -1.5), Vector3(side * 3.7, 2.1, 1), Vector3(side * 3.2, 0.8, 2)]), GOLD)
	batch.box(Vector3(0, 1, -0.6), Vector3(1.3, 0.7, 1.5), VectorArt.CYAN)
	return VectorArt.remember_model("web_drone", batch.build())

static func pirate_skirmisher() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("pirate_skirmisher")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var hull := PackedVector3Array([Vector3(0, 0, -2.0), Vector3(-1.5, -0.3, 1.0), Vector3(1.5, -0.3, 1.0), Vector3(0, 0.8, 0.7), Vector3(0, -0.6, 1.3)])
	batch.surface(hull, PackedInt32Array([0, 1, 3, 0, 3, 2, 0, 4, 1, 0, 2, 4, 1, 4, 2, 1, 2, 3]), Color("#382a22"))
	for pair in [[0, 1], [0, 2], [0, 3], [1, 3], [2, 3], [1, 4], [2, 4]]:
		batch.line(hull[pair[0]], hull[pair[1]], VectorArt.AMBER)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 0.8, 0, 0.7), 0.32, 1.3)
		batch.box(Vector3(side * 1.2, 0.1, -0.1), Vector3(0.25, 0.3, 1.5), VectorArt.HOSTILE)
	batch.box(Vector3(0, 0.5, -0.5), Vector3(0.6, 0.3, 0.8), VectorArt.CYAN)
	batch.ring(Vector3(0, 0.1, 1.4), 0.42, VectorArt.HOSTILE, 12)
	# Salvaged belly crate opposite a single long boarding prong.
	batch.box(Vector3(-1.05, -0.27, 0.1), Vector3(1, 0.94, 1.55), GOLD)
	batch.limb(Vector3(1.15, 0, 0.45), Vector3(1.5, -0.2, -2.0), 0.28, 0.08, HULL, 5)
	return VectorArt.remember_model("pirate_skirmisher", batch.build())

static func radar_dish() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("radar_dish")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var vertices := PackedVector3Array([Vector3(0, 0, -1.4)])
	var indices := PackedInt32Array()
	for ring in range(1, 5):
		var radius: float = ring * 1.1
		for sector in range(24):
			var angle: float = sector * TAU / 24
			vertices.append(Vector3(cos(angle) * radius, sin(angle) * radius, -1.4 + radius * radius * 0.11))
	for sector in range(24):
		var next: int = (sector + 1) % 24
		indices.append_array(PackedInt32Array([0, 1 + sector, 1 + next]))
		for ring in range(3):
			var a: int = 1 + ring * 24 + sector
			var b: int = 1 + ring * 24 + next
			indices.append_array(PackedInt32Array([a, b, a + 24, b, b + 24, a + 24]))
		if sector % 3 == 0:
			batch.line(vertices[0], vertices[1 + 72 + sector], VectorArt.CYAN)
	batch.surface(vertices, indices, Color("#15353c"))
	for ring in range(1, 5):
		var radius: float = ring * 1.1
		batch.ring(Vector3(0, 0, -1.4 + radius * radius * 0.11), radius, VectorArt.CYAN, 24)
	for side in [-1.0, 1.0]:
		batch.line(Vector3(side * 3.8, 0, 0.2), Vector3(0, 0, 3.4), GOLD)
	batch.box(Vector3(0, 0, 3.4), Vector3(1, 1, 1.2), VectorArt.AMBER)
	return VectorArt.remember_model("radar_dish", batch.build())

static func missile_turret() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("boss_missile_turret")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 0, 0.2), Vector3(7, 3.5, 4), HULL, Color("#242731"))
	for x in [-2.0, 0.0, 2.0]:
		for y in [-0.75, 0.75]:
			batch.tube(Vector3(x, y, -2.2), 0.65, 3.2, GOLD, 12)
			batch.ring(Vector3(x, y, -3.85), 0.47, VectorArt.HOSTILE, 12)
			batch.ring(Vector3(x, y, -3.87), 0.23, VectorArt.AMBER, 12)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 3.8, 0, 0.3), Vector3(0.7, 2.2, 3.5), GOLD)
		for i in range(5):
			batch.line(Vector3(side * 3.3, 1.8, -1.2 + i * 0.55), Vector3(side * 1.5, 1.8, -1.2 + i * 0.55), TRIM)
	return VectorArt.remember_model("boss_missile_turret", batch.build())

static func engine(batch: GeometryBatch, at: Vector3, radius: float, length: float) -> void:
	batch.tube(at, radius, length, HULL, 16, radius * 0.8)
	for i in range(5):
		batch.ring(at + Vector3(0, 0, -length * 0.35 + i * length * 0.17), radius * 1.02, TRIM, 16)
	var nozzle: Vector3 = at + Vector3(0, 0, length * 0.5 + radius * 0.3)
	batch.tube(nozzle, radius * 1.08, radius * 0.6, GOLD, 20, radius * 0.65)
	batch.ring(nozzle + Vector3(0, 0, radius * 0.31), radius * 0.83, VectorArt.AMBER, 20)
	batch.ring(nozzle + Vector3(0, 0, radius * 0.32), radius * 0.5, VectorArt.CYAN, 16)
	batch.ring(nozzle + Vector3(0, 0, radius * 0.33), radius * 0.22, VectorArt.AMBER, 12)
	for i in range(8):
		var angle: float = i * TAU / 8.0
		var radial := Vector3(cos(angle), sin(angle), 0)
		batch.line(nozzle + radial * radius * 0.52, nozzle + radial * radius * 0.8, GOLD)

static func light_fighter() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("engine_scout")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ship_hull(Vector3(0, 0.2, 0), [Vector3(0.65, 0.4, -3.3), Vector3(1.6, 0.8, -0.5), Vector3(1.35, 0.55, 2)], HULL, Color("#293e49"))
	batch.box(Vector3(0, 1.1, -0.6), Vector3(1.8, 0.8, 2.2), VectorArt.CYAN)
	for x in [-1.4, 0.0, 1.4]:
		engine(batch, Vector3(x, -0.2, 1.2), 0.58, 2.8)
	for side in [-1.0, 1.0]:
		batch.truss(Vector3(side * 1.5, 0.35, -0.5), Vector3(side * 4.0, 0.35, 0), 0.45, GOLD, 3)
		batch.ship_hull(Vector3(side * 3.65, 0.3, 0), [Vector3(0.15, 0.15, -1.5), Vector3(0.48, 1.0, -0.25), Vector3(0.28, 0.7, 0.95)], HULL, Color("#384954"))
		batch.tube(Vector3(side * 2, 0.3, -2.2), 0.15, 2.3, VectorArt.HOSTILE, 8)
	batch.line(Vector3(0, 1.5, 0), Vector3(0, 2.2, -0.1), GOLD)
	return VectorArt.remember_model("engine_scout", batch.build())

static func strike_fighter() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("swept_fighter")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var body := PackedVector3Array([Vector3(-0.65, -0.5, -5.8), Vector3(0.65, -0.5, -5.8), Vector3(-1.3, -0.7, 3.2), Vector3(1.3, -0.7, 3.2), Vector3(-0.55, 0.6, -4.7), Vector3(0.55, 0.6, -4.7), Vector3(-1.2, 0.9, 2.5), Vector3(1.2, 0.9, 2.5)])
	batch.surface(body, PackedInt32Array([0, 1, 4, 1, 5, 4, 4, 5, 6, 5, 7, 6, 0, 4, 2, 4, 6, 2, 1, 3, 5, 5, 3, 7, 2, 6, 3, 6, 7, 3]), Color("#152b35"))
	for pair in [[0, 1], [0, 2], [1, 3], [0, 4], [1, 5], [4, 5], [4, 6], [5, 7], [6, 7], [2, 6], [3, 7]]:
		batch.line(body[pair[0]], body[pair[1]], HULL)
	var canopy := PackedVector3Array([Vector3(-0.55, 0.7, -4), Vector3(0.55, 0.7, -4), Vector3(0.8, 1.65, -1.6), Vector3(-0.8, 1.65, -1.6)])
	batch.surface(canopy, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#0c202a"))
	batch.outline(canopy, VectorArt.CYAN)
	batch.line(Vector3(0, 0.7, -4), Vector3(0, 1.65, -1.6), HULL)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 1.9, 0.65, 1.4), 0.85, 4.0)
		var wing := PackedVector3Array([Vector3(side * 1.2, 0, -1.7), Vector3(side * 5.8, -0.55, 0.6), Vector3(side * 6.2, 0.65, 3.5), Vector3(side * 2.0, 0.05, 2.7)])
		batch.surface(wing, PackedInt32Array([0, 1, 3, 1, 2, 3]), Color("#19313c"))
		batch.outline(wing, HULL)
		for i in range(1, 4):
			var t: float = i / 4.0
			batch.line(wing[0].lerp(wing[1], t), wing[3].lerp(wing[1], t), TRIM)
		var fin := PackedVector3Array([Vector3(side * 1.9, 1.0, 0.6), Vector3(side * 2.8, 3.0, 3.3), Vector3(side * 1.9, 1.1, 3.4)])
		batch.surface(fin, PackedInt32Array([0, 1, 2]), Color("#203442"))
		batch.outline(fin, HULL)
		batch.tube(Vector3(side * 3.1, -0.5, 0.4), 0.42, 2.2, GOLD, 10)
		batch.tube(Vector3(side * 3.1, -0.5, -1.2), 0.16, 1.3, VectorArt.HOSTILE, 8)
		for i in range(4):
			batch.line(Vector3(side * 1.25, 0.95, -0.7 + i * 0.55), Vector3(side * 2.55, 0.95, -0.7 + i * 0.55), TRIM)
	return VectorArt.remember_model("swept_fighter", batch.build())

static func delta_fighter() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("delta_fighter")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var top := PackedVector3Array([Vector3(0, 0.1, -6.5), Vector3(-4.6, 0, 3.2), Vector3(-2.2, 0.3, 4.1), Vector3(2.2, 0.3, 4.1), Vector3(4.6, 0, 3.2)])
	var bottom := PackedVector3Array()
	for point in top:
		bottom.append(point + Vector3.DOWN * 0.65)
	batch.surface(top, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4]), Color("#1b303a"))
	batch.surface(bottom, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4]), Color("#111e2a"))
	batch.outline(top, HULL)
	batch.outline(bottom, TRIM)
	for i in range(5):
		var next: int = (i + 1) % 5
		batch.surface(PackedVector3Array([top[i], top[next], bottom[next], bottom[i]]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#172a34"))
	var glass := PackedVector3Array([Vector3(0, 0.6, -1.4), Vector3(-0.9, 0.8, 0.1), Vector3(-0.7, 1.1, 2.8), Vector3(0.7, 1.1, 2.8), Vector3(0.9, 0.8, 0.1)])
	batch.surface(glass, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4]), Color("#0a202e"))
	batch.outline(glass, VectorArt.CYAN)
	batch.line(Vector3(0, 0.15, -6.5), Vector3(0, 0.6, -1.4), GOLD)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 1.9, 0.3, 3.3), 0.58, 1.7)
		batch.limb(Vector3(side * 3.8, 0, 2.85), Vector3(side * 4.4, -0.75, 0.25), 0.45, 0.12, HULL, 4)
		batch.outline(PackedVector3Array([Vector3(side * 1.1, 0.18, -2.6), Vector3(side * 3.9, 0.18, 2.7), Vector3(side * 2.8, 0.18, 3.0), Vector3(side * 1.15, 0.18, 0.2)]), TRIM)
		for i in range(4):
			batch.line(Vector3(side * (0.8 + i * 0.45), 0.2, -3.2 + i * 1.3), Vector3(side * (1.45 + i * 0.6), 0.2, -3.2 + i * 1.3), HULL)
		batch.tube(Vector3(side * 0.65, 0.15, -3.0), 0.11, 1.7, VectorArt.HOSTILE, 8)
	return VectorArt.remember_model("delta_fighter", batch.build())

static func siege_runner() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("siege_runner")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 2, -4), Vector3(31, 8, 32), HULL, Color("#16222a"))
	batch.box(Vector3(0, 9, -10), Vector3(16, 7, 13), GOLD)
	batch.box(Vector3(0, 13, -12), Vector3(10, 2.0, 8), HULL)
	for x in [-11.0, 0.0, 11.0]:
		batch.box(Vector3(x, 0, 12.1), Vector3(8.5, 8, 0.3), TRIM, Color("#080b12"))
		batch.ring(Vector3(x, 0, 12.3), 3.7, TRIM, 20)
		for i in range(5):
			batch.box(Vector3(x, 5.2, -7 + i * 3.3), Vector3(7.5, 0.6, 1.1), TRIM)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 22, 0.2, 9), 2.5, 12)
		batch.truss(Vector3(side * 10, 9, -8), Vector3(side * 29, 9, -4), 2.8, HULL, 7)
		batch.truss(Vector3(side * 13, 5, 10), Vector3(side * 19, 9, 14), 2.0, HULL, 3)
		for i in range(4):
			batch.line(Vector3(side * (16 + i * 2.5), 6, 8), Vector3(side * (17 + i * 2.5), 9, 8), GOLD)
		batch.ring(Vector3(side * 9, 13, -9), 2.3, HULL, 14)
		batch.line(Vector3(side * 9, 10, -9), Vector3(side * 9, 16, -9), GOLD)
	for i in range(6):
		batch.box(Vector3(-6.5 + i * 2.6, 10, 2.6), Vector3(1.5, 1.2, 0.18), VectorArt.CYAN)
		batch.line(Vector3(-6.5 + i * 2.6, 6, 1), Vector3(-6.5 + i * 2.6, 6, 11), GOLD)
	batch.box(Vector3(0, 8.5, 2.65), Vector3(4, 3.5, 0.2), HULL)
	batch.line(Vector3(0, 14, -12), Vector3(0, 22, -13), GOLD)
	batch.truss(Vector3(-7, 14, -8), Vector3(7, 14, -8), 0.8, HULL, 5)
	return VectorArt.remember_model("siege_runner", batch.build())

static func escort_gunship() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("escort_gunship")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var deck := PackedVector3Array([Vector3(-1.7, 0, -8), Vector3(1.7, 0, -8), Vector3(4.2, 0, 5), Vector3(-4.2, 0, 5)])
	var lower := PackedVector3Array()
	for point in deck:
		lower.append(point + Vector3.DOWN * 1.8)
	batch.surface(deck, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#20333d"))
	batch.surface(lower, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#14232c"))
	batch.outline(deck, HULL)
	batch.outline(lower, HULL)
	for i in range(4):
		var next: int = (i + 1) % 4
		batch.surface(PackedVector3Array([deck[i], deck[next], lower[next], lower[i]]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#192b35"))
		batch.line(deck[i], lower[i], TRIM)
	# Side island and a low boat deck rather than a centered stack.
	batch.ship_hull(Vector3(-1.45, 0.8, 0), [Vector3(0.55, 0.6, -1), Vector3(1.35, 1.2, 1.2), Vector3(1.1, 1, 4.6)], HULL, Color("#33454e"))
	batch.box(Vector3(-1.45, 2.25, 2.8), Vector3(2.5, 0.75, 2.3), GOLD)
	batch.box(Vector3(1.65, 0.22, 2), Vector3(2, 0.45, 4.8), TRIM)
	for z in [-4.6, -0.8]:
		batch.box(Vector3(0, 0.7, z), Vector3(2.2, 1.4, 2.3), HULL)
		for side in [-1.0, 1.0]:
			batch.tube(Vector3(side * 0.55, 1.0, z - 2.0), 0.16, 3.0, GOLD, 8)
	for side in [-1.0, 1.0]:
		engine(batch, Vector3(side * 2.2, -0.3, 5.0), 0.9, 2.0)
		for i in range(5):
			var z: float = -5 + i * 2.0
			batch.box(Vector3(side * (2.1 + i * 0.3), -0.9, z), Vector3(0.25, 0.75, 1.25), TRIM)
			batch.line(Vector3(side * 0.5, 0.05, z), Vector3(side * (1.7 + i * 0.3), 0.05, z), GOLD)
	batch.line(Vector3(-1.45, 2.6, 3), Vector3(-1.45, 3.8, 3.6), HULL)
	return VectorArt.remember_model("escort_gunship", batch.build())

static func battleship() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("battleship")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 0, -3), Vector3(30, 12, 72), HULL, Color("#16232e"))
	# Twin wave-piercing bows leave a visible channel down the foredeck.
	for side in [-1.0, 1.0]:
		batch.ship_hull(Vector3(side * 8, 0, 0), [Vector3(1.3, 2.2, -56), Vector3(5.2, 5.4, -44), Vector3(6.8, 6, -36)], HULL, Color("#283942"))
	batch.box(Vector3(0, 8, -6), Vector3(20, 7, 46), GOLD)
	batch.box(Vector3(0, 14, 9), Vector3(14, 8, 16), HULL)
	batch.box(Vector3(0, 19, 9), Vector3(10, 3, 12), GOLD)
	for x in [-10.0, 0.0, 10.0]:
		batch.box(Vector3(x, 0, 33.1), Vector3(8, 8, 0.3), TRIM, Color("#080b12"))
		batch.ring(Vector3(x, 0, 33.3), 3.5, TRIM, 20)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 17, -4, 0), Vector3(5, 7, 62), TRIM)
		for z in [-22.0, -8.0, 6.0, 20.0]:
			batch.box(Vector3(side * 16.8, 3, z), Vector3(3.5, 9, 11), HULL)
			batch.box(Vector3(side * 18.7, 3, z), Vector3(0.2, 5, 7), Color("#324653"), Color("#050a10"))
			batch.box(Vector3(side * 22, -1.8, z), Vector3(9, 0.6, 10), GOLD)
			for i in range(4):
				batch.line(Vector3(side * 27, -1.45, z - 3 + i * 2), Vector3(side * 17, -1.45, z - 3 + i * 2), TRIM)
		for row in range(3):
			batch.truss(Vector3(side * 14, 7, 27 - row * 22), Vector3(side * (22 + row * 16), 8 + row * 4, 27 - row * 22), 2.0, HULL, 6)
		for i in range(10):
			var z: float = -44 + i * 8
			batch.box(Vector3(side * 12.7, 6.3, z), Vector3(3, 0.3, 4.7), TRIM)
			batch.line(Vector3(side * 15.1, -2, z), Vector3(side * 15.1, 5, z + 2.5), GOLD)
		batch.truss(Vector3(side * 15, 1, -35), Vector3(side * 15, 1, 30), 1.2, GOLD, 12)
	for i in range(6):
		batch.box(Vector3(-5 + i * 2, 16, 17.1), Vector3(1, 1.2, 0.2), VectorArt.CYAN)
	batch.line(Vector3(0, 20, 9), Vector3(0, 29, 9), HULL)
	batch.truss(Vector3(-6, 24, 9), Vector3(6, 24, 9), 1.4, GOLD, 5)
	return VectorArt.remember_model("battleship", batch.build())

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
