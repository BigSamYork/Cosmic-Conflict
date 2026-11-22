class_name LaunchApproach
extends Node3D

const PLANET_RADIUS: float = 4000.0
const SURFACE_CLEARANCE: float = 80.0
const VIEW_DISTANCE: float = 22000.0
const HYPERSPACE_DURATION: float = 3.0
const PLANET_SHADER: Shader = preload("res://shaders/planet_surface.gdshader")
const GROUND_SHADER: Shader = preload("res://shaders/arrival_ground.gdshader")
const TERRAIN_REVEAL_HEIGHT: float = 280.0
const TERRAIN_OPAQUE_HEIGHT: float = 60.0
const CURVE_START_HEIGHT: float = 95.0
const CURVE_END_HEIGHT: float = 20.0
const HORIZON_EDGE_LENGTH: float = 500.0
static var horizon_meshes: Dictionary = {}
var ground_course: Transform3D
var alignment_frame: Transform3D
var descent_frame: Transform3D
var planet: Node3D
var planet_material: ShaderMaterial
var planet_lines: ShaderMaterial
var streaks: MultiMeshInstance3D
var streak_material: ShaderMaterial
var star_positions := PackedVector3Array()
var age: float = 0.0
var star_travel: float = 0.0
var ground_shaders: Array[ShaderMaterial] = []
var ground_sources: Array[Dictionary] = []
var sector: String = "ignis"
var curvature: float = 1.0

func _ready() -> void:
	planet = _planet_model(sector)
	add_child(planet)
	var solid := planet.get_child(0) as MeshInstance3D
	planet_material = solid.material_override.duplicate()
	planet_material.set_shader_parameter("reveal", 0.0)
	solid.material_override = planet_material
	var lines := planet.get_child(1) as MeshInstance3D
	planet_lines = lines.material_override.duplicate()
	planet_lines.render_priority = 1
	planet_lines.set_shader_parameter("fade_start", VIEW_DISTANCE)
	planet_lines.set_shader_parameter("fade_end", VIEW_DISTANCE + 5000)
	lines.material_override = planet_lines
	planet.hide()
	var unit: MeshInstance3D = VectorArt.lines(PackedVector3Array([Vector3.ZERO, Vector3.BACK]), VectorArt.CYAN)
	streak_material = unit.material_override.duplicate()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = unit.mesh
	instances.instance_count = 128
	streaks = MultiMeshInstance3D.new()
	streaks.multimesh = instances
	streaks.material_override = streak_material
	streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streaks)
	unit.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 27117
	for _i in range(instances.instance_count):
		var angle: float = rng.randf_range(0, TAU)
		var radius: float = rng.randf_range(18, 75)
		star_positions.append(Vector3(cos(angle) * radius, sin(angle) * radius, rng.randf_range(0, 400)))
	streaks.hide()

func configure(station_frame: Transform3D) -> void:
	var exit_basis: Basis = station_frame.basis * Basis(Vector3.UP, PI)
	var heading := Vector3(-exit_basis.z.x, 0, -exit_basis.z.z).normalized()
	var level := Basis.looking_at(heading)
	ground_course = Transform3D(level, station_frame.origin + heading * 11000 - Vector3.UP * 2200)
	alignment_frame = Transform3D(Basis.looking_at((heading + Vector3.UP * 0.55).normalized()), station_frame.origin + heading * 900 + Vector3.UP * 560)
	descent_frame = ground_course * Transform3D(Basis.looking_at(Vector3(0, -0.65, -1).normalized()), Vector3(0, 1600, 2000))
	planet.global_transform = ground_course * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * PLANET_RADIUS), Vector3(0, -PLANET_RADIUS - SURFACE_CLEARANCE, 0))

func attach_ground(ground: Node3D, horizon: Node3D = null) -> void:
	var copies: Dictionary = {}
	for child in ground.find_children("*", "GeometryInstance3D", true, false):
		var geometry := child as GeometryInstance3D
		var original: Material = geometry.material_override
		assert(original is StandardMaterial3D or original is ShaderMaterial)
		if not copies.has(original):
			var material: ShaderMaterial
			if original is StandardMaterial3D:
				assert(original.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)
				material = ShaderMaterial.new()
				material.shader = GROUND_SHADER
				material.set_shader_parameter("base_color", original.albedo_color)
				material.set_shader_parameter("use_vertex_color", original.vertex_color_use_as_albedo)
			else:
				material = original.duplicate() as ShaderMaterial
				if original.shader == FrontierArt.WATER:
					material.shader = FrontierArt.WATER_ARRIVAL
				material.render_priority = 1
			material.set_shader_parameter("effect_opacity", 0.0)
			material.set_shader_parameter("arrival_ground_to_world", ground_course)
			material.set_shader_parameter("arrival_world_to_ground", ground_course.affine_inverse())
			material.set_shader_parameter("arrival_radius", PLANET_RADIUS)
			material.set_shader_parameter("arrival_clearance", SURFACE_CLEARANCE)
			material.set_shader_parameter("arrival_curvature", 1.0)
			ground_shaders.append(material)
			copies[original] = material
		var mesh: Mesh = geometry.mesh if geometry is MeshInstance3D else null
		ground_sources.append({"node": geometry, "material": original, "mesh": mesh, "margin": geometry.extra_cull_margin})
		if horizon != null and horizon.is_ancestor_of(geometry) and (original is StandardMaterial3D or (original is ShaderMaterial and original.shader == FrontierArt.WATER)):
			geometry.mesh = _subdivided_horizon(mesh)
		geometry.extra_cull_margin += PLANET_RADIUS
		geometry.material_override = copies[original]

func restore_ground() -> void:
	for source in ground_sources:
		if is_instance_valid(source["node"]):
			source["node"].material_override = source["material"]
			source["node"].extra_cull_margin = source["margin"]
			if source["node"] is MeshInstance3D and source["node"].mesh != source["mesh"]:
				source["node"].mesh = source["mesh"]
	ground_sources.clear()

func _exit_tree() -> void:
	restore_ground()

func terrain_reveal(camera_frame: Transform3D) -> float:
	var height: float = (ground_course.affine_inverse() * camera_frame.origin).y
	return 1.0 - smoothstep(TERRAIN_OPAQUE_HEIGHT, TERRAIN_REVEAL_HEIGHT, height)

static func curved_point(point: Vector3, amount: float = 1.0) -> Vector3:
	var radial := Vector3(point.x, PLANET_RADIUS, point.z).normalized()
	return point.lerp(radial * (PLANET_RADIUS + point.y + SURFACE_CLEARANCE) + Vector3.DOWN * (PLANET_RADIUS + SURFACE_CLEARANCE), amount)

static func _subdivided_horizon(mesh: Mesh) -> Mesh:
	if horizon_meshes.has(mesh):
		return horizon_meshes[mesh]
	# A two-triangle foundation cannot follow an arc in a vertex shader.
	var vertices: PackedVector3Array = mesh.get_meta("fragment_vertices")
	var indices: PackedInt32Array = mesh.get_meta("fragment_indices")
	var colors: PackedColorArray = mesh.get_meta("fragment_colors")
	var batch := GeometryBatch.new()
	for i in range(0, indices.size(), 3):
		_subdivide_triangle(vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]], colors[indices[i]] if not colors.is_empty() else Color.WHITE, batch)
	var model: Node3D = batch.build()
	var result: Mesh = model.get_child(0).mesh
	horizon_meshes[mesh] = result
	model.free()
	return result

static func _subdivide_triangle(a: Vector3, b: Vector3, c: Vector3, tint: Color, batch: GeometryBatch) -> void:
	var ab: float = a.distance_squared_to(b)
	var bc: float = b.distance_squared_to(c)
	var ca: float = c.distance_squared_to(a)
	if maxf(ab, maxf(bc, ca)) <= HORIZON_EDGE_LENGTH * HORIZON_EDGE_LENGTH:
		batch.surface(PackedVector3Array([a, b, c]), PackedInt32Array([0, 1, 2]), tint)
	elif ab >= bc and ab >= ca:
		var middle: Vector3 = (a + b) * 0.5
		_subdivide_triangle(a, middle, c, tint, batch)
		_subdivide_triangle(middle, b, c, tint, batch)
	elif bc >= ca:
		var middle: Vector3 = (b + c) * 0.5
		_subdivide_triangle(a, b, middle, tint, batch)
		_subdivide_triangle(a, middle, c, tint, batch)
	else:
		var middle: Vector3 = (c + a) * 0.5
		_subdivide_triangle(a, b, middle, tint, batch)
		_subdivide_triangle(middle, b, c, tint, batch)

func advance(delta: float, intensity: float, planet_reveal: float, ground_reveal: float, camera_frame: Transform3D) -> void:
	age += delta
	planet.visible = planet_reveal > 0
	planet_material.set_shader_parameter("reveal", planet_reveal)
	planet_material.set_shader_parameter("surface_time", age)
	planet_lines.set_shader_parameter("effect_opacity", planet_reveal * 0.22)
	var height: float = (ground_course.affine_inverse() * camera_frame.origin).y
	curvature = smoothstep(CURVE_END_HEIGHT, CURVE_START_HEIGHT, height)
	for material in ground_shaders:
		material.set_shader_parameter("effect_opacity", smoothstep(0.75, 1.0, ground_reveal) if material.shader == VectorArt.LINE_SHADER else ground_reveal)
		material.set_shader_parameter("arrival_curvature", curvature)
		if material.shader == VectorArt.LINE_SHADER:
			material.set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))
			material.set_shader_parameter("stroke_width", VectorArt.line_material.get_shader_parameter("stroke_width"))
	streaks.global_transform = camera_frame
	streaks.visible = intensity > 0.001
	streak_material.set_shader_parameter("effect_opacity", intensity)
	for material: ShaderMaterial in [streak_material, planet_lines]:
		if material != null:
			material.set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))
			material.set_shader_parameter("stroke_width", VectorArt.line_material.get_shader_parameter("stroke_width"))
	if streaks.visible:
		star_travel += delta * (250 + intensity * 800)
		for i in range(star_positions.size()):
			var at: Vector3 = star_positions[i]
			at.z = -fposmod(at.z - star_travel, 400) - 8
			streaks.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1, 3 + intensity * 35)), at))

static func _planet_model(destination: String = "ignis") -> Node3D:
	assert(SectorCatalog.NAMES.has(destination), "Unknown arrival planet: " + destination)
	var icy: bool = destination == "cryo"
	var urban: bool = destination == "vespera"
	var key: String = destination + "_arrival_planet"
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var vertices := PackedVector3Array()
	var triangles := PackedInt32Array()
	const RINGS: int = 64
	const SECTORS: int = 128
	var noise := FastNoiseLite.new()
	noise.seed = 7341 + SectorCatalog.NAMES.keys().find(destination)
	noise.frequency = 4.0
	noise.fractal_octaves = 4
	for ring in range(RINGS + 1):
		var latitude: float = PI * ring / RINGS
		for sector in range(SECTORS + 1):
			var longitude: float = TAU * sector / SECTORS
			var normal := Vector3(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude))
			vertices.append(normal * (1.0 + noise.get_noise_3dv(normal) * 0.003))
	for ring in range(RINGS):
		for sector in range(SECTORS):
			var a: int = ring * (SECTORS + 1) + sector
			var b: int = a + SECTORS + 1
			triangles.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
	var model := Node3D.new()
	var surface: MeshInstance3D = VectorArt.solid(vertices, triangles, Color.WHITE)
	var material := ShaderMaterial.new()
	material.shader = PLANET_SHADER
	material.set_shader_parameter("terrain_style", SectorCatalog.NAMES.keys().find(destination))
	surface.material_override = material
	model.add_child(surface)
	var grid := GeometryBatch.new()
	for ring in range(8, RINGS, 8):
		var points := PackedVector3Array()
		for sector in range(SECTORS):
			points.append(vertices[ring * (SECTORS + 1) + sector] * 1.002)
		grid.outline(points, SectorCatalog.ACCENTS[destination].darkened(0.25))
	for sector in range(0, SECTORS, 16):
		var points := PackedVector3Array()
		for ring in range(RINGS + 1):
			points.append(vertices[ring * (SECTORS + 1) + sector] * 1.002)
		grid.outline(points, VesperaArt.SIGNAL if urban else Color("#6aa3cb") if icy else Color("#704955"), false)
	var outline: Node3D = grid.build()
	var strokes: MeshInstance3D = outline.get_child(0)
	outline.remove_child(strokes)
	outline.free()
	model.add_child(strokes)
	return VectorArt.remember_model(key, model)
