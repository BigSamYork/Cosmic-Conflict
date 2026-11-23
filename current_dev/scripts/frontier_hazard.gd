extends Node3D
## A time-sampled visual for the localized planetary strike. The encounter
## director owns contact and advances this clock even across long frames.
const Art := preload("res://scripts/frontier_hazard_art.gd")
const SURFACE := preload("res://shaders/frontier_hazard_material.gdshader")
const DUST := preload("res://shaders/frontier_hazard_dust.gdshader")
const MAULER := preload("res://scripts/glacier_mauler.gd")
const CONTACT := 2.5
const END := 5.5
const NOSE := Vector3(0, -1.1, 9.25)
const BLOCKS := 13
const FRAGMENTS := 46
const CLOUDS := 24

var sector := "cryo"
var creature_encounter := false
var creature: Node3D
var carriage: MeshInstance3D
var ice: MultiMeshInstance3D
var scar: MeshInstance3D
var fragments: MultiMeshInstance3D
var cloud: MultiMeshInstance3D
var light := OmniLight3D.new()
var material := ShaderMaterial.new()
var layout := PackedVector3Array()
var dimensions := PackedVector3Array()
var yaw := 0.72

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(roundi(global_position.x), roundi(global_position.z))) ^ 629
	yaw *= -1.0 if rng.randi() % 2 else 1.0
	material.shader = SURFACE
	material.set_shader_parameter("ice", sector == "cryo")
	if sector == "cryo" and creature_encounter:
		creature = MAULER.new()
		creature.approach_side = signf(yaw)
		add_child(creature)
	elif sector == "cryo":
		ice = _instances(Art.glacier_block(), material, BLOCKS)
		for i in range(BLOCKS):
			var a := i * 2.39996 + rng.randf_range(-0.15, 0.15)
			var r := 6.7 * sqrt(float(i) / BLOCKS)
			layout.append(Vector3(cos(a) * r, a, sin(a) * r))
			dimensions.append(Vector3(rng.randf_range(2.8, 5.0), lerpf(15.0, 3.9, r / 7.0) * rng.randf_range(0.89, 1.09), rng.randf_range(0.86, 1.85)))
		scar = MeshInstance3D.new()
		scar.mesh = _fissures(rng)
		scar.material_override = material
		add_child(scar)
	else:
		carriage = MeshInstance3D.new()
		carriage.mesh = Art.railcar()
		carriage.material_override = material
		add_child(carriage)
	var particle_mesh: Mesh = Art.glacier_block()
	if sector == "vespera":
		var shard := BoxMesh.new()
		shard.size = Vector3.ONE
		particle_mesh = shard
	fragments = _instances(particle_mesh, material, FRAGMENTS)
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var vapor := ShaderMaterial.new()
	vapor.shader = DUST
	cloud = _instances(quad, vapor, CLOUDS)
	light.light_color = Color("#a0e5ff") if sector == "cryo" else Color("#ff914d")
	light.omni_range = 18.0
	light.shadow_enabled = false
	add_child(light)
	advance_event(0, false)

func _instances(mesh: Mesh, ink: Material, count: int) -> MultiMeshInstance3D:
	var set := MultiMesh.new()
	set.transform_format = MultiMesh.TRANSFORM_3D
	set.use_colors = true
	set.mesh = mesh
	set.instance_count = count
	var node := MultiMeshInstance3D.new()
	node.multimesh = set
	node.material_override = ink
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Include the approaching train's spark trail before the impact.
	node.custom_aabb = AABB(Vector3(-110, -10, -110), Vector3(220, 140, 235))
	add_child(node)
	return node

func _fissures(rng: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(9):
		var heading := i * TAU / 9 + rng.randf_range(-0.24, 0.24)
		var p := Vector3(0, 0.17, 0)
		for j in range(5):
			heading += rng.randf_range(-0.39, 0.39)
			var side := Vector3(-sin(heading), 0, cos(heading))
			var along := Vector3(cos(heading), 0, sin(heading))
			var next := p + along * rng.randf_range(1.4, 3.05)
			var w := lerpf(0.76, 0.06, j / 4.0)
			_rift_strip(st, p, next, side, w, Color("#0f273d"))
			_rift_strip(st, p + side * w * 0.87 + Vector3.UP * 0.025, next + side * w * 0.64 + Vector3.UP * 0.025, side, w * 0.19, Color("#b4ebed"))
			if j in [1, 3]:
				_rift_strip(st, p, p + along * 2.5 + side * rng.randf_range(1.5, 3.8), side, w * 0.5, Color("#25495b"))
			p = next
	return st.commit()

func _rift_strip(st: SurfaceTool, a: Vector3, b: Vector3, side: Vector3, width: float, color: Color) -> void:
	var points := PackedVector3Array([a - side * width, a + side * width, b + side * width * 0.45, b - side * width * 0.45])
	for idx: int in [0, 1, 2, 0, 2, 3]:
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.20, 0))
		st.add_vertex(points[idx])

func advance_event(age: float, reduced: bool) -> void:
	if cloud == null:
		return
	visible = age >= 0 and age < END
	if not visible:
		return
	var t := age - CONTACT
	if creature != null:
		creature.advance_event(age, reduced)
		light.position = Vector3(0, 3, 0)
		light.light_energy = 0.2 + 0.5 * exp(-absf(t) * 4.0)
	elif sector == "cryo":
		_glacier(age, t)
	else:
		carriage.transform = _carriage_pose(age)
		light.position = carriage.transform * Vector3(0, 0, 7.4)
		light.light_energy = 0.42 + 0.42 * exp(-3.0 * absf(t))
		material.set_shader_parameter("power", 0.47 + 0.30 * (0.5 + 0.5 * sin(age * 5.1)) if t < 0 else 0.13 + exp(-1.7 * t))
	light.visible = not reduced
	_particles(age, t, reduced)

func _glacier(age: float, t: float) -> void:
	var pressure := smoothstep(0.0, CONTACT, age)
	var escape := 1.0 - exp(-maxf(0, t) * 7)
	var decay := smoothstep(0.85, 2.98, t)
	var footprint := lerpf(0.05, 1.0, smoothstep(0, 2.1, age))
	scar.scale = Vector3(footprint, 1, footprint)
	for i in range(BLOCKS):
		var site := layout[i]
		var heave := maxf(0.0, t + 0.095 - 0.024 * (i % 4))
		# The sheet flexes first, then the advancing pressure front tips the
		# fractured plates toward the rim. Slabs settle below the surface.
		var lift := 0.026 + 0.102 * pressure + (1 - exp(-heave * 8.2)) * (1 - 0.97 * decay)
		var angle: float = site.y
		var tilt: float = (0.045 * pressure + 0.53 * escape) * (0.70 + 0.35 * sin(i * 1.7))
		var size := dimensions[i] * Vector3(0.9 + pressure * 0.1, lift, 1.0)
		var rotation_basis := Basis(Vector3.UP, -angle) * Basis(Vector3.BACK, -tilt)
		var origin := Vector3(site.x * (0.82 + 0.24 * escape), -0.21 - decay * 0.63, site.z * (0.82 + 0.24 * escape))
		ice.multimesh.set_instance_transform(i, Transform3D(rotation_basis * Basis.from_scale(size), origin))
		ice.multimesh.set_instance_color(i, Color.WHITE.lerp(Color("#9bb9c6"), 0.14 + 0.13 * sin(i * 2.73)))
	light.position = Vector3(0, 2 + escape * 3, 0)
	light.light_energy = 0.15 + 0.38 * pressure + 0.5 * exp(-2.8 * absf(t))

func _carriage_pose(age: float) -> Transform3D:
	var t := age - CONTACT
	var direction := Vector3(sin(yaw), 0, cos(yaw))
	var bearing := yaw
	var pitch: float
	var roll: float
	var contact: Vector3
	if t < 0:
		var pre := clampf(age / CONTACT, 0, 1)
		contact = direction * (t * 32) + Vector3.UP * (51.0 * (1.0 - pre * pre) + 0.22)
		pitch = lerpf(0.095, 0.585, pre)
		roll = 0.19 + 0.22 * pre + 0.05 * sin(age * 3.4)
	else:
		var slide := 1 - exp(-t * 1.35)
		contact = direction * (17.0 * slide) + Vector3.UP * (0.22 + 1.05 * absf(sin(t * 7)) * exp(-t * 3))
		pitch = 0.585 * exp(-t * 2.8) + 0.10 * sin(t * 8) * exp(-2.0 * t)
		roll = 0.40 + 0.78 * slide + 0.10 * sin(t * 8) * exp(-t * 2.9)
		bearing += 0.36 * slide
	var pose := Basis(Vector3.UP, bearing) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, roll)
	return Transform3D(pose, contact - pose * NOSE)

func _particles(age: float, t: float, reduced: bool) -> void:
	var frozen := sector == "cryo"
	var sparks := fragments.multimesh
	var dust := cloud.multimesh
	sparks.visible_instance_count = 16 if reduced else FRAGMENTS
	dust.visible_instance_count = 9 if reduced else CLOUDS
	sparks.visible_instance_count = 0 if frozen and t < 0 else sparks.visible_instance_count
	for i in range(sparks.visible_instance_count):
		var angle := i * 2.39996
		var radial := Vector3(cos(angle), 0, sin(angle))
		var at: Vector3
		var size: Vector3
		var spin: Basis
		var tint: Color
		if frozen or t >= 0:
			var u := maxf(0, t - 0.014 * (i % 11))
			var speed := 2.5 + fmod(i * 3.37, 7.1)
			var rise := 8.4 + fmod(i * 2.74, 10.3)
			at = radial * (1.1 + speed * u) + Vector3.UP * (rise * u - 9.6 * u * u + 0.15)
			var length := 0.35 + 0.22 * (i % 5)
			size = Vector3(length * 0.52, length, length * 0.67) if frozen else Vector3(0.07, 0.07, length * 1.55)
			spin = Basis.from_euler(Vector3(angle + u * 3, angle * 0.7, angle + u * 3.9))
			tint = Color("#c7e8f6") if frozen else Color("#ffb05e")
			if at.y < 0 or t < 0.014 * (i % 11):
				size *= 0.001
		else:
			# Sampling the actual falling body's earlier pose leaves a curved
			# wake from each failing bogie while the camera moves past it.
			var u := fposmod(age * 1.30 + i * 0.618, 1.0)
			var old := _carriage_pose(maxf(0, age - u * 0.63))
			at = old * Vector3(-2.3 if i % 2 else 2.3, -2.15, -4.5)
			at += radial * (u * (1 + i % 3)) + Vector3.UP * (-3 * u * u)
			size = Vector3(0.055, 0.055, 0.36 + 0.26 * (i % 4)) * (1.0 - u * 0.84)
			spin = old.basis
			tint = Color("#ffb777").lerp(Color("#dc5726"), u)
		sparks.set_instance_transform(i, Transform3D(spin * Basis.from_scale(size), at))
		sparks.set_instance_color(i, tint)
	for i in range(dust.visible_instance_count):
		var angle := i * 2.39996
		var radial := Vector3(cos(angle), 0, sin(angle))
		var at: Vector3
		var width: float
		var alpha: float
		var tint: Color
		if t < 0 and not frozen:
			var trail := float(i) / CLOUDS
			var past := _carriage_pose(maxf(0.0, age - trail * 1.22))
			at = past * Vector3(-2.2, -1.96, -4.5) + Vector3.UP * trail * 5 + radial * 0.6
			width = 0.36 + 2.6 * trail
			alpha = (1 - trail) * 0.68 * minf(1, age * 2)
			tint = Color("#605861")
		else:
			var swell := maxf(0, t)
			var rad := 1.7 + fmod(i * 3.741, 4.6)
			at = radial * (rad + swell * (1 + i % 4)) + Vector3.UP * (0.45 + (i % 5) * 0.21 + swell * (1.0 + 0.50 * (i % 5)))
			width = 1.0 + smoothstep(0, CONTACT, age) * 1.6 + swell * (0.36 + 0.25 * (i % 4))
			alpha = (0.32 * smoothstep(0.18, 2.3, age) + 0.65 * (1 - exp(-swell * 6))) * (1.0 - smoothstep(0.58, 3, t))
			at.x += swell * swell * 0.65
			tint = Color("#d1e1e2") if frozen else Color("#a89a92")
		dust.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(width, width * (0.73 + 0.14 * (i % 3)), width)), at))
		tint.a = alpha
		dust.set_instance_color(i, tint)
