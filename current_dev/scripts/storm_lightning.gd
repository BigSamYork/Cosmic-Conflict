class_name StormLightning
extends FrostField

func _ready() -> void:
	contact_height = 45
	var warning := GeometryBatch.new()
	var circle := PackedVector3Array()
	for i in range(32):
		var angle: float = TAU * i / 32
		circle.append(Vector3(cos(angle) * RADIUS, 0.2, sin(angle) * RADIUS))
	warning.outline(circle, VectorArt.AMBER)
	ring = warning.build()
	add_child(ring)
	var bolt := GeometryBatch.new()
	var previous := Vector3(0, 45, 0)
	for i in range(1, 13):
		var at := Vector3(sin(i * 3.1 + phase) * 2.5, 45 - i * 3.75, cos(i * 2.7) * 1.5)
		bolt.line(previous, at, Color("#d5faff"))
		bolt.line(previous + Vector3.RIGHT * 0.3, at + Vector3.RIGHT * 0.3, FrontierArt.OCEAN)
		previous = at
	plume = bolt.build()
	add_child(plume)
	_update_visual()

func _update_visual() -> void:
	plume.visible = active(age)
	ring.visible = warning() or active(age)
	plume.rotation.y = sin(age * 19) * 0.2
