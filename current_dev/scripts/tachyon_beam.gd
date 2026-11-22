class_name TachyonBeam
extends Node3D

const RADIUS: float = 0.45
const RANGE: float = 490.0
var segments: Array[MeshInstance3D] = []

func update_path(origins: PackedVector3Array, end: Vector3) -> void:
	while segments.size() < origins.size():
		var segment: MeshInstance3D = PrimaryArt.segment(2)
		add_child(segment)
		segments.append(segment)
	for i in range(segments.size()):
		segments[i].visible = i < origins.size() and origins[i].distance_squared_to(end) > 0.0001
		if segments[i].visible:
			var direction: Vector3 = end - origins[i]
			segments[i].global_transform = Transform3D(Basis.looking_at(direction.normalized()) * Basis.from_scale(Vector3(1, 1, direction.length())), origins[i])
	show()
