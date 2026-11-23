class_name VolcanoEruption
extends Node3D

const CRATER_HEIGHT: float = 3.65
const PROFILE: Array[Vector2] = [Vector2(4.3, 0), Vector2(3.35, 0.8), Vector2(2.35, 2.1), Vector2(1.05, 4.2), Vector2(0.64, 4.0), Vector2(0.5, 3.3)]
const SMOKE_COUNT: int = 30
const CINDER_COUNT: int = 16
static var smoke_mesh: QuadMesh
static var smoke_material: ShaderMaterial

var cone: Node3D
var jet: Node3D
var smoke: MultiMeshInstance3D
var cinders: Array[MultiMeshInstance3D] = []
var lava_material: ShaderMaterial
var terrain_height: Callable
var lava_light := OmniLight3D.new()

func _ready() -> void:
	cone = cone_model()
	add_child(cone)
	var lava := MeshInstance3D.new()
	lava.mesh = _lava_mesh()
	lava.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lava_material = ShaderMaterial.new()
	lava_material.shader = preload("res://shaders/volcanic_lava.gdshader")
	lava_material.render_priority = 1
	lava.material_override = lava_material
	add_child(lava)
	lava_light.light_color = Color("#ff792e")
	lava_light.omni_range = 12.0
	lava_light.omni_attenuation = 1.45
	lava_light.position.y = 2.6
	lava_light.distance_fade_enabled = true
	lava_light.distance_fade_begin = 85.0
	lava_light.distance_fade_length = 30.0
	add_child(lava_light)
	jet = EncounterArt.heat_plume()
	jet.position.y = CRATER_HEIGHT
	add_child(jet)
	if smoke_mesh == null:
		smoke_mesh = QuadMesh.new()
		smoke_mesh.size = Vector2(3.9,3.9)
	smoke = _instances(smoke_mesh, ash_material(), SMOKE_COUNT)
	add_child(smoke)
	var stones := cinder_model()
	for mesh: MeshInstance3D in stones.get_children():
		var material: Material = mesh.material_override
		if material is StandardMaterial3D:
			material = material.duplicate()
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var instances: MultiMeshInstance3D = _instances(mesh.mesh, material, CINDER_COUNT)
		add_child(instances)
		cinders.append(instances)
	stones.free()

func update_visual(time: float, eruption_age: float, active: bool, cooling: float, height: float) -> void:
	var warming: float = clampf(eruption_age + 1.0, 0, 1) if eruption_age < 0 else 1.0
	var maturity: float = smoothstep(0.0, 0.85, maxf(0, eruption_age))
	var ash_alpha: float = (1.0 - smoothstep(0.2, 1.0, cooling)) if eruption_age >= 0 else 0.0
	var spread: float = lerpf(1.2, 5.3, smoothstep(0.15, 1.25, maxf(0, eruption_age))) + cooling * 1.8
	var ceiling: float = lerpf(8.0, 24.0, maturity) + cooling * 3.0
	jet.visible = active
	jet.scale = Vector3(1.0 + 0.08 * sin(time * 21), height - CRATER_HEIGHT, 1.0 + 0.08 * cos(time * 17))
	lava_material.set_shader_parameter("activity", (0.12 + warming * 0.32) if eruption_age < 0 else 1.0 - smoothstep(0.1, 1, cooling))
	lava_material.set_shader_parameter("flow_amount", 0.2 + warming * 0.5 if eruption_age < 0 else minf(1, 0.7 + eruption_age * 0.5))
	lava_material.set_shader_parameter("flow_time", time)
	lava_light.light_energy = 0.38 + 0.52 * (warming if eruption_age < 0 else 1.0 - cooling) + 0.03 * sin(time * 2.4)
	for i in range(SMOKE_COUNT):
		var at: Vector3
		var size: Vector3
		var alpha: float
		if i < 6:
			var progress: float = fposmod(time * 0.42 + i / 6.0, 1.0)
			at = Vector3(sin(time * 0.5 + i) * progress * 0.9, CRATER_HEIGHT + progress * (5.0 + warming * 4.0), progress * 0.7)
			size = Vector3.ONE * (0.45 + progress * (0.8 + warming * 0.7))
			alpha = sin(progress * PI) * (0.4 if active else 0.65)
		elif i < 14:
			var progress: float = (i - 6) / 7.0
			at = Vector3(sin(time * 1.5 + i) * 0.35, lerpf(CRATER_HEIGHT, ceiling - 1.0, progress), cos(i * 1.7 + time) * 0.35)
			size = Vector3(1.7, 1.9, 1.7) * (0.8 + progress * 0.55)
			alpha = ash_alpha * 0.82
		else:
			var index: int = i - 14
			var angle: float = index * TAU / (12.0 if index < 12 else 4.0) + time * 0.07
			var radius: float = spread if index < 12 else spread * 0.32
			at = Vector3(cos(angle) * radius, ceiling + sin(index * 2.7 + time * 0.4) * 0.7, sin(angle) * radius)
			at.x += maxf(0, eruption_age) * 0.35
			size = Vector3(2.1, 1.55, 2.1) * (0.55 + maturity * 0.65 + cooling * 0.3)
			if index >= 12:
				size *= 1.15
				at.y += 1.8
			alpha = ash_alpha * 0.82
		size.x *= 1.0 + 0.12 * sin(time * 0.8 + i)
		size.z *= 1.0 + 0.12 * cos(time * 0.7 + i)
		smoke.multimesh.set_instance_transform(i, Transform3D(Basis.from_euler(Vector3(i * 0.3, time * 0.1 + i * 0.7, sin(time * 0.4 + i) * 0.2)) * Basis.from_scale(size), at))
		var tint := Color("#847778") if i >= 14 else Color("#675e6a")
		tint.a = alpha
		smoke.multimesh.set_instance_color(i, tint)
	for i in range(CINDER_COUNT):
		var age: float = eruption_age - (i % 6) * 0.17
		var angle: float = i * 2.399
		var speed: float = 1.8 + (i % 4) * 0.45
		var at := Vector3(cos(angle) * speed * maxf(0, age), CRATER_HEIGHT + (10 + i % 5) * age - 7 * age * age, sin(angle) * speed * maxf(0, age))
		var size: float = 0.14 + (i % 3) * 0.06
		var transform := Transform3D(Basis.from_euler(Vector3(age * 2, angle, age * 3)).scaled(Vector3.ONE * size), at)
		var alpha: float = (1.0 - smoothstep(1.0, 2.7, age)) if age >= 0 and at.y > 0.2 else 0.0
		for instances in cinders:
			instances.multimesh.set_instance_transform(i, transform)
			instances.multimesh.set_instance_color(i, Color(1, 1, 1, alpha))

static func ash_material() -> ShaderMaterial:
	if smoke_material == null:
		smoke_material = ShaderMaterial.new()
		smoke_material.shader = preload("res://shaders/volcanic_smoke.gdshader")
		smoke_material.set_shader_parameter("density_map",_density_map())
	return smoke_material

# One shared RG texture supplies irregular density and internally lit folds to all
# puffs. Baking the turbulence keeps the fragment shader to a single texture read.
static func _density_map() -> ImageTexture:
	var img := Image.create_empty(96,96,false,Image.FORMAT_RG8)
	var noise := FastNoiseLite.new()
	noise.seed = 527
	noise.frequency = 1.0
	noise.fractal_octaves = 4
	for y in img.get_height():
		for x in img.get_width():
			var p := (Vector2(x,y)+Vector2(0.5,0.5))/48.0-Vector2.ONE
			var q := p*3.5 + Vector2(noise.get_noise_2dv(p*2.3),noise.get_noise_2dv(p*2.3+Vector2(8,5)))*1.4
			var billow := noise.get_noise_2dv(q)*0.55+noise.get_noise_2dv(q*2.1)*0.25
			var edge := 0.73 - p.length() + billow * 0.33
			var density := smoothstep(-0.06,0.27,edge) * (0.62+0.38*smoothstep(-0.26,0.34,billow))
			var ridge := billow-noise.get_noise_2dv(q+Vector2(-0.20,-0.21))*0.60
			img.set_pixel(x,y,Color(density,clampf(0.48+2.2*ridge,0,1),0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _instances(mesh: Mesh, material: Material, count: int) -> MultiMeshInstance3D:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = mesh
	instances.instance_count = count
	var result := MultiMeshInstance3D.new()
	result.multimesh = instances
	result.material_override = material
	result.custom_aabb = AABB(Vector3(-12, -1, -12), Vector3(24, 40, 24))
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result

static func _cone_point(angle: float, level: int) -> Vector3:
	var profile: Vector2 = PROFILE[level]
	var radius: float = profile.x * (1.0 + sin(angle * 5 + 0.4) * 0.06 + cos(angle * 3) * 0.035)
	return Vector3(cos(angle) * radius, profile.y * (1.0 + 0.04 * sin(angle * 4 + 0.3)), sin(angle) * radius)

static func cone_model() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("volcanic_cone")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for level in range(PROFILE.size() - 1):
		for i in range(32):
			var angle: float = i * TAU / 32
			var next: float = (i + 1) * TAU / 32
			var a: Vector3 = _cone_point(angle, level)
			var b: Vector3 = _cone_point(next, level)
			var c: Vector3 = _cone_point(next, level + 1)
			var d: Vector3 = _cone_point(angle, level + 1)
			batch.surface(PackedVector3Array([a, b, c, d]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#38282d") if i % 3 == 0 else Color("#251d27"))
			if i % 4 == 0 or level >= 3:
				batch.line(a, d, Color("#885e50"))
			if level >= 3:
				batch.line(a, b, VectorArt.AMBER if level == 3 else Color("#793c28"))
			if i % 3 == 0 and level < 3:
				batch.line(a.lerp(d, 0.25), b.lerp(c, 0.45), Color("#5d4041"))
	return VectorArt.remember_model("volcanic_cone", batch.build())

static func _slope_point(progress: float, angle: float) -> Vector3:
	var step: float = minf(progress * 3, 2.9999)
	var level: int = floori(step)
	return _cone_point(angle, 3 - level).lerp(_cone_point(angle, 2 - level), step - level) + Vector3.UP * 0.04

# A raised middle and slower edges give each lobe a viscous cross-section.
# The runout follows the lowest accessible outlet instead of climbing the canyon walls.
func _lava_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stream in 6:
		var base_angle := stream * TAU / 6.0
		var path := PackedVector3Array()
		for step in 19:
			var t := step / 18.0
			var angle := base_angle + 0.11 * sin(t * 6.5 + stream)
			path.append(_slope_point(t, angle))
		var head := path[-1]
		var heading := Vector2(head.x, head.z).normalized()
		for step in 18:
			var best := heading
			var best_cost := INF
			for turn in [-0.72, -0.36, 0.0, 0.36, 0.72]:
				var direction := heading.rotated(turn + 0.08 * sin(step * 0.8 + stream))
				var probe := head + Vector3(direction.x, 0, direction.y) * 0.64
				var cost := _floor_at(probe) + 0.16 * absf(turn)
				if cost < best_cost:
					best_cost = cost
					best = direction
			var next := head + Vector3(best.x, 0, best.y) * 0.64
			next.y = _floor_at(next) + 0.07
			if next.y > head.y + 0.20:
				break
			path.append(next)
			head = next
			heading = best
		# Build all five rails before stitching the cross-sections together.
		var rows: Array[PackedVector3Array] = []
		for step in path.size():
			var delta := path[mini(step+1,path.size()-1)] - path[maxi(0,step-1)]
			var side := Vector3(delta.z, 0, -delta.x).normalized()
			var width := 0.22 + 0.56 * smoothstep(0, 20, step) + 0.10 * sin(step * 0.7 + stream)
			width *= 1.0 - 0.79 * smoothstep(path.size()-5, path.size()-1, step)
			var row := PackedVector3Array()
			for col in 5:
				var cross_channel := (col - 2.0) * 0.5
				var point := path[step] + side * width * cross_channel
				if step > 18:
					point.y = _floor_at(point) + 0.07
				point.y += (1 - cross_channel * cross_channel) * 0.09
				row.append(point)
			rows.append(row)
		for step in range(path.size()-1):
			for col in 4:
				for corner: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
					var x := col + corner.x
					var y := step + corner.y
					surface.set_uv(Vector2(x / 4.0, y / 36.0))
					surface.add_vertex(rows[y][x])
	return surface.commit()

func _floor_at(point: Vector3) -> float:
	return float(terrain_height.call(point)) if terrain_height.is_valid() else 0.0

static func cinder_model() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("volcanic_cinder")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var points := PackedVector3Array([Vector3.UP, Vector3.DOWN * 0.8, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
	batch.surface(points, PackedInt32Array([0, 2, 4, 0, 4, 3, 0, 3, 5, 0, 5, 2, 1, 4, 2, 1, 3, 4, 1, 5, 3, 1, 2, 5]), Color("#873b22"))
	for i in range(2, 6):
		batch.line(points[0], points[i], VectorArt.AMBER)
		batch.line(points[1], points[i], Color("#db5d32"))
	return VectorArt.remember_model("volcanic_cinder", batch.build())
