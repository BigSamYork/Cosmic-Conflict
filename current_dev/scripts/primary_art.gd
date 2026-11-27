class_name PrimaryArt
extends RefCounted

static var meshes: Dictionary = {}
static var materials: Dictionary = {}
static var reduced: bool = false

static func segment(level: int) -> MeshInstance3D:
	assert(level in [1, 2])
	if not meshes.has(level):
		var prototype: MeshInstance3D = VectorArt.lines(PackedVector3Array([Vector3.ZERO, Vector3.FORWARD]), Color("#ffdb9c") if level == 1 else Color("#a3eaff"))
		meshes[level] = prototype.mesh
		prototype.free()
		var material := ShaderMaterial.new()
		material.shader = VectorArt.LINE_SHADER if level == 1 else preload("res://shaders/tachyon_beam.gdshader")
		materials[level] = material
		_configure(level)
	var result := MeshInstance3D.new()
	result.mesh = meshes[level]
	result.material_override = materials[level]
	result.extra_cull_margin = 6.0
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result

static func set_reduced_effects(value: bool) -> void:
	reduced = value
	for level: int in materials:
		_configure(level)

static func _configure(level: int) -> void:
	var material: ShaderMaterial = materials[level]
	material.set_shader_parameter("stroke_width", (3.2 if reduced else 3.4) if level == 1 else (5.0 if reduced else 6.0))
	material.set_shader_parameter("halo_strength", 0.0 if reduced else 0.9)
	if level == 1:
		material.set_shader_parameter("emission_gain", 2.0)
		material.set_shader_parameter("fade_start", VectorArt.DETAIL_FADE_START)
		material.set_shader_parameter("fade_end", VectorArt.DETAIL_FADE_END)
