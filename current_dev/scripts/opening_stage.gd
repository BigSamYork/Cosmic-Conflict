extends Node3D

const LOCATIONS := {
	"aegis": "USV Aegis-4  ·  Low Orbit, Thalassa",
	"blockade": "Astra Relay  ·  Orbital Blockade",
	"ignis": "Ignis Prime  ·  Orbital Shipyards",
	"cryo": "Cryo-Vex  ·  Sub-Surface Habitat",
	"vespera": "Vespera-9  ·  Transit Hub",
	"kharon": "Kharon  ·  Relay Station",
	"departure": "Astra Surface Base  ·  Hangar 04",
	"answer": "UESS Rook  ·  Ascent Vector",
}
const FEEDS := ["ignis", "cryo", "vespera", "kharon"]
const SKY_MIX := {"cryo": "icy_mix", "vespera": "city_mix", "kharon": "desert_mix"}
const IMPACT := preload("res://scripts/impact_spray.gd")
var camera := Camera3D.new()
var weather := SurfaceWeather.new()
var sky_ink := ShaderMaterial.new()
var set_pieces: Node3D
var subject: Node3D
var welding: MultiMeshInstance3D
var streaks: Array[Node3D] = []
var data_lights: Array[MeshInstance3D] = []
var hardlines: Array[Curve3D] = []
var shot := ""
var elapsed := 0.0
var from: Vector3
var to: Vector3
var focus: Vector3
var reduced := false
var miniature := false

func _ready() -> void:
	var environment := Environment.new()
	sky_ink.shader = preload("res://shaders/sky.gdshader")
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_ink
	environment.glow_enabled = not reduced and not miniature
	environment.glow_hdr_threshold = 1.12
	environment.fog_sky_affect = 0
	var surroundings := WorldEnvironment.new()
	surroundings.environment = environment
	add_child(surroundings)
	camera.fov = 46
	camera.far = 5000
	add_child(camera)
	camera.add_child(weather)
	camera.make_current()

func stage(id: String) -> void:
	shot = id
	elapsed = 0
	welding = null
	streaks.clear()
	data_lights.clear()
	hardlines.clear()
	if set_pieces != null:
		set_pieces.free()
	set_pieces = Node3D.new()
	add_child(set_pieces)
	var surface := id in ["cryo", "vespera", "kharon", "departure", "answer"]
	weather.configure(id, id == "kharon" and not miniature, reduced)
	var env := get_world_3d().environment
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = surface
	env.fog_density = 0.0028
	env.fog_light_color = Color("#263749").lerp(SectorCatalog.ACCENTS.get(id, Color("#5b9fb7")), 0.14)
	sky_ink.set_shader_parameter("atmosphere_mix", 0.76 if id == "answer" else 0.92 if surface else 0.0)
	sky_ink.set_shader_parameter("planet_visibility", 0.0)
	for sector: String in SKY_MIX:
		sky_ink.set_shader_parameter(SKY_MIX[sector], 1.0 if sector == id else 0.0)
	match id:
		"aegis":
			_planet("thalassa", Vector3(72, -318, -500), 375)
			subject = _model("traffic", "fleet", Vector3.ZERO, 32, -0.8)
			_park(subject)
			_fit_colony_transport()
			from = Vector3(-14, 8, 44)
			to = Vector3(3, 4, 29)
			focus = Vector3(4, 0, -2)
		"blockade":
			_planet("thalassa", Vector3(-240, -260, -700), 260)
			subject = _model("cruiser", "fleet", Vector3(-9, 8, -36), 99, 1.15)
			for i in 3:
				_model("escort", "fleet", Vector3(23 - 21 * i, -5 + i * 2, 12 - 9 * i), 10, 1.15)
			var corridor := GeometryBatch.new()
			for i in 3:
				corridor.ring(Vector3(38, 10, -85 - i * 8), 18.0, Color("#54b9bc"), 64)
			for side in [-1.0, 1.0]:
				corridor.line(Vector3(-9 + side * 11, 6, -31), Vector3(38 + side * 3, 8, -91), Color("#a25249"))
			set_pieces.add_child(corridor.build())
			from = Vector3(-24, -7, 85)
			to = Vector3(14, -3, 67)
			focus = Vector3(2, 7, -40)
		"ignis": _drydock()
		"cryo": _greenhouse()
		"vespera": _concourse()
		"kharon": _hardline_station()
		"departure", "answer": _hangar(id == "answer")
	advance(0)

func _model(id: String, folder: String, at: Vector3, span: float, yaw: float = 0) -> Node3D:
	var model := FrontierArt.player_ship(id) if folder == "fleet" and CampaignState.SHIPS.has(id) else FleetArt.model(id, folder)
	var size := FleetArt.mesh_for(id, folder).get_aabb().size
	model.scale = Vector3.ONE * span / size[size.max_axis_index()]
	model.rotation.y = yaw
	model.position = at
	set_pieces.add_child(model)
	return model

func _park(ship: Node3D) -> void:
	ship.get_child(0).set_instance_shader_parameter("parked", true)

func _planet(sector: String, at: Vector3, span: float) -> void:
	if miniature:
		return
	var planet := LaunchApproach._planet_model(sector)
	planet.position = at
	planet.scale = Vector3.ONE * span
	planet.get_child(1).hide()
	set_pieces.add_child(planet)

func _fit_colony_transport() -> void:
	var fittings := GeometryBatch.new()
	var alloy := Color("#506571")
	var panel := Color("#24313a")
	for side in [-1.0, 1.0]:
		fittings.tube(Vector3(side * 5.7, -1.1, 0.6), 2.1, 21, alloy, 24)
		for station in 5:
			fittings.tube(Vector3(side * 5.7, -1.1, -8.4 + station * 4.5), 2.16, 0.22, Color("#788086"), 24)
		# Two banks of cold radiator fins remain cantilevered off the cargo spine.
		for bank in 2:
			var z := -5.0 + bank * 7.2
			fittings.truss(Vector3(side * 4.5, 0, z), Vector3(side * 12, 0, z), 0.65, alloy, 5)
			fittings.box(Vector3(side * 10.3, 0.35, z), Vector3(4.8, 0.17, 5.9), panel, panel.darkened(0.25))
			for fin in 10:
				fittings.box(Vector3(side * 10.3, 0.48, z - 2.6 + fin * 0.58), Vector3(4.6, 0.18, 0.14), Color("#394754"), panel)
	var assembly := fittings.build()
	assembly.scale = Vector3.ONE / subject.scale.x
	subject.add_child(assembly)

func _drydock() -> void:
	_planet("ignis", Vector3(-115, -325, -590), 360)
	subject = _model("traffic", "fleet", Vector3(0, 4, -6), 24, -0.28)
	_park(subject)
	for i in 3:
		_model("cargo_gantry", "ground", Vector3(-9 + i * 0.4, -5, 4 - i * 9), 15, PI * 0.5)
	_model("ignis_kiln_battery", "ground", Vector3(12, -10, -15), 23)
	welding = IMPACT.new()
	set_pieces.add_child(welding)
	welding.build(Vector3(-5, 3.8, 1), Vector3(0.5, 0.6, 0.6), IMPACT.Surface.HULL, 0.76, reduced or miniature)
	for i in 3:
		var trail := GeometryBatch.new()
		trail.limb(Vector3.ZERO, Vector3(-5, 2.2, -1.3), 0.22, 0.015, Color("#ff8945"))
		trail.ellipsoid(Vector3.ZERO, Vector3(0.28, 0.13, 0.18), Color("#ffead2"), 5, 8)
		var debris := trail.build()
		set_pieces.add_child(debris)
		streaks.append(debris)
	from = Vector3(18, 9, 36)
	to = Vector3(-7, 7, 28)
	focus = Vector3(0, 2, -4)

func _greenhouse() -> void:
	subject = _model("cryo_greenhouse", "ground", Vector3(0, -2, -17), 33)
	var infrared := ShaderMaterial.new()
	infrared.shader = preload("res://shaders/opening_thermal.gdshader")
	subject.get_child(0).material_override = infrared
	var environment := get_world_3d().environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101024")
	var ward := GeometryBatch.new()
	ward.box(Vector3(0, -0.38, 0), Vector3(26, 0.6, 22), Color("#397389"), Color("#152942"))
	for i in 4:
		var bed := Vector3(-6.0 + i * 3.8, 0, -2 + (i % 2) * 2)
		ward.box(bed + Vector3.UP * 0.8, Vector3(2, 1.25, 1), Color("#efac64"), Color("#675271"))
		ward.ellipsoid(bed + Vector3.UP * 1.4, Vector3(0.67, 0.32, 0.35), Color("#ffc868"))
		_crew(ward, bed + Vector3(-0.95, 0, 0.7), Color("#ffac5e"), i * 0.12)
	var image := ward.build()
	var warm := infrared.duplicate() as ShaderMaterial
	warm.set_shader_parameter("read_heat", true)
	image.get_child(0).material_override = warm
	image.get_child(1).hide()
	set_pieces.add_child(image)
	from = Vector3(-10, 4, 22)
	to = Vector3(5, 2.8, 14)
	focus = Vector3(0, 1.7, -2)

func _crew(batch: GeometryBatch, at: Vector3, tint: Color, lean: float) -> void:
	var chest := at + Vector3(lean, 1.22, -0.1)
	batch.ellipsoid(chest, Vector3(0.33, 0.46, 0.22), tint, 6)
	batch.ellipsoid(chest + Vector3(0, 0.53, -0.03), Vector3.ONE * 0.23, tint.lightened(0.25), 6)
	for side in [-1.0, 1.0]:
		batch.limb(chest + Vector3(side * 0.25, 0.15, 0), chest + Vector3(side * 0.38, -0.25, -0.33), 0.11, 0.075, tint)
		batch.limb(at + Vector3(side * 0.16, 1, 0), at + Vector3(side * 0.22, 0.08, 0.04), 0.14, 0.09, tint)

func _concourse() -> void:
	subject = _model("vespera_arcade", "ground", Vector3(0, -3.5, -28), 40, -0.12)
	_model("vespera_sky_exchange", "ground", Vector3(-29, -3.5, -52), 40)
	var queue := GeometryBatch.new()
	queue.box(Vector3(0, -0.55, -5), Vector3(42, 1, 64), Color("#364459"), Color("#121b2c"))
	set_pieces.add_child(queue.build())
	# The serpentine queue is one draw call, including every colored light stick.
	var stick := CapsuleMesh.new()
	stick.radius = 0.044
	stick.height = 0.38
	stick.radial_segments = 6
	stick.rings = 1
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.vertex_color_use_as_albedo = true
	stick.material = surface
	var glow := MultiMesh.new()
	glow.transform_format = MultiMesh.TRANSFORM_3D
	glow.use_colors = true
	glow.mesh = stick
	glow.instance_count = 2160
	var person := GeometryBatch.new()
	var coat := Color("#505c6b")
	person.limb(Vector3(0, 0.06, 0), Vector3(0, 1.18, 0), 0.22, 0.28, coat, 7)
	person.ellipsoid(Vector3(0, 1.45, 0), Vector3(0.17, 0.21, 0.17), Color("#869099"), 4, 6)
	var figure := VectorArt.solid(person.vertices, person.indices, Color.WHITE, person.face_colors)
	var bodies := MultiMesh.new()
	bodies.transform_format = MultiMesh.TRANSFORM_3D
	bodies.mesh = figure.mesh
	bodies.mesh.surface_set_material(0, figure.material_override)
	figure.free()
	bodies.instance_count = glow.instance_count
	var rng := RandomNumberGenerator.new()
	rng.seed = 9214
	var colors := [Color("#e4b855"), Color("#62d6bb"), Color("#e78dbc"), Color("#69b5ff")]
	for i in glow.instance_count:
		var row := i / 60
		var at := Vector3((i % 60 - 29.5) * 0.60 + rng.randf_range(-0.10, 0.10), 0, 13.0 - row * 0.96 + sin(i % 60 * 0.13) * 0.4)
		var height := rng.randf_range(0.65, 0.87)
		bodies.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.8, 0.8)).scaled(Vector3.ONE * height), at))
		glow.set_instance_transform(i, Transform3D(Basis(Vector3.FORWARD, rng.randf_range(-0.8, 0.8)), at + Vector3(0.26, height * 1.35, -0.18)))
		glow.set_instance_color(i, colors[rng.randi_range(0, colors.size() - 1)])
	var crowd := MultiMeshInstance3D.new()
	crowd.multimesh = glow
	set_pieces.add_child(crowd)
	var silhouettes := MultiMeshInstance3D.new()
	silhouettes.multimesh = bodies
	set_pieces.add_child(silhouettes)
	from = Vector3(-14, 10, 27)
	to = Vector3(3, 5.2, 19)
	focus = Vector3(0, 2.2, -4)

func _hardline_station() -> void:
	subject = _model("kharon_caravanserai", "ground", Vector3(-12, -2, -22), 28)
	_model("fleet_dish", "ground", Vector3(-15, -1, -12), 11)
	var deck := GeometryBatch.new()
	deck.box(Vector3(0, -0.55, -2), Vector3(45, 1, 36), Color("#575341"), Color("#353038"))
	var terminal := Vector3(-4, 0, 4)
	_crew(deck, terminal + Vector3(0.15, 0, 0.85), Color("#dbbf90"), 0.18)
	deck.box(terminal + Vector3(0, 0.75, 0), Vector3(1.6, 1.4, 0.8), Color("#669799"))
	for i in 3:
		var ship := Vector3(0.5 + 5.6 * i, 1.4, -3.0 - 2.9 * i)
		_park(_model("traffic", "fleet", ship, 8.2, -0.5))
		var path := Curve3D.new()
		path.add_point(terminal + Vector3(0, 1.3, 0))
		path.add_point(terminal + Vector3(1 + i * 0.5, 0.12, -0.8))
		path.add_point(ship + Vector3(0.5, -1.22, 3))
		path.add_point(ship + Vector3(0.25, 0.1, 1))
		for j in range(path.point_count - 1):
			deck.limb(path.get_point_position(j), path.get_point_position(j + 1), 0.075, 0.075, Color("#65c4c1"))
		hardlines.append(path)
		var pulse := MeshInstance3D.new()
		var lamp := SphereMesh.new()
		lamp.radius = 0.14
		lamp.height = 0.28
		var phosphor := StandardMaterial3D.new()
		phosphor.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		phosphor.albedo_color = Color("#affff0")
		lamp.material = phosphor
		pulse.mesh = lamp
		set_pieces.add_child(pulse)
		data_lights.append(pulse)
	set_pieces.add_child(deck.build())
	from = Vector3(-11, 7, 20)
	to = Vector3(-4, 3.3, 13)
	focus = Vector3(1, 1.1, 0)

func _hangar(launch: bool) -> void:
	_model("astra_terminal", "ground", Vector3(-26, -5, -53), 76, -0.55)
	_model("cargo_gantry", "ground", Vector3(-11, -4, -9), 22, -0.2)
	var rails := GeometryBatch.new()
	rails.box(Vector3(0, -3.9, -13), Vector3(46, 0.9, 83), Color("#344754"), Color("#202e38"))
	for side in [-1.0, 1.0]:
		rails.box(Vector3(side * 2.6, -2.4, -9), Vector3(0.66, 0.65, 79), Color("#66aaa9"), Color("#313e49"))
		for i in 16:
			rails.box(Vector3(side * 3.1, -2.08, 25 - i * 4.8), Vector3(0.30, 0.1, 1.1), Color("#f0a35c"))
	set_pieces.add_child(rails.build())
	subject = _model("rook", "fleet", Vector3.ZERO, 16)
	if not launch:
		_park(subject)
		for side in [-1.0, 1.0]:
			_vent(Vector3(side * 2.3, 0, 6))
	from = Vector3(7.5, 1.6, 12) if not launch else Vector3(-11, 3, 18)
	to = Vector3(20, 5.5, 25) if not launch else Vector3(-6, 4, 18)
	focus = Vector3(1, 0, -1)

func mount_holo_table(feeds: Array[SubViewport]) -> void:
	# Begin on the same four images as the tactical display, then reveal the launch rails.
	var table := Node3D.new()
	table.position = Vector3(6, 0.6, 9)
	table.rotation = Vector3(-0.28, 0.46, 0)
	set_pieces.add_child(table)
	var frame := GeometryBatch.new()
	frame.box(Vector3.ZERO, Vector3(3.8, 2.1, 0.18), Color("#609eac"), Color("#122332"))
	frame.box(Vector3(0, -1.95, -0.1), Vector3(0.5, 2.1, 0.3), Color("#526674"))
	table.add_child(frame.build())
	for i in feeds.size():
		var panel := MeshInstance3D.new()
		var screen := QuadMesh.new()
		screen.size = Vector2(1.75, 0.94)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_texture = feeds[i].get_texture()
		screen.material = material
		panel.mesh = screen
		panel.position = Vector3((i % 2 - 0.5) * 1.8, (0.5 - floori(i / 2.0)) * 0.99, 0.1)
		table.add_child(panel)

func _vent(at: Vector3) -> void:
	var gas := CPUParticles3D.new()
	gas.amount = 10 if reduced else 25
	gas.lifetime = 1.6
	gas.preprocess = gas.lifetime
	gas.direction = Vector3(0.04, 0.4, 1)
	gas.spread = 19
	gas.gravity = Vector3(0, 0.58, 0)
	gas.initial_velocity_min = 2.6
	gas.initial_velocity_max = 4.3
	gas.scale_amount_min = 0.55
	gas.scale_amount_max = 1.5
	var mist := StandardMaterial3D.new()
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.6, 0.75, 0.8, 0.18), Color(0.38, 0.53, 0.6, 0)])
	var plume := GradientTexture2D.new()
	plume.fill = GradientTexture2D.FILL_RADIAL
	plume.fill_from = Vector2(0.5, 0.5)
	plume.fill_to = Vector2(1, 0.5)
	plume.gradient = gradient
	mist.albedo_texture = plume
	var sprite := QuadMesh.new()
	sprite.material = mist
	gas.mesh = sprite
	gas.position = at
	set_pieces.add_child(gas)

func advance(delta: float) -> void:
	elapsed += delta
	var t := 1.0 - exp(-elapsed * (0.065 if reduced else 0.12))
	camera.position = from.lerp(to, t)
	var aim := focus
	if shot == "aegis":
		subject.rotation.z = -0.13 + sin(elapsed * 0.18) * 0.045
		subject.position.y = -elapsed * 0.045
	elif shot == "departure":
		aim = Vector3(6, 0.6, 9).lerp(focus, smoothstep(0.0, 3.2, elapsed))
	elif shot == "answer":
		var climb := maxf(0, elapsed - 0.65)
		subject.position = Vector3(0, climb * 3.5, -minf(elapsed * elapsed * 10, elapsed * 16.0))
		subject.rotation.x = lerpf(0, 0.19, smoothstep(0.6, 1.8, elapsed))
		camera.position += subject.position * (0.90 if reduced else 0.86)
		aim += subject.position
	camera.look_at(aim)
	if welding != null:
		welding.age = fmod(elapsed, 0.95)
		welding.advance(0)
	for i in streaks.size():
		var travel := fmod(elapsed * (0.16 + i * 0.014) + 0.27 * i, 1.0)
		streaks[i].position = Vector3(-62.0 + 115.0 * travel, 34.0 - 41.0 * travel + i * 4, -61.0 - i * 6)
	for i in data_lights.size():
		var distance := hardlines[i].get_baked_length()
		data_lights[i].position = hardlines[i].sample_baked(fmod(elapsed * 4 + i * 2, distance))
	weather.advance(delta)
