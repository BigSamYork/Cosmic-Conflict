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
	var terrain := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
	var layout := RandomNumberGenerator.new()
	layout.seed = hash(Vector2i(roundi(start / VectorArt.CHUNK_LENGTH), sector.hash()))
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
		for side in [-1.0, 1.0]:
			var travel := start + layout.randf_range(22.0, 106.0)
			var lateral: float = side * layout.randf_range(46.0, 96.0)
			var at: Vector3 = floor_point(lateral, travel)
			if branching and absf(lateral - GroundRoute.lateral_offset(travel)) < 40:
				at.x += side * 75
			if layout.randf() > 0.19:
				var footprint := layout.randf_range(0.87, 1.23)
				scenery.append(GroundArt.placement(at, Vector3(footprint, layout.randf_range(0.8, 1.18), footprint), layout.randf_range(-0.6, 0.6) + (PI if side > 0 else 0.0)))
		terrain.box(floor_point(0, start + 64) + Vector3(0, -0.5, 0), Vector3(24, 0.6, 128), OCEAN, Color.WHITE)
		GroundArt.finish_chunk(result, terrain, scenery, sector)
		return VectorArt.remember_model(key, result) if start < VectorArt.TERRAIN_CACHE_CHUNKS * 128 else result
	var arches: Array[Transform3D] = []
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
			terrain.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE)
	for side in [-1.0, 1.0]:
		for i in range(3):
			var lateral: float = side * (layout.randf_range(36.0, 63.0) + i * 27.0)
			var travel := start + layout.randf_range(10.0, 30.0) + i * 39.0
			var at: Vector3 = floor_point(lateral, travel, sector)
			if branching and absf(lateral - GroundRoute.lateral_offset(travel)) < 35:
				continue
			scenery.append(GroundArt.placement(at, Vector3(1, layout.randf_range(0.69, 1.35) + i * 0.18, 1), layout.randf_range(-1.2, 1.2)))
			if i == 0 and layout.randf() < 0.29:
				arches.append(GroundArt.placement(at + Vector3(0, 0, 30), Vector3(0.95, layout.randf_range(0.72, 1.21), 1), layout.randf_range(-0.52, 0.52)))
	var chunk := GroundArt.finish_chunk(batch.build(), terrain, scenery, sector)
	GroundArt.add_landmarks(chunk, "ruin_arch", arches)
	return VectorArt.remember_model(key, chunk) if start < VectorArt.TERRAIN_CACHE_CHUNKS * 128 else chunk

static func fighter(sector: String, heavy: bool = false) -> Node3D:
	var id := "tide" if sector == "thalassa" else "scarab"
	return FleetArt.model(id + "_heavy" if heavy else id)

static func pylon(sector: String) -> Node3D:
	return GroundArt.tower(sector)

static func turret_base(sector: String) -> Node3D:
	return FleetArt.model("mount_" + sector, "ground")

static func boss(sector: String, orbital: bool) -> Node3D:
	if orbital:
		return FleetArt.model("ark" if sector == "thalassa" else "sovereign")
	return FleetArt.model("tempest_walker" if sector == "thalassa" else "sunforge_colossus", "ground")

static func player_ship(id: String) -> Node3D:
	var model := FleetArt.model(id if CampaignState.SHIPS.has(id) else "rook")
	model.set_meta("player_hull", id)
	return model
