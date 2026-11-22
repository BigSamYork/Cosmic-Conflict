class_name RuinFall
extends FallingIce

func support_model() -> Node3D:
	var side: float = signf(lane.x)
	var batch := GeometryBatch.new()
	batch.box(Vector3(side * 9, 17, 0), Vector3(6, 36, 8), FrontierArt.SAND, Color("#453829"))
	batch.box(Vector3(side * 4, 39, 0), Vector3(15, 5, 8), FrontierArt.SAND)
	var model: Node3D = batch.build()
	var origin: Vector3 = FlightState.rail_point(travel)
	model.position = Vector3(origin.x + lane.x, 0, origin.z)
	return model

func _ready() -> void:
	super._ready()
	var old: Node3D = get_child(0)
	remove_child(old)
	old.queue_free()
	var batch := GeometryBatch.new()
	batch.box(Vector3.ZERO, Vector3(3.2, 4.6, 3.2), FrontierArt.SAND, Color("#695038"))
	for i in range(3):
		batch.line(Vector3(-1.5, -1.5 + i, 1.65), Vector3(1.5, -0.8 + i, 1.65), Color("#6bcdd0"))
	add_child(batch.build())
