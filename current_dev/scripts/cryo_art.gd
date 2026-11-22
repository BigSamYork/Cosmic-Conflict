class_name CryoArt
extends RefCounted

const ICE := Color("#a5dce9")
const STEEL := Color("#688fae")
const HULL := Color("#1b3047")

static func warm_cache() -> void:
	for factory in [ice_pylon, tank_base, fighter, bore_mech, hydra, drill, drone_bay, frost_plume]:
		var model: Node3D = factory.call()
		model.free()
	for variant in AsteroidArt.GIANT_VARIANTS:
		var rock: Node3D = AsteroidArt.create(variant, Color("#9bb6cb"), true, true)
		rock.free()
	for variant in range(AsteroidArt.VARIANTS):
		var rock: Node3D = AsteroidArt.create(variant, Color("#91b2cb"), true, true)
		rock.free()

static func ice_pylon() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_pylon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, -4.9, 0), Vector3(3.2, 1.2, 4), VectorArt.AMBER, HULL)
	batch.crystal(Vector3(0, -4.3, 0), 1.55, 9.8, ICE)
	for side in [-1.0, 1.0]:
		batch.crystal(Vector3(side * 1.0, -4.3, 0.7), 0.55, 5.2, STEEL)
	return VectorArt.remember_model("cryo_pylon", batch.build())

static func tank_base() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_tank")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 0.45, 0), Vector3(4.5, 1.8, 6), ICE, HULL)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 2.7, -0.15, 0), Vector3(1.0, 1.8, 7.6), STEEL, Color("#101d30"))
		for i in range(5):
			var ring := PackedVector3Array()
			for point in range(12):
				var angle: float = point * TAU / 12
				ring.append(Vector3(side * 3.22, -0.15 + sin(angle) * 0.64, -2.7 + i * 1.35 + cos(angle) * 0.64))
			batch.outline(ring, ICE)
		for i in range(4):
			batch.box(Vector3(side * 1.8, 1.4, -2.2 + i * 1.4), Vector3(0.75, 0.18, 0.55), STEEL, Color("#37556c"))
	return VectorArt.remember_model("cryo_tank", batch.build())

static func fighter() -> Node3D:
	return FleetArt.model("cryo")

static func bore_mech() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_bore_mech")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 0, -4), Vector3(30, 8, 31), ICE, HULL)
	batch.box(Vector3(0, 7, -4), Vector3(17, 7, 20), STEEL, Color("#294157"))
	batch.box(Vector3(0, 11, 0), Vector3(11, 2, 8), ICE, HULL)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 19, -5, -3), Vector3(8, 7, 34), STEEL, Color("#101b2c"))
		for i in range(7):
			var ring := PackedVector3Array()
			for point in range(16):
				var angle: float = point * TAU / 16
				ring.append(Vector3(side * 23.1, -5 + sin(angle) * 2.7, -16.5 + i * 4.5 + cos(angle) * 2.7))
			batch.outline(ring, ICE)
		for i in range(5):
			batch.box(Vector3(side * 15.3, 2, -15 + i * 6), Vector3(0.5, 3, 3.6), ICE, Color("#38526a"))
			batch.line(Vector3(side * 7, 9, -12 + i * 4), Vector3(side * 7, 9, -10 + i * 4), VectorArt.CYAN)
		batch.truss(Vector3(side * 13, 1, 10), Vector3(side * 30, 7, -4), 2, STEEL, 6)
	return VectorArt.remember_model("cryo_bore_mech", batch.build())

static func drill() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_drill")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for section in range(8):
		var z: float = -5 + section * 2.5
		var radius: float = 4.1 * (1 - section / 8.5)
		batch.tube(Vector3(0, 0, z), radius, 2.6, ICE, 16, maxf(0.2, radius - 0.5))
		for tooth in range(6):
			var angle: float = tooth * TAU / 6 + section * 0.4
			batch.line(Vector3(cos(angle) * radius, sin(angle) * radius, z - 1), Vector3(cos(angle + 0.5) * (radius + 0.35), sin(angle + 0.5) * (radius + 0.35), z + 1.2), VectorArt.CYAN)
	return VectorArt.remember_model("cryo_drill", batch.build())

static func hydra() -> Node3D:
	return FleetArt.model("hydra")

static func drone_bay() -> Node3D:
	return FleetArt.model("boss_drone_hangar")

static func frost_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_frost_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(9):
		var angle: float = i * 2.4
		batch.crystal(Vector3(cos(angle) * 2.5, 1 + (i % 3) * 4, sin(angle) * 2.5), 0.35, 2.5, ICE)
		batch.line(Vector3(cos(angle) * 3, 0.3, sin(angle) * 3), Vector3(cos(angle + 0.6) * 1.7, 14, sin(angle + 0.6) * 1.7), STEEL)
	return VectorArt.remember_model("cryo_frost_plume", batch.build())
