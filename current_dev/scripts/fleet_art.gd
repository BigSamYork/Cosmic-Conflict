class_name FleetArt
extends RefCounted

const HULL_SHADER: Shader = preload("res://shaders/fleet_hull.gdshader")
static var hull_material := ShaderMaterial.new()
static var meshes: Dictionary[String, Mesh] = {}

static func _static_init() -> void:
	hull_material.shader = HULL_SHADER

static func model(id: String) -> Node3D:
	if not meshes.has(id):
		var scene: PackedScene = load("res://assets/fleet/%s.glb" % id)
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
		meshes[id] = mesh
		imported.free()
	var root := Node3D.new()
	var hull := MeshInstance3D.new()
	hull.name = id
	hull.mesh = meshes[id]
	hull.material_override = hull_material
	hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hull)
	return root
