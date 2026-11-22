class_name GroundArt
extends RefCounted

const SURFACE := preload("res://shaders/ground_surface.gdshader")
static var materials: Dictionary[String, ShaderMaterial] = {}

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

# The flight surface follows the course mesh exactly. Repeated Blender scenery
# shares one GPU instance batch per chunk, including on cached return trips.
static func finish_chunk(model: Node3D, floor_mesh: GeometryBatch, props: Array[Transform3D], sector: String) -> Node3D:
	if not floor_mesh.vertices.is_empty() and not materials.has(sector):
		var material := ShaderMaterial.new()
		material.shader = SURFACE
		material.set_shader_parameter("swatch", load("res://assets/ground/%s_surface.png" % sector))
		material.set_shader_parameter("deposits_map", preload("res://assets/ground/sea_detail.png"))
		material.set_shader_parameter("surface_id", SectorCatalog.AVAILABLE.find(sector))
		materials[sector] = material
	if not floor_mesh.vertices.is_empty():
		var floor_surface := VectorArt.solid(floor_mesh.vertices, floor_mesh.indices, Color.WHITE, floor_mesh.face_colors)
		floor_surface.material_override = materials[sector]
		model.add_child(floor_surface)
	var familiar: Array[Transform3D] = []
	var landmarks: Array[Transform3D] = []
	for pose in props:
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
	return model

static func add_landmarks(model: Node3D, id: String, props: Array[Transform3D]) -> void:
	if props.is_empty():
		return
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = FleetArt.mesh_for(id, "ground")
	instances.instance_count = props.size()
	instances.set_meta("placements", props)
	for i in range(props.size()):
		instances.set_instance_transform(i, props[i])
	var terrain_prop := MultiMeshInstance3D.new()
	terrain_prop.multimesh = instances
	terrain_prop.material_override = FleetArt.hull_material
	terrain_prop.set_instance_shader_parameter(&"weathered", true)
	terrain_prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.add_child(terrain_prop)
