extends SceneTree
## Rebuild the compressed, groomed meshes with Godot --headless --path current_dev
## --script <absolute path to this file>. Each body part has one draw surface.
# Radii, guard hair length, number of locks and cold-silver undercoat.
const PELTS := {
	"haunch":[Vector3(3.12, 2.30, 2.86), 0.76, 680, true],
	"mane":[Vector3(3.45, 2.54, 2.32), 1.05, 840, false],
	"skull":[Vector3(1.70, 1.63, 1.71), 0.57, 430, false],
	"ruff":[Vector3(0.64, 1.26, 1.05), 0.73, 180, true],
	"upper":[Vector3(1.12, 1.72, 1.24), 0.77, 350, false],
	"lower":[Vector3(0.96, 2.15, 1.11), 0.87, 410, true],
	"thigh":[Vector3(1.22, 1.60, 1.50), 0.78, 295, true],
	"calf":[Vector3(0.84, 1.00, 0.92), 0.55, 180, true],
	"paw":[Vector3(0.90, 0.58, 1.03), 0.35, 155, true],
	"ear":[Vector3(0.48, 0.55, 0.33), 0.25, 105, false],
}

func _initialize() -> void:
	var library := MeshLibrary.new()
	for key: String in PELTS:
		var recipe: Array = PELTS[key]
		var item := library.get_last_unused_item_id()
		library.create_item(item)
		library.set_item_name(item, key)
		library.set_item_mesh(item, coat(key, recipe[0], recipe[1], recipe[2], recipe[3]))
	var result := ResourceSaver.save(library, "res://assets/ground/glacier_mauler.res", ResourceSaver.FLAG_COMPRESS)
	print("MAULER_PELTS=", library.get_item_list().size(), " SAVE_RESULT=", result)
	quit(int(result != OK))

static func _vertex(st: SurfaceTool, at: Vector3, normal: Vector3, uv: Vector2, color: Color) -> void:
	st.set_normal(normal)
	st.set_uv(uv)
	st.set_color(color)
	st.add_vertex(at)

static func _shell_vertex(st: SurfaceTool, n: Vector3, radii: Vector3, color: Color) -> void:
	_vertex(st, n * radii, (n / radii).normalized(), Vector2(0.1, 0), color)

static func _direction(theta: float, phi: float) -> Vector3:
	return Vector3(cos(phi) * sin(theta), cos(theta), sin(phi) * sin(theta))

static func coat(key: String, radii: Vector3, length: float, count: int, silver: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Color("#818b90") if silver else Color("#9f9d92")
	for row in range(12):
		for col in range(20):
			var a := _direction(row * PI / 12.0, col * TAU / 20.0)
			var b := _direction((row + 1) * PI / 12.0, col * TAU / 20.0)
			var c := _direction((row + 1) * PI / 12.0, (col + 1) * TAU / 20.0)
			var d := _direction(row * PI / 12.0, (col + 1) * TAU / 20.0)
			for n: Vector3 in [a, c, b, a, d, c]:
				_shell_vertex(st, n, radii, base.darkened(0.20))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	const GOLDEN := 2.399963
	for i in range(count):
		# Evenly distribute locks over the ellipsoid. A dense inner fleece and
		# longer uneven guard hairs break the silhouette at different depths.
		var y := 1.0 - 2.0 * (i + 0.5) / count
		var phi := i * GOLDEN + rng.randf_range(-0.035, 0.035)
		var ring := sqrt(maxf(0.0, 1 - y * y))
		var unit := Vector3(cos(phi) * ring, y, sin(phi) * ring)
		var n := (unit / radii).normalized()
		var root := unit * radii
		var comb := Vector3(0.14 * sin(root.z * 1.9), -1, -0.40)
		var along := (comb - n * n.dot(comb)).normalized()
		if along.length_squared() < 0.01:
			along = Vector3.FORWARD
		var across := n.cross(along).normalized()
		var outward := (n * 0.60 + along * 0.80).normalized()
		var l := length * rng.randf_range(0.53, 1.40)
		var guard := i % 4 == 0
		var w := l * rng.randf_range(0.045, 0.09) if guard else l * rng.randf_range(0.14, 0.23)
		if guard:
			l *= 1.38
		var root_outer := root + n * 0.05
		var mid := root_outer + outward * l * 0.51 + across * rng.randf_range(-0.065, 0.065)
		var tip := mid + (outward * 0.40 + along * 0.64 + Vector3.DOWN * 0.10) * l * 0.58
		var pale := 0.46 + rng.randf_range(-0.22, 0.25) + 0.15 * n.y
		var tint := base.lerp(Color("#f2eadb") if not silver else Color("#e9eeee"), pale)
		if guard:
			tint = tint.lightened(0.08)
		var pts := PackedVector3Array([root_outer - across * w, root_outer + across * w,
			mid - across * w * 0.57, mid + across * w * 0.57, mid + n * w * 0.46, tip])
		var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 0.54), Vector2(1, 0.54), Vector2(0.5, 0.59), Vector2(0.46, 1)])
		for idx: int in [0, 2, 4, 0, 4, 1, 1, 4, 3, 2, 5, 4, 4, 5, 3]:
			var normal := (n + across * ((uvs[idx].x - 0.5) * 0.32)).normalized()
			_vertex(st, pts[idx], normal, uvs[idx], tint)
	return st.commit()
