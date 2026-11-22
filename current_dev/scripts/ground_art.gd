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
	if not materials.has(sector):
		var material := ShaderMaterial.new()
		material.shader = SURFACE
		material.set_shader_parameter("swatch", load("res://assets/ground/%s_surface.png" % sector))
		materials[sector] = material
	var floor_surface := VectorArt.solid(floor_mesh.vertices, floor_mesh.indices, Color.WHITE, floor_mesh.face_colors)
	floor_surface.material_override = materials[sector]
	model.add_child(floor_surface)
	add_landmarks(model, "landmark_" + sector, props)
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
