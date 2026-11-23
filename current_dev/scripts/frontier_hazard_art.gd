extends RefCounted

# A single opaque surface carries bodywork, glazing, trim and lamps so each
# damaged railcar uses one draw call. UV.x identifies emissive surfaces.
static var carriage_mesh: ArrayMesh
static var floe_mesh: ArrayMesh

static func _face(st: SurfaceTool, points: PackedVector3Array, outward: Vector3, color: Color, emission: float = 0.0) -> void:
	var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var reverse := normal.dot(outward) >= 0.0
	if not reverse:
		normal = -normal
	for i in range(1, points.size() - 1):
		for index: int in [0, i + 1 if reverse else i, i if reverse else i + 1]:
			st.set_normal(normal)
			st.set_color(color)
			st.set_uv(Vector2(emission, 0))
			st.add_vertex(points[index])

static func _box(st: SurfaceTool, at: Vector3, size: Vector3, color: Color, emission: float = 0.0) -> void:
	var half := size * 0.5
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		var u: Vector3 = Vector3.UP if axis == Vector3.RIGHT else Vector3.RIGHT
		var v: Vector3 = axis.cross(u)
		for signum: float in [-1.0, 1.0]:
			var center: Vector3 = at + axis * half * signum
			var p: Vector3 = u * half
			var q: Vector3 = v * half
			_face(st, PackedVector3Array([center - p - q, center + p - q, center + p + q, center - p + q]), axis * signum, color, emission)

static func railcar() -> ArrayMesh:
	if carriage_mesh != null:
		return carriage_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := PackedVector3Array()
	# Chamfered lower skirt, flat sides, sloping roof and tapered driver's cab.
	const SECTION := [Vector2(-0.72, -1), Vector2(0.72, -1), Vector2(1, -0.61),
		Vector2(1, 0.63), Vector2(0.74, 1), Vector2(-0.74, 1), Vector2(-1, 0.63), Vector2(-1, -0.61)]
	for station: Vector3 in [Vector3(2.1, 1.5, -9.0), Vector3(2.7, 1.88, -8.2),
			Vector3(2.7, 1.88, 6.45), Vector3(2.46, 1.58, 8.05), Vector3(1.95, 1.13, 9.25)]:
		var rim := PackedVector3Array()
		for pt: Vector2 in SECTION:
			rim.append(Vector3(station.x * pt.x, station.y * pt.y, station.z))
		if previous.is_empty():
			_face(st, rim, Vector3.FORWARD, Color("#32333e"))
		else:
			for i in range(rim.size()):
				var j := (i + 1) % rim.size()
				var n := (rim[i] + rim[j]) * 0.5
				n.z = 0
				var panel := Color("#756d71") if i in [2, 6] else Color("#535363")
				if n.y < -0.8:
					panel = Color("#2b2d38")
				_face(st, PackedVector3Array([previous[i], previous[j], rim[j], rim[i]]), n, panel)
		previous = rim
	_face(st, previous, Vector3.BACK, Color("#514a52"))
	var rubber := Color("#151c24")
	var steel := Color("#7d8186")
	var glass := Color("#273946")
	for side: float in [-1, 1]:
		_box(st, Vector3(side * 2.71, -0.47, -0.79), Vector3(0.06, 0.20, 14.72), Color("#da754d"))
		_box(st, Vector3(side * 2.73, -0.77, -0.79), Vector3(0.06, 0.09, 14.72), Color("#b0aab0"))
		for i in range(8):
			var z := -7.29 + i * 1.78
			var is_door := i in [2, 6]
			if is_door:
				_box(st, Vector3(side * 2.72, -0.05, z), Vector3(0.11, 2.32, 1.39), rubber)
				for j: float in [-1, 1]:
					_box(st, Vector3(side * 2.80, -0.05, z + j * 0.34), Vector3(0.09, 2.13, 0.63), Color("#685f67"))
					_box(st, Vector3(side * 2.86, 0.40, z + j * 0.34), Vector3(0.04, 0.68, 0.43), glass)
				_box(st, Vector3(side * 2.78, 1.20, z), Vector3(0.07, 0.09, 0.65), Color("#ff8556"), 0.85)
			else:
				_box(st, Vector3(side * 2.71, 0.47, z), Vector3(0.09, 1.03, 1.53), rubber)
				_box(st, Vector3(side * 2.78, 0.47, z), Vector3(0.04, 0.83, 1.34), glass)
				# Reflections, saloon stanchion and seat backs behind each pane.
				_box(st, Vector3(side * 2.805, 0.76, z), Vector3(0.02, 0.10, 1.21), Color("#78929c"), 0.22)
				_box(st, Vector3(side * 2.81, 0.46, z + 0.39), Vector3(0.02, 0.74, 0.055), steel)
				_box(st, Vector3(side * 2.81, 0.18, z - 0.26), Vector3(0.02, 0.20, 0.46), Color("#461f31"))
		_box(st, Vector3(side * 1.44, 0.5, 9.265), Vector3(0.62, 0.30, 0.08), rubber)
		_box(st, Vector3(side * 1.44, 0.5, 9.320), Vector3(0.45, 0.16, 0.035), Color("#ffc784"), 1.0)
		for z: float in [-5.65, 4.5]:
			_box(st, Vector3(side * 1.85, -1.85, z), Vector3(0.92, 1.04, 3.34), rubber)
			for j in range(6):
				_box(st, Vector3(side * 2.34, -1.86, z - 1.25 + j * 0.49), Vector3(0.22, 0.62, 0.19), steel)
			_box(st, Vector3(side * 2.31, -2.18, z), Vector3(0.18, 0.16, 2.80), Color("#ff8243"), 0.8)
	# The angled windshield joins the upper nose sections.
	_face(st, PackedVector3Array([Vector3(-1.97, 1.07, 9.27), Vector3(1.97, 1.07, 9.27),
		Vector3(1.88, 1.65, 7.81), Vector3(-1.88, 1.65, 7.81)]), Vector3(0, 0.8, 1), glass)
	_box(st, Vector3(0, 0.82, 9.285), Vector3(1.85, 0.29, 0.07), rubber)
	for j in range(11):
		_box(st, Vector3(-0.76 + 0.15 * j, 0.83, 9.332), Vector3(0.085, 0.10, 0.025), Color("#eab76a"), 0.8)
	_box(st, Vector3(0, -0.69, 9.29), Vector3(2.17, 0.34, 0.27), rubber)
	for z: float in [-5.2, 0.1, 4.3]:
		_box(st, Vector3(0, 1.97, z), Vector3(2.77, 0.38, 2.24), steel)
		for l in range(9):
			_box(st, Vector3(0, 2.19, z - 0.89 + l * 0.215), Vector3(2.31, 0.09, 0.11), rubber)
	carriage_mesh = st.commit()
	return carriage_mesh

static func glacier_block() -> ArrayMesh:
	if floe_mesh != null:
		return floe_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Broad, torn tables of dirty blue ice with milky pressure ridges and
	# suspended dark sediment, rather than regular hexagonal mineral crystals.
	var contour := PackedVector2Array([Vector2(-0.99, -0.41), Vector2(-0.35, -0.83),
		Vector2(0.72, -0.64), Vector2(1, 0.08), Vector2(0.47, 0.70), Vector2(-0.63, 0.56)])
	var prev := PackedVector3Array()
	for y: float in [0, 0.24, 0.27, 0.56, 0.59, 0.90, 1.0]:
		var rim := PackedVector3Array()
		for i in range(contour.size()):
			var v := contour[i]
			var w := 1.0 - 0.12 * y + 0.04 * sin(i * 2.8 + y * 1.8)
			rim.append(Vector3(v.x * w + y * 0.24, y * (0.88 + 0.11 * cos(i * 2.1)), v.y * w + y * 0.06))
		if not prev.is_empty():
			for i in range(rim.size()):
				var j := (i + 1) % rim.size()
				var tint := Color("#6194ad").lerp(Color("#96c6d0"), 0.5 + 0.5 * sin(i * 2.9))
				if is_equal_approx(y, 0.27): tint = Color("#597781")
				if is_equal_approx(y, 0.59): tint = Color("#a7d7de")
				if is_equal_approx(y, 1.0): tint = Color("#bce5eb")
				_face(st, PackedVector3Array([prev[i], prev[j], rim[j], rim[i]]), Vector3(contour[i].x, 0, contour[i].y), tint)
		prev = rim
	var ridge := Vector3(0.08, 0.99, -0.03)
	for i in range(prev.size()):
		_face(st, PackedVector3Array([prev[i], prev[(i + 1) % prev.size()], ridge]), Vector3.UP, Color("#cae1df").darkened(0.06 * (i % 3)))
	floe_mesh = st.commit()
	return floe_mesh
