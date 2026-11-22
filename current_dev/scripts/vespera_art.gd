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
	var cached: Node3D = VectorArt.cached_model("vespera_pylon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, -4.9, 0), Vector3(3.2, 1.2, 4), VectorArt.AMBER, HULL)
	batch.box(Vector3(0, 0.6, 0), Vector3(2.4, 9.8, 3.2), NEON, PANEL)
	for side in [-1.0, 1.0]:
		batch.line(Vector3(side * 0.8, -3.8, 1.65), Vector3(side * 0.8, 5, 1.65), SIGNAL)
	for row in range(5):
		batch.box(Vector3(0, -2.7 + row * 1.6, 1.7), Vector3(1, 0.35, 0.2), NEON, HULL)
	return VectorArt.remember_model("vespera_pylon", batch.build())

static func turret_base() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_turret")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3(0, -0.5, 0), Vector3(7, 1, 7), NEON, HULL)
	batch.box(Vector3(0, 0.5, 0), Vector3(4.5, 1.6, 4.5), SIGNAL, PANEL)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side * 2.8, 0.3, 0), Vector3(0.7, 1.7, 6), NEON, HULL)
		for i in range(4):
			batch.line(Vector3(side * 3.2, 0.2, -2.2 + i * 1.4), Vector3(side * 3.2, 1.1, -2.2 + i * 1.4), SIGNAL)
	return VectorArt.remember_model("vespera_turret", batch.build())

static func fighter() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_fighter")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.ship_hull(Vector3.ZERO, [Vector3(0.18, 0.16, -4.5), Vector3(1.15, 0.66, -0.5), Vector3(0.68, 0.34, 1.5)], NEON, HULL)
	for side in [-1.0, 1.0]:
		# Bent cloak vanes fold down at the elbow, then rise towards the tail.
		var vane := PackedVector3Array([Vector3(side * 0.4, 0.25, -3), Vector3(side * 4.15, -0.7, -0.8), Vector3(side * 2.2, 0.75, 3), Vector3(side * 1.85, 0.2, 0.4), Vector3(side * 0.7, 0.1, 0.8)])
		batch.surface(vane, PackedInt32Array([0, 1, 3, 1, 2, 3, 0, 3, 4]), PANEL)
		batch.outline(vane, NEON)
		batch.box(Vector3(side * 2.1, 0.2, 1.3), Vector3(0.8, 0.9, 2.8), SIGNAL, PANEL)
		batch.ring(Vector3(side * 2.1, 0.2, 2.75), 0.35, NEON, 12)
		batch.line(Vector3(side * 2.1, 0.2, 2.8), Vector3(side * 2.1, 0.2, 4.5), SIGNAL)
	return VectorArt.remember_model("vespera_fighter", batch.build())

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
	var cached: Node3D = VectorArt.cached_model("vespera_nyx")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var hull := PackedVector3Array([Vector3(0, 0, 31), Vector3(-15, -4, 23), Vector3(15, -4, 23), Vector3(-13, 8, -12), Vector3(13, 8, -12), Vector3(-10, -4, -39), Vector3(10, -4, -39), Vector3(0, 12, -24), Vector3(0, -6, -2)])
	batch.surface(hull, PackedInt32Array([0, 3, 4, 0, 1, 3, 0, 4, 2, 0, 8, 1, 0, 2, 8, 1, 8, 5, 2, 6, 8, 3, 5, 7, 4, 7, 6, 3, 7, 4, 5, 6, 7, 5, 8, 6, 1, 5, 3, 2, 4, 6]), HULL)
	for pair in [[0, 1], [0, 2], [0, 3], [0, 4], [1, 3], [2, 4], [3, 7], [4, 7], [3, 5], [4, 6], [5, 6], [5, 7], [6, 7], [1, 5], [2, 6]]:
		batch.line(hull[pair[0]], hull[pair[1]], NEON)
	for side in [-1.0, 1.0]:
		var wing := PackedVector3Array([Vector3(side * 12, 2, 20), Vector3(side * 24, 7, 28), Vector3(side * 40, 11, 8), Vector3(side * 61, 15, -26), Vector3(side * 45, 7, -34), Vector3(side * 13, -1, -24)])
		batch.surface(wing, PackedInt32Array([0, 1, 2, 0, 2, 5, 2, 3, 4, 2, 4, 5]), PANEL)
		batch.outline(wing, NEON)
		batch.line(wing[0], wing[2], SIGNAL)
		batch.line(wing[2], wing[5], SIGNAL)
		batch.line(wing[2], wing[4], SIGNAL)
		for row in range(3):
			var at := Vector3(side * (22 + row * 16), 7 + row * 4, 27 - row * 22)
			batch.box(at, Vector3(8, 2, 8), NEON, HULL)
		for i in range(7):
			var z: float = -30 + i * 7
			batch.line(Vector3(side * 3, 9 - i, z), Vector3(side * 6, 7 - i, z + 2), SIGNAL)
	for x in [-6.0, 0.0, 6.0]:
		batch.tube(Vector3(x, -1, -38), 2.3, 6, NEON, 12)
		batch.ring(Vector3(x, -1, -41.1), 1.8, SIGNAL, 16)
	return VectorArt.remember_model("vespera_nyx", batch.build())

static func traffic_pod() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("vespera_traffic")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, Vector3(4, 1.6, 7), SIGNAL, HULL)
	batch.box(Vector3(0, 1.1, -0.8), Vector3(2.7, 0.8, 3.2), NEON, PANEL)
	for side in [-1.0, 1.0]:
		batch.line(Vector3(side * 1.5, 0, 3.5), Vector3(side * 1.5, 0, 9), SIGNAL)
	return VectorArt.remember_model("vespera_traffic", batch.build())

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
	for row in range(8):
		var travel: float = start + row * 16
		for column in range(32):
			var x: float = (column - 16) * 10.0
			var a: Vector3 = floor_point(x, travel)
			var b: Vector3 = floor_point(x + 10, travel)
			var c: Vector3 = floor_point(x + 10, travel + 16)
			var d: Vector3 = floor_point(x, travel + 16)
			batch.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#171324") if (row + column) % 2 == 0 else Color("#211b30"))
			batch.line(a, b, Color("#704179"))
			if column % 2 == 0:
				batch.line(a, d, Color("#483556"))
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
				batch.box(at + Vector3(0, height * 0.5, 0), Vector3(23, height, 29), NEON.darkened(tier * 0.18), HULL)
				batch.box(at + Vector3(0, height + 4, 0), Vector3(15, 8, 19), SIGNAL.darkened(0.3), PANEL)
				batch.box(at + Vector3(-side * 9, 8, 2), Vector3(6, 16, 14), NEON, PANEL)
				for floor_index in range(1, int(height / 10)):
					var y: float = floor_index * 10
					batch.line(at + Vector3(-11.6, y, 14.6), at + Vector3(11.6, y, 14.6), NEON.darkened(0.2))
					var inner_x: float = -side * 11.6
					batch.line(at + Vector3(inner_x, y, -14.6), at + Vector3(inner_x, y, 14.6), NEON.darkened(0.15))
					for window in range(3):
						var wx: float = -7 + window * 7
						batch.line(at + Vector3(wx, y + 2, 14.7), at + Vector3(wx, y + 5, 14.7), SIGNAL.darkened(0.2))
						var z: float = -9 + window * 9
						batch.outline(PackedVector3Array([at + Vector3(inner_x, y + 1, z), at + Vector3(inner_x, y + 6, z), at + Vector3(inner_x, y + 6, z + 4), at + Vector3(inner_x, y + 1, z + 4)]), SIGNAL.darkened(0.25))
				for pillar in [-1.0, 1.0]:
					batch.line(at + Vector3(pillar * 8, 2, 14.8), at + Vector3(pillar * 8, height - 2, 14.8), NEON)
					batch.line(at + Vector3(-side * 11.7, 2, pillar * 12), at + Vector3(-side * 11.7, height - 2, pillar * 12), NEON)
	if posmod(int(start / VectorArt.CHUNK_LENGTH), 3) == 1:
		var center: Vector3 = FlightState.rail_point(start + 64)
		batch.box(Vector3(center.x, 53, center.z), Vector3(162, 2.0, 12), SIGNAL, HULL)
		batch.truss(Vector3(center.x - 81, 58, center.z), Vector3(center.x + 81, 58, center.z), 5, NEON, 18)
		for side in [-1.0, 1.0]:
			batch.line(Vector3(center.x - 81, 54.2, center.z + side * 3), Vector3(center.x + 81, 54.2, center.z + side * 3), SIGNAL)
	return VectorArt.remember_model(key, batch.build()) if start < VectorArt.TERRAIN_CACHE_CHUNKS * VectorArt.CHUNK_LENGTH else batch.build()

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
