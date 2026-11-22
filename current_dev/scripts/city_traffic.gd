class_name CityTraffic
extends Node3D

var meshes: Array[MultiMesh] = []
var age: float = 0
var poses: Array[Transform3D] = []
const COUNT: int = 80

func _ready() -> void:
	var model: Node3D = VesperaArt.traffic_pod()
	for surface: MeshInstance3D in model.get_children():
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = surface.mesh
		mesh.instance_count = COUNT
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mesh
		instance.material_override = surface.material_override
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		meshes.append(mesh)
	model.free()
	advance(0, 0)

func advance(delta: float, pilot_travel: float) -> void:
	age += delta
	poses.clear()
	for i in range(COUNT):
		var lane: int = i % 4
		var reverse: bool = lane % 2 == 1
		var travel: float = fposmod((i / 4) * 260.0 + lane * 71 + age * (-21 if reverse else 26) - pilot_travel + 1300, 5200) + pilot_travel - 1300
		var point: Vector3 = FlightState.rail_point(travel)
		point.x += (-1 if lane < 2 else 1) * (23 + lane % 2 * 4)
		point.y = 35 + (lane % 2) * 4 + sin(age * 0.5 + i) * 0.8
		var pose := Transform3D(Basis(Vector3.UP, PI if reverse else 0), point)
		poses.append(pose)
		for mesh in meshes:
			mesh.set_instance_transform(i, pose)
