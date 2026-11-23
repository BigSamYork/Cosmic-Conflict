extends RefCounted

# Each moving joint is one indexed mesh; folds, plates, and keratin are part of
# the same surface. All five digits reuse their three meshes.
const SKIN := 0.0
const SCUTE := 0.32
const HORN := 0.66
const FLESH := 1.0
static var meshes: Dictionary = {}
static var hide_material: ShaderMaterial

static func part(kind: String) -> MeshInstance3D:
	if hide_material == null:
		hide_material = ShaderMaterial.new()
		hide_material.shader = preload("res://shaders/canopy_hide.gdshader")
	if not meshes.has(kind):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		match kind:
			"palm": _palm(st)
			"upper", "fore": _arm(st, kind == "upper")
			"root", "medial", "unguis": _digit(st, kind)
		var mesh := st.commit()
		mesh.surface_set_material(0, hide_material)
		meshes[kind] = mesh
	var piece := MeshInstance3D.new()
	piece.mesh = meshes[kind]
	return piece

# Sweep an elliptical changing section along a curved spine. Derive normals
# from both neighbours so the sockets, hooks and tendons catch grazing light.
static func _loft(st: SurfaceTool, path: PackedVector3Array, widths: PackedVector2Array, kind: float, sides: int = 16) -> void:
	var rings := PackedVector3Array()
	for i in path.size():
		var tangent := path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]
		var across := Vector3.BACK.cross(tangent)
		if across.length_squared() < 0.00001:
			across = Vector3.UP.cross(tangent)
		across = across.normalized()
		var depth := tangent.normalized().cross(across)
		for j in sides + 1:
			var theta := TAU * j / sides
			var flute := 1.0 + (0.055 if kind == SKIN else 0.022) * cos(theta * 7.0 + i * 0.17)
			rings.append(path[i] + (across * widths[i].x * cos(theta) + depth * widths[i].y * sin(theta)) * flute)
	var stride := sides + 1
	var first: int = st.get_meta("vertex_count", 0)
	st.set_meta("vertex_count", first + rings.size())
	for i in path.size():
		for j in sides + 1:
			var idx := i * stride + j
			var along := rings[mini(i + 1, path.size() - 1) * stride + j] - rings[maxi(0, i - 1) * stride + j]
			var around := rings[i * stride + (j + 1) % sides] - rings[i * stride + posmod(j - 1, sides)]
			var normal := around.cross(along).normalized()
			if normal.dot(rings[idx] - path[i]) < 0:
				normal = -normal
			st.set_normal(normal)
			st.set_color(Color(kind, 0, 0, 1))
			st.set_uv(Vector2(float(j) / sides, float(i) / (path.size() - 1)))
			st.add_vertex(rings[idx])
			if i < path.size() - 1 and j < sides:
				var a := first + idx
				for k in [a, a + stride, a + 1, a + 1, a + stride, a + stride + 1]:
					st.add_index(k)

static func _arm(st: SurfaceTool, upper: bool) -> void:
	# Native length is 36 m; runtime alignment stretches only the limb axis.
	var path := PackedVector3Array()
	var widths := PackedVector2Array()
	for i in 23:
		var t := float(i) / 22
		var radius := lerpf(6.7, 11.8, t) if upper else lerpf(7.0, 4.1, t)
		radius *= 1.0 + 0.23 * sin(PI * t) + 0.06 * cos(t * TAU * 4)
		path.append(Vector3(1.3 * sin(t * PI), -36 * t, 1.0 * sin(t * PI)))
		widths.append(Vector2(radius, radius * 0.85))
	_loft(st, path, widths, SKIN, 28)
	for row in 7:
		var i := 2 + row * 3
		var c := path[i]
		for side: float in [-1.0, 1.0]:
			var r := widths[i]
			var start := c + Vector3(side * r.x * 0.70, 1.3, r.y * 0.43)
			var barb := Vector3(side * (2.8 + float(row % 3) * 0.48), 3.4, -1.25)
			_loft(st, [start, start + barb * 0.33, start + barb * 0.76, start + barb], [Vector2(2, 1.72), Vector2(1.9, 1.25), Vector2(0.87, 0.71), Vector2(0.04, 0.04)], SCUTE, 12)
	_mantle(st, path, widths, upper)
	# Pale parallel tendons emerge from beneath the ridges as the wrist turns.
	for sinew in 3:
		var cord := PackedVector3Array()
		var gauges := PackedVector2Array()
		for i in path.size():
			var a := -0.53 + sinew * 0.49 + 0.20 * sin(i * 0.30 + sinew * 0.74) + 0.08 * sin(i * 0.57 + sinew)
			cord.append(path[i] + Vector3(sin(a) * widths[i].x, 0, cos(a) * widths[i].y) * 0.992)
			var w := 0.13 + 0.20 * sin(PI * i / (path.size() - 1)) + 0.08 * cos(i * 0.43 + sinew)
			gauges.append(Vector2(w, w * 0.66))
		_loft(st, cord, gauges, FLESH, 8)

# A patagium stretches from the knuckled elbow towards a shoulder lost in the
# canopy. Bony rays tension the skin; the scalloped bays sag between them.
static func _mantle(st: SurfaceTool, spine: PackedVector3Array, widths: PackedVector2Array, upper: bool) -> void:
	var sign_x := -1.0 if upper else 1.0
	var panels := 6
	var rows := panels * 6
	var cols := 8
	var points := PackedVector3Array()
	var coordinates := PackedVector2Array()
	for i in rows + 1:
		var t := float(i) / rows
		var station := t * (spine.size() - 1)
		var j := mini(floori(station), spine.size() - 2)
		var c := spine[j].lerp(spine[j + 1], station - j)
		var rad := widths[j].lerp(widths[j + 1], station - j)
		var bay := sin(PI * float(i % 6) / 6.0)
		var reach := lerpf(32.0, 48.0, t) if upper else 31.5 * pow(1.0 - t, 0.78) + 0.3
		var length := reach * (1.0 - 0.21 * bay) * (0.94 + 0.06 * cos(3 * PI * t))
		var base := c + Vector3(sign_x * rad.x * 0.69, 0.0, -rad.y * 0.21)
		for col in cols + 1:
			var s := float(col) / cols
			var tension := sin(s * PI) * bay
			points.append(base + Vector3(sign_x * length * s, -1.85 * sin(t * PI) * s, -reach * s * (0.38 + 0.24 * s) + reach * 0.15 * tension))
			coordinates.append(Vector2(t, s))
		if i % 6 == 0:
			var root := points[points.size() - cols - 1]
			var mid := points[points.size() - 5]
			var tip := points[points.size() - 1]
			_loft(st, [root + Vector3(0, 0, -0.40), mid, tip, tip + Vector3(sign_x * 0.55, 0.22, -0.33)], [Vector2(0.72, 0.84), Vector2(0.40, 0.53), Vector2(0.14, 0.21), Vector2(0.03, 0.03)], SCUTE, 10)
	var stride := cols + 1
	# The underside is visible from the cockpit; give it its own lighting normal.
	for face: int in [1, -1]:
		var first: int = st.get_meta("vertex_count", 0)
		st.set_meta("vertex_count", first + points.size())
		for i in rows + 1:
			for j in cols + 1:
				var idx := i * stride + j
				var across := points[i * stride + mini(j + 1, cols)] - points[i * stride + maxi(j - 1, 0)]
				var along := points[mini(i + 1, rows) * stride + j] - points[maxi(i - 1, 0) * stride + j]
				st.set_normal(along.cross(across).normalized() * face)
				st.set_uv(coordinates[idx])
				st.set_color(Color(0.88, 0, 0, 1))
				st.add_vertex(points[idx])
				if i < rows and j < cols:
					var a := first + idx
					var tri := [a, a + 1, a + stride, a + 1, a + stride + 1, a + stride]
					if face < 0:
						tri.reverse()
					for k in tri:
						st.add_index(k)

static func _palm(st: SurfaceTool) -> void:
	_loft(st, [Vector3(0, 4, 0), Vector3(0, 3, 0), Vector3(0, 1.5, 0), Vector3.ZERO, Vector3(0, -1.1, 0), Vector3(0, -1.8, 0)], [Vector2(1.6, 1.4), Vector2(4.0, 3.6), Vector2(5.4, 4.8), Vector2(5.7, 5.0), Vector2(4.3, 4.0), Vector2(0.1, 0.1)], SKIN, 32)
	for i in 12:
		var angle := TAU * i / 12
		var radial := Vector3(cos(angle), 0, sin(angle))
		var p := radial * 3.3 + Vector3.UP * 1.5
		_loft(st, [p, p + radial * 0.9 + Vector3.UP * 0.65, p + radial * 1.5 + Vector3.UP * 1.7], [Vector2(1.1, 0.82), Vector2(0.91, 0.74), Vector2(0.06, 0.06)], SCUTE, 12)

static func _digit(st: SurfaceTool, kind: String) -> void:
	if kind == "unguis":
		# Continuous recurved horn ending well inside the opposed thumb.
		_loft(st, [Vector3(0, 0.5, -0.1), Vector3.ZERO, Vector3(0, -0.65, -0.14), Vector3(0, -1.38, -0.45), Vector3(0, -1.93, -1.05), Vector3(0, -2.25, -1.84), Vector3(0, -2.25, -2.47)], [Vector2(0.68, 0.77), Vector2(0.88, 0.91), Vector2(0.78, 0.84), Vector2(0.64, 0.72), Vector2(0.45, 0.5), Vector2(0.23, 0.24), Vector2(0.017, 0.017)], HORN, 18)
		return
	var length := 4.9 if kind == "root" else 3.7
	var width := 1.53 if kind == "root" else 1.05
	_loft(st, [Vector3(0, 0.85, 0), Vector3(0, 0.33, 0.05), Vector3.ZERO, Vector3(0, -length * 0.29, 0.16), Vector3(0, -length * 0.59, 0.19), Vector3(0, -length * 0.85, 0.08), Vector3(0, -length, 0), Vector3(0, -length - 0.45, 0)], [Vector2(0.62, 0.66) * width, Vector2(0.98, 1.01) * width, Vector2(1.12, 1.08) * width, Vector2(0.94, 0.9) * width, Vector2(0.73, 0.71) * width, Vector2(0.79, 0.76) * width, Vector2(0.84, 0.83) * width, Vector2(0.32, 0.32) * width], SKIN, 18)
	for i in 3:
		var p := Vector3(0, -length * (0.14 + 0.22 * i), width * (0.72 - 0.08 * i))
		_loft(st, [p, p + Vector3(0, 0.20, 0.26), p + Vector3(0, 0.57, 0.54), p + Vector3(0, 0.82, 0.65)], [Vector2(0.7, 0.72) * width, Vector2(0.67, 0.63) * width, Vector2(0.36, 0.4) * width, Vector2(0.04, 0.04)], SCUTE, 12)
