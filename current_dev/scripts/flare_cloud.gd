class_name FlareCloud
extends Node3D

const DURATION: float = 2.2
const RANGE: float = 110.0
const MAX_DIVERTED: int = 4
var age: float = 0.0
var carrier_velocity: Vector3
var particles: Array[MeshInstance3D] = []
var material: ShaderMaterial

func _ready() -> void:
	var points := PackedVector3Array([Vector3.LEFT * 0.4, Vector3.RIGHT * 0.4, Vector3.DOWN * 0.4, Vector3.UP * 0.4, Vector3.FORWARD * 0.4, Vector3.BACK * 2.5])
	var unit: MeshInstance3D = VectorArt.lines(points, VectorArt.AMBER)
	material = unit.material_override.duplicate()
	for i in range(8):
		var flare := MeshInstance3D.new()
		flare.mesh = unit.mesh
		flare.material_override = material
		flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flare)
		particles.append(flare)
	unit.free()
	advance(0.0)

func advance(delta: float) -> void:
	age += delta
	global_position += carrier_velocity * delta
	for i in range(particles.size()):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		particles[i].position = Vector3(side * (1.2 + age * (6 + i * 0.35)), -0.5 - age * (1 + (i % 3)), -8 - age * (4 + i * 0.25))
	material.set_shader_parameter("effect_opacity", 1.0 - smoothstep(DURATION * 0.3, DURATION, age))
	material.set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))

func complete() -> bool:
	return age >= DURATION
