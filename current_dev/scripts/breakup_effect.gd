class_name BreakupEffect
extends Node3D

var pieces: Array[Dictionary] = []
var age: float = 0.0
var lifetime: float = 1.6
var solid_instances: MultiMeshInstance3D
var line_instances: MultiMeshInstance3D
static var solid_mesh: Mesh
static var solid_material: Material
static var line_mesh: Mesh

func build(source: Node3D, destroyed: bool, _tint: Color, maximum_pieces: int = 96, duration: float = 2.6, force: float = 5.0) -> void:
	global_position = source.global_position
	var surfaces: Array[Dictionary] = []
	_collect(source, surfaces)
	var triangle_count: int = 0
	for surface in surfaces:
		triangle_count += surface["indices"].size() / 3
	var count: int = mini(maximum_pieces if destroyed else 1, triangle_count)
	lifetime = duration if destroyed else 0.65
	_prepare_meshes()
	solid_instances = _instances(solid_mesh, solid_material, count)
	line_instances = _instances(line_mesh, VectorArt.line_material, count)
	for i in range(count):
		var face: Dictionary = _triangle(surfaces, int(float(i) * triangle_count / count))
		var triangle: PackedVector3Array = face["vertices"]
		var center: Vector3 = (triangle[0] + triangle[1] + triangle[2]) / 3.0
		var edge_a: Vector3 = triangle[1] - triangle[0]
		var edge_b: Vector3 = triangle[2] - triangle[0]
		var transform := Transform3D(Basis(edge_a, edge_b, edge_a.cross(edge_b).normalized()), center - global_position)
		var outward: Vector3 = (center - global_position + Vector3(cos(i * 2.4), 0.7, sin(i * 2.4))).normalized()
		pieces.append({"transform": transform, "velocity": outward * (force + (i % 7) * 0.8), "spin": Vector3(0.8 + (i % 5) * 0.3, 1.2, -0.6), "opacity": 1.0,
			"color": face["color"], "edge_color": face["edge_color"]})
		_upload(i, transform)

static func _prepare_meshes() -> void:
	var unit := PackedVector3Array([Vector3(-1.0 / 3.0, -1.0 / 3.0, 0), Vector3(2.0 / 3.0, -1.0 / 3.0, 0), Vector3(-1.0 / 3.0, 2.0 / 3.0, 0)])
	if solid_mesh == null:
		var instance: MeshInstance3D = VectorArt.solid(unit, PackedInt32Array([0, 1, 2]), Color.WHITE)
		solid_mesh = instance.mesh
		var material := instance.material_override.duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.vertex_color_use_as_albedo = true
		solid_material = material
		instance.free()
	if line_mesh == null:
		var instance: MeshInstance3D = VectorArt.lines(PackedVector3Array([unit[0], unit[1], unit[1], unit[2], unit[2], unit[0]]), Color.WHITE)
		line_mesh = instance.mesh
		instance.free()

func _instances(mesh: Mesh, material: Material, count: int) -> MultiMeshInstance3D:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = mesh
	instances.instance_count = count
	var node := MultiMeshInstance3D.new()
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 2.0
	add_child(node)
	return node

func _upload(index: int, transform: Transform3D, opacity: float = 1.0) -> void:
	solid_instances.multimesh.set_instance_transform(index, transform)
	line_instances.multimesh.set_instance_transform(index, transform)
	var fill: Color = pieces[index]["color"]
	var edge: Color = pieces[index]["edge_color"]
	solid_instances.multimesh.set_instance_color(index, Color(fill, fill.a * opacity))
	line_instances.multimesh.set_instance_color(index, Color(edge, edge.a * opacity))

func _collect(node: Node3D, output: Array[Dictionary]) -> void:
	if node is MeshInstance3D and node.mesh != null and (node.material_override is StandardMaterial3D or node.material_override == FleetArt.hull_material):
		if node.mesh.has_meta("fragment_vertices"):
			output.append({"vertices": node.mesh.get_meta("fragment_vertices"), "indices": node.mesh.get_meta("fragment_indices"), "transform": node.global_transform,
				"colors": node.mesh.get_meta("fragment_colors", PackedColorArray()), "base_color": node.material_override.albedo_color if node.material_override is StandardMaterial3D else Color.WHITE,
				"edge_colors": node.mesh.get_meta("fragment_edge_colors", PackedColorArray())})
		else:
			push_warning("Breakup geometry has no CPU source: " + str(node.name))
	for child in node.get_children():
		if child is RangeTarget and child.destroyed:
			continue
		if child is Node3D and child.visible:
			_collect(child, output)

func _triangle(surfaces: Array[Dictionary], index: int) -> Dictionary:
	for surface in surfaces:
		var indices: PackedInt32Array = surface["indices"]
		var count: int = indices.size() / 3
		if index < count:
			var vertices: PackedVector3Array = surface["vertices"]
			var transform: Transform3D = surface["transform"]
			var colors: PackedColorArray = surface["colors"]
			var tint: Color = surface["base_color"]
			if not colors.is_empty():
				tint *= (colors[indices[index * 3]] + colors[indices[index * 3 + 1]] + colors[indices[index * 3 + 2]]) / 3.0
			var edge_colors: PackedColorArray = surface["edge_colors"]
			return {"vertices": PackedVector3Array([transform * vertices[indices[index * 3]], transform * vertices[indices[index * 3 + 1]], transform * vertices[indices[index * 3 + 2]]]),
				"color": tint, "edge_color": edge_colors[index] if not edge_colors.is_empty() else tint}
		index -= count
	assert(false, "Breakup triangle is outside its source geometry.")
	return {}

func advance(delta: float) -> void:
	age += delta
	for i in range(pieces.size()):
		pieces[i]["velocity"] += Vector3.DOWN * delta * 2.5
		var transform: Transform3D = pieces[i]["transform"]
		transform.origin += pieces[i]["velocity"] * delta
		transform.basis = Basis.from_euler(pieces[i]["spin"] * delta) * transform.basis
		pieces[i]["transform"] = transform
		var fade_start: float = lifetime * (0.25 + (i % 5) * 0.03)
		var opacity: float = 1.0 - smoothstep(fade_start, lifetime, age)
		pieces[i]["opacity"] = opacity
		_upload(i, transform, opacity)

func complete() -> bool:
	return age >= lifetime
