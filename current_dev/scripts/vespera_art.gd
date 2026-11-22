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
	var cached: Node3D = VectorArt.cached_model("vespera_overlord")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, -2, -4), Vector3(30, 4, 32), NEON, HULL)
	for level in range(5):
		var y: float = 1 + level * 4.5
		var radius: float = 10.0 if level % 2 == 0 else 8.0
		for face in range(12):
			var a: float = face * TAU / 12
			var b: float = (face + 1) * TAU / 12
			var p := Vector3(cos(a) * radius, y, -4 + sin(a) * radius)
			var q := Vector3(cos(b) * radius, y, -4 + sin(b) * radius)
			var quad := PackedVector3Array([p, q, q + Vector3.UP * 4, p + Vector3.UP * 4])
			batch.surface(quad, PackedInt32Array([0, 1, 2, 0, 2, 3]), HULL if face % 2 == 0 else PANEL)
			batch.outline(quad, NEON)
			batch.line(p.lerp(q, 0.3) + Vector3.UP, p.lerp(q, 0.3) + Vector3.UP * 3, SIGNAL)
	for side in [-1.0, 1.0]:
		batch.truss(Vector3(side * 10, 4, -4), Vector3(side * 30, 7, -4), 2.5, SIGNAL, 6)
		batch.box(Vector3(side * 19, 7, 14), Vector3(8, 2, 8), NEON, HULL)
	return VectorArt.remember_model("vespera_overlord", batch.build())

static func core_ring() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_core_ring")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for radius in [13.0, 15.0]:
		var points := PackedVector3Array()
		for i in range(48):
			var angle: float = i * TAU / 48
			points.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		batch.outline(points, SIGNAL if radius == 13 else NEON)
	for i in range(12):
		var angle: float = i * TAU / 12
		batch.box(Vector3(cos(angle) * 14, 0, sin(angle) * 14), Vector3(2.6, 1, 1.2), SIGNAL, HULL, Basis(Vector3.UP, -angle))
	return VectorArt.remember_model("vespera_core_ring", batch.build())

static func nyx() -> Node3D:
	return FleetArt.model("nyx")

static func traffic_pod() -> Node3D:
	return FleetArt.model("traffic")

static func gate_emitter() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_gate_post")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, 2, 0), Vector3(1.8, 22, 2.8), NEON, HULL)
	for i in range(11):
		batch.box(Vector3(0, -8 + i * 2, 1.5), Vector3(1.2, 0.7, 0.4), SIGNAL, PANEL)
	return VectorArt.remember_model("vespera_gate_post", batch.build())

static func terrain_chunk(start: float, branching: bool = false) -> Node3D:
	branching = branching and start + VectorArt.CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("vespera_branch:%d" if branching else "vespera_terrain:%d") % int(start)
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var terrain := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
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
		var travel: float = start + 20 + row * 42
		for side in [-1.0, 1.0]:
			for tier in range(3):
				var x: float = side * (43 + tier * 40 + (row % 2) * 8)
				if branching and absf(x - GroundRoute.lateral_offset(travel)) < 36:
					continue
				var at: Vector3 = floor_point(x, travel)
				var height: float = 54 + posmod(int(start / 128) * 13 + row * 7 + tier * 11, 80)
				scenery.append(GroundArt.placement(at, Vector3(1, height / 60, 1), PI if side < 0 else 0.0))
	if posmod(int(start / VectorArt.CHUNK_LENGTH), 3) == 1:
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
	for side in [-1.0, 1.0]:
		for i in range(50):
			var height: float = 100 + (i * 37) % 210
			batch.box(Vector3(side * (260 + (i % 3) * 55), height * 0.5, 300 - i * 170), Vector3(70, height, 110), Color("#4b315f"), Color("#100e20"))
	return VectorArt.remember_model("vespera_horizon", batch.build())
