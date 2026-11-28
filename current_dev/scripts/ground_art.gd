class_name GroundArt
extends RefCounted

const SURFACE := preload("res://shaders/ground_surface.gdshader")
static var materials: Dictionary[String, ShaderMaterial] = {}
const BUILDINGS := {
	"ignis": ["crucible", "kiln_battery", "exchange"],
	"cryo": ["observatory", "borehead", "greenhouse"],
	"vespera": ["arcade", "lantern_hotel", "sky_exchange"],
	"xylo": ["reed_lodge", "seed_vault", "canopy_clinic"],
	"thalassa": ["wave_station", "lighthouse", "nursery"],
	"kharon": ["windcatcher", "cistern", "caravanserai"],
}
const PLANTS := {
	"ignis": ["aloe", "emberbell", "ash_fan"],
	"cryo": ["rime_spruce", "frost_cushion", "willow"],
	"vespera": ["ginkgo", "wisteria", "cycad"],
	"xylo": ["pitchers", "shield_fern", "mangrove"],
	"thalassa": ["kelp", "bladderwrack", "lotus"],
	"kharon": ["barrel_bloom", "yucca", "acacia"],
}
static var foliage_material := ShaderMaterial.new()
static var plant_shapes: Dictionary[String, ConcavePolygonShape3D] = {}

static func _static_init() -> void:
	foliage_material.shader = preload("res://shaders/foliage.gdshader")

static func tower(sector: String) -> Node3D:
	var model := FleetArt.model("tower_" + sector, "ground")
	# Approach lights take over when the foundation and crown become subpixel.
	var marker := GeometryBatch.new()
	for side in [-1.0, 1.0]:
		marker.line(Vector3(side * 1.42, -4.7, 1.63), Vector3(side * 0.55, 4.2, 0.84), Color("#f3b879"))
	marker.line(Vector3(-1.42, -4.7, 1.63), Vector3(1.42, -4.7, 1.63), VectorArt.AMBER)
	var lights := VectorArt.lines(marker.edges, Color.WHITE, marker.edge_colors)
	lights.visibility_range_begin = 250.0
	model.add_child(lights)
	return model

static func placement(at: Vector3, size: Vector3, heading: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, heading).scaled_local(size), at)

static func _height_sample(x: float, travel: float, sector: String, branching: bool) -> Vector3:
	if sector == "kharon":
		return FrontierArt.floor_point(x, travel, sector, branching)
	return VectorArt.ground_point(x, travel, branching)

static func _ground_normals(vertices: PackedVector3Array, sector: String, branching: bool) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	if sector not in ["ignis", "cryo", "kharon"]:
		normals.fill(Vector3.UP)
		return normals
	# Sample the same height field beyond both ends of each chunk. Shared
	# vertices get the same lighting even when their neighbours stream out.
	var corners: Dictionary[Vector3, Vector3] = {}
	var step_x := 10.0 if sector == "kharon" else 9.0
	for i in vertices.size():
		var p := vertices[i]
		if not corners.has(p):
			var travel := -p.z
			var x := p.x - FlightState.rail_point(travel).x
			var across := _height_sample(x + step_x, travel, sector, branching) - _height_sample(x - step_x, travel, sector, branching)
			var forward := _height_sample(x, travel + 8.0, sector, branching) - _height_sample(x, travel - 8.0, sector, branching)
			corners[p] = across.cross(forward).normalized()
		normals[i] = corners[p]
	return normals

# The flight surface follows the course mesh exactly. Repeated Blender scenery
# shares one GPU instance batch per chunk, including on cached return trips.
static func finish_chunk(model: Node3D, floor_mesh: GeometryBatch, props: Array[Transform3D], sector: String, start: float, branching: bool) -> Node3D:
	if not floor_mesh.vertices.is_empty() and not materials.has(sector):
		var material := ShaderMaterial.new()
		material.shader = SURFACE
		if sector not in ["ignis", "cryo"]:
			material.set_shader_parameter("swatch", load("res://assets/ground/%s_surface.png" % sector))
		var deposits := preload("res://assets/ground/ignis_basalt.png") if sector == "ignis" else preload("res://assets/ground/sea_detail.png")
		material.set_shader_parameter("deposits_map", deposits)
		material.set_shader_parameter("surface_id", SectorCatalog.AVAILABLE.find(sector))
		if sector == "cryo":
			material.set_shader_parameter("cryo_snow_map", preload("res://assets/ground/cryo_snow.png"))
		materials[sector] = material
	if not floor_mesh.vertices.is_empty():
		var normals := _ground_normals(floor_mesh.vertices, sector, branching)
		var floor_surface := VectorArt.solid(floor_mesh.vertices, floor_mesh.indices, Color.WHITE, floor_mesh.face_colors, normals)
		floor_surface.material_override = materials[sector]
		model.add_child(floor_surface)
	var familiar: Array[Transform3D] = []
	var landmarks: Array[Transform3D] = []
	var block := floori(start / VectorArt.CHUNK_LENGTH)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(block, sector.hash()))
	var slot := -1
	if not props.is_empty() and posmod(block, 4) != 3:
		var first := rng.randi_range(0, props.size() - 1)
		for i in range(props.size()):
			var candidate := (first + i) % props.size()
			var at := props[candidate].origin
			var lateral := at.x - FlightState.rail_point(-at.z).x
			if absf(lateral) >= 31 and (not branching or absf(lateral - GroundRoute.lateral_offset(-at.z)) >= 30):
				slot = candidate
				break
	for i in range(props.size()):
		var pose := props[i]
		if i == slot:
			var variant := posmod(block + hash(Vector2i(floori(block / 3.0), sector.hash())), 3)
			pose.basis = pose.basis.orthonormalized().scaled_local(Vector3.ONE * rng.randf_range(0.89, 1.13))
			add_landmarks(model, sector + "_" + BUILDINGS[sector][variant], [pose])
			continue
		# Broad districts change the mix, with irregular transitions inside each district.
		var at := pose.origin
		var district := sin(at.z * 0.0061 + sector.length()) + cos(at.z * 0.0022)
		var seed_value := hash(Vector2i(roundi(at.x * 4), roundi(at.z * 4)))
		var fraction := float(posmod(seed_value, 997)) / 997.0
		if fraction < clampf(0.43 + district * 0.17, 0.13, 0.78):
			var size := 0.83 + fraction * 0.36
			pose.basis = pose.basis.rotated(Vector3.UP, (fraction - 0.31) * 0.92).scaled_local(Vector3(size, 0.79 + 0.43 * (1.0 - fraction), size))
			landmarks.append(pose)
		else:
			familiar.append(pose)
	add_landmarks(model, "landmark_" + sector, familiar)
	add_landmarks(model, "vista_" + sector, landmarks)
	_plant_banks(model, sector, start, branching, props, rng)
	return model

static func _plant_banks(model: Node3D, sector: String, start: float, branching: bool, props: Array[Transform3D], rng: RandomNumberGenerator) -> void:
	var block := floori(start / VectorArt.CHUNK_LENGTH)
	for bank in range(2):
		var poses: Array[Transform3D] = []
		var species := posmod(block + bank + sector.length(), 3)
		var side := -1.0 if bank == 0 else 1.0
		var center_x := side * rng.randf_range(23, 44)
		var center_z := start + rng.randf_range(21, 106)
		for _i in range(rng.randi_range(3, 6)):
			var lateral := center_x + rng.randf_range(-6, 6)
			var travel := center_z + rng.randf_range(-14, 14)
			if branching and absf(lateral - GroundRoute.lateral_offset(travel)) < 19:
				continue
			var at := VectorArt.ground_point(lateral, travel, branching) if sector in ["ignis", "cryo"] else FrontierArt.floor_point(lateral, travel, sector)
			if sector == "thalassa":
				at.y = FrontierArt.SEA_LEVEL
			var clear := true
			for prop in props:
				if Vector2(prop.origin.x - at.x, prop.origin.z - at.z).length_squared() < 140:
					clear = false
					break
			if clear:
				var scale := rng.randf_range(0.72, 1.23)
				poses.append(placement(at, Vector3.ONE * scale, rng.randf_range(0, TAU)))
		add_landmarks(model, sector + "_" + PLANTS[sector][species], poses, true, sector == "thalassa")

static func add_landmarks(model: Node3D, id: String, props: Array[Transform3D], foliage: bool = false, floating: bool = false) -> void:
	if props.is_empty():
		return
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = foliage
	instances.mesh = FleetArt.mesh_for(id, "ground")
	instances.instance_count = props.size()
	instances.set_meta("placements", props)
	if foliage:
		instances.set_meta("species", id)
	for i in range(props.size()):
		instances.set_instance_transform(i, props[i])
		if foliage:
			var at := props[i].origin
			instances.set_instance_custom_data(i, Color(at.x, at.z, float(floating), props[i].basis.get_scale().y))
	var terrain_prop := MultiMeshInstance3D.new()
	terrain_prop.multimesh = instances
	terrain_prop.material_override = foliage_material if foliage else FleetArt.hull_material
	if foliage:
		terrain_prop.extra_cull_margin = 3.0
	else:
		terrain_prop.set_instance_shader_parameter(&"weathered", true)
	terrain_prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.add_child(terrain_prop)

static func plant_hull(instances: MultiMesh) -> ConcavePolygonShape3D:
	var species: String = instances.get_meta("species")
	if species.begins_with("thalassa_") or species in ["ignis_emberbell", "ignis_aloe", "xylo_shield_fern"]:
		return null
	if plant_shapes.has(species):
		return plant_shapes[species]
	# The Blender garden exporter bakes the frame finish into UV.x for wood.
	# Three fleshy species instead use the paint finish for their solid bodies.
	var finish := 0.15 if species in ["xylo_pitchers", "kharon_barrel_bloom", "cryo_frost_cushion"] else 0.18
	var arrays := instances.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var faces := PackedVector3Array()
	for i in range(0, indices.size(), 3):
		if absf(uv[indices[i]].x - finish) < 0.002:
			faces.append(vertices[indices[i]])
			faces.append(vertices[indices[i + 1]])
			faces.append(vertices[indices[i + 2]])
	var shape: ConcavePolygonShape3D
	if not faces.is_empty():
		shape = ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(faces)
	plant_shapes[species] = shape
	return shape
