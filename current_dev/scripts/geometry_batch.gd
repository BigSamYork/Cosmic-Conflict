class_name GeometryBatch
extends RefCounted

const BOX_FACES := [0, 1, 3, 0, 3, 2, 4, 6, 7, 4, 7, 5, 0, 4, 5, 0, 5, 1, 2, 3, 7, 2, 7, 6, 0, 2, 6, 0, 6, 4, 1, 5, 7, 1, 7, 3]
const BOX_EDGES := [[0, 1], [1, 3], [3, 2], [2, 0], [4, 5], [5, 7], [7, 6], [6, 4], [0, 4], [1, 5], [2, 6], [3, 7]]

var vertices := PackedVector3Array()
var indices := PackedInt32Array()
var face_colors := PackedColorArray()
var edges := PackedVector3Array()
var edge_colors := PackedColorArray()

func surface(points: PackedVector3Array, triangles: PackedInt32Array, tint: Color) -> void:
	var offset: int = vertices.size()
	vertices.append_array(points)
	for _point in points:
		face_colors.append(tint)
	for index in triangles:
		indices.append(offset + index)

func line(start: Vector3, end: Vector3, tint: Color) -> void:
	edges.append(start)
	edges.append(end)
	edge_colors.append(tint)

func outline(points: PackedVector3Array, tint: Color, closed: bool = true) -> void:
	for i in range(points.size() - 1):
		line(points[i], points[i + 1], tint)
	if closed and points.size() > 2:
		line(points[-1], points[0], tint)

func box(center: Vector3, dimensions: Vector3, tint: Color, fill: Color = Color("#101622"), orientation: Basis = Basis.IDENTITY) -> void:
	var points := PackedVector3Array()
	for z in [-0.5, 0.5]:
		for y in [-0.5, 0.5]:
			for x in [-0.5, 0.5]:
				points.append(center + orientation * (Vector3(x, y, z) * dimensions))
	surface(points, PackedInt32Array(BOX_FACES), fill)
	for pair in BOX_EDGES:
		line(points[pair[0]], points[pair[1]], tint)

# Each transverse ship frame gives half-beam, half-height and longitudinal station.
func ship_hull(center: Vector3, frames: Array[Vector3], trim: Color, plating: Color) -> void:
	var previous := PackedVector3Array()
	const SECTION := [Vector2(-1, 0), Vector2(-0.55, 1), Vector2(0.55, 1), Vector2(1, 0), Vector2(0.55, -1), Vector2(-0.55, -1)]
	for station in frames:
		var rim := PackedVector3Array()
		for p: Vector2 in SECTION:
			rim.append(center + Vector3(p.x * station.x, p.y * station.y, station.z))
		if previous.is_empty() or station == frames.back():
			surface(rim, PackedInt32Array([0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 5]), plating)
			outline(rim, trim)
		if not previous.is_empty():
			for i in rim.size():
				var j := (i + 1) % rim.size()
				surface(PackedVector3Array([previous[i], previous[j], rim[j], rim[i]]), PackedInt32Array([0, 1, 2, 0, 2, 3]), plating.darkened(0.08 * i))
				line(previous[i], rim[i], trim)
		previous = rim

func ring(center: Vector3, radius: float, tint: Color, segments: int = 12) -> void:
	var points := PackedVector3Array()
	for i in range(segments):
		var angle: float = float(i) / float(segments) * TAU
		points.append(center + Vector3(cos(angle), sin(angle), 0.0) * radius)
	outline(points, tint)

func tube(center: Vector3, radius: float, length: float, tint: Color, segments: int = 12, end_radius: float = -1.0) -> void:
	var tip_radius: float = radius if end_radius < 0.0 else end_radius
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	for i in range(segments):
		var angle: float = i * TAU / segments
		var radial := Vector3(cos(angle), sin(angle), 0)
		front.append(center + radial * radius + Vector3(0, 0, length * 0.5))
		back.append(center + radial * tip_radius - Vector3(0, 0, length * 0.5))
	outline(front, tint)
	outline(back, tint)
	for i in range(segments):
		var next: int = (i + 1) % segments
		surface(PackedVector3Array([front[i], front[next], back[next], back[i]]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#15222c"))
		line(front[i], back[i], tint)

func truss(start: Vector3, end: Vector3, thickness: float, tint: Color, bays: int = 6) -> void:
	var edge := Vector3(0, thickness * 0.5, 0)
	line(start + edge, end + edge, tint)
	line(start - edge, end - edge, tint)
	for i in range(bays):
		var a: Vector3 = start.lerp(end, float(i) / bays)
		var b: Vector3 = start.lerp(end, float(i + 1) / bays)
		line(a - edge, b + edge, tint)
		line(a + edge, b - edge, tint)

func crystal(center: Vector3, radius: float, height: float, tint: Color) -> void:
	var lower := PackedVector3Array()
	var upper := PackedVector3Array()
	var tip: Vector3 = center + Vector3(radius * 0.35, height, -radius * 0.25)
	for i in range(6):
		var angle: float = i * TAU / 6
		lower.append(center + Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		upper.append(center + Vector3(cos(angle + 0.12) * radius * 0.65, height * 0.7, sin(angle + 0.12) * radius * 0.65))
	for i in range(6):
		var next: int = (i + 1) % 6
		var fill: Color = tint.darkened(0.55 if i % 2 == 0 else 0.25)
		surface(PackedVector3Array([lower[i], lower[next], upper[next], upper[i]]), PackedInt32Array([0, 1, 2, 0, 2, 3]), fill)
		surface(PackedVector3Array([upper[i], upper[next], tip]), PackedInt32Array([0, 1, 2]), tint.darkened(0.12 if i % 2 == 0 else 0.4))
		line(lower[i], upper[i], tint)
		line(upper[i], tip, tint)
		line(upper[i], upper[next], tint)

func ellipsoid(center: Vector3, radii: Vector3, tint: Color, rings: int = 8, sectors: int = 12) -> void:
	for row in range(rings):
		var a: float = PI * row / rings
		var b: float = PI * (row + 1) / rings
		for column in range(sectors):
			var u: float = TAU * column / sectors
			var v: float = TAU * (column + 1) / sectors
			var p := center + radii * Vector3(sin(a) * cos(u), cos(a), sin(a) * sin(u))
			var q := center + radii * Vector3(sin(a) * cos(v), cos(a), sin(a) * sin(v))
			var r := center + radii * Vector3(sin(b) * cos(v), cos(b), sin(b) * sin(v))
			var s := center + radii * Vector3(sin(b) * cos(u), cos(b), sin(b) * sin(u))
			surface(PackedVector3Array([p, q, r, s]), PackedInt32Array([0, 1, 2, 0, 2, 3]), tint.darkened(0.58 + 0.12 * sin(u + row * 0.4)))
			if row % 3 == 1:
				line(p, q, tint)
			if column % 3 == 0:
				line(p, s, tint.darkened(0.18))

func limb(start: Vector3, end: Vector3, start_radius: float, end_radius: float, tint: Color, sectors: int = 8) -> void:
	var axis: Vector3 = (end - start).normalized()
	var u: Vector3 = axis.cross(Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.95 else Vector3.UP).normalized()
	var v: Vector3 = axis.cross(u)
	for i in range(sectors):
		var a: float = i * TAU / sectors
		var b: float = (i + 1) * TAU / sectors
		var first: Vector3 = u * cos(a) + v * sin(a)
		var next: Vector3 = u * cos(b) + v * sin(b)
		var p: Vector3 = start + first * start_radius
		var q: Vector3 = start + next * start_radius
		var r: Vector3 = end + next * end_radius
		var s: Vector3 = end + first * end_radius
		surface(PackedVector3Array([p, q, r, s]), PackedInt32Array([0, 1, 2, 0, 2, 3]), tint.darkened(0.6 + (i % 2) * 0.1))
		if i % 2 == 0:
			line(p, s, tint)
		line(s, r, tint.darkened(0.15))

func build() -> Node3D:
	# One opaque draw and one colored stroke draw, regardless of detail count.
	var model := Node3D.new()
	if not vertices.is_empty():
		var solid: MeshInstance3D = VectorArt.solid(vertices, indices, Color.WHITE, face_colors)
		var lookup: Dictionary = {}
		for i in range(0, edges.size(), 2):
			var a: Vector3 = edges[i]
			var b: Vector3 = edges[i + 1]
			if not lookup.has(a):
				lookup[a] = {}
			if not lookup.has(b):
				lookup[b] = {}
			lookup[a][b] = edge_colors[i / 2]
			lookup[b][a] = edge_colors[i / 2]
		var fragment_edges := PackedColorArray()
		for i in range(0, indices.size(), 3):
			var tint: Color = face_colors[indices[i]]
			for edge in range(3):
				var a: Vector3 = vertices[indices[i + edge]]
				var b: Vector3 = vertices[indices[i + (edge + 1) % 3]]
				if lookup.has(a) and lookup[a].has(b):
					tint = lookup[a][b]
					break
			fragment_edges.append(tint)
		solid.mesh.set_meta("fragment_edge_colors", fragment_edges)
		model.add_child(solid)
	if not edges.is_empty():
		model.add_child(VectorArt.lines(edges, Color.WHITE, edge_colors))
	return model
