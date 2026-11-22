extends MultiMeshInstance3D

enum Surface { HULL, STONE, FLESH }
const LIFETIME := 0.72
const MAX_BURSTS := 16
const SPRAY_SHADER := preload("res://shaders/impact_spray.gdshader")
static var quad := QuadMesh.new()
static var spray_material := ShaderMaterial.new()
var age := 0.0

static func surface_for(target: Node3D) -> Surface:
	if target is EggShip or ((target is BossPart or target is PirateSkirmisher or target is EnemyMissile) and target.biological):
		return Surface.FLESH
	if (target is EnemyFighter or target is GroundTurret or target is DestructibleTower) and target.sector == "xylo":
		return Surface.FLESH
	if target is DestructibleTower or target is Asteroid or target is FallingIce:
		return Surface.STONE
	return Surface.HULL

func build(at: Vector3, outward: Vector3, kind: Surface, size: float, reduced: bool) -> void:
	global_position = at
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if spray_material.shader == null:
		spray_material.shader = SPRAY_SHADER
	material_override = spray_material
	var particles := MultiMesh.new()
	particles.transform_format = MultiMesh.TRANSFORM_3D
	particles.use_custom_data = true
	particles.mesh = quad
	particles.instance_count = 9 if reduced else 24
	particles.custom_aabb = AABB(Vector3.ONE * -17.0 * size, Vector3.ONE * 34.0 * size)
	var across := outward.cross(Vector3.RIGHT if absf(outward.y) > 0.9 else Vector3.UP).normalized()
	var up := across.cross(outward)
	var roll := randf() * TAU
	for i in range(particles.instance_count):
		var angle := roll + i * 2.39996
		var fan := across * cos(angle) + up * sin(angle)
		var velocity := (outward * randf_range(0.4, 1.0) + fan * randf_range(0.28, 1.0)).normalized()
		var dust := kind != Surface.FLESH and i % (2 if kind == Surface.STONE else 4) == 0
		var family := 0.0 if dust else 2.0 if kind == Surface.FLESH else 3.0 if kind == Surface.STONE else 1.0
		var width := randf_range(0.40, 0.78) if dust else randf_range(0.08, 0.23)
		velocity *= randf_range(3.0, 8.0) if dust else randf_range(6.5, 16.0)
		var emission := Transform3D(Basis(Vector3.RIGHT, velocity * size, Vector3.BACK), fan * randf_range(0.04, 0.35) * size)
		particles.set_instance_transform(i, emission)
		particles.set_instance_custom_data(i, Color(family, width * size, randf(), randf_range(0.36, LIFETIME)))
	multimesh = particles

func advance(delta: float) -> void:
	age += delta
	set_instance_shader_parameter(&"burst_age", age)
