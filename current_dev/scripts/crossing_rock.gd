extends Asteroid

const Igneous := preload("res://scripts/igneous_hazard.gd")
var meteor := false
var drift := Vector3.ZERO
var age := 0.0
var wake_material: ShaderMaterial

func _ready() -> void:
	super._ready()
	if meteor:
		var wake := MeshInstance3D.new()
		wake.mesh = Igneous._wake_mesh()
		wake_material = ShaderMaterial.new()
		wake_material.shader = Igneous.WAKE
		wake_material.set_shader_parameter("basalt", true)
		wake.material_override = wake_material
		wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(wake)
		var tail := -drift.normalized()
		wake.global_basis = Basis.looking_at(tail, Vector3.RIGHT if absf(tail.y) > 0.95 else Vector3.UP).scaled_local(Vector3(radius, radius, radius * 7))

func advance_crossing(delta: float) -> void:
	global_position += drift * delta
	age += delta
	animate(age)
	if meteor:
		wake_material.set_shader_parameter("phase", age)
