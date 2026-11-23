extends RefCounted

static var sphere: SphereMesh

static func skin(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if sphere == null:
		sphere = SphereMesh.new()
		sphere.radius = 1
		sphere.height = 2
		sphere.radial_segments = 20
		sphere.rings = 12
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	mesh.material_override = material
	mesh.position = at
	mesh.scale = size
	parent.add_child(mesh)
	return mesh

static func tooth(parent: Node3D, a: Vector3, b: Vector3, r: float, tip: float, material: Material) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = r
	shape.bottom_radius = tip
	shape.height = a.distance_to(b)
	shape.radial_segments = 8
	shape.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = (a + b) * 0.5
	mesh.basis = Basis(Quaternion(Vector3.UP, (a - b).normalized()))
	parent.add_child(mesh)
