class_name EngineWake
extends MultiMeshInstance3D

static var sprites: MultiMesh
static var emission := ShaderMaterial.new()

func mount(body: Node3D, tint: Color) -> void:
	if sprites == null:
		emission.shader = preload("res://shaders/engine_wake.gdshader")
		sprites = MultiMesh.new()
		sprites.transform_format = MultiMesh.TRANSFORM_3D
		sprites.use_custom_data = true
		sprites.mesh = QuadMesh.new()
		sprites.instance_count = 15
		sprites.custom_aabb = AABB(Vector3(-2, -2, 0), Vector3(4, 4, 7))
		for i in range(sprites.instance_count):
			sprites.set_instance_transform(i, Transform3D.IDENTITY)
			sprites.set_instance_custom_data(i, Color(float(i) / sprites.instance_count, fmod(i * 0.618, 1.0), 0, 1))
	multimesh = sprites
	material_override = emission
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(self)
	set_instance_shader_parameter(&"exhaust_color", tint)
	visible = not PrimaryArt.reduced

func advance(age: float) -> void:
	visible = not PrimaryArt.reduced
	if visible:
		set_instance_shader_parameter(&"flight_age", age)
