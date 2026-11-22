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
	var cached: Node3D = VectorArt.cached_model("cryo_fighter")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	# Raised pressure cabin on two long ice runners; daylight under the bridge.
	batch.ship_hull(Vector3(0, 0.45, 0), [Vector3(0.7, 0.32, -2.2), Vector3(1.4, 0.7, -0.6), Vector3(1.2, 0.55, 2.3)], ICE, HULL)
	for side in [-1.0, 1.0]:
		var x: float = side * 3.25
		batch.ship_hull(Vector3(x, -0.36, 0), [Vector3(0.22, 0.18, -3.5), Vector3(0.8, 0.64, -0.4), Vector3(0.65, 0.54, 3.1)], STEEL, HULL)
		for z in [-0.75, 1.45]:
			batch.limb(Vector3(side, 0.48, z), Vector3(x, -0.2, z + 0.4), 0.32, 0.24, ICE, 5)
		batch.ring(Vector3(x, -0.36, 3.12), 0.41, VectorArt.CYAN, 10)
	return VectorArt.remember_model("cryo_fighter", batch.build())

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
	var cached: Node3D = VectorArt.cached_model("cryo_hydra")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 0, -3), Vector3(29, 12, 72), ICE, HULL)
	batch.box(Vector3(0, 10, -14), Vector3(13, 8, 36), STEEL, Color("#294157"))
	for side in [-1.0, 1.0]:
		for row in range(3):
			var at := Vector3(side * (24 + row * 15), 5 + row * 4, 24 - row * 22)
			batch.box(at, Vector3(14, 8, 23), ICE, HULL)
			batch.truss(Vector3(side * 13, 2, at.z), at, 3, STEEL, 5)
			batch.box(at + Vector3(0, 0, 12), Vector3(9, 4, 0.4), VectorArt.CYAN, Color("#0c1e30"))
			for rib in range(4):
				batch.box(at + Vector3(0, 4.3, -8 + rib * 5), Vector3(12, 0.6, 1.1), STEEL, Color("#3d5f73"))
			batch.ring(at + Vector3(0, 0, -12), 2.7, VectorArt.CYAN, 16)
		for i in range(9):
			batch.box(Vector3(side * 14.8, 1, -33 + i * 8), Vector3(0.5, 5, 4), STEEL, Color("#3b586e"))
			batch.line(Vector3(side * 4.5, 14.1, -27 + i * 5), Vector3(side * 4.5, 14.1, -24 + i * 5), VectorArt.CYAN)
	return VectorArt.remember_model("cryo_hydra", batch.build())

static func drone_bay() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_drone_bay")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, Vector3(8, 5, 6), ICE, HULL)
	batch.box(Vector3(0, 0, 3.2), Vector3(6, 3.5, 0.3), VectorArt.HOSTILE, Color("#07131e"))
	for i in range(5):
		batch.line(Vector3(-2.6 + i * 1.3, -1.5, 3.4), Vector3(-2.6 + i * 1.3, 1.5, 3.4), STEEL)
	return VectorArt.remember_model("cryo_drone_bay", batch.build())

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
