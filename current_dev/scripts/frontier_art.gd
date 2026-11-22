class_name FrontierArt
extends RefCounted

const WATER: Shader = preload("res://shaders/storm_water.gdshader")
const WATER_REFLECTION: Shader = preload("res://shaders/storm_water_reflection.gdshader")
const WATER_ARRIVAL: Shader = preload("res://shaders/storm_water_arrival.gdshader")
const OCEAN := Color("#72d8ff")
const SAND := Color("#e8bf65")
const SEA_LEVEL := -1.8
const SEA_COLUMNS := 96
const SEA_ROWS := 24
static var sea_indices := PackedInt32Array()

static func _static_init() -> void:
	for shader: Shader in [WATER, WATER_REFLECTION, WATER_ARRIVAL]:
		shader.set_default_texture_parameter(&"sea_detail", preload("res://assets/ground/sea_detail.png"))

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
		scenery = _rigs(start, branching)
		var nearby := _rigs(start - VectorArt.CHUNK_LENGTH, branching)
		nearby.append_array(scenery)
		nearby.append_array(_rigs(start + VectorArt.CHUNK_LENGTH, branching))
		var result := Node3D.new()
		result.add_child(_sea_surface(start, nearby))
		GroundArt.finish_chunk(result, terrain, scenery, sector, start, branching)
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
	var chunk := GroundArt.finish_chunk(batch.build(), terrain, scenery, sector, start, branching)
	GroundArt.add_landmarks(chunk, "ruin_arch", arches)
	return VectorArt.remember_model(key, chunk) if start < VectorArt.TERRAIN_CACHE_CHUNKS * 128 else chunk

static func _rigs(start: float, branching: bool) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(roundi(start / VectorArt.CHUNK_LENGTH), "thalassa".hash()))
	var rigs: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		var travel := start + rng.randf_range(22.0, 106.0)
		var lateral: float = side * rng.randf_range(46.0, 96.0)
		var at := floor_point(lateral, travel)
		if branching and absf(lateral - GroundRoute.lateral_offset(travel)) < 40:
			at.x += side * 75
		if rng.randf() > 0.19:
			var width := rng.randf_range(0.87, 1.23)
			rigs.append(GroundArt.placement(at, Vector3(width, rng.randf_range(0.8, 1.18), width), rng.randf_range(-0.6, 0.6) + (PI if side > 0 else 0.0)))
	return rigs

static func _sea_surface(start: float, rigs: Array[Transform3D]) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var rig_masks := PackedVector2Array()
	var stride := SEA_COLUMNS + 1
	vertices.resize(stride * (SEA_ROWS + 1))
	rig_masks.resize(vertices.size())
	for row in range(SEA_ROWS + 1):
		var z := -start - VectorArt.CHUNK_LENGTH * row / SEA_ROWS
		for column in range(stride):
			var index := row * stride + column
			vertices[index] = Vector3((column - SEA_COLUMNS * 0.5) * 6.0, SEA_LEVEL, z)
	# UV.x follows the oil plume down-current. UV.y marks disturbed water by the rig.
	# Include adjacent chunks so both edges agree when a plume crosses the seam.
	for rig in rigs:
		var center := Vector2(rig.origin.x, rig.origin.z)
		for row in range(SEA_ROWS + 1):
			var dz := vertices[row * stride].z - center.y
			if absf(dz) > 55.0:
				continue
			for column in range(stride):
				var index := row * stride + column
				var dx := vertices[index].x - center.x
				if absf(dx) > 86.0:
					continue
				var oil := 1.0 - Vector2((dx - 30.0) / 56.0, (dz - 0.24 * dx) / 22.0).length()
				var wash := 1.0 - Vector2(dx / 23.0, dz / 31.0).length()
				var mask := rig_masks[index]
				rig_masks[index] = Vector2(maxf(mask.x, oil), maxf(mask.y, wash))
	if sea_indices.is_empty():
		for row in range(SEA_ROWS):
			for column in range(SEA_COLUMNS):
				var a := row * stride + column
				sea_indices.append_array(PackedInt32Array([a, a + 1, a + stride, a + 1, a + stride + 1, a + stride]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = rig_masks
	arrays[Mesh.ARRAY_INDEX] = sea_indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Missiles and the swept flight probe only need the mean waterline.
	var cover := ConcavePolygonShape3D.new()
	cover.backface_collision = true
	cover.set_faces(PackedVector3Array([vertices[0], vertices[SEA_COLUMNS], vertices[-1], vertices[0], vertices[-1], vertices[-stride]]))
	mesh.set_meta("ground_cover", cover)
	var surface := MeshInstance3D.new()
	surface.mesh = mesh
	var water := ShaderMaterial.new()
	water.shader = WATER
	surface.material_override = water
	surface.extra_cull_margin = 3.0
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return surface

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
