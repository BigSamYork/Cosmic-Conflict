class_name FrontierArt
extends RefCounted

const WATER: Shader = preload("res://shaders/storm_water.gdshader")
const WATER_ARRIVAL: Shader = preload("res://shaders/storm_water_arrival.gdshader")
const OCEAN := Color("#72d8ff")
const SAND := Color("#e8bf65")

static func is_frontier(sector: String) -> bool:
	return sector in ["thalassa", "kharon"]

static func floor_point(x: float, travel: float, sector: String = "thalassa") -> Vector3:
	var rise: float = 0
	if sector == "kharon":
		rise = maxf(0, absf(x) - 16) * 0.22 * (0.65 + 0.35 * sin(travel * 0.018 + x * 0.07))
	return Vector3(FlightState.rail_point(travel).x + x, -1 + rise, -travel)

static func horizon(sector: String) -> Node3D:
	var key: String = sector + "_horizon"
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for z in range(-20, 20):
		for x in range(-20, 20):
			var points := PackedVector3Array()
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = (x + corner.x) * 1000
				var pz: float = (z + corner.y) * 1000
				var y: float = -9 if sector == "thalassa" else -24 - 10 * absf(sin(px * 0.002 + pz * 0.001))
				points.append(Vector3(px, y, pz))
			batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#143441") if sector == "thalassa" else Color("#5b3e29"))
	var model: Node3D = batch.build()
	if sector == "thalassa":
		var material := ShaderMaterial.new()
		material.shader = WATER
		model.get_child(0).material_override = material
	return VectorArt.remember_model(key, model)

static func terrain_chunk(start: float, sector: String, branching: bool) -> Node3D:
	var key: String = "%s-terrain:%d:%s" % [sector, int(start), branching]
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	if sector == "thalassa":
		for row in range(16):
			for column in range(24):
				var points := PackedVector3Array()
				for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
					points.append(Vector3((column - 12 + corner.x) * 24, -4, -start - (row + corner.y) * 8))
				batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#145165"))
		var result: Node3D = batch.build()
		var water := ShaderMaterial.new()
		water.shader = WATER
		result.get_child(0).material_override = water
		var platforms := GeometryBatch.new()
		for side in [-1.0, 1.0]:
			var at: Vector3 = floor_point(side * 57, start + 64)
			if branching and absf(side * 57 - GroundRoute.lateral_offset(start + 64)) < 40:
				at.x += side * 75
			platforms.box(at + Vector3(0, 3, 0), Vector3(26, 3, 45), OCEAN, Color("#243641"))
			for x in [-9.0, 9.0]:
				for z in [-17.0, 17.0]:
					platforms.limb(at + Vector3(x, -10, z), at + Vector3(x, 2, z), 1.5, 1.2, OCEAN)
			platforms.box(at + Vector3(0, 10, -5), Vector3(14, 11, 18), Color("#e1b466"), Color("#293f4c"))
			platforms.box(at + Vector3(0, 16, -5), Vector3(17, 1.5, 21), OCEAN)
			for i in range(5):
				platforms.box(at + Vector3((i - 2) * 2.4, 12, 4.1), Vector3(1.4, 2, 0.3), OCEAN)
			platforms.truss(at + Vector3(side * 8, 4, -12), at + Vector3(side * 8, 37, -12), 2, OCEAN)
			platforms.truss(at + Vector3(side * 8, 37, -12), at + Vector3(side * 24, 37, -12), 1.5, OCEAN)
			platforms.line(at + Vector3(side * 24, 37, -12), at + Vector3(side * 24, 8, -12), Color("#e1b466"))
		platforms.box(floor_point(0, start + 64) + Vector3(0, -0.5, 0), Vector3(24, 0.6, 128), OCEAN.darkened(0.55), Color("#102b37"))
		var platform_model: Node3D = platforms.build()
		for child in platform_model.get_children():
			platform_model.remove_child(child)
			result.add_child(child)
		platform_model.free()
		return VectorArt.remember_model(key, result) if start < VectorArt.TERRAIN_CACHE_CHUNKS * 128 else result
	for row in range(16):
		var travel: float = start + row * 8
		for column in range(32):
			var x: float = (column - 16) * 10
			var points := PackedVector3Array()
			for corner in [Vector2(0, 0), Vector2(10, 0), Vector2(10, 8), Vector2(0, 8)]:
				var p: Vector3 = floor_point(x + corner.x, travel + corner.y, sector)
				if branching and absf(x + corner.x - GroundRoute.lateral_offset(travel + corner.y)) < 15:
					p.y = -1
				points.append(p)
			batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#6a4b30") if (row + column) % 3 == 0 else Color("#503923"))
			if row % 3 == 0:
				batch.line(points[0], points[1], SAND.darkened(0.35))
	for side in [-1.0, 1.0]:
		for i in range(3):
			var at: Vector3 = floor_point(side * (44 + i * 27), start + 20 + i * 38, sector)
			if branching and absf(side * (44 + i * 27) - GroundRoute.lateral_offset(start + 20 + i * 38)) < 35:
				continue
			batch.box(at + Vector3(0, 5, 0), Vector3(18, 10, 18), SAND, Color("#493b32"))
			batch.crystal(at + Vector3(0, 10, 0), 5, 35 + i * 8, SAND)
			for mark in range(4):
				batch.line(at + Vector3(-3, 16 + mark * 5, 4), at + Vector3(3, 19 + mark * 5, 4), Color("#68c3c6"))
			if i == 0:
				for pillar in [-1.0, 1.0]:
					batch.box(at + Vector3(pillar * 12, 18, 30), Vector3(5, 36, 7), SAND)
				batch.box(at + Vector3(-5, 36, 30), Vector3(22, 6, 8), SAND)
	return VectorArt.remember_model(key, batch.build()) if start < VectorArt.TERRAIN_CACHE_CHUNKS * 128 else batch.build()

static func fighter(sector: String, heavy: bool = false) -> Node3D:
	var key: String = "%s-fighter:%s" % [sector, heavy]
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	if sector == "thalassa":
		var p := PackedVector3Array([Vector3(0, 0, -5), Vector3(-2, 1.2, 0), Vector3(2, 1.2, 0), Vector3(0, -0.8, 3), Vector3(-7, 0.1, 2), Vector3(7, 0.1, 2), Vector3(-3, -0.5, 5), Vector3(3, -0.5, 5)])
		batch.surface(p, PackedInt32Array([0, 1, 2, 0, 3, 1, 0, 2, 3, 1, 4, 6, 1, 6, 3, 2, 7, 5, 2, 3, 7]), Color("#193a50"))
		for pair in [[0, 1], [0, 2], [1, 4], [4, 6], [6, 3], [3, 7], [7, 5], [5, 2]]:
			batch.line(p[pair[0]], p[pair[1]], OCEAN)
		batch.tube(Vector3(0, 0.2, 2), 0.7, 4, Color("#d7aa69"))
		for side in [-1.0, 1.0]:
			batch.limb(Vector3(side * 5.8, 0.06, 2.4), Vector3(side * 6.6, 1.5, 0.1), 0.52, 0.1, OCEAN, 4)
	else:
		batch.ellipsoid(Vector3.ZERO, Vector3(2.7, 1.1, 4), SAND, 6, 10)
		for side in [-1.0, 1.0]:
			for i in range(3):
				batch.limb(Vector3(side * 2, 0, -2 + i * 1.8), Vector3(side * 4.7, -0.4, -1 + i * 1.8), 0.35, 0.18, SAND)
				batch.line(Vector3(side * 4.7, -0.4, -1 + i * 1.8), Vector3(side * 3, -1, 1 + i * 1.8), Color("#65d4d7"))
		batch.crystal(Vector3(0, 0.7, 1), 0.8, 2, Color("#65d4d7"))
	if heavy:
		for side in [-1.0, 1.0]:
			var x: float = side * (3.8 if sector == "thalassa" else 2.4)
			batch.ship_hull(Vector3(x, -0.25, 0), [Vector3(0.45, 0.5, -3.1), Vector3(1.15, 1.2, 0), Vector3(0.9, 0.8, 3.8)], OCEAN if sector == "thalassa" else SAND, Color("#36434b"))
	return VectorArt.remember_model(key, batch.build())

static func pylon(sector: String) -> Node3D:
	var batch := GeometryBatch.new()
	var tint: Color = OCEAN if sector == "thalassa" else SAND
	batch.box(Vector3(0, -4.8, 0), Vector3(3.2, 1.3, 4), VectorArt.AMBER)
	if sector == "thalassa":
		batch.box(Vector3(0, -0.2, 0), Vector3(2.6, 8, 3), tint)
		for i in range(4):
			batch.ring(Vector3(0, -2 + i * 1.5, 1.6), 0.85, tint)
	else:
		batch.crystal(Vector3(0, -4, 0), 1.5, 9, tint)
	return batch.build()

static func turret_base(sector: String) -> Node3D:
	var batch := GeometryBatch.new()
	var tint: Color = OCEAN if sector == "thalassa" else SAND
	batch.box(Vector3(0, -0.5, 0), Vector3(7, 1.5, 7), tint)
	if sector == "thalassa":
		for side in [-1.0, 1.0]:
			batch.tube(Vector3(side * 2.7, 0, 0), 0.9, 6, tint)
	else:
		batch.crystal(Vector3(0, -0.5, 0), 2.5, 2.7, tint)
	return batch.build()

static func boss(sector: String, orbital: bool) -> Node3D:
	var key: String = "%s-boss:%s" % [sector, orbital]
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var tint: Color = OCEAN if sector == "thalassa" else SAND
	if sector == "thalassa":
		if orbital:
			batch.box(Vector3(0, 0, -4), Vector3(28, 12, 76), tint, Color("#1b3444"))
			for side in [-1.0, 1.0]:
				batch.tube(Vector3(side * 26, 0, -8), 7, 68, tint, 10)
				batch.box(Vector3(side * 16, 2, -3), Vector3(20, 4, 58), tint)
				for i in range(5):
					batch.box(Vector3(side * 42, 4, -26 + i * 12), Vector3(18, 2, 7), tint)
					batch.truss(Vector3(side * 25, 1, -26 + i * 12), Vector3(side * 50, 5, -26 + i * 12), 2, tint)
			batch.box(Vector3(0, 11, -20), Vector3(20, 10, 24), tint)
		else:
			batch.box(Vector3(0, 0, -4), Vector3(28, 8, 32), tint, Color("#223b4a"))
			batch.box(Vector3(0, 7, -4), Vector3(19, 6, 18), Color("#f0c886"))
			for side in [-1.0, 1.0]:
				for row in [-1.0, 1.0]:
					batch.limb(Vector3(side * 12, -1, row * 10), Vector3(side * 23, -8, row * 15), 2.8, 1.5, tint)
					batch.box(Vector3(side * 23, -9, row * 15), Vector3(9, 2, 12), tint)
			for i in range(4):
				batch.box(Vector3((i - 1.5) * 4, 8, 5.2), Vector3(2.5, 2.5, 0.4), tint)
	else:
		if orbital:
			batch.box(Vector3(0, 0, -4), Vector3(28, 12, 76), tint, Color("#443a36"))
			for side in [-1.0, 1.0]:
				for i in range(3):
					var at := Vector3(side * (24 + i * 15), 4, 20 - i * 22)
					batch.crystal(at - Vector3.UP * 8, 6, 23 + i * 6, tint)
					batch.limb(Vector3(side * 12, 0, at.z), at, 3, 1.7, Color("#6bd6d0"))
			batch.crystal(Vector3(0, 6, -18), 6, 26, tint)
		else:
			for i in range(3):
				batch.box(Vector3(0, i * 5, -4), Vector3(30 - i * 7, 5, 30 - i * 6), tint, Color("#45382c"))
			for side in [-1.0, 1.0]:
				batch.box(Vector3(side * 19, -4, -5), Vector3(8, 7, 35), tint)
				for i in range(6):
					batch.ring(Vector3(side * 19, -4, 13 - i * 5), 2.5, Color("#68c5c6"))
				batch.crystal(Vector3(side * 11, 5, -13), 3, 18, tint)
			batch.box(Vector3(0, 15, -4), Vector3(10, 2, 12), Color("#68c5c6"))
	for side in [-1.0, 1.0]:
		for row in range(3 if orbital else 2):
			var at := Vector3(side * (22 + row * 16), 9 + row * 4, 27 - row * 22) if orbital else Vector3(side * (19 if row == 0 else 30), 10 if row == 0 else 8, 14 if row == 0 else -4)
			var root := Vector3(side * 12, 3, at.z - 5)
			batch.limb(root, at - Vector3.UP, 2.2, 1.3, tint)
			batch.box(at - Vector3.UP * 0.6, Vector3(9, 1.2, 9), tint)
	return VectorArt.remember_model(key, batch.build())

static func player_ship(id: String) -> Node3D:
	var key := "player:" + id
	var model := VectorArt.cached_model(key)
	if model == null:
		var batch := GeometryBatch.new()
		match id:
			"titan", "bastion": _capital_hull(batch, id == "bastion")
			"hawk": _hawk(batch)
			"emergency": _skiff(batch)
			_: _rook(batch)
		model = VectorArt.remember_model(key, batch.build())
	model.set_meta("player_hull", id)
	return model

static func _rook(batch: GeometryBatch) -> void:
	var trim := VectorArt.CYAN
	batch.ship_hull(Vector3.ZERO, [Vector3(0.6, 0.3, -3.3), Vector3(1.2, 0.7, -1.2), Vector3(1, 0.6, 2.1)], trim, Color("#284353"))
	batch.ship_hull(Vector3(0, 0.64, 0), [Vector3(0.4, 0.12, -1.6), Vector3(0.67, 0.48, -0.5), Vector3(0.6, 0.35, 0.4)], trim, Color("#10556a"))
	for side in [-1.0, 1.0]:
		batch.limb(Vector3(side * 0.8, 0, -0.1), Vector3(side * 2.8, 0.32, 0.8), 0.45, 0.25, trim, 5)
		batch.ship_hull(Vector3(side * 2.8, 0.32, 0), [Vector3(0.3, 0.3, -0.9), Vector3(0.54, 0.6, 0.3), Vector3(0.48, 0.5, 2.4)], trim, Color("#345266"))
		batch.ring(Vector3(side * 2.8, 0.32, 2.42), 0.32, VectorArt.AMBER)

static func _hawk(batch: GeometryBatch) -> void:
	batch.ship_hull(Vector3.ZERO, [Vector3(0.12, 0.1, -4.5), Vector3(0.75, 0.6, -0.5), Vector3(0.9, 0.5, 2.4)], VectorArt.CYAN, Color("#32495f"))
	batch.tube(Vector3(0, 0, 2.35), 0.55, 0.55, VectorArt.AMBER)
	for side in [-1.0, 1.0]:
		var foil := PackedVector3Array([Vector3(side * 0.55, 0.2, -1.2), Vector3(side * 3.4, -0.32, -2.3), Vector3(side * 2.6, -0.2, 0.2), Vector3(side * 0.7, 0.13, 1.8)])
		batch.surface(foil, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#294457"))
		batch.outline(foil, VectorArt.CYAN)
		batch.limb(Vector3(side * 0.6, 0.25, 0.9), Vector3(side * 1.4, 1.35, 2.5), 0.35, 0.09, OCEAN, 4)

static func _skiff(batch: GeometryBatch) -> void:
	# Offset wheelhouse leaves a clear loading lane beside the rescue capsule.
	batch.box(Vector3(0, -0.45, 0), Vector3(3.2, 0.45, 4.4), VectorArt.AMBER)
	batch.ship_hull(Vector3(-0.85, 0.25, 0), [Vector3(0.5, 0.38, -2.5), Vector3(0.74, 0.85, -1.3), Vector3(0.7, 0.75, 1.5)], VectorArt.CYAN, Color("#384d58"))
	batch.tube(Vector3(0.8, 0.34, 0.4), 0.66, 2.7, VectorArt.AMBER, 8)
	for z in [-0.8, 1.6]:
		batch.ring(Vector3(0.8, 0.34, z), 0.7, OCEAN, 8)
	for side in [-1.0, 1.0]:
		batch.box(Vector3(side, -0.25, 2.1), Vector3(0.85, 0.75, 1.1), OCEAN)

static func _capital_hull(batch: GeometryBatch, bastion: bool) -> void:
	var tint: Color = Color("#d3b3ef") if bastion else OCEAN
	if bastion:
		# Tall citadel straddles an open slot between two armored prows.
		batch.ship_hull(Vector3.ZERO, [Vector3(1.2, 0.5, -0.6), Vector3(2.9, 0.9, 1), Vector3(2.2, 0.7, 3.2)], tint, Color("#403851"))
		batch.box(Vector3(0, 1.15, 1.35), Vector3(2.2, 1.4, 2.1), tint)
	else:
		batch.ship_hull(Vector3.ZERO, [Vector3(0.45, 0.35, -4.9), Vector3(1.2, 0.8, -2.8), Vector3(2, 1, 1.6), Vector3(1.7, 0.7, 3.9)], tint, Color("#283844"))
		batch.box(Vector3(0, 1, 1.25), Vector3(2.1, 1.05, 1.8), tint)
	for side in [-1.0, 1.0]:
		var x: float = side * (2.3 if bastion else 1.9)
		batch.ship_hull(Vector3(x, -0.2, 0), [Vector3(0.4, 0.4, -4 if bastion else -1.2), Vector3(0.95, 0.8, -0.2), Vector3(0.72, 0.65, 3.5)], tint, Color("#384356"))
		batch.ring(Vector3(x, -0.2, 3.52), 0.49, VectorArt.AMBER)
		for z in [-0.2, 1.1, 2.4]:
			batch.box(Vector3(x, 0.56, z), Vector3(1, 0.24, 0.55), tint)
