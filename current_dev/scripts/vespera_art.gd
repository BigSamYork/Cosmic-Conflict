class_name VesperaArt
extends RefCounted

const NEON := Color("#d979d5")
const SIGNAL := Color("#73dce3")
const HULL := Color("#242035")
const PANEL := Color("#382b4c")

static func warm_cache() -> void:
	for factory in [pylon, turret_base, fighter, overlord, core_ring, nyx, traffic_pod, gate_emitter, horizon]:
		var model: Node3D = factory.call()
		model.free()

static func pylon() -> Node3D:
	return GroundArt.tower("vespera")

static func turret_base() -> Node3D:
	return FleetArt.model("mount_vespera", "ground")

static func fighter() -> Node3D:
	return FleetArt.model("vespera")

static func overlord() -> Node3D:
	return FleetArt.model("overlord_spire", "ground")

static func core_ring() -> Node3D:
	return FleetArt.model("induction_carousel", "ground")

static func nyx() -> Node3D:
	return FleetArt.model("nyx")

static func traffic_pod() -> Node3D:
	return FleetArt.model("traffic")

static func gate_emitter() -> Node3D:
	return FleetArt.model("gate_projector", "ground")

static func terrain_chunk(start: float, branching: bool = false) -> Node3D:
	branching = branching and start + VectorArt.CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("vespera_branch:%d" if branching else "vespera_terrain:%d") % int(start)
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var terrain := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
	var district := RandomNumberGenerator.new()
	district.seed = hash(Vector2i(roundi(start / VectorArt.CHUNK_LENGTH), 81961))
	for row in range(8):
		var travel: float = start + row * 16
		for column in range(32):
			var x: float = (column - 16) * 10.0
			var a: Vector3 = floor_point(x, travel)
			var b: Vector3 = floor_point(x + 10, travel)
			var c: Vector3 = floor_point(x + 10, travel + 16)
			var d: Vector3 = floor_point(x, travel + 16)
			terrain.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE)
		for route in range(2 if branching else 1):
			for side in [-1.0, 1.0]:
				var offset: float = GroundRoute.lateral_offset(travel) if route == 1 else 0
				var next_offset: float = GroundRoute.lateral_offset(travel + 16) if route == 1 else 0
				batch.line(floor_point(offset + side * 9, travel) + Vector3.UP * 0.2, floor_point(next_offset + side * 9, travel + 16) + Vector3.UP * 0.2, SIGNAL)
		for side in [-1.0, 1.0]:
			for lane in range(2):
				var x: float = side * (23 + lane * 4)
				var a: Vector3 = floor_point(x - 1.8, travel)
				var b: Vector3 = floor_point(x + 1.8, travel)
				var c: Vector3 = floor_point(x + 1.8, travel + 16)
				var d: Vector3 = floor_point(x - 1.8, travel + 16)
				a.y = 32 + lane * 4
				b.y = a.y
				c.y = a.y
				d.y = a.y
				batch.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), HULL)
				batch.line(a, d, SIGNAL.darkened(0.25))
				batch.line(b, c, NEON)
	for row in range(3):
		for side in [-1.0, 1.0]:
			for tier in range(3):
				var travel: float = start + 20 + row * 42 + district.randf_range(-10.0, 10.0)
				var x: float = side * (43 + tier * 40 + district.randf_range(0.0, 16.0))
				if branching and absf(x - GroundRoute.lateral_offset(travel)) < 36:
					continue
				if tier == 0 and district.randf() < 0.23:
					continue # Open squares expose the next block and the distant skyline.
				var at: Vector3 = floor_point(x, travel)
				var height := district.randf_range(38.0, 134.0) + tier * 8.0
				scenery.append(GroundArt.placement(at, Vector3(district.randf_range(0.81, 1.15), height / 60, 1), PI if side < 0 else 0.0))
	if district.randf() < 0.28:
		var center: Vector3 = FlightState.rail_point(start + 64)
		batch.box(Vector3(center.x, 53, center.z), Vector3(162, 2.0, 12), SIGNAL, HULL)
		batch.truss(Vector3(center.x - 81, 58, center.z), Vector3(center.x + 81, 58, center.z), 5, NEON, 18)
		for side in [-1.0, 1.0]:
			batch.line(Vector3(center.x - 81, 54.2, center.z + side * 3), Vector3(center.x + 81, 54.2, center.z + side * 3), SIGNAL)
	var chunk := GroundArt.finish_chunk(batch.build(), terrain, scenery, "vespera")
	return VectorArt.remember_model(key, chunk) if start < VectorArt.TERRAIN_CACHE_CHUNKS * VectorArt.CHUNK_LENGTH else chunk

static func floor_point(x: float, travel: float) -> Vector3:
	return Vector3(FlightState.rail_point(travel).x + x, -1, -travel)

static func horizon() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_horizon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.surface(PackedVector3Array([Vector3(-20000, -12, -20000), Vector3(20000, -12, -20000), Vector3(20000, -12, 20000), Vector3(-20000, -12, 20000)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#100e20"))
	var model := batch.build()
	for stretch in range(10):
		var skyline: Array[Transform3D] = []
		for side in [-1.0, 1.0]:
			for j in range(5):
				var i := stretch * 5 + j
				var height := 100.0 + (i * 37) % 210
				var at := Vector3(side * (260 + (i % 3) * 55), -12, 300 - i * 170)
				skyline.append(GroundArt.placement(at, Vector3(3, height / 54, 3.6), side * (i % 3) * 0.25))
		GroundArt.add_landmarks(model, "landmark_vespera" if stretch % 2 else "vista_vespera", skyline)
	return VectorArt.remember_model("vespera_horizon", model)
