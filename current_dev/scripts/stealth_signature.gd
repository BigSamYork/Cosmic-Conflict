class_name StealthSignature
extends RefCounted

const CYCLE: float = 8.0
const CLOAK_START: float = 2.5
const CLOAK_END: float = 6.5
const REVEAL_DURATION: float = 3.0
const SURFACE: Shader = preload("res://shaders/stealth_surface.gdshader")
var age: float = 0
var phase: float = 0
var revealed_remaining: float = 0
var meshes: Array[MeshInstance3D] = []
var originals: Array[Material] = []
var veils: Array[ShaderMaterial] = []

func attach(model: Node3D) -> void:
	for child: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var source: Material = child.material_override
		assert(source is StandardMaterial3D or source is ShaderMaterial)
		var material: ShaderMaterial
		if source is StandardMaterial3D or source == FleetArt.hull_material:
			material = ShaderMaterial.new()
			material.shader = SURFACE
			material.set_shader_parameter("hull_tint", source.albedo_color if source is StandardMaterial3D else Color.WHITE)
		else:
			material = source.duplicate()
		meshes.append(child)
		originals.append(source)
		veils.append(material)
	refresh()

func active() -> bool:
	var cycle: float = fposmod(age + phase, CYCLE)
	return revealed_remaining <= 0 and cycle >= CLOAK_START and cycle < CLOAK_END

func advance(delta: float) -> void:
	age += delta
	revealed_remaining = maxf(0, revealed_remaining - delta)
	refresh()

func reveal(duration: float = REVEAL_DURATION) -> void:
	revealed_remaining = maxf(revealed_remaining, duration)
	refresh()

func restore() -> void:
	for i in range(meshes.size()):
		if is_instance_valid(meshes[i]):
			meshes[i].material_override = originals[i]

func refresh() -> void:
	var cloaked: bool = active()
	for i in range(meshes.size()):
		if not is_instance_valid(meshes[i]):
			continue
		meshes[i].material_override = veils[i] if cloaked else originals[i]
		var scars := meshes[i].material_overlay as ShaderMaterial
		if scars != null and scars.get_shader_parameter("cloaked") != cloaked:
			scars.set_shader_parameter("cloaked", cloaked)
		if not cloaked:
			continue
		if veils[i].shader == SURFACE:
			veils[i].set_shader_parameter("phase_time", age + phase)
		elif veils[i].shader == VectorArt.LINE_SHADER:
			veils[i].set_shader_parameter("effect_opacity", 0.36 + sin(age * 8 + phase) * 0.08)
			veils[i].set_shader_parameter("stroke_width", VectorArt.line_material.get_shader_parameter("stroke_width"))
			veils[i].set_shader_parameter("halo_strength", VectorArt.line_material.get_shader_parameter("halo_strength"))
