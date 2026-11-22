class_name VectorArt
extends RefCounted

const LINE_SHADER: Shader = preload("res://shaders/vector_line.gdshader")
const AMBER := Color("#ff984b")
const CYAN := Color("#6eebed")
const HOSTILE := Color("#ff667e")
const VIEW_DISTANCE: float = 1200.0
const DETAIL_FADE_START: float = 850.0
const DETAIL_FADE_END: float = 1150.0
const CHUNK_LENGTH: float = 128.0
const TERRAIN_CACHE_CHUNKS: int = 62
static var line_material: ShaderMaterial
static var flat_materials: Dictionary = {}
static var vertex_materials: Dictionary = {}
static var model_cache: Dictionary = {}

static func cached_model(key: String) -> Node3D:
	if not model_cache.has(key):
		return null
	var result := Node3D.new()
	for item in model_cache[key]:
		var instance: GeometryInstance3D
		if item["mesh"] is MultiMesh:
			instance = MultiMeshInstance3D.new()
			instance.multimesh = item["mesh"]
			instance.set_instance_shader_parameter(&"weathered", true)
		else:
			instance = MeshInstance3D.new()
			instance.mesh = item["mesh"]
		instance.material_override = item["material"]
		instance.extra_cull_margin = item["margin"]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		result.add_child(instance)
	return result

static func remember_model(key: String, model: Node3D) -> Node3D:
	var surfaces: Array[Dictionary] = []
	for child in model.get_children():
		var mesh: Resource = child.multimesh if child is MultiMeshInstance3D else child.mesh
		surfaces.append({"mesh": mesh, "material": child.material_override, "margin": child.extra_cull_margin})
	model_cache[key] = surfaces
	return model

static func set_reduced_effects(reduced: bool) -> void:
	ensure_material()
	FleetArt.hull_material.set_shader_parameter("pulse_strength", 0.0 if reduced else 1.0)
	line_material.set_shader_parameter("halo_strength", 0.0 if reduced else 0.65)
	line_material.set_shader_parameter("stroke_width", 1.15 if reduced else 1.4)

static func ensure_material() -> void:
	if line_material == null:
		line_material = ShaderMaterial.new()
		line_material.shader = LINE_SHADER
		line_material.set_shader_parameter("fade_start", DETAIL_FADE_START)
		line_material.set_shader_parameter("fade_end", DETAIL_FADE_END)

static func lines(points: PackedVector3Array, color: Color, segment_colors: PackedColorArray = PackedColorArray()) -> MeshInstance3D:
	ensure_material()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in range(0, points.size(), 2):
		var start: Vector3 = points[i]
		var end: Vector3 = points[i + 1]
		var direction: Vector3 = end - start
		if direction.length_squared() < 0.000001:
			continue
		var base: int = vertices.size()
		vertices.append_array(PackedVector3Array([start, start, end, end]))
		# NORMAL carries the segment direction for screen-space stroke expansion.
		for _j in range(4):
			normals.append(direction)
			colors.append(color if segment_colors.is_empty() else segment_colors[i / 2])
		uvs.append_array(PackedVector2Array([Vector2(0, -1), Vector2(0, 1), Vector2(1, 1), Vector2(1, -1)]))
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = line_material
	instance.extra_cull_margin = 2.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

static func solid(vertices: PackedVector3Array, triangles: PackedInt32Array, tint: Color, vertex_colors: PackedColorArray = PackedColorArray()) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = triangles
	if not vertex_colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = vertex_colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Keep breakup data on the CPU instead of reading renderer buffers on impact.
	mesh.set_meta("fragment_vertices", vertices)
	mesh.set_meta("fragment_indices", triangles)
	mesh.set_meta("fragment_colors", vertex_colors)
	var materials: Dictionary = flat_materials if vertex_colors.is_empty() else vertex_materials
	if not materials.has(tint):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color = tint
		material.vertex_color_use_as_albedo = not vertex_colors.is_empty()
		material.vertex_color_is_srgb = true
		materials[tint] = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = materials[tint]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance

static func box(size: Vector3, color: Color) -> Node3D:
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, size, color)
	return batch.build()

static func ship() -> Node3D:
	return FleetArt.model("range")

static func cockpit_detail() -> Node3D:
	var batch := GeometryBatch.new()
	var trim := Color("#37616e")
	for side in [-1.0, 1.0]:
		var x: float = side * 1.12
		batch.box(Vector3(x, -0.7, -2.28), Vector3(0.32, 0.24, 1.45), trim, Color("#13232c"))
		batch.box(Vector3(x, -0.7, -3.12), Vector3(0.16, 0.14, 0.5), AMBER)
		batch.ring(Vector3(x, -0.7, -3.38), 0.07, AMBER, 8)
		for i in range(6):
			batch.box(Vector3(x, -0.565, -2.75 + i * 0.19), Vector3(0.28, 0.035, 0.06), trim)
		batch.box(Vector3(x, -0.88, -1.91), Vector3(0.46, 0.2, 0.37), trim)
		batch.outline(PackedVector3Array([Vector3(side * 1.5, -0.86, -1.79), Vector3(side * 1.82, -0.6, -2.0), Vector3(side * 2.0, -0.55, -2.2)]), trim, false)
		batch.box(Vector3(side * 0.63, -0.94, -1.69), Vector3(0.5, 0.28, 0.05), trim, Color("#08131d"))
		for i in range(5):
			batch.box(Vector3(side * (0.44 + i * 0.085), -0.9, -1.654), Vector3(0.025, 0.07 + (i % 3) * 0.025, 0.008), Color("#397c85"))
		batch.outline(PackedVector3Array([Vector3(side * 0.36, -1.11, -1.65), Vector3(side * 0.9, -1.11, -1.65), Vector3(side * 1.03, -1.3, -1.65)]), trim, false)
	batch.box(Vector3(0, -0.79, -1.76), Vector3(0.65, 0.07, 0.12), trim)
	for i in range(11):
		batch.line(Vector3(-0.28 + i * 0.056, -0.77, -1.69), Vector3(-0.28 + i * 0.056, -0.805, -1.69), Color("#59898d"))
	return batch.build()

static func tower() -> Node3D:
	return GroundArt.tower("ignis")

static func ground_point(x: float, travel: float, branching: bool = false) -> Vector3:
	var cliff: float = maxf(0.0, absf(x) - 12.0)
	if branching:
		cliff = minf(cliff, maxf(0.0, absf(x - GroundRoute.lateral_offset(travel)) - 10.0))
	var height: float = cliff * 0.4 + sin(travel * 0.043 + x * 0.17) * minf(8.0, cliff * 0.33)
	return Vector3(FlightState.rail_point(travel).x + x, height - 1.0, -travel)

static func canyon_clearance(point: Vector3, branching: bool, icy: bool, radius: float) -> float:
	var row := floorf(-point.z / 8.0) * 8.0
	var v := (-point.z - row) / 8.0
	var x := point.x - lerpf(FlightState.rail_point(row).x, FlightState.rail_point(row + 8).x, v)
	if absf(x) + radius > 108.0:
		return -INF
	var column := floorf(x / 9.0) * 9.0
	var u := (x - column) / 9.0
	var a := ground_point(column, row, branching).y
	var b := ground_point(column + 9, row, branching).y
	var c := ground_point(column, row + 8, branching).y
	var d := ground_point(column + 9, row + 8, branching).y
	# The two meshes split the same sloping quad on opposite diagonals.
	var height: float
	if icy:
		height = a + u * (b - a) + v * (d - b) if u >= v else a + u * (d - c) + v * (c - a)
	else:
		height = a + u * (b - a) + v * (c - a) if u + v <= 1 else d + (1 - u) * (c - d) + (1 - v) * (b - d)
	return point.y - height - radius - 0.35 # Includes cockpit shake and road markings.

static func ground_horizon(icy: bool = false) -> Node3D:
	var key: String = "cryo_horizon" if icy else "ground_horizon"
	var cached: Node3D = cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for row in range(40):
		for column in range(40):
			var points := PackedVector3Array()
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var x: float = (column - 20 + corner.x) * 1000
				var z: float = (row - 20 + corner.y) * 1000
				var y: float = -22 - absf(sin(x * 0.002) * cos(z * 0.0015)) * 12
				points.append(Vector3(x, y, z))
			batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#152e44") if icy else Color("#21151c") if (row + column) % 3 == 0 else Color("#1b1520"))
			batch.outline(points, Color("#335b76") if icy else Color("#38212c"))
	return remember_model(key, batch.build())

static func turret_base() -> Node3D:
	return FleetArt.model("mount_ignis", "ground")

static func turret_head() -> Node3D:
	return FleetArt.model("battery", "ground")

static func enemy_missile(tint: Color = HOSTILE) -> Node3D:
	var batch := GeometryBatch.new()
	var points := PackedVector3Array([Vector3(0, 0, -1.5), Vector3(-0.32, 0, 0.6), Vector3(0, 0.32, 0.6), Vector3(0.32, 0, 0.6), Vector3(0, -0.32, 0.6)])
	batch.surface(points, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1]), Color("#461d30"))
	for i in range(1, 5):
		batch.line(points[0], points[i], tint)
	batch.ring(Vector3(0, 0, 0.65), 0.3, AMBER, 8)
	for side in [-1.0, 1.0]:
		batch.outline(PackedVector3Array([Vector3(side * 0.3, 0, 0), Vector3(side * 0.85, 0, 0.8), Vector3(side * 0.3, 0, 0.55)]), tint)
	batch.line(Vector3(0, 0, 0.6), Vector3(0, 0, 3.8), AMBER)
	return batch.build()

static func terrain_chunk(start: float, branching: bool = false, icy: bool = false) -> Node3D:
	if icy:
		return _ice_chunk(start, branching)
	branching = branching and start + CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("branch_terrain:%d" if branching else "terrain:%d") % int(start)
	var cached: Node3D = cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var terrain := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
	var points := PackedVector3Array()
	var triangles := PackedInt32Array()
	const COLUMNS: int = 25
	const ROWS: int = 17
	for row in range(ROWS):
		var travel: float = start + float(row) * 8.0
		for column in range(COLUMNS):
			var x: float = float(column - 12) * 9.0
			points.append(ground_point(x, travel, branching))
	for row in range(ROWS - 1):
		for column in range(COLUMNS - 1):
			var a: int = row * COLUMNS + column
			var b: int = a + 1
			var c: int = a + COLUMNS
			var d: int = c + 1
			triangles.append_array(PackedInt32Array([a, c, b, b, c, d]))
	terrain.surface(points, triangles, Color.WHITE)
	for row in range(ROWS - 1):
		for side in [-1.0, 1.0]:
			var travel: float = start + float(row) * 8.0
			var next_travel: float = travel + 8.0
			var a: Vector3 = ground_point(side * 3.0, travel) + Vector3.UP * 0.2
			var b: Vector3 = ground_point(side * 3.0, next_travel) + Vector3.UP * 0.2
			batch.line(a, b, AMBER)
			batch.line(a, ground_point(side * (3.2 + sin(travel * 0.12) * 0.3), next_travel) + Vector3.UP * 0.2, Color("#91432e"))
	for section in range(8):
		var travel: float = start + section * 16.0 + 2.0
		for side in [-1.0, 1.0]:
			var panel := PackedVector3Array()
			for corner in [Vector2(4.2, 0), Vector2(10.8, 0), Vector2(10.8, 10), Vector2(4.2, 10)]:
				panel.append(ground_point(side * corner.x, travel + corner.y) + Vector3.UP * 0.07)
			batch.surface(panel, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#172027"))
			batch.outline(panel, Color("#40545d"))
			for groove in range(3):
				batch.line(ground_point(side * 5.0, travel + 2 + groove * 2) + Vector3.UP * 0.1, ground_point(side * 9.8, travel + 2 + groove * 2) + Vector3.UP * 0.1, Color("#5c5d50"))
	for i in range(6):
		var travel: float = start + 12.0 + i * 19.0
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var rock_x: float = side * (22.0 + (i % 3) * 11.0)
		if branching and absf(rock_x - GroundRoute.lateral_offset(travel)) < 18.0:
			continue
		var center: Vector3 = ground_point(rock_x, travel, branching)
		var size := Vector3(1.0, 0.72 + (i % 3) * 0.36, 1.0)
		scenery.append(GroundArt.placement(center, size, travel * 0.47))
	var station: Vector3 = ground_point(-28.0 if branching or int(start / CHUNK_LENGTH) % 2 == 0 else 28.0, start + 64.0)
	var chunk := GroundArt.finish_chunk(batch.build(), terrain, scenery, "ignis")
	GroundArt.add_landmarks(chunk, "canyon_substation", [GroundArt.placement(station, Vector3.ONE)])
	return remember_model(key, chunk) if start < TERRAIN_CACHE_CHUNKS * CHUNK_LENGTH else chunk

static func _ice_chunk(start: float, branching: bool) -> Node3D:
	branching = branching and start + CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("cryo_branch:%d" if branching else "cryo_terrain:%d") % int(start)
	var cached: Node3D = cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var terrain := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
	for row in range(16):
		var travel: float = start + row * 8.0
		for column in range(24):
			var x: float = (column - 12) * 9.0
			var a: Vector3 = ground_point(x, travel, branching)
			var b: Vector3 = ground_point(x + 9, travel, branching)
			var c: Vector3 = ground_point(x + 9, travel + 8, branching)
			var d: Vector3 = ground_point(x, travel + 8, branching)
			terrain.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE)
		for route in range(2 if branching else 1):
			var offset: float = GroundRoute.lateral_offset(travel) if route == 1 else 0.0
			var next_offset: float = GroundRoute.lateral_offset(travel + 8) if route == 1 else 0.0
			var a: Vector3 = ground_point(offset - 3.2, travel, branching) + Vector3.UP * 0.08
			var b: Vector3 = ground_point(offset + 3.2, travel, branching) + Vector3.UP * 0.08
			var c: Vector3 = ground_point(next_offset + 3.2, travel + 8, branching) + Vector3.UP * 0.08
			var d: Vector3 = ground_point(next_offset - 3.2, travel + 8, branching) + Vector3.UP * 0.08
			terrain.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#6ecae1"))
			batch.line(a, d, Color("#c0e8ed"))
			batch.line(b, c, Color("#c0e8ed"))
			batch.line(a.lerp(b, 0.3), d.lerp(c, 0.55), Color("#73b6ce"))
	for i in range(8):
		var travel: float = start + 8 + i * 15
		var x: float = (-1 if i % 2 == 0 else 1) * (25 + (i % 3) * 18)
		if branching and absf(x - GroundRoute.lateral_offset(travel)) < 22:
			continue
		var at: Vector3 = ground_point(x, travel, branching)
		var height := (18.0 + i % 4 * 7) / 22.0
		scenery.append(GroundArt.placement(at, Vector3(1, height, 1), travel * 0.23))
	var chunk := GroundArt.finish_chunk(batch.build(), terrain, scenery, "cryo")
	return remember_model(key, chunk) if start < TERRAIN_CACHE_CHUNKS * CHUNK_LENGTH else chunk
