class_name XyloRovers
extends Node3D

var vehicles: Array[Node3D] = []
var ages: float = 0
var locations: PackedVector3Array = PackedVector3Array()

func _ready() -> void:
	for i in range(8):
		var travel: float = 350 + i * 450
		var side: float = -1 if i % 2 == 0 or (travel > GroundRoute.FORK and travel < GroundRoute.REJOIN) else 1
		var model: Node3D = XyloArt.rover()
		model.position = XyloArt.floor_point(side * 21, travel)
		add_child(model)
		vehicles.append(model)
		locations.append(model.position)

func advance(delta: float) -> void:
	ages += delta
	for i in range(vehicles.size()):
		vehicles[i].position = locations[i] + Vector3(0, 0, sin(ages * 0.18 + i) * 2)
		vehicles[i].rotation.y = sin(ages * 0.1 + i) * 0.1
