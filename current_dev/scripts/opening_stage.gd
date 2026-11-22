extends Node3D

# The camera crosses the same terrain, weather, and Blender meshes used in flight.
const LOCATIONS := {
	"lantern": "Ferry Lantern  /  emergency band",
	"blockade": "Astra approach  /  civilian channel",
	"departure": "Astra Terminal  /  launch berth",
	"answer": "Rook scout  /  outbound",
}
const LANDMARKS := {
	"ignis": "kiln_battery", "cryo": "greenhouse", "vespera": "lantern_hotel",
	"xylo": "canopy_clinic", "thalassa": "lighthouse", "kharon": "cistern"
}
const SKY_MIX := {"cryo": "icy_mix", "vespera": "city_mix", "xylo": "swamp_mix", "thalassa": "ocean_mix", "kharon": "desert_mix"}
var camera := Camera3D.new()
var weather := SurfaceWeather.new()
var sky_ink := ShaderMaterial.new()
var set_pieces: Node3D
var subject: Node3D
var volcano: VolcanoEruption
var beacon: Node3D
var water: Array[ShaderMaterial] = []
var shot := ""
var elapsed := 0.0
var from: Vector3
var to: Vector3
var focus: Vector3
var reduced := false

func _ready() -> void:
	var environment := Environment.new()
	sky_ink.shader = preload("res://shaders/sky.gdshader")
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = sky_ink
	environment.glow_enabled = not reduced
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
	water.clear()
	volcano = null
	beacon = null
	if set_pieces != null:
		set_pieces.free()
	set_pieces = Node3D.new()
	add_child(set_pieces)
	var surface := LANDMARKS.has(id)
	weather.configure(id if surface else "ignis", surface, reduced)
	var env := get_world_3d().environment
	env.fog_enabled = surface
	env.fog_density = 0.0028
	env.fog_light_color = Color("#384450").lerp(SectorCatalog.ACCENTS.get(id, Color.WHITE), 0.16)
	sky_ink.set_shader_parameter("atmosphere_mix", 0.92 if surface else 0.0)
	sky_ink.set_shader_parameter("planet_visibility", 1.0 if surface else 0.0)
	for sector: String in SKY_MIX:
		sky_ink.set_shader_parameter(SKY_MIX[sector], 1.0 if sector == id else 0.0)
	if surface:
		_surface(id)
	else:
		_orbit(id)
	advance(0)

func _model(id: String, folder: String, at: Vector3, span: float, yaw: float = 0) -> Node3D:
	var model := FrontierArt.player_ship(id) if folder == "fleet" and CampaignState.SHIPS.has(id) else FleetArt.model(id, folder)
	var size := FleetArt.mesh_for(id, folder).get_aabb().size
	model.scale = Vector3.ONE * span / size[size.max_axis_index()]
	model.rotation.y = yaw
	model.position = at
	set_pieces.add_child(model)
	return model

func _orbit(id: String) -> void:
	var planet := LaunchApproach._planet_model("thalassa")
	planet.position = Vector3(165, -225, -525)
	planet.scale = Vector3.ONE * 265
	if id == "lantern":
		planet.position = Vector3(72, -318, -500)
		planet.scale = Vector3.ONE * 375
	elif id == "answer":
		planet.position = Vector3(-140, -195, -640)
		planet.scale = Vector3.ONE * 220
	planet.get_child(1).hide()
	set_pieces.add_child(planet)
	match id:
		"lantern":
			subject = _model("traffic", "fleet", Vector3.ZERO, 32, -0.8)
			subject.get_child(0).set_instance_shader_parameter("parked", true)
			from = Vector3(-14, 8, 44)
			to = Vector3(1, 5, 32)
			focus = Vector3(5, 0, -2)
		"blockade":
			subject = _model("cruiser", "fleet", Vector3(0, 8, -36), 99, 1.15)
			for i in range(3):
				_model("escort", "fleet", Vector3(22 - 21 * i, -5 + i * 2, 12 - 9 * i), 8, 1.15)
			from = Vector3(-23, -8, 79)
			to = Vector3(8, -4, 53)
			focus = Vector3(0, 6, -35)
		"departure":
			_model("astra_terminal", "ground", Vector3(-30, 3, -85), 132, -0.55)
			subject = _model("rook", "fleet", Vector3(7, 0, 0), 16, -0.48)
			from = Vector3(21, 5, 30)
			to = Vector3(13, 4, 20)
			focus = Vector3(3, 0, -4)
		"answer":
			subject = _model("rook", "fleet", Vector3.ZERO, 17, 0.18)
			from = Vector3(-8, 5, 24)
			to = Vector3(-5, 3, 23)
			focus = Vector3(2, 0, -5)

func _surface(id: String) -> void:
	for index in range(-1, 4):
		var start := index * VectorArt.CHUNK_LENGTH
		var terrain: Node3D
		match id:
			"ignis", "cryo": terrain = VectorArt.terrain_chunk(start, false, id == "cryo")
			"vespera": terrain = VesperaArt.terrain_chunk(start)
			"xylo": terrain = XyloArt.terrain_chunk(start)
			_: terrain = FrontierArt.terrain_chunk(start, id, false)
		set_pieces.add_child(terrain)
		if id == "thalassa":
			for mesh in terrain.get_children():
				if mesh is MeshInstance3D and mesh.material_override is ShaderMaterial and mesh.material_override.shader == FrontierArt.WATER:
					water.append(mesh.material_override)
	var at := Vector3(4, -1, -60)
	var span := 34.0 if id == "vespera" else 25.0
	subject = _model(id + "_" + LANDMARKS[id], "ground", at, span, -0.24)
	focus = at + Vector3(0, FleetArt.mesh_for(id + "_" + LANDMARKS[id], "ground").get_aabb().get_center().y * subject.scale.y, 0)
	match id:
		"ignis":
			volcano = VolcanoEruption.new()
			volcano.position = VectorArt.ground_point(-19, 108)
			volcano.scale = Vector3.ONE * 1.65
			set_pieces.add_child(volcano)
			from = focus + Vector3(19, 12, 45)
			to = focus + Vector3(6, 8, 33)
		"cryo":
			_model("traffic", "fleet", at + Vector3(17, 2.2, -5), 12, 0.8)
			from = focus + Vector3(-21, 4, 32)
			to = focus + Vector3(-9, 7, 26)
		"vespera":
			_hotel_windows()
			from = focus + Vector3(10, -8, 43)
			to = focus + Vector3(-8, 4, 38)
		"xylo":
			GroundArt.add_landmarks(set_pieces, "xylo_shield_fern", [GroundArt.placement(at + Vector3(-10, 0, 4), Vector3.ONE)], true)
			from = focus + Vector3(-22, 2, 36)
			to = focus + Vector3(-7, 7, 31)
		"thalassa":
			_lighthouse_beam()
			from = focus + Vector3(16, -6, 44)
			to = focus + Vector3(-12, 1, 35)
		"kharon":
			for i in range(3):
				var ferry := _model("traffic", "fleet", at + Vector3(12 + 4 * i, 1.3, -5 - 5 * i), 7.6, -0.9)
				ferry.get_child(0).set_instance_shader_parameter("parked", true)
			from = focus + Vector3(-19, 19, 37)
			to = focus + Vector3(-7, 8, 33)

func _hotel_windows() -> void:
	var lamp := SphereMesh.new()
	lamp.radius = 0.18
	lamp.height = 0.62
	var candle := StandardMaterial3D.new()
	candle.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	candle.albedo_color = Color(2.3, 1.2, 0.36)
	lamp.material = candle
	for level in range(4):
		var radius: float = [6.4, 7.4, 5.7, 3.9][level]
		for room in range(13):
			if (room + level) % 4 == 0:
				continue
			var angle := TAU * (room + level * 0.3) / 13.0
			var light := MeshInstance3D.new()
			light.mesh = lamp
			light.position = Vector3(cos(angle) * radius, 9.1 + 7 * level, sin(angle) * radius)
			subject.add_child(light)

func _lighthouse_beam() -> void:
	beacon = Node3D.new()
	beacon.position.y = 23.5
	subject.add_child(beacon)
	var lens := CylinderMesh.new()
	lens.top_radius = 0.45
	lens.bottom_radius = 3.5
	lens.height = 48
	lens.cap_bottom = false
	lens.cap_top = false
	var shaft := MeshInstance3D.new()
	shaft.mesh = lens
	shaft.rotation.z = PI / 2.0
	shaft.position.x = 24
	var light := ShaderMaterial.new()
	light.shader = preload("res://shaders/lighthouse_beam.gdshader")
	shaft.material_override = light
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(shaft)

func advance(delta: float) -> void:
	elapsed += delta
	var t := 1.0 - exp(-elapsed * (0.045 if reduced else 0.085))
	camera.position = from.lerp(to, t)
	camera.look_at(focus)
	if shot == "lantern":
		subject.rotation.z = -0.13 + sin(elapsed * 0.12) * 0.04
	elif shot == "answer":
		subject.position.z = -elapsed * 2.6
		subject.position.y = elapsed * 0.20
		subject.rotation.z = -sin(minf(elapsed * 0.25, PI)) * 0.18
	if volcano != null:
		volcano.update_visual(elapsed, 1.6 + sin(elapsed * 0.5), not reduced, 0.1, 8.0)
	if beacon != null:
		beacon.rotation.y = elapsed * (0.18 if reduced else 0.46)
	weather.advance(delta)
	for material in water:
		material.set_shader_parameter("wave_time", elapsed)
	if LANDMARKS.has(shot):
		GroundArt.foliage_material.set_shader_parameter("wave_time", elapsed if not reduced or shot == "thalassa" else 0.0)
