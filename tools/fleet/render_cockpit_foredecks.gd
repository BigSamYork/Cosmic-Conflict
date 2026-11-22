extends SceneTree

# Bake the actual flight meshes looking forward from each bridge station.
# Bounds enclose the external glass dome, its backing and the two canopy hoops
# built by Skin.canopy in build_fleet.py. The interior frame replaces these.
# Run with Godot --path current_dev --script <absolute path to this file>.
const STATIONS := {
	"rook": [Vector3(0, 1.00, -0.35), Vector3(0, 0.68, -0.74), Vector3(0.76, 0.63, 1.11)],
	"hawk": [Vector3(0, 0.90, -0.50), Vector3(0, 0.47, -0.80), Vector3(0.56, 0.52, 1.73)],
	"titan": [Vector3(0, 1.78, 1.48), Vector3(0, 1.29, 1.49), Vector3(0.97, 0.60, 1.18)],
	"bastion": [Vector3(0, 1.53, 1.16), Vector3(0, 1.18, 1.23), Vector3(1.26, 0.55, 0.98)],
	"emergency": [Vector3(-0.69, 1.00, -0.28), Vector3(-0.69, 0.51, -0.86), Vector3(0.67, 0.57, 0.92)],
}

func _initialize() -> void:
	call_deferred("render")

func render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1376, 768)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.fov = 75
	viewport.add_child(camera)
	var dir := "res://assets/cockpits/foredecks/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for ship: String in STATIONS:
		var hull := FleetArt.model(ship)
		var mesh := hull.get_child(0) as MeshInstance3D
		var center: Vector3 = STATIONS[ship][1]
		var half_extent: Vector3 = STATIONS[ship][2]
		mesh.mesh = interior_view(mesh.mesh, AABB(center - half_extent, half_extent * 2.0))
		var material := FleetArt.hull_material.duplicate() as ShaderMaterial
		material.set_shader_parameter("pulse_strength", 0.0)
		mesh.material_override = material
		mesh.set_instance_shader_parameter("parked", true)
		viewport.add_child(hull)
		camera.position = STATIONS[ship][0]
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		var err := image.save_png(dir + ship + ".png")
		if err != OK or not image.get_used_rect().has_area():
			push_error("Could not bake " + ship)
			quit(1)
			return
		print(ship, " ", image.get_used_rect())
		hull.free()
	quit()

func interior_view(source: Mesh, dome: AABB) -> ArrayMesh:
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var triangles: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var keep := PackedInt32Array()
	for i in range(0, triangles.size(), 3):
		var a := triangles[i]
		var b := triangles[i + 1]
		var c := triangles[i + 2]
		var finish := uv[a].x
		var canopy_material := absf(finish - 0.44) < 0.005 or absf(finish - 0.18) < 0.005 or absf(finish - 0.29) < 0.005
		if canopy_material and dome.has_point(vertices[a]) and dome.has_point(vertices[b]) and dome.has_point(vertices[c]):
			continue
		keep.append(a)
		keep.append(b)
		keep.append(c)
	arrays[Mesh.ARRAY_INDEX] = keep
	var cutaway := ArrayMesh.new()
	cutaway.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return cutaway
