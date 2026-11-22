class_name XyloArt
extends RefCounted

const LEAF := Color("#88bf45")
const ACID := Color("#d0df45")
const SHELL := Color("#83b86b")
const DARK := Color("#173220")

static func warm_cache() -> void:
	for factory in [pylon, spitter_base, spitter_head, insect, insect_leg, goliath, goliath_leg, leviathan, hive_mother, rover, acid_plume, spore_plume, sensor]:
		var model: Node3D = factory.call()
		model.free()
	for kind in range(3):
		var egg: Node3D = egg_ship(kind)
		egg.free()
		egg = egg_ship(kind, true)
		egg.free()

static func pylon() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_pylon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3(0, -4.7, 0), Vector3(1.6, 0.8, 2), VectorArt.AMBER, 6, 10)
	batch.limb(Vector3(0, -4, 0), Vector3(0.4, 3.8, 0), 1.1, 0.7, LEAF)
	batch.ellipsoid(Vector3(0.4, 4, 0), Vector3(1.1, 1.5, 1.5), SHELL, 6, 10)
	for side in [-1.0, 1.0]:
		batch.limb(Vector3(side * 0.5, -2, 0), Vector3(side * 1.4, 4.7, 0.8), 0.35, 0.04, ACID, 6)
	return VectorArt.remember_model("xylo_pylon", batch.build())

static func spitter_base() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_spitter_base")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3(0, 0, 0), Vector3(3.2, 1.1, 3.2), LEAF, 6, 12)
	for i in range(6):
		var angle: float = i * TAU / 6
		batch.limb(Vector3.ZERO, Vector3(cos(angle) * 3.4, -0.9, sin(angle) * 3.4), 0.55, 0.12, SHELL, 6)
	return VectorArt.remember_model("xylo_spitter_base", batch.build())

static func spitter_head() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_spitter_head")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3(0, 0.2, 0), Vector3(2.6, 1.6, 2), SHELL, 8, 12)
	for side in [-1.0, 1.0]:
		batch.limb(Vector3(side, 0, -0.6), Vector3(side * 1.4, 0.2, -3.8), 0.7, 0.35, ACID)
		batch.ring(Vector3(side * 1.4, 0.2, -3.85), 0.35, VectorArt.HOSTILE, 10)
	return VectorArt.remember_model("xylo_spitter_head", batch.build())

static func insect() -> Node3D:
	return FleetArt.model("insect")

static func insect_leg() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_insect_leg")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.limb(Vector3.ZERO, Vector3(1.3, -0.4, 0.3), 0.17, 0.13, LEAF, 6)
	batch.limb(Vector3(1.3, -0.4, 0.3), Vector3(1.8, -1, 0.9), 0.13, 0.025, ACID, 6)
	return VectorArt.remember_model("xylo_insect_leg", batch.build())

static func goliath() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_goliath")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3(0, 9, -4), Vector3(8.5, 12, 7), SHELL, 12, 16)
	for rib in range(5):
		batch.ellipsoid(Vector3(0, 2 + rib * 4, 1.8), Vector3(8 - absf(rib - 2) * 0.7, 1.3, 4), LEAF if rib % 2 == 0 else SHELL, 6, 12)
	batch.limb(Vector3(0, 17, -3), Vector3(0, 25, 0), 3.3, 2.8, LEAF)
	batch.ellipsoid(Vector3(0, 26, 0), Vector3(6.5, 3.8, 5.5), SHELL, 8, 16)
	for side in [-1.0, 1.0]:
		batch.ellipsoid(Vector3(side * 4, 27, 4.8), Vector3(1, 0.7, 0.8), ACID, 6, 10)
		batch.limb(Vector3(side * 2, 25, 5), Vector3(side * 3.5, 23, 7), 0.7, 0.4, ACID)
		batch.limb(Vector3(side * 3.5, 23, 7), Vector3(side, 22.5, 8.5), 0.4, 0.04, LEAF)
		batch.limb(Vector3(side * 8, 17, -4), Vector3(side * 22, 14, 1), 3.4, 2.6, LEAF)
		batch.limb(Vector3(side * 22, 14, 1), Vector3(side * 19, 8, 14), 2.6, 1.6, SHELL)
		batch.limb(Vector3(side * 9, 6, -9), Vector3(side * 30, 7, -4), 2.6, 1.7, LEAF)
		for finger in range(3):
			batch.limb(Vector3(side * (17 + finger * 2), 8, 13), Vector3(side * (18 + finger * 2), 2, 17 + finger), 0.55, 0.04, ACID, 6)
	return VectorArt.remember_model("xylo_goliath", batch.build())

static func goliath_leg() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_goliath_leg")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.limb(Vector3.ZERO, Vector3(1.5, -4, 1.5), 2.3, 1.7, SHELL)
	batch.ellipsoid(Vector3(1.5, -4, 1.5), Vector3(1.8, 1.8, 1.8), LEAF)
	batch.limb(Vector3(1.5, -4, 1.5), Vector3(-1, -8.5, 5), 1.6, 0.7, SHELL)
	for toe in range(3):
		batch.limb(Vector3(-1, -8.2, 4), Vector3(-2 + toe, -8.5, 7 + toe * 0.3), 0.45, 0.05, ACID, 6)
	return VectorArt.remember_model("xylo_goliath_leg", batch.build())

static func leviathan() -> Node3D:
	return FleetArt.model("leviathan")

static func leviathan_segment(index: int) -> Vector3:
	return Vector3(sin(index * 0.36) * 18, 10 + index * 7, -18 - index * 14)

static func hive_mother(distant: bool = false) -> Node3D:
	return FleetArt.model("hive_mother_far" if distant else "hive_mother")

static func egg_ship(variant: int = 0, distant: bool = false) -> Node3D:
	return FleetArt.model("egg_%d%s" % [clampi(variant, 0, 2), "_far" if distant else ""])

static func rover() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_rover")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 1.5, 0), Vector3(4, 2, 5), ACID, DARK)
	batch.box(Vector3(0, 3, -0.6), Vector3(2.2, 1.5, 2.8), LEAF, Color("#294534"))
	for side in [-1.0, 1.0]:
		for z in [-1.6, 1.6]:
			batch.ellipsoid(Vector3(side * 2.1, 0.8, z), Vector3(0.6, 0.8, 0.8), SHELL, 6, 8)
	batch.limb(Vector3(0, 3.7, 0.6), Vector3(0, 6, 0.6), 0.12, 0.08, ACID, 6)
	batch.ring(Vector3(0, 6, 0.6), 0.8, LEAF, 12)
	return VectorArt.remember_model("xylo_rover", batch.build())

static func acid_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_acid_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(14):
		var angle: float = i * 2.4
		var top := Vector3(cos(angle) * 2.6, 8 + i % 4 * 1.8, sin(angle) * 2.6)
		batch.limb(Vector3(cos(angle) * 1.5, 0, sin(angle) * 1.5), top, 0.15, 0.03, ACID, 5)
		batch.ellipsoid(top, Vector3(0.22, 0.45, 0.22), ACID, 4, 6)
	return VectorArt.remember_model("xylo_acid_plume", batch.build())

static func spore_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_spore_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(20):
		var angle: float = i * 2.4
		var at := Vector3(cos(angle) * 3.8, 2 + i % 5 * 2.5, sin(angle) * 3.8)
		batch.ellipsoid(at, Vector3(0.25, 0.25, 0.25), LEAF, 4, 6)
		batch.line(at + Vector3.LEFT * 0.8, at + Vector3.RIGHT * 0.8, LEAF.darkened(0.3))
	return VectorArt.remember_model("xylo_spore_plume", batch.build())

static func sensor() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_sensor")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for side in [-1.0, 1.0]:
		batch.limb(Vector3.ZERO, Vector3(side * 4, 2, 0), 0.45, 0.08, LEAF)
		batch.ellipsoid(Vector3(side * 4, 2, 0), Vector3(0.8, 0.8, 0.8), ACID, 6, 8)
	return VectorArt.remember_model("xylo_sensor", batch.build())

static func organ_sac(radius: float, length: float, core: bool) -> Node3D:
	var key: String = "xylo_organ_%s_%s_%s" % [radius, length, core]
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3.ZERO, Vector3(radius, radius, length * 0.5), SHELL, 8, 12)
	var front: float = length * 0.5 + radius * 0.7
	var tint: Color = VectorArt.CYAN if core else VectorArt.AMBER
	batch.ellipsoid(Vector3(0, 0, front - 0.5), Vector3(radius * 0.85, radius * 0.85, 0.65), tint, 8, 12)
	batch.ring(Vector3(0, 0, front + 0.18), radius * 0.65, tint, 24)
	batch.ring(Vector3(0, 0, front + 0.2), radius * 0.3, VectorArt.CYAN, 16)
	return VectorArt.remember_model(key, batch.build())

static func spore_bolt() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_spore_bolt")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ellipsoid(Vector3.ZERO, Vector3(0.4, 0.4, 1.2), ACID, 6, 8)
	for i in range(6):
		var angle: float = i * TAU / 6
		batch.line(Vector3(cos(angle) * 0.3, sin(angle) * 0.3, 0.2), Vector3(cos(angle) * 0.65, sin(angle) * 0.65, 1.1), VectorArt.HOSTILE)
	batch.line(Vector3(0, 0, 0.8), Vector3(0, 0, 4), LEAF)
	return VectorArt.remember_model("xylo_spore_bolt", batch.build())

static func floor_point(x: float, travel: float) -> Vector3:
	return Vector3(FlightState.rail_point(travel).x + x, -1, -travel)

static func _tree(batch: GeometryBatch, at: Vector3, height: float, side: float) -> void:
	var seed: float = at.z * 0.073 + at.x * 0.11
	var trunk := PackedVector3Array([at])
	for level in range(1, 6):
		var t: float = level / 5.0
		var point: Vector3 = at + Vector3(sin(seed + t * 4.5) * 5 * t + side * sin(t * PI) * 3, height * t, cos(seed * 0.6 + t * 3.7) * 6 * t)
		batch.limb(trunk[-1], point, 4.5 - (level - 1) * 0.67, 4.5 - level * 0.67, LEAF if level % 2 == 0 else SHELL)
		trunk.append(point)
	for root in range(5):
		var angle: float = root * TAU / 5 + seed
		var knee: Vector3 = at + Vector3(cos(angle) * 4, 3, sin(angle) * 4)
		batch.limb(at + Vector3.UP * 5, knee, 1.4, 0.8, LEAF)
		batch.limb(knee, at + Vector3(cos(angle) * 9, 0, sin(angle) * 9), 0.8, 0.15, SHELL)
	for branch in range(3):
		var from: Vector3 = trunk[3 + branch]
		var tip: Vector3 = at + Vector3(-side * (13 + branch * 4), height * (0.72 + branch * 0.08), -14 + branch * 15 + sin(seed) * 5)
		batch.limb(from, tip, 1.2, 0.12, SHELL)
		for frond in range(3):
			var angle: float = seed + frond * 2.1
			var forward := Vector3(cos(angle), 0, sin(angle))
			var across: Vector3 = forward.cross(Vector3.UP)
			var leaf := PackedVector3Array([tip, tip + forward * 5 + across * 2.5 + Vector3.UP * 2, tip + forward * 12 - Vector3.UP, tip + forward * 5 - across * 2.5 + Vector3.UP, tip + forward * 5 + Vector3.UP * 3])
			batch.surface(leaf, PackedInt32Array([0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4]), Color("#1c3e24"))
			batch.outline(PackedVector3Array([leaf[0], leaf[1], leaf[2], leaf[3]]), LEAF.darkened(0.22))
			batch.line(leaf[0], leaf[4], ACID.darkened(0.35))
			batch.line(leaf[4], leaf[2], LEAF)
	var vine: Vector3 = trunk[3] + Vector3(side * 2, 0, 0)
	for segment in range(6):
		var next: Vector3 = vine + Vector3(sin(seed + segment) * 0.7, -3, cos(seed + segment) * 0.7)
		batch.line(vine, next, LEAF.darkened(0.1))
		vine = next

static func terrain_chunk(start: float, branching: bool = false) -> Node3D:
	branching = branching and start + VectorArt.CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("xylo_branch:%d" if branching else "xylo_terrain:%d") % int(start)
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for row in range(8):
		var travel: float = start + row * 16
		for column in range(32):
			var x: float = (column - 16) * 10.0
			var a: Vector3 = floor_point(x, travel)
			var b: Vector3 = floor_point(x + 10, travel)
			var c: Vector3 = floor_point(x + 10, travel + 16)
			var d: Vector3 = floor_point(x, travel + 16)
			batch.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#142b1e") if (row + column) % 3 == 0 else Color("#1c3020"))
			if row % 2 == 0:
				batch.line(a, b, Color("#3d5b32"))
		for route in range(2 if branching else 1):
			var offset: float = GroundRoute.lateral_offset(travel) if route == 1 else 0
			var next_offset: float = GroundRoute.lateral_offset(travel + 16) if route == 1 else 0
			var a: Vector3 = floor_point(offset - 4.2, travel) + Vector3.UP * 0.08
			var b: Vector3 = floor_point(offset + 4.2, travel) + Vector3.UP * 0.08
			var c: Vector3 = floor_point(next_offset + 4.2, travel + 16) + Vector3.UP * 0.08
			var d: Vector3 = floor_point(next_offset - 4.2, travel + 16) + Vector3.UP * 0.08
			batch.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#174532"))
			batch.line(a, d, Color("#67964a"))
			batch.line(b, c, Color("#67964a"))
	for i in range(6):
		var travel: float = start + 12 + i * 19
		var side: float = -1 if i % 2 == 0 else 1
		var x: float = side * (35 + (i % 3) * 22)
		if not branching or absf(x - GroundRoute.lateral_offset(travel)) > 38:
			_tree(batch, floor_point(x, travel), 50 + posmod(int(start / 128) * 7 + i * 13, 35), side)
		var reed: Vector3 = floor_point(side * 16, travel)
		for blade in range(4):
			batch.line(reed + Vector3(blade * 0.3, 0, 0), reed + Vector3((blade - 1) * 0.7, 3 + blade * 0.5, 1), ACID.darkened(0.2))
	return VectorArt.remember_model(key, batch.build()) if start < VectorArt.TERRAIN_CACHE_CHUNKS * VectorArt.CHUNK_LENGTH else batch.build()

static func horizon() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_horizon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.surface(PackedVector3Array([Vector3(-20000, -12, -20000), Vector3(20000, -12, -20000), Vector3(20000, -12, 20000), Vector3(-20000, -12, 20000)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#10281e"))
	for i in range(40):
		var side: float = -1 if i % 2 == 0 else 1
		var at := Vector3(side * (220 + i % 3 * 70), -12, -i * 160)
		batch.limb(at, at + Vector3(side * 20, 130 + i % 4 * 30, 0), 16, 5, Color("#315533"), 6)
	return VectorArt.remember_model("xylo_horizon", batch.build())
