class_name EMPPulse
extends Node3D

const RANGE: float = 220.0
const DURATION: float = 0.9
var age: float = 0.0
var material: ShaderMaterial

func _ready() -> void:
	var batch := GeometryBatch.new()
	for plane in range(3):
		var ring := PackedVector3Array()
		for i in range(64):
			var angle: float = i * TAU / 64
			var point := Vector3(cos(angle), sin(angle), 0)
			if plane == 1:
				point = Vector3(point.x, 0, point.y)
			elif plane == 2:
				point = Vector3(0, point.x, point.y)
			ring.append(point)
		batch.outline(ring, VectorArt.CYAN)
	var model: Node3D = batch.build()
	var strokes := model.get_child(0) as MeshInstance3D
	material = strokes.material_override.duplicate()
	strokes.material_override = material
	add_child(model)
	advance(0.0)

func advance(delta: float) -> void:
	age += delta
	scale = Vector3.ONE * maxf(0.1, age / DURATION * RANGE)
	material.set_shader_parameter("effect_opacity", 1.0 - clampf(age / DURATION, 0, 1))
	material.set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))
	material.set_shader_parameter("stroke_width", VectorArt.line_material.get_shader_parameter("stroke_width"))

func complete() -> bool:
	return age >= DURATION
