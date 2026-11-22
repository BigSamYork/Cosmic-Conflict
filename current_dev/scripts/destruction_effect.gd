class_name DestructionEffect
extends Node3D

signal fracture_requested
var source: Node3D
var age: float = 0.0
var size: float = 20.0
var fired: bool = false
var balls: MultiMeshInstance3D
var ring: Node3D
static var sphere_mesh: SphereMesh
static var fire_material: StandardMaterial3D

func _ready() -> void:
	if sphere_mesh == null:
		sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 1
		sphere_mesh.height = 2
		sphere_mesh.radial_segments = 12
		sphere_mesh.rings = 6
		fire_material = StandardMaterial3D.new()
		fire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fire_material.albedo_color = Color("#ffb553")
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = sphere_mesh
	instances.instance_count = 9
	balls = MultiMeshInstance3D.new()
	balls.multimesh = instances
	balls.material_override = fire_material
	balls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(balls)
	var batch := GeometryBatch.new()
	batch.ring(Vector3.ZERO, 1.0, VectorArt.AMBER, 48)
	batch.ring(Vector3(0, 0, 0.03), 0.91, VectorArt.CYAN, 48)
	ring = batch.build()
	add_child(ring)
	advance(0.0)

func advance(delta: float) -> void:
	age += delta
	if is_instance_valid(source) and age < 1.7:
		global_transform = source.global_transform
	for i in range(9):
		var started: float = age - i * 0.15
		var envelope: float = maxf(0.0, sin(clampf(started / 2.0, 0, 1) * PI))
		var angle: float = i * 2.4
		var at := Vector3(cos(angle) * size * 0.45, sin(angle) * size * 0.25, sin(angle * 2) * size * 0.4)
		var radius: float = envelope * size * (0.25 if i > 0 else 0.45)
		balls.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * maxf(radius, 0.0001)), at))
	ring.visible = age > 0.55 and age < 3.2
	ring.scale = Vector3.ONE * maxf(0.001, (age - 0.5) * size * 1.2)
	if age > 1.2 and not fired:
		fired = true
		fracture_requested.emit()

func complete() -> bool:
	return age >= 4.0
