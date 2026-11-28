extends MultiMeshInstance3D

enum Surface { HULL, STONE, FLESH }
const LIFETIME := 0.72
const MAX_BURSTS := 16
const SPRAY_SHADER := preload("res://shaders/impact_spray.gdshader")
static var quad := QuadMesh.new()
static var spray_material := ShaderMaterial.new()
var age := 0.0
var carrier: Node3D
var previous_carrier_position := Vector3.ZERO

static func surface_for(target: Node3D) -> Surface:
	if target is BurrowEye or target is EggShip or ((target is BossPart or target is PirateSkirmisher or target is EnemyMissile or target is RadarDish) and target.biological):
		return Surface.FLESH
	if (target is EnemyFighter or target is GroundTurret or target is DestructibleTower) and target.sector == "xylo":
		return Surface.FLESH
	if target is DestructibleTower or target is Asteroid or target is FallingIce:
		return Surface.STONE
	return Surface.HULL

# Gameplay hitboxes are intentionally generous. Use the visible tissue for
# the entry wound, so a shot through a protruding vessel bleeds at that vessel.
static func skin_contact(part: BossPart, hit: Dictionary, axis: Vector3) -> Dictionary:
	var at: Vector3 = hit["position"]
	if axis.is_zero_approx():
		return hit
	axis = axis.normalized()
	var start := at - axis * 16.0
	var end := at + axis * 42.0
	var nearest := INF
	var contact := hit.duplicate()
	contact["position"] = part.aim_point()
	for surface: MeshInstance3D in part.find_children("*", "MeshInstance3D", true, false):
		if not surface.is_visible_in_tree() or surface.mesh == null or not surface.mesh.has_meta("fragment_vertices"):
			continue
		var mesh := surface.mesh
		if not mesh.has_meta("blood_triangles"):
			mesh.set_meta("blood_triangles", mesh.generate_triangle_mesh())
		var triangles: TriangleMesh = mesh.get_meta("blood_triangles")
		var point := triangles.intersect_segment(surface.to_local(start), surface.to_local(end))
		if point.is_empty():
			continue
		var wound := surface.to_global(point.position)
		var distance := start.distance_squared_to(wound)
		if distance < nearest:
			nearest = distance
			contact["position"] = wound
			var normal := (surface.global_basis.inverse().transposed() * Vector3(point.normal)).normalized()
			contact["normal"] = -normal if normal.dot(axis) > 0.0 else normal
	# A graze may count at a corner of the generous collider. Project the
	# target's aiming point onto its skin before falling back to the mount.
	if nearest == INF and not at.is_equal_approx(part.aim_point()):
		return skin_contact(part, contact, axis)
	return contact

func build(at: Vector3, outward: Vector3, kind: Surface, size: float, reduced: bool, boss: BossEncounter = null) -> void:
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
	if kind == Surface.FLESH and boss != null:
		carrier = boss
		previous_carrier_position = boss.global_position
		set_instance_shader_parameter(&"orbital", boss.orbital)
	for i in range(particles.instance_count):
		var angle := roll + i * 2.39996
		var fan := across * cos(angle) + up * sin(angle)
		var velocity: Vector3
		var family: float
		var width: float
		if kind == Surface.FLESH:
			# A narrow pressure jet breaks into thick beads. Fine spray travels
			# around its edges and loses speed quickly in atmosphere.
			var mist := i % 4 == 0
			family = 4.0 if mist else 2.0
			var spread := randf_range(0.48, 1.0) if mist else randf_range(0.07, 0.59)
			velocity = (outward + fan * spread).normalized() * randf_range(8.0, 16.0)
			width = randf_range(0.65, 1.2) if mist else lerpf(0.065, 0.25, pow(randf(), 1.7))
		else:
			var dust := i % (2 if kind == Surface.STONE else 4) == 0
			family = 0.0 if dust else 3.0 if kind == Surface.STONE else 1.0
			width = randf_range(0.40, 0.78) if dust else randf_range(0.08, 0.23)
			velocity = (outward * randf_range(0.4, 1.0) + fan * randf_range(0.28, 1.0)).normalized()
			velocity *= randf_range(3.0, 8.0) if dust else randf_range(6.5, 16.0)
		var emission := Transform3D(Basis(Vector3.RIGHT, velocity * size, Vector3.BACK), fan * randf_range(0.04, 0.35) * size)
		particles.set_instance_transform(i, emission)
		particles.set_instance_custom_data(i, Color(family, width * size, randf(), randf_range(0.36, LIFETIME)))
	multimesh = particles

func advance(delta: float) -> void:
	if is_instance_valid(carrier):
		global_position += carrier.global_position - previous_carrier_position
		previous_carrier_position = carrier.global_position
	age += delta
	set_instance_shader_parameter(&"burst_age", age)
