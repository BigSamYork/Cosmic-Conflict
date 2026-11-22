class_name AsteroidArt
extends RefCounted

const VARIANTS: int = 3
const GIANT_VARIANTS: Array[int] = [3, 4]
const CRATERS := [
	Vector3(0.3, 0.6, 0.75), Vector3(-0.65, -0.2, 0.8),
	Vector3(0.72, -0.55, 0.3), Vector3(-0.5, 0.65, -0.55),
	Vector3(0.4, -0.15, -0.95), Vector3(-0.85, -0.5, -0.3),
	Vector3(0.1, -0.95, 0.15), Vector3(0.85, 0.3, -0.35),
	Vector3(-0.2, 0.1, 1), Vector3(0.45, 0.25, 1), Vector3(0.2, -0.6, 1),
	Vector3(-0.5, 0.65, 0.4), Vector3(0.92, 0.1, 0.15), Vector3(0.3, 0.8, -0.5),
	Vector3(0.1, 0, -1), Vector3(-0.6, 0.1, -0.7), Vector3(0.7, -0.7, -0.3),
	Vector3(-0.2, -0.7, 0.7)
]

static var _centers: Dictionary[int, PackedVector3Array] = {}
static var _rim_cutoffs := PackedFloat64Array()
static var _shade_cutoffs := PackedFloat64Array()

static func _crater_centers(variant: int) -> PackedVector3Array:
	if not _centers.has(variant):
		var centers := PackedVector3Array()
		var rotation := Basis(Vector3.UP, variant * 0.37)
		for direction: Vector3 in CRATERS:
			centers.append((rotation * direction).normalized())
		_centers[variant] = centers
		if _rim_cutoffs.is_empty():
			for i in range(CRATERS.size()):
				_rim_cutoffs.append(cos(crater_radius(i) * 1.3))
				_shade_cutoffs.append(cos(crater_radius(i) * 0.7))
	return _centers[variant]

static func point(direction: Vector3, variant: int) -> Vector3:
	var normal: Vector3 = direction.normalized()
	var radial: float = 0.88 + 0.05 * sin(normal.x * 8.0 + normal.y * 4.0 + variant) + 0.045 * sin(normal.z * 9.0 - normal.y * 5.0)
	if variant == 2:
		radial += 0.045 * sin(normal.y * 6.0 + normal.x * 3.0)
	var centers := _crater_centers(variant)
	for i in range(centers.size()):
		var dot := normal.dot(centers[i])
		if dot <= _rim_cutoffs[i]:
			continue
		var angle: float = acos(clampf(dot, -1.0, 1.0))
		var ratio: float = angle / crater_radius(i)
		if ratio < 1.3:
			var bowl: float = minf(0.14, crater_radius(i) * 0.5) * (1.0 - smoothstep(0.18, 0.95, ratio))
			var rim: float = 0.045 * exp(-pow((ratio - 1.0) / 0.16, 2.0))
			radial += rim - bowl
	var axes := Vector3(0.82, 1.17, 0.76) if variant == 1 else Vector3(1.1, 0.86, 0.94) if variant == 2 else Vector3(1.0, 0.97, 0.91)
	if variant == 3:
		axes = Vector3(1.25, 0.62, 0.7)
	elif variant == 4:
		axes = Vector3(1.2, 0.58, 0.67)
		radial *= 0.74 + 0.26 * absf(normal.x)
	var result: Vector3 = normal * radial * axes
	if variant == 4:
		result.z += 0.12 * sin(normal.x * 2.8)
	return result

static func crater_center(index: int, variant: int) -> Vector3:
	return _crater_centers(variant)[index]

static func crater_radius(index: int) -> float:
	return (0.19 + float(index % 3) * 0.065) if index < 8 else (0.085 + float(index % 3) * 0.02)

static func tumble_velocity(seed_value: int) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var axis := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.25, 1), rng.randf_range(-1, 1)).normalized()
	return axis * rng.randf_range(0.06, 0.65) * (-1.0 if rng.randf() < 0.5 else 1.0)

static func _stroke_point(direction: Vector3, vertices: PackedVector3Array, rings: int, sectors: int) -> Vector3:
	var normal: Vector3 = direction.normalized()
	var latitude: float = acos(clampf(normal.y, -1, 1)) / PI * rings
	var longitude: float = fposmod(atan2(normal.z, normal.x), TAU) / TAU * sectors
	var row: int = mini(rings - 1, floori(latitude))
	var column: int = mini(sectors - 1, floori(longitude))
	var u: float = longitude - column
	var v: float = clampf(latitude - row, 0, 1)
	var next: int = (column + 1) % sectors
	var surface: Vector3
	# Attach lines to the actual triangulated surface, including concave crater walls.
	if row == 0:
		surface = vertices[0].lerp(vertices[1 + column].lerp(vertices[1 + next], u), v)
	elif row == rings - 1:
		var last: int = 1 + (rings - 2) * sectors
		surface = vertices[last + column].lerp(vertices[last + next], u).lerp(vertices[-1], v)
	else:
		var a: int = 1 + (row - 1) * sectors + column
		var b: int = 1 + (row - 1) * sectors + next
		var c: int = a + sectors
		var d: int = b + sectors
		if u + v <= 1:
			surface = vertices[a] * (1.0 - u - v) + vertices[b] * u + vertices[c] * v
		else:
			surface = vertices[b] * (1.0 - v) + vertices[d] * (u + v - 1.0) + vertices[c] * (1.0 - u)
	return surface * 1.003

static func create(variant: int, tint: Color, distant: bool = false, icy: bool = false) -> Node3D:
	var key: String = "crater-rock:%d:%s:%s" % [variant, tint.to_html(), distant] + (":ice" if icy else "")
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var vertices := PackedVector3Array([point(Vector3.UP, variant)])
	var colors := PackedColorArray([Color("#465d73") if icy else Color("#34313c")])
	var triangles := PackedInt32Array()
	var rings: int = (18 if variant >= 3 else 14) if distant else 28
	var sectors: int = (36 if variant >= 3 else 28) if distant else 56
	var centers := _crater_centers(variant)
	for ring in range(1, rings):
		var theta: float = PI * ring / rings
		for sector in range(sectors):
			var phi: float = TAU * sector / sectors
			var direction := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
			vertices.append(point(direction, variant))
			var shading: float = 0.62 + 0.38 * maxf(0.0, direction.dot(Vector3(0.3, 0.6, 0.7).normalized()))
			for crater in range(CRATERS.size()):
				if direction.dot(centers[crater]) > _shade_cutoffs[crater]:
					shading *= 0.7
					break
			colors.append((Color("#526877") if icy else Color("#45404a")) * Color(shading, shading, shading, 1))
	var bottom: int = vertices.size()
	vertices.append(point(Vector3.DOWN, variant))
	colors.append(Color("#293c50") if icy else Color("#24232c"))
	for sector in range(sectors):
		var next: int = (sector + 1) % sectors
		triangles.append_array(PackedInt32Array([0, 1 + next, 1 + sector]))
		var last: int = 1 + (rings - 2) * sectors
		triangles.append_array(PackedInt32Array([bottom, last + sector, last + next]))
	for ring in range(rings - 2):
		for sector in range(sectors):
			var a: int = 1 + ring * sectors + sector
			var b: int = 1 + ring * sectors + (sector + 1) % sectors
			triangles.append_array(PackedInt32Array([a, b, a + sectors, b, b + sectors, a + sectors]))
	var result := Node3D.new()
	var hull := VectorArt.solid(vertices, triangles, Color.WHITE, colors)
	var stone := ShaderMaterial.new()
	stone.shader = preload("res://shaders/regolith.gdshader")
	stone.set_shader_parameter("geology", preload("res://assets/ground/regolith.png"))
	stone.set_shader_parameter("formation", float(variant))
	stone.set_shader_parameter("glacial", icy)
	stone.set_shader_parameter("seam_color", tint)
	hull.material_override = stone
	result.add_child(hull)
	for i in range(CRATERS.size()):
		var center: Vector3 = crater_center(i, variant)
		var u: Vector3 = center.cross(Vector3.UP).normalized()
		var v: Vector3 = center.cross(u).normalized()
		for band in [1.0, 0.64]:
			var rim := PackedVector3Array()
			var angular_radius: float = crater_radius(i) * band
			var segments: int = (20 if variant >= 3 else 16) if distant else 28
			for j in range(segments):
				var angle: float = TAU * j / segments
				var local_radius: float = angular_radius * (1.0 + 0.045 * sin(angle * 3.0 + i))
				var direction: Vector3 = center * cos(local_radius) + (u * cos(angle) + v * sin(angle)) * sin(local_radius)
				rim.append(_stroke_point(direction, vertices, rings, sectors))
			batch.outline(rim, tint.darkened(0.59 if band == 1.0 else 0.73))
		if not distant:
			for spoke in range(5):
				var angle: float = spoke * TAU / 5 + i
				var radial: Vector3 = u * cos(angle) + v * sin(angle)
				var a: Vector3 = center * cos(crater_radius(i)) + radial * sin(crater_radius(i))
				var b: Vector3 = center * cos(crater_radius(i) * 0.7) + radial * sin(crater_radius(i) * 0.7)
				batch.line(_stroke_point(a, vertices, rings, sectors), _stroke_point(b, vertices, rings, sectors), tint.darkened(0.73))
	for crack in range((12 if variant >= 3 else 18) if distant else 32):
		var start: Vector3 = Vector3(sin(crack * 2.3), cos(crack * 1.7), sin(crack * 0.9 + 0.5)).normalized()
		var tangent: Vector3 = start.cross(Vector3(0.3, 1, 0.2)).normalized()
		var previous: Vector3 = _stroke_point(start, vertices, rings, sectors)
		for segment in range(1, 13):
			var distance: float = segment * 0.075
			var normal: Vector3 = (start * cos(distance) + tangent * sin(distance) + start.cross(tangent) * sin(segment * 1.8 + crack) * 0.02).normalized()
			var current: Vector3 = _stroke_point(normal, vertices, rings, sectors)
			batch.line(previous, current, tint.darkened(0.58))
			previous = current
	var outline: Node3D = batch.build()
	var strokes: MeshInstance3D = outline.get_child(0)
	outline.remove_child(strokes)
	outline.free()
	result.add_child(strokes)
	return VectorArt.remember_model(key, result)
