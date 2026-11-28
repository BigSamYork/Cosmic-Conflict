class_name DestructionEffect
extends Node3D

signal fracture_requested
const DURATION := 4.0
var source: Node3D
var age := 0.0
var size := 20.0
var fired := false
var reduced := false
var plume := MultiMeshInstance3D.new()
static var smoke_shader := preload("res://shaders/blast_cloud.gdshader")
static var cloud_material := ShaderMaterial.new()
static var blood_material := ShaderMaterial.new()
var wound: BossPart
static var sprite := QuadMesh.new()

func _ready() -> void:
	var particles := MultiMesh.new()
	particles.transform_format = MultiMesh.TRANSFORM_3D
	particles.use_custom_data = true
	particles.mesh = sprite
	particles.instance_count = 18 if reduced else 55
	particles.custom_aabb = AABB(Vector3.ONE * -size * 4, Vector3.ONE * size * 8)
	for i in range(particles.instance_count):
		var family := fmod(i * 0.381966, 1.0)
		var direction := fmod(i * 0.618034, 1.0)
		var phase := fmod((i + 3) * 0.754878, 1.0)
		var delay := fmod(i * 0.32841, 1.0) * (1.1 if family < 0.65 else 0.45)
		particles.set_instance_transform(i, Transform3D.IDENTITY)
		particles.set_instance_custom_data(i, Color(family, direction, phase, delay))
	if cloud_material.shader == null:
		cloud_material.shader = smoke_shader
		blood_material.shader = preload("res://shaders/blood_rupture.gdshader")
	plume.multimesh = particles
	if source is BossEncounter and source.core.biological:
		wound = source.core
	elif source is BossPart and source.biological:
		wound = source
	plume.material_override = blood_material if wound != null else cloud_material
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plume)
	plume.set_instance_shader_parameter(&"radius", size)
	if wound != null:
		var host := wound.get_parent() as BossEncounter
		plume.set_instance_shader_parameter(&"orbital", host != null and host.orbital)
		plume.set_instance_shader_parameter(&"whole_body", source is BossEncounter)
	advance(0)

func advance(delta: float) -> void:
	age += delta
	if is_instance_valid(source) and age < 1.7:
		global_transform = source.global_transform
		if is_instance_valid(wound):
			global_position = wound.to_global(wound.last_blood_contact) if wound.last_blood_contact.is_finite() else wound.aim_point()
	plume.set_instance_shader_parameter(&"age", age)
	if age > 1.2 and not fired:
		fired = true
		fracture_requested.emit()

func complete() -> bool:
	return age >= DURATION
