class_name XyloArt
extends RefCounted

const LEAF := Color("#88bf45")
const ACID := Color("#d0df45")
const SHELL := Color("#83b86b")
const DARK := Color("#173220")
const SERPENT_TRAVEL := 824.0
const SERPENT_BANK := 15.0
static var sedge_mesh: ArrayMesh
static var sedge_material := ShaderMaterial.new()

static func warm_cache() -> void:
	for factory in [pylon, spitter_base, spitter_head, insect, insect_leg, goliath, goliath_leg, leviathan, hive_mother, rover, acid_plume, spore_plume, sensor]:
		var model: Node3D = factory.call()
		model.free()
	for kind in range(3):
		var egg: Node3D = egg_ship(kind)
		egg.free()
		egg = egg_ship(kind, true)
		egg.free()

static func pylon() -> Node3D:
	return GroundArt.tower("xylo")

static func spitter_base() -> Node3D:
	return FleetArt.model("mount_xylo", "ground")

static func spitter_head() -> Node3D:
	return FleetArt.model("spitter", "ground")

static func insect() -> Node3D:
	return FleetArt.model("insect")

static func insect_leg() -> Node3D:
	return FleetArt.model("hive_flight_leg")

static func goliath() -> Node3D:
	return FleetArt.model("bio_titan", "ground")

static func goliath_leg() -> Node3D:
	return FleetArt.model("titan_leg", "ground")

static func leviathan() -> Node3D:
	return FleetArt.model("leviathan")

static func leviathan_segment(index: int) -> Vector3:
	return Vector3(sin(index * 0.36) * 18, 10 + index * 7, -18 - index * 14)

static func hive_mother(distant: bool = false) -> Node3D:
	return FleetArt.model("hive_mother_far" if distant else "hive_mother")

static func egg_ship(variant: int = 0, distant: bool = false) -> Node3D:
	return FleetArt.model("egg_%d%s" % [clampi(variant, 0, 2), "_far" if distant else ""])

static func rover() -> Node3D:
	return SurfaceRig.model("field_rover")

static func acid_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_acid_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(14):
		var angle: float = i * 2.4
		var top := Vector3(cos(angle) * 2.6, 8 + i % 4 * 1.8, sin(angle) * 2.6)
		batch.limb(Vector3(cos(angle) * 1.5, 0, sin(angle) * 1.5), top, 0.15, 0.03, ACID, 5)
		batch.ellipsoid(top, Vector3(0.22, 0.45, 0.22), ACID, 4, 6)
	return VectorArt.remember_model("xylo_acid_plume", batch.build())

static func spore_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_spore_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(20):
		var angle: float = i * 2.4
		var at := Vector3(cos(angle) * 3.8, 2 + i % 5 * 2.5, sin(angle) * 3.8)
		batch.ellipsoid(at, Vector3(0.25, 0.25, 0.25), LEAF, 4, 6)
		batch.line(at + Vector3.LEFT * 0.8, at + Vector3.RIGHT * 0.8, LEAF.darkened(0.3))
	return VectorArt.remember_model("xylo_spore_plume", batch.build())

static func sensor() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_sensor")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for side in [-1.0, 1.0]:
		batch.limb(Vector3.ZERO, Vector3(side * 4, 2, 0), 0.45, 0.08, LEAF)
		batch.ellipsoid(Vector3(side * 4, 2, 0), Vector3(0.8, 0.8, 0.8), ACID, 6, 8)
	return VectorArt.remember_model("xylo_sensor", batch.build())

static func spore_bolt() -> Node3D:
	return FleetArt.model("living_spore_round")

static func floor_point(x: float, travel: float) -> Vector3:
	return Vector3(FlightState.rail_point(travel).x + x, -1, -travel)

static func terrain_chunk(start: float, branching: bool = false) -> Node3D:
	branching = branching and start + VectorArt.CHUNK_LENGTH > GroundRoute.FORK and start < GroundRoute.REJOIN
	var key: String = ("xylo_branch:%d" if branching else "xylo_terrain:%d") % int(start)
	var cached: Node3D = VectorArt.cached_model(key)
	if cached != null:
		return cached
	var terrain := GeometryBatch.new()
	var turf := GeometryBatch.new()
	var scenery: Array[Transform3D] = []
	for row in range(8):
		var travel: float = start + row * 16
		for column in range(32):
			var x: float = (column - 16) * 10.0
			var a: Vector3 = floor_point(x, travel)
			var b: Vector3 = floor_point(x + 10, travel)
			var c: Vector3 = floor_point(x + 10, travel + 16)
			var d: Vector3 = floor_point(x, travel + 16)
			var corners := PackedVector3Array([a, b, c, d])
			if travel + 8.0 == SERPENT_TRAVEL and x + 5.0 == SERPENT_BANK:
				_burrow_cell(terrain, turf, corners)
			else:
				terrain.surface(corners, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE)
	for i in range(6):
		var travel: float = start + 12 + i * 19
		var side: float = -1 if i % 2 == 0 else 1
		var x: float = side * (35 + (i % 3) * 22)
		if not branching or absf(x - GroundRoute.lateral_offset(travel)) > 38:
			var height := 50 + posmod(int(start / 128) * 7 + i * 13, 35)
			scenery.append(GroundArt.placement(floor_point(x, travel), Vector3(1, height / 48.0, 1), travel * 0.17))
	var chunk := GroundArt.finish_chunk(Node3D.new(), terrain, scenery, "xylo", start, branching)
	if not turf.vertices.is_empty():
		var normals := PackedVector3Array()
		normals.resize(turf.vertices.size())
		normals.fill(Vector3.UP)
		var cap := VectorArt.solid(turf.vertices, turf.indices, Color.WHITE, turf.face_colors, normals)
		cap.name = "UnbrokenTurf"
		cap.material_override = GroundArt.materials["xylo"]
		chunk.add_child(cap)
	_add_sedge_banks(chunk, start, branching)
	return VectorArt.remember_model(key, chunk) if start < VectorArt.TERRAIN_CACHE_CHUNKS * VectorArt.CHUNK_LENGTH else chunk

static func _burrow_cell(terrain: GeometryBatch, cap: GeometryBatch, corners: PackedVector3Array) -> void:
	var center := floor_point(SERPENT_BANK, SERPENT_TRAVEL)
	var outer := PackedVector3Array()
	var inner := PackedVector3Array()
	for edge in 4:
		for step in 8:
			var p := corners[edge].lerp(corners[(edge + 1) % 4], step / 8.0)
			var dir := center.direction_to(p)
			var angle := atan2(dir.z, dir.x)
			outer.append(p)
			inner.append(center + dir * (4.45 + 0.24 * sin(angle * 3.0) + 0.15 * cos(angle * 7.0)))
	for i in outer.size():
		var j := (i + 1) % outer.size()
		terrain.surface(PackedVector3Array([outer[i], outer[j], inner[j], inner[i]]), PackedInt32Array([0,1,2,0,2,3]), Color.WHITE)
		cap.surface(PackedVector3Array([center, inner[i], inner[j]]), PackedInt32Array([0,1,2]), Color.WHITE)

static func _add_sedge_banks(chunk: Node3D, start: float, branching: bool) -> void:
	if sedge_mesh == null:
		sedge_mesh = _make_sedge()
		sedge_material.shader = preload("res://shaders/xylo_sedge.gdshader")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(int(start), 3749))
	var tufts: Array[Transform3D] = []
	var wind_data := PackedColorArray()
	for side in [-1.0, 1.0]:
		for _bed in range(14):
			var center := start + rng.randf_range(0, VectorArt.CHUNK_LENGTH)
			var bank_x: float = side * (12.0 + 4.5 * sin(center * 0.044 + side) + rng.randf_range(0.0, 27.0))
			var bed_size := rng.randf_range(0.7, 1.42)
			for _tuft in range(rng.randi_range(4, 10)):
				var travel := center + rng.randfn(0.0, 4.5)
				var x := bank_x + rng.randfn(0.0, 2.3)
				if travel < start or travel >= start + VectorArt.CHUNK_LENGTH or absf(x) < 6.1:
					continue
				if branching and absf(x - GroundRoute.lateral_offset(travel)) < 6.1:
					continue
				var base := floor_point(x, travel)
				var angle := rng.randf_range(-PI, PI)
				var size := bed_size * rng.randf_range(0.68, 1.26)
				var stature := rng.randf_range(0.55, 1.26)
				tufts.append(GroundArt.placement(base, Vector3(size, size * stature, size), angle))
				wind_data.append(Color(base.x, base.z, cos(angle), sin(angle)))
	var grass := MultiMesh.new()
	grass.transform_format = MultiMesh.TRANSFORM_3D
	grass.use_custom_data = true
	grass.mesh = sedge_mesh
	grass.instance_count = tufts.size()
	grass.set_meta("decorative_ground_cover", true)
	for i in tufts.size():
		grass.set_instance_transform(i, tufts[i])
		grass.set_instance_custom_data(i, wind_data[i])
	var bank := MultiMeshInstance3D.new()
	bank.multimesh = grass
	bank.material_override = sedge_material
	bank.extra_cull_margin = 2.0
	# Past the last visible tuft, cull the entire 128 m batch on the CPU.
	bank.visibility_range_end = 265.0
	bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chunk.add_child(bank)

static func _make_sedge() -> ArrayMesh:
	# Folded, opaque leaves share one mesh and avoid alpha-sorted grass cards.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8953
	const FOOT := Color("#263728")
	const STEM := Color("#425d3f")
	const LEAF_DARK := Color("#406747")
	const LEAF_LIGHT := Color("#86a45c")
	const TIP := Color("#b5b56d")
	const REEDS := 7
	for blade in range(REEDS):
		var angle := blade * 2.39996 + rng.randf_range(-0.24, 0.24)
		var radial := Vector3(cos(angle), 0, sin(angle))
		var narrow := Vector3(-radial.z, 0, radial.x) * rng.randf_range(0.065, 0.145)
		var height := rng.randf_range(0.88, 2.25)
		var reach := rng.randf_range(0.55, 1.26)
		var foot := radial * rng.randf_range(0.08, 0.35)
		var belly := foot + Vector3.UP * height * 0.66 + radial * reach * 0.28
		var tip := foot + Vector3.UP * height + radial * reach
		var tint := LEAF_DARK.lerp(LEAF_LIGHT, rng.randf())
		var base := blade * 7
		_sedge_vertex(surface, foot - narrow * 0.4, FOOT, 0.0)
		_sedge_vertex(surface, foot + radial * 0.02, STEM, 0.0)
		_sedge_vertex(surface, foot + narrow * 0.4, FOOT, 0.0)
		_sedge_vertex(surface, belly - narrow, tint.darkened(0.19), 0.61)
		_sedge_vertex(surface, belly + radial * 0.065, tint.lightened(0.10), 0.61)
		_sedge_vertex(surface, belly + narrow, tint, 0.61)
		_sedge_vertex(surface, tip, tint.lerp(TIP, 0.58), 1.0)
		for index in [0, 3, 4, 0, 4, 1, 1, 4, 5, 1, 5, 2, 3, 6, 4, 4, 6, 5]:
			surface.add_index(base + index)
	# Shorter swords grow on creeping rhizomes around the taller reed. Their
	# wider footprint lets neighbouring plants merge into uneven stands.
	for blade in range(18):
		var angle := blade * 2.39996 + rng.randf_range(-0.42, 0.42)
		var radial := Vector3(cos(angle), 0, sin(angle))
		var spread := rng.randf_range(0.28, 2.95)
		var foot := radial * spread * Vector3(1.4, 1.0, 0.82)
		var height := rng.randf_range(0.58, 1.28) * (1.13 - spread * 0.14)
		var reach := radial * rng.randf_range(0.27, 0.76) + Vector3(0.25, 0.0, 0.1)
		var width := Vector3(-radial.z, 0, radial.x) * rng.randf_range(0.06, 0.115)
		var belly := foot + Vector3.UP * height * 0.53 + reach * 0.31
		var tip := foot + Vector3.UP * height + reach
		var tint := LEAF_DARK.lerp(LEAF_LIGHT, rng.randf_range(0.0, 0.72))
		var base := REEDS * 7 + blade * 4
		_sedge_vertex(surface, foot, FOOT, 0.0)
		_sedge_vertex(surface, belly - width, tint.darkened(0.10), 0.55)
		_sedge_vertex(surface, belly + width, tint, 0.55)
		_sedge_vertex(surface, tip, tint.lerp(TIP, 0.30), 1.0)
		for index in [0, 1, 2, 1, 3, 2]:
			surface.add_index(base + index)
	return surface.commit()

static func _sedge_vertex(surface: SurfaceTool, point: Vector3, pigment: Color, flex: float) -> void:
	surface.set_color(pigment)
	surface.set_uv(Vector2(0.0, flex))
	surface.set_normal(Vector3.UP)
	surface.add_vertex(point)

static func horizon() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("xylo_horizon")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	batch.surface(PackedVector3Array([Vector3(-20000, -12, -20000), Vector3(20000, -12, -20000), Vector3(20000, -12, 20000), Vector3(-20000, -12, 20000)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#10281e"))
	var model := batch.build()
	for stretch in range(8):
		var crowns: Array[Transform3D] = []
		for j in range(5):
			var i := stretch * 5 + j
			var side := -1.0 if i % 2 == 0 else 1.0
			var at := Vector3(side * (220 + i % 3 * 70), -12, -i * 160)
			crowns.append(GroundArt.placement(at, Vector3(3.7, 3.4 + 0.42 * (i % 4), 3.7), i * 0.7))
		GroundArt.add_landmarks(model, "vista_xylo" if stretch % 3 else "landmark_xylo", crowns)
	return VectorArt.remember_model("xylo_horizon", model)
