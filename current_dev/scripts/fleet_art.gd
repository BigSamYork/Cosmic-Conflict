class_name FleetArt
extends RefCounted

const HULL_SHADER: Shader = preload("res://shaders/fleet_hull.gdshader")
const PILOT_LAYER := 16
static var hull_material := ShaderMaterial.new()
static var meshes: Dictionary[String, Mesh] = {}

static func _static_init() -> void:
	hull_material.shader = HULL_SHADER

static func mesh_for(id: String, folder: String = "fleet") -> Mesh:
	var path := "res://assets/%s/%s.glb" % [folder, id]
	if not meshes.has(path):
		var scene: PackedScene = load(path)
		var imported: Node3D = scene.instantiate()
		var surface := imported as MeshInstance3D
		if surface == null:
			surface = imported.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var mesh := surface.mesh
		assert(mesh.get_surface_count() == 1)
		var arrays := mesh.surface_get_arrays(0)
		mesh.set_meta("fragment_vertices", arrays[Mesh.ARRAY_VERTEX])
		mesh.set_meta("fragment_indices", arrays[Mesh.ARRAY_INDEX])
		mesh.set_meta("fragment_colors", arrays[Mesh.ARRAY_COLOR])
		meshes[path] = mesh
		imported.free()
	return meshes[path]

static func model(id: String, folder: String = "fleet") -> Node3D:
	var root := Node3D.new()
	var hull := MeshInstance3D.new()
	hull.name = id
	hull.mesh = mesh_for(id, folder)
	hull.material_override = hull_material
	if folder == "ground":
		hull.set_instance_shader_parameter(&"weathered", true)
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hull)
	return root

# Weapons keep their aiming envelopes. Pilot contact follows the rendered hull,
# including its local scale, articulation, and orientation on a ground pass.
static func add_pilot_hull(model_root: Node3D) -> void:
	var surfaces := model_root.find_children("*", "MeshInstance3D", true, false)
	if model_root is MeshInstance3D:
		surfaces.append(model_root)
	for surface: MeshInstance3D in surfaces:
		if surface.mesh == null or surface.material_override == VectorArt.line_material:
			continue
		var mesh := surface.mesh
		if not mesh.has_meta("pilot_hull"):
			var shape := mesh.create_trimesh_shape()
			if shape == null:
				continue
			shape.backface_collision = true
			mesh.set_meta("pilot_hull", shape)
		var body := StaticBody3D.new()
		body.collision_layer = PILOT_LAYER if surface.is_visible_in_tree() else 0
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		collider.shape = mesh.get_meta("pilot_hull")
		body.add_child(collider)
		surface.add_child(body)
		surface.visibility_changed.connect(func(): body.collision_layer = PILOT_LAYER if surface.is_visible_in_tree() else 0)
