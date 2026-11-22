extends Node3D

enum Mode { TITLE, FLIGHT, PAUSE, COMPLETE, TRANSITION, MARKET, DEBUG, SAVE_ERROR, CAMPAIGN_COMPLETE, NAMED_GAMES }
var named_games_origin: Mode

var flight := FlightState.new()
var mode: Mode = Mode.TITLE
var camera: Camera3D
var combat_lights := CombatLighting.new()
var surface_weather := SurfaceWeather.new()
var surface_flight := false
var cockpit_artwork: TextureRect
var cockpit_foredeck: TextureRect
var cockpit_livery := ShaderMaterial.new()
var hull_plate := Label.new()
var hull_plate_mount := Node2D.new()
var cockpit_skin: String = ""
const COCKPITS := {
	"rook": {
		"frame": preload("res://assets/cockpits/rook.png"), "deck": preload("res://assets/cockpits/foredecks/rook.png"),
		"enamel": Color("#d3dcd7"), "stripe": Color("#e84a29"), "bands": Vector3(18, 24, 1),
	},
	"hawk": {
		"frame": preload("res://assets/cockpits/hawk.png"), "deck": preload("res://assets/cockpits/foredecks/hawk.png"),
		"enamel": Color("#89a8be"), "stripe": Color("#f6b544"), "bands": Vector3(4, 10, 2),
	},
	"titan": {
		"frame": preload("res://assets/cockpits/titan.png"), "deck": preload("res://assets/cockpits/foredecks/titan.png"),
		"enamel": Color("#566d83"), "stripe": Color("#e79143"), "bands": Vector3(12, 22, 3),
	},
	"bastion": {
		"frame": preload("res://assets/cockpits/bastion.png"), "deck": preload("res://assets/cockpits/foredecks/bastion.png"),
		"enamel": Color("#8a82ae"), "stripe": Color("#dcc98f"), "bands": Vector3(6, 15, 2),
	},
	"emergency": {
		"frame": preload("res://assets/cockpits/emergency.png"), "deck": preload("res://assets/cockpits/foredecks/emergency.png"),
		"enamel": Color("#ef923e"), "stripe": Color("#f1e3c5"), "bands": Vector3(15, 29, 3),
	},
}
var gun_level_displayed: int = 0
var rotor_mount := Node2D.new()
var rotors: Array[Sprite2D] = []
var rotor_speed: float = 0.0
var rotor_phase: float = 0.0
var muzzle_points := PackedVector2Array([Vector2(548, 480), Vector2(828, 480)])
var player_probe_shape := SphereShape3D.new()
var player_probe := PhysicsShapeQueryParameters3D.new()
var world: Node3D
var targets: Array[RangeTarget] = []
var turrets: Array[GroundTurret] = []
var towers: Array[DestructibleTower] = []
var explosions: Array[DestructionEffect] = []
var director := FlightDirector.new()
var mission_world: MissionWorld
var approaching_belt: MissionWorld
var approaching_boss: MissionWorld
var retired_world: Node3D
var belt_entry: Transform3D
var launch_approach: LaunchApproach
var launch_prepared: bool = false
var ground_chunks: Array[Node3D] = []
var ground_horizon: Node3D
var ground_branch: GroundBranch
var next_ground_chunk: float = -VectorArt.CHUNK_LENGTH
var sequence: String = ""
var sequence_time: float = 0.0
const TRANSIT_LEGS := {
	"station_departure": FlightDirector.UNDOCK_DURATION, "warp_alignment": FlightDirector.ALIGN_DURATION,
	"hyperspace": LaunchApproach.HYPERSPACE_DURATION, "planet_descent": FlightDirector.DESCENT_DURATION,
	"ground_victory": DestructionEffect.DURATION, "ascent": FlightDirector.ASCENT_DURATION,
	"blockade_exit": FlightDirector.BOSS_TURN_DURATION,
	"orbital_victory": FlightDirector.VICTORY_DURATION, "belt_transfer": FlightDirector.BELT_TRANSFER_DURATION,
	"belt_exit": FlightDirector.BELT_COAST_DURATION, "belt_climb": FlightDirector.BELT_CLIMB_DURATION,
	"station_approach": FlightDirector.STATION_APPROACH_DURATION, "docking": FlightDirector.DOCK_DURATION,
}
const NEXT_LEG := {
	"station_departure": "warp_alignment", "warp_alignment": "hyperspace", "hyperspace": "planet_descent",
	"ground_victory": "ascent", "orbital_victory": "belt_transfer",
	"belt_exit": "belt_climb", "belt_climb": "station_approach", "station_approach": "docking",
}
var transit_time_at_leg_start: float = 0.0
var sequence_log: Array[String] = []
var resume_mode: Mode = Mode.FLIGHT
var docked: bool = false
var capture_marks: Dictionary = {}
var largest_phase_jump: float = 0.0
var largest_phase_turn: float = 0.0
var minimum_render_size := Vector2(100000, 100000)
var blocked_primary_hits: int = 0
var stunned_gunships: int = 0
var missiles: Array[EnemyMissile] = []
var debris: Array[BreakupEffect] = []
const ImpactSpray := preload("res://scripts/impact_spray.gd")
var impact_sprays: Array[ImpactSpray] = []
var parasites: Array[CanopyParasite] = []
var torpedoes: Array[PlayerTorpedo] = []
var emp_pulses: Array[EMPPulse] = []
var flare_clouds: Array[FlareCloud] = []
const MAX_PLAYER_ORDNANCE: int = 18
var mineral_pickups: Array[MineralPickup] = []
var volatile_blasts: Array[VolatileBlast] = []
var heat_vents: Array[HeatVent] = []
var frost_fields: Array[FrostField] = []
var lightning_fields: Array[StormLightning] = []
var ocean_material: ShaderMaterial
var ocean_age: float = 0.0
var falling_ice: Array[FallingIce] = []
var laser_gates: Array[CityLaserGate] = []
var city_traffic: CityTraffic
var xylo_fields: Array[XyloField] = []
var xylo_rovers: XyloRovers
var sky_icy_mix: float = 0.0
var sky_city_mix: float = 0.0
var sky_swamp_mix: float = 0.0
var sky_ocean_mix: float = 0.0
var sky_desert_mix: float = 0.0
var sky_planet_visibility: float = 1.0
var launch_sky_start: float = 0.0
var launch_city_start: float = 0.0
var launch_swamp_start: float = 0.0
var launch_ocean_start: float = 0.0
var launch_desert_start: float = 0.0
var thermal_sweeps: Array[ThermalSweep] = []
var rock_fragments: Array[Asteroid] = []
var rock_debris: Array[RockBreakup] = []
const MAX_ROCK_FRAGMENTS: int = 48
const MAX_MINERAL_PICKUPS: int = 32
var campaign: CampaignState
var store := CampaignStore.new()
var normal_save_path: String = "user://campaign.json"
var is_campaign: bool = false
var choosing_new_operation: bool = false
var boss: BossEncounter
var station: Node3D
var god_mode: bool = false
var zero_heat: bool = false
var infinite_ammo: bool = false
var one_hit_kill: bool = false
var auto_burst_cooling: bool = false
var debug_previous: Mode = Mode.PAUSE
var phase_log: Array[String] = []
const MAX_MISSILES: int = 12
var hud: FlightHUD
var sound: SynthAudio
var music: AmbientMusic
var computer_voice: ComputerVoice
var voice_stealth_seen: bool = false
var voice_nyx_cloaked: bool = false
var display_ship: Node3D
var beams: Array[Dictionary] = []
var plasma_bolts: Array[PlasmaBolt] = []
var tachyon_beam: TachyonBeam
var cursor := Vector2(960, 540)
var fire_armed: bool = false
var settings: Dictionary = {"reduced_effects": false, "mute": false, "shake": true, "response": 1, "voice_volume": 70, "music_volume": AmbientMusic.DEFAULT_VOLUME}
var telemetry: Array[float] = []
var last_frame_usec: int = 0
var profile_frames: bool = false
var slow_frames: Array[Dictionary] = []
var physics_cost_ms: float = 0.0
var fire_cost_ms: float = 0.0
var debris_cost_ms: float = 0.0
var automation: String = ""
var automated_session: bool = false
var automation_time: float = 0.0
var automation_stage: int = 0
var automation_failures: int = 0
var automation_realtime: bool = false
var automation_music: bool = false
var automation_music_peak: float = -200.0
var automation_ship: String = "rook"
var automation_primary: int = 0
var automation_sector: String = "ignis"
var automation_tour: int = 1
var automation_frost_damage_only: bool = false
var automation_frost_events: int = 0
var automation_hull_damage: float = 0.0
var automation_hazard: bool = false
var automation_saw_sweep: bool = false
var automation_saw_cloak: bool = false
var automation_voice_peak: float = -200.0
var pause_snapshot: float = 0.0
var screenshot_directory: String = ""

func _ready() -> void:
	player_probe.shape = player_probe_shape
	player_probe.collision_mask = 1
	_define_inputs()
	_build_environment()
	_build_world()
	EncounterArt.warm_cache()
	CryoArt.warm_cache()
	VesperaArt.warm_cache()
	XyloArt.warm_cache()
	Asteroid.warm_cache()
	var planet_model: Node3D = LaunchApproach._planet_model()
	planet_model.free()
	planet_model = LaunchApproach._planet_model("cryo")
	planet_model.free()
	planet_model = LaunchApproach._planet_model("vespera")
	planet_model.free()
	planet_model = LaunchApproach._planet_model("xylo")
	planet_model.free()
	var mineral_model: Node3D = MineralPickup.create_model()
	mineral_model.free()
	for i in range(-1, VectorArt.TERRAIN_CACHE_CHUNKS):
		var chunk: Node3D = VectorArt.terrain_chunk(i * VectorArt.CHUNK_LENGTH)
		chunk.free()
		chunk = VesperaArt.terrain_chunk(i * VectorArt.CHUNK_LENGTH, true)
		chunk.free()
		if i * VectorArt.CHUNK_LENGTH < GroundRoute.REJOIN and (i + 1) * VectorArt.CHUNK_LENGTH > GroundRoute.FORK:
			var branch_chunk: Node3D = VectorArt.terrain_chunk(i * VectorArt.CHUNK_LENGTH, true)
			branch_chunk.free()
	sound = SynthAudio.new()
	add_child(sound)
	var layer := CanvasLayer.new()
	layer.layer = 2
	layer.name = "LiveHUDLayer"
	add_child(layer)
	hud = FlightHUD.new()
	layer.add_child(hud)
	hud.flight = flight
	hud.credits_text = "Cosmic Conflict v%s\nCockpit artwork supplied by the project owner.\n\n" % ProjectSettings.get_setting("application/config/version") + FileAccess.get_file_as_string("res://assets/music/credits.txt") + "\n\n" + Engine.get_license_text() + "\n\n" + JSON.stringify(Engine.get_copyright_info(), "\t") + "\n\n" + JSON.stringify(Engine.get_license_info(), "\t")
	hud.launch_requested.connect(start_flight)
	hud.resume_requested.connect(resume_flight)
	hud.title_requested.connect(show_title)
	hud.opening_requested.connect(func() -> void: get_tree().change_scene_to_file("res://opening.tscn"))
	hud.quit_requested.connect(func() -> void: get_tree().quit())
	hud.setting_changed.connect(_change_setting)
	hud.mission_requested.connect(_request_new_campaign)
	hud.continue_requested.connect(_continue_campaign)
	hud.named_games_requested.connect(_open_named_games)
	hud.hall_requested.connect(_show_hall_of_fame)
	hud.purchase_requested.connect(_market_purchase)
	hud.secondary_selected.connect(_select_secondary)
	hud.depart_requested.connect(func() -> void: _open_sector_map(false))
	hud.sector_selected.connect(_choose_sector)
	hud.sector_cancelled.connect(func() -> void:
		if choosing_new_operation:
			show_title()
		else:
			_show_market())
	hud.debug_action.connect(_debug_action)
	music = AmbientMusic.new()
	music.fault.connect(hud.show_message)
	add_child(music)
	computer_voice = ComputerVoice.new()
	computer_voice.speaking_changed.connect(sound.set_ducked)
	computer_voice.speaking_changed.connect(music.set_ducked)
	computer_voice.fault.connect(hud.show_message)
	add_child(computer_voice)
	_load_settings()
	_parse_automation()
	show_title()

func _define_inputs() -> void:
	var primary := InputEventMouseButton.new()
	primary.button_index = MOUSE_BUTTON_LEFT
	var pause_mouse := InputEventMouseButton.new()
	pause_mouse.button_index = MOUSE_BUTTON_RIGHT
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	var secondary := InputEventKey.new()
	secondary.physical_keycode = KEY_SPACE
	var fullscreen := InputEventKey.new()
	fullscreen.physical_keycode = KEY_F11
	var debug_key := InputEventKey.new()
	debug_key.physical_keycode = KEY_QUOTELEFT
	var evade_key := InputEventKey.new()
	evade_key.physical_keycode = KEY_SHIFT
	var flare_key := InputEventKey.new()
	flare_key.physical_keycode = KEY_C
	var bindings: Dictionary = {"primary": [primary], "pause": [pause_mouse, escape], "secondary": [secondary], "fullscreen": [fullscreen], "debug": [debug_key], "evade": [evade_key], "countermeasures": [flare_key]}
	var pilot_keys := {"barrel_roll": KEY_B, "radar_range": KEY_R, "boss_intel": KEY_I, "precision_hold": KEY_F, "heat_governor": KEY_V, "shield_surge": KEY_X, "strafe_left": KEY_A, "strafe_right": KEY_D, "strafe_up": KEY_W, "strafe_down": KEY_S}
	for action: String in pilot_keys:
		var key := InputEventKey.new()
		key.physical_keycode = pilot_keys[action]
		bindings[action] = [key]
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for event: InputEvent in bindings[action]:
			InputMap.action_add_event(action, event)
	for i in range(CampaignState.POWER_MODES.size()):
		var key := InputEventKey.new()
		key.physical_keycode = KEY_0 + i
		var action: String = "power_" + CampaignState.POWER_MODES[i]
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		InputMap.action_add_event(action, key)

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/sky.gdshader")
	sky.sky_material = material
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled = true
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.05
	environment.glow_intensity = 0.85
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.fog_enabled = true
	environment.fog_light_color = Color("#1b1022")
	environment.fog_density = 0.0009
	environment.fog_sky_affect = 0.0
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	add_child(combat_lights)
	camera = Camera3D.new()
	camera.fov = 78.0
	camera.near = 0.15
	camera.far = VectorArt.VIEW_DISTANCE
	add_child(camera)
	camera.add_child(surface_weather)
	camera.make_current()
	_build_cockpit()

func _build_cockpit() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CockpitArtworkLayer"
	layer.layer = 1
	add_child(layer)
	cockpit_foredeck = TextureRect.new()
	cockpit_foredeck.name = "Foredeck"
	cockpit_foredeck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cockpit_foredeck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cockpit_foredeck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(cockpit_foredeck)
	cockpit_foredeck.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var artwork := TextureRect.new()
	cockpit_artwork = artwork
	artwork.name = "CockpitArtwork"
	artwork.texture = preload("res://assets/cockpit_overlay.png")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cockpit_livery.shader = preload("res://shaders/cockpit_livery.gdshader")
	artwork.add_child(hull_plate_mount)
	hull_plate_mount.add_child(hull_plate)
	# The port sill stays clear of the warning strip above the central gauges.
	hull_plate.position = Vector2(102, 688)
	hull_plate.rotation = deg_to_rad(-23)
	hull_plate.size = Vector2(118, 18)
	hull_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hull_plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hull_plate.add_theme_font_size_override("font_size", 13)
	hull_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(rotor_mount)
	rotor_mount.show_behind_parent = true
	for right in [false, true]:
		var rotor := Sprite2D.new()
		rotor.texture = preload("res://assets/guns/plasma_rotor.png")
		rotor.hframes = 8
		rotor.vframes = 4
		rotor.position = Vector2(948 if right else 428, 456)
		rotor.flip_h = right
		rotor_mount.add_child(rotor)
		rotors.append(rotor)
	artwork.resized.connect(_place_cockpit_fittings)
	_place_cockpit_fittings()
	_set_cockpit("rook")

func _place_cockpit_fittings() -> void:
	var placement := CockpitInstruments.artwork_transform(cockpit_artwork.size)
	rotor_mount.transform = placement
	hull_plate_mount.transform = placement

func _advance_rotors(delta: float, firing: bool) -> void:
	if not rotor_mount.visible:
		return
	rotor_speed = move_toward(rotor_speed, 1.8 if firing else 0.0, delta * (5.0 if firing else 2.2))
	rotor_phase = fposmod(rotor_phase + rotor_speed * delta, 1.0)
	for rotor in rotors:
		rotor.frame = floori(rotor_phase * rotor.hframes * rotor.vframes)

func _set_cockpit(ship: String, primary_level: int = 0) -> void:
	var skin: Dictionary = COCKPITS.get(ship, {})
	if skin.is_empty() and not ship.is_empty():
		push_error("No cockpit is defined for ship: " + ship)
		return
	var frame: Texture2D = skin.get("frame", preload("res://assets/cockpit_overlay.png"))
	var equipped: int = 0 if ship.is_empty() else primary_level
	var combined: Texture2D = GunAppearance.texture_for(frame, equipped)
	if combined == null:
		return
	cockpit_skin = ship
	cockpit_foredeck.texture = skin.get("deck")
	cockpit_artwork.material = null if skin.is_empty() else cockpit_livery
	if skin.is_empty():
		hull_plate.text = ""
	else:
		cockpit_livery.set_shader_parameter("enamel", skin.enamel)
		cockpit_livery.set_shader_parameter("stripe", skin.stripe)
		cockpit_livery.set_shader_parameter("bands", skin.bands)
		hull_plate.text = String(CampaignState.SHIPS[ship].name).to_upper()
		hull_plate.add_theme_color_override("font_color", skin.stripe)
	cockpit_artwork.texture = combined
	gun_level_displayed = equipped
	rotor_mount.visible = equipped == 1
	if not rotor_mount.visible:
		rotor_speed = 0.0
		rotor_phase = 0.0
		for rotor in rotors:
			rotor.frame = 0
	if display_ship != null and display_ship.get_meta("player_hull", "") != ship:
		var pose: Transform3D = display_ship.global_transform
		var shown: bool = display_ship.visible
		display_ship.queue_free()
		display_ship = FrontierArt.player_ship(ship, equipped)
		add_child(display_ship)
		display_ship.global_transform = pose
		display_ship.visible = shown
	elif display_ship != null and display_ship.get_meta("primary_level") != equipped:
		GunAppearance.fit_exterior(display_ship, ship, equipped)
	muzzle_points = PackedVector2Array([Vector2(548, 480), Vector2(828, 480)]) if cockpit_skin.is_empty() else GunAppearance.muzzle_points(equipped)

func _build_world(training: bool = true) -> void:
	var sector: String = campaign.sector if not training and campaign != null else "ignis"
	var icy: bool = sector == "cryo"
	world = Node3D.new()
	if not training:
		world.transform = director.ground_course
		ground_branch = GroundBranch.new()
		ground_branch.sector = sector
		ground_branch.health_scale = campaign.health_multiplier()
		director.ground_route = ground_branch.route
	add_child(world)
	if sector == "thalassa":
		ocean_material = ShaderMaterial.new()
		ocean_age = 0
		_configure_ocean_material()
	if not training:
		ground_horizon = FrontierArt.horizon(sector) if FrontierArt.is_frontier(sector) else XyloArt.horizon() if sector == "xylo" else VesperaArt.horizon() if sector == "vespera" else VectorArt.ground_horizon(icy)
		world.add_child(ground_horizon)
		_bind_ocean(ground_horizon)
	next_ground_chunk = -VectorArt.CHUNK_LENGTH
	_stream_ground(0.0)
	for i in range(19 if training else 23):
		var travel: float = 190.0 + float(i) * 160.0
		var obstacle := DestructibleTower.new()
		obstacle.sector = sector
		obstacle.travel = travel
		obstacle.lane.x = -4.5 if i % 2 == 0 else 4.5
		obstacle.transform = FlightState.rail_frame(travel)
		obstacle.position += obstacle.basis * Vector3(obstacle.lane.x, -4, 0)
		if sector in ["vespera", "xylo", "thalassa", "kharon"]:
			obstacle.position.y = 4.5
		obstacle.fractured.connect(_tower_fractured)
		world.add_child(obstacle)
		towers.append(obstacle)
	for i in range(33 if training else 40):
		var target: RangeTarget = RangeTarget.new() if training else EnemyFighter.new()
		target.ground_pilot = camera
		target.travel = 130.0 + float(i) * 91.0
		target.lane = Vector2(float(i % 3 - 1) * 4.4, float(i % 4) * 0.9 + 0.8)
		target.phase = float(i) * 1.7
		if target is EnemyFighter:
			target.sector = sector
			target.health_scale = campaign.health_multiplier()
		world.add_child(target)
		targets.append(target)
		if target is EnemyFighter:
			target.missile_requested.connect(_launch_missile)
	for i in range(13 if training else 16):
		var turret := GroundTurret.new()
		turret.sector = sector
		turret.health_scale = 1.0 if training else campaign.health_multiplier()
		turret.travel = 330.0 + i * 220.0
		turret.lane.x = -18.0 if i % 2 == 0 else 18.0
		turret.phase = float(i % 3) * 0.45
		turret.missile_requested.connect(_launch_missile)
		world.add_child(turret)
		turrets.append(turret)
		targets.append(turret)
	targets.append_array(towers)
	if not training:
		if icy or sector == "kharon":
			for i in range(8):
				var ice: FallingIce = RuinFall.new() if sector == "kharon" else FallingIce.new()
				ice.travel = 560 + i * 390
				ice.lane.x = -8.0 if i % 2 == 0 else 8.0
				ice.landed.connect(func(chunk: FallingIce) -> void: _spawn_breakup(chunk, true))
				world.add_child(ice.support_model())
				world.add_child(ice)
				falling_ice.append(ice)
				targets.append(ice)
		for i in range(5):
			var dish := RadarDish.new()
			dish.biological = sector == "xylo"
			dish.travel = 620.0 + i * 700.0
			dish.lane.x = -23.0 if i % 2 == 0 else 23.0
			dish.phase = i * 1.3
			world.add_child(dish)
			if sector in ["vespera", "xylo", "thalassa", "kharon"]:
				dish.position.y = 0.5
			targets.append(dish)
		for i in range(8):
			if sector in ["vespera", "xylo", "thalassa", "kharon"]:
				continue
			if icy:
				var frost := FrostField.new()
				frost.phase = i * 1.1
				frost.position = VectorArt.ground_point(-6.5 if i % 2 == 0 else 6.5, 450 + i * 410)
				world.add_child(frost)
				frost_fields.append(frost)
				continue
			var vent := HeatVent.new()
			var travel: float = 450.0 + i * 410 + (50 if i == 4 else 0)
			vent.phase = i * 1.1
			vent.terrain_mounted = true
			vent.position = VectorArt.ground_point(-16.0 if i % 2 == 0 else 16.0, travel)
			world.add_child(vent)
			heat_vents.append(vent)
		if sector == "thalassa":
			for i in range(10):
				var lightning := StormLightning.new()
				lightning.site = i
				lightning.phase = i * 1.1
				lightning.position = FrontierArt.floor_point(-8 if i % 2 == 0 else 8, 460 + i * 320)
				lightning.aim_requested.connect(_storm_aim)
				lightning.contact.connect(_storm_contact)
				lightning.grounded.connect(_storm_grounded)
				world.add_child(lightning)
				lightning_fields.append(lightning)
		elif sector == "vespera":
			city_traffic = CityTraffic.new()
			world.add_child(city_traffic)
			for i in range(6):
				var travel: float = 500 + i * 560
				for route_index in range(2 if travel > GroundRoute.FORK and travel < GroundRoute.REJOIN else 1):
					var gate := CityLaserGate.new()
					gate.phase = i * 0.6
					gate.transform = GroundRoute.frame(travel) if route_index == 1 else FlightState.rail_frame(travel)
					world.add_child(gate)
					laser_gates.append(gate)
					targets.append_array(gate.emitters)
		elif sector == "xylo":
			xylo_rovers = XyloRovers.new()
			world.add_child(xylo_rovers)
			for i in range(14):
				var field := XyloField.new()
				field.kind = XyloField.Kind.ACID if i < 8 else XyloField.Kind.SPORES
				var travel: float = 450 + i * 410 if i < 8 else 680 + (i - 8) * 490
				field.phase = i * 1.1
				field.position = XyloArt.floor_point(-6.5 if i % 2 == 0 else 6.5, travel)
				world.add_child(field)
				xylo_fields.append(field)
	var beacons := PackedVector3Array()
	for i in range(120):
		var travel: float = float(i) * 28.0
		var origin: Vector3 = FlightState.rail_point(travel)
		for side in [-1.0, 1.0]:
			beacons.append(origin + Vector3(side * 10.5, -10.0, 0))
			beacons.append(origin + Vector3(side * 10.5, -6.0, 0))
	world.add_child(VectorArt.lines(beacons, Color("#2d7787")))
	if ground_branch != null:
		world.add_child(ground_branch)
		for turret in ground_branch.turrets:
			turret.missile_requested.connect(_launch_missile)
			turrets.append(turret)
			targets.append(turret)
		for tower in ground_branch.towers:
			tower.fractured.connect(_tower_fractured)
			towers.append(tower)
			targets.append(tower)
	if display_ship == null:
		display_ship = FrontierArt.player_ship(cockpit_skin, gun_level_displayed)
		add_child(display_ship)

func start_flight() -> void:
	computer_voice.stop_speech(true)
	computer_voice.pause_speech(false)
	is_campaign = false
	god_mode = false
	zero_heat = false
	infinite_ammo = false
	one_hit_kill = false
	_set_cockpit("rook")
	_clear_stage()
	_build_world()
	flight = FlightState.new()
	director = FlightDirector.new()
	sequence = ""
	docked = false
	_apply_settings()
	hud.flight = flight
	hud.autopilot = false
	for target in targets:
		target.reset()
	_clear_beams()
	_clear_missiles()
	telemetry.clear()
	mode = Mode.FLIGHT
	display_ship.hide()
	cursor = get_viewport().get_visible_rect().size * 0.5
	fire_armed = false
	_set_pointer(true, true)
	hud.show_menu("flight", settings)
	sound.stop_all()
	sound.pause_sounds(false)
	_update_camera()
	hud.phase_title = "TRAINING // CANYON APPROACH"
	hud.objective = "DISABLE TURRETS / SHOOT OR EVADE MISSILES"
	hud.boss_fraction = -1.0
	_set_ground_environment(true)

func show_title() -> void:
	surface_flight = false
	surface_weather.configure("ignis", false, settings["reduced_effects"])
	_clear_parasites()
	computer_voice.stop_speech(true)
	computer_voice.pause_speech(false)
	if launch_approach != null:
		launch_approach.queue_free()
		launch_approach = null
	if approaching_boss != null:
		approaching_boss.queue_free()
		approaching_boss = null
	launch_prepared = false
	camera.far = VectorArt.VIEW_DISTANCE
	is_campaign = false
	god_mode = false
	zero_heat = false
	infinite_ammo = false
	one_hit_kill = false
	sequence = ""
	mode = Mode.TITLE
	hud.autopilot = false
	_set_pointer(false)
	camera.transform = FlightState.rail_frame(15.0)
	camera.position += Vector3(-2.0, 3.0, 0.0)
	display_ship.show()
	display_ship.transform = camera.transform
	display_ship.position += camera.basis * Vector3(6.0, 0.1, -15.0)
	display_ship.rotate_object_local(Vector3.UP, 2.7)
	_clear_beams()
	_clear_missiles()
	_clear_debris()
	_clear_torpedoes()
	_clear_salvage()
	sound.stop_all()
	store = CampaignStore.new(normal_save_path)
	hud.can_resume = false
	if FileAccess.file_exists(store.path):
		var error: Error = store.load_game()
		if error == OK:
			campaign = store.state
			hud.can_resume = true
		else:
			push_warning(store.message)
			hud.show_notice("CAMPAIGN SAVE NEEDS ATTENTION", store.message + "\nThe existing file has not been replaced.", [
				{"label": "START NEW OPERATION (CONFIRM REPLACEMENT)", "action": _request_new_campaign},
				{"label": "TRAINING / LEAVE SAVE UNCHANGED", "action": start_flight}])
			return
	_set_cockpit(campaign.ship if hud.can_resume and campaign != null else "rook", campaign.primary_level if hud.can_resume and campaign != null else 0)
	hud.show_menu("title", settings)
	if not computer_voice.failure_message.is_empty():
		hud.show_message(computer_voice.failure_message)
	elif not music.failure_message.is_empty():
		hud.show_message(music.failure_message)

func pause_flight() -> void:
	if mode != Mode.FLIGHT and not (mode == Mode.TRANSITION and not sequence.is_empty()):
		return
	resume_mode = mode
	mode = Mode.PAUSE
	fire_armed = false
	_set_pointer(false)
	sound.pause_sounds(true)
	computer_voice.pause_speech(true)
	hud.show_menu("pause", settings)

func resume_flight() -> void:
	if mode != Mode.PAUSE:
		return
	mode = resume_mode
	fire_armed = false
	_set_pointer(true, true)
	sound.pause_sounds(false)
	computer_voice.pause_speech(false)
	hud.show_menu("flight", settings)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not automated_session and automation.is_empty():
		pause_flight()

func _set_pointer(captured: bool, warp: bool = false) -> void:
	if automated_session or not automation.is_empty():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN if captured else Input.MOUSE_MODE_VISIBLE
	if warp:
		Input.warp_mouse(cursor)

func _input(_event: InputEvent) -> void:
	if automated_session or not automation.is_empty():
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.FLIGHT and is_campaign:
		for power: String in CampaignState.POWER_MODES:
			if event.is_action_pressed("power_" + power):
				var changed: bool = flight.power_mode != power
				flight.power_mode = power
				campaign.power_mode = power
				hud.show_message("REACTOR POWER / " + power.to_upper())
				if changed:
					computer_voice.cancel_group("reactor")
					_voice_event("reactor_" + power)
				return
	if event.is_action_pressed("fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event.is_action_pressed("debug"):
		_toggle_debug()
	elif event.is_action_pressed("pause"):
		if mode == Mode.FLIGHT or (mode == Mode.TRANSITION and not sequence.is_empty()):
			pause_flight()
		elif mode == Mode.PAUSE:
			resume_flight()
		elif mode == Mode.NAMED_GAMES:
			_close_named_games()
		elif mode == Mode.DEBUG:
			_debug_action("close")
	elif event.is_action_pressed("secondary") and mode == Mode.FLIGHT:
		fire_secondary()
	elif event.is_action_pressed("countermeasures") and mode == Mode.FLIGHT:
		deploy_countermeasures()
	elif event.is_action_pressed("barrel_roll") and mode == Mode.FLIGHT:
		var error := flight.request_barrel_roll()
		hud.show_message(error if not error.is_empty() else "BARREL ROLL / EVASION ACTIVE")
	elif event.is_action_pressed("boss_intel") and mode == Mode.FLIGHT and boss != null and not boss.defeated():
		hud.show_message(boss.objective())
		_voice_event("recon_" + boss.sector + ("_orbit" if boss.orbital else "_ground"))
	elif event.is_action_pressed("radar_range") and mode == Mode.FLIGHT:
		hud.sensors.cycle_range()
	elif event.is_action_pressed("heat_governor") and mode == Mode.FLIGHT:
		flight.heat_governor = not flight.heat_governor
		hud.show_message("THERMAL GOVERNOR / AUTOMATIC BURSTS" if flight.heat_governor else "THERMAL GOVERNOR / MANUAL FIRE")
	elif event.is_action_pressed("shield_surge") and mode == Mode.FLIGHT:
		hud.show_message(flight.request_shield_surge())
	elif event.is_action_pressed("evade") and mode == Mode.FLIGHT:
		var error: String = flight.request_evasion()
		hud.show_message(error if not error.is_empty() else "EVASIVE SHIFT / PROJECTILE DEFLECTION ACTIVE")
	elif event is InputEventMouseMotion and mode == Mode.FLIGHT and automation.is_empty():
		cursor = event.position.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)

func _physics_process(delta: float) -> void:
	if mode == Mode.TRANSITION and not sequence.is_empty():
		_advance_sequence(delta)
		return
	if mode != Mode.FLIGHT:
		return
	if is_campaign and flight.hull <= 0.0:
		mode = Mode.TRANSITION
		_eject.call_deferred()
		return
	var physics_start: int = Time.get_ticks_usec()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	flight.aim = (cursor / viewport_size * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	flight.strafe = Vector2(Input.get_axis("strafe_left", "strafe_right"), Input.get_axis("strafe_up", "strafe_down"))
	flight.precision_hold = Input.is_action_pressed("precision_hold")
	var held: bool = Input.is_action_pressed("primary")
	if not held:
		fire_armed = true
	var previous: Vector3 = camera.position
	var previous_overheats: int = flight.overheat_events
	var previous_vent: float = flight.overheat_remaining
	var previous_recharge: float = flight.recharge_delay
	var previous_shields: float = flight.shields
	var volleys: int = flight.advance(delta, held and fire_armed)
	_advance_rotors(delta, held and fire_armed and flight.overheat_remaining <= 0.0)
	if previous_vent > 0 and flight.overheat_remaining == 0:
		_voice_event("cooling")
	if previous_recharge > 0 and flight.recharge_delay == 0 and flight.shields > previous_shields:
		_voice_event("shields_regen")
	var shots: int = volleys * flight.primary_samples()
	if flight.overheat_events > previous_overheats:
		hud.show_message("PRIMARY OVERHEATED / TWO-SECOND VENT CYCLE")
		sound.play_sound(sound.hit)
	if is_campaign:
		campaign.stats["shots"] += shots
		if ground_branch != null and campaign.phase == "ground":
			if ground_branch.route.advance(flight.distance, flight.offset.x):
				hud.show_message("HAZARD ROUTE SELECTED / SUPPLIES AND +100 CR AT REJOIN" if ground_branch.route.selected else "SAFE ROUTE SELECTED")
				_voice_route(ground_branch.route.selected)
		if mission_world != null:
			mission_world.advance(delta, director.frame)
		director.advance(campaign.phase, delta, flight.distance, flight.elapsed, targets, flight.aim, flight.precision_hold)
	if not is_campaign or campaign.phase.begins_with("ground"):
		_stream_ground(flight.distance)
	var canyon_contact := false
	if is_campaign and campaign.phase in ["ground", "ground_boss"] and campaign.sector in ["ignis", "cryo"]:
		canyon_contact = _limit_canyon_travel()
	_update_camera()
	_advance_rock_fragments(delta, previous, camera.position)
	_advance_parasites(delta)
	_check_obstacles(previous, camera.position, canyon_contact)
	for target in targets:
		if target is Asteroid or target is EggShip:
			continue
		target.animate(flight.elapsed)
		if target is EnemyFighter:
			if ground_branch == null or ground_branch.engages(target, flight.distance):
				target.advance(delta, camera.position, (camera.position - previous) / delta)
		elif target is PirateSkirmisher:
			target.advance(delta, camera.position, (camera.position - previous) / delta)
	for turret in turrets:
		if ground_branch == null or ground_branch.engages(turret, flight.distance):
			turret.advance(delta, camera.position, (camera.position - previous) / delta)
	for tower in towers:
		tower.advance(delta)
	if boss != null:
		boss.advance(delta, camera.position, (camera.position - previous) / delta)
		var cloaked: bool = boss.cloak != null and boss.cloak.active() and boss.parts[0].unlocked and not boss.defeated()
		if cloaked and not voice_nyx_cloaked:
			_voice_event("nyx_cloak")
		voice_nyx_cloaked = cloaked
	_advance_missiles(delta, previous, camera.position)
	if is_campaign and flight.hull <= 0.0:
		flight.shots -= shots
		campaign.stats["shots"] -= shots
		shots = 0
		volleys = 0
	var fire_start: int = Time.get_ticks_usec()
	for _i in range(volleys):
		fire_primary()
	fire_cost_ms = float(Time.get_ticks_usec() - fire_start) / 1000.0
	_update_beams(delta)
	var debris_start: int = Time.get_ticks_usec()
	_advance_debris(delta)
	_advance_explosions(delta)
	debris_cost_ms = float(Time.get_ticks_usec() - debris_start) / 1000.0
	_advance_torpedoes(delta)
	_advance_plasma(delta)
	_advance_salvage(delta, previous, camera.position)
	_advance_thermal_hazards(delta, previous, camera.position)
	for frost in frost_fields:
		if frost.advance(delta, previous, camera.position) and _apply_pilot_damage("CRYO FROST", FrostField.DAMAGE):
			_apply_frost()
	_advance_ocean(delta)
	if not lightning_fields.is_empty():
		_advance_storm(delta, previous)
	for ice in falling_ice:
		if ice.advance(delta, previous, camera.position, flight.collision_radius):
			_apply_pilot_damage("FALLING RUIN" if ice is RuinFall else "FALLING ICE", FallingIce.DAMAGE)
	for gate in laser_gates:
		if gate.advance(delta, previous, camera.position, flight.collision_radius):
			_apply_pilot_damage("CITY LASER GATE", CityLaserGate.DAMAGE)
	if city_traffic != null:
		city_traffic.advance(delta, flight.distance)
	if xylo_rovers != null:
		xylo_rovers.advance(delta)
	for field in xylo_fields:
		if field.advance(delta, previous, camera.position):
			if field.kind == XyloField.Kind.ACID:
				if _apply_pilot_damage("CORROSIVE GEYSER", XyloField.ACID_DAMAGE):
					_voice_event("xylo_acid")
			elif flight.apply_spores():
				hud.show_message("SPORE STATIC / RADAR ONLY / FLIGHT CONTROLS UNAFFECTED")
				_voice_event("xylo_spores")
	if ground_branch != null and is_campaign and campaign.phase == "ground":
		for message in ground_branch.advance(delta, previous, camera.position, campaign, flight):
			hud.show_message(message)
		hud.objective = ground_branch.objective(flight.distance)
	if mission_world != null and mission_world.advance_webs(delta, previous, camera.position, flight.collision_radius):
		if _apply_pilot_damage("LASER TRIPWIRE", LaserWeb.DAMAGE):
			sound.play_sound(sound.impact)
	_update_tachyon(held and fire_armed and flight.hull > 0 and flight.overheat_remaining <= 0)
	hud.cursor = cursor
	_update_contacts()
	if flight.overheat_events > previous_overheats:
		_voice_event("overheat")
	if retired_world != null and flight.elapsed > 2.0:
		retired_world.queue_free()
		retired_world = null
	if is_campaign and flight.hull <= 0.0:
		mode = Mode.TRANSITION
		_eject.call_deferred()
	elif is_campaign and ((boss != null and boss.defeated()) or flight.complete()):
		mode = Mode.TRANSITION
		_finish_phase.call_deferred()
	elif flight.complete():
		mode = Mode.COMPLETE
		_set_pointer(false)
		sound.pause_sounds(true)
		hud.show_menu("complete", settings)
	physics_cost_ms = float(Time.get_ticks_usec() - physics_start) / 1000.0

func _update_camera() -> void:
	camera.transform = director.frame if is_campaign else FlightState.rail_frame(flight.distance)
	camera.position += camera.basis * Vector3(flight.offset.x, flight.offset.y, 0.0)
	camera.rotate_object_local(Vector3.FORWARD, -flight.offset.x * 0.007)
	camera.rotate_object_local(Vector3.FORWARD, flight.roll_bank(bool(settings["reduced_effects"]) or not bool(settings["shake"])))
	if bool(settings["shake"]):
		camera.rotate_object_local(Vector3.FORWARD, flight.evade_bank)
	if bool(settings["shake"]) and flight.damage_flash > 0.0:
		camera.position.y += sin(flight.elapsed * 70.0) * flight.damage_flash * 0.25

func _limit_canyon_travel() -> bool:
	var frame := director.ground_course.affine_inverse() * director.frame
	var branching := ground_branch != null
	var icy := campaign.sector == "cryo"
	var requested := Vector3(flight.offset.x, flight.offset.y, 0)
	if VectorArt.canyon_clearance(frame * requested, branching, icy, flight.collision_radius) >= 0:
		return false
	# The route centre is clear. Find the last safe offset toward the requested
	# position instead of letting a held steering input push through the slope.
	var safe := Vector3(0, requested.y, 0)
	if VectorArt.canyon_clearance(frame * safe, branching, icy, flight.collision_radius) < 0:
		safe = Vector3.ZERO
	for _step in range(12):
		var middle := safe.lerp(requested, 0.5)
		if VectorArt.canyon_clearance(frame * middle, branching, icy, flight.collision_radius) >= 0:
			safe = middle
		else:
			requested = middle
	flight.offset = Vector2(safe.x, safe.y)
	return true

func _check_obstacles(previous: Vector3, current: Vector3, canyon_contact: bool = false) -> void:
	var query: PhysicsShapeQueryParameters3D = player_probe
	if not is_equal_approx(player_probe_shape.radius, flight.collision_radius):
		player_probe_shape.radius = flight.collision_radius
	query.transform = Transform3D(Basis.IDENTITY, previous)
	query.motion = current - previous
	var fraction: PackedFloat32Array = get_world_3d().direct_space_state.cast_motion(query)
	query.transform.origin = current
	query.motion = Vector3.ZERO
	var overlapping: bool = not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
	if (canyon_contact or fraction[0] < 1.0 or overlapping) and _apply_pilot_damage("PROXIMITY IMPACT"):
		sound.play_sound(sound.impact)
		if not automation.is_empty():
			print("AUTOMATION_IMPACT phase=%s distance=%.2f offset=%s previous=%s current=%s" % [campaign.phase if is_campaign else "training", flight.distance, flight.offset, previous, current])

func _apply_pilot_damage(reason: String, damage: float = 18.0, direct_hull: bool = false) -> bool:
	if god_mode:
		return false
	var previous_hull: float = flight.hull
	var previous_shields: float = flight.shields
	var previous_multiplier: int = campaign.combo_multiplier() if is_campaign else 1
	var damaged: bool = flight.impact(reason, damage, direct_hull)
	if not automation.is_empty():
		automation_hull_damage += maxf(0, previous_hull - flight.hull)
	if is_campaign and flight.hull < previous_hull:
		campaign.hull_damage += previous_hull - flight.hull
		campaign.break_combo()
		if previous_multiplier > 1:
			hud.show_message("HULL DAMAGE / COMBAT STREAK RESET")
	if damaged and is_campaign and flight.hull > 0:
		if flight.hull <= flight.max_hull * 0.25 and previous_hull > flight.max_hull * 0.25:
			_voice_event("hull_critical")
		elif previous_shields > 0 and flight.shields <= 0:
			_voice_event("shields_empty")
		elif flight.hull < previous_hull:
			_voice_event("streak_break" if previous_multiplier > 1 else "hull_damage")
	return damaged

func _voice_event(event: String) -> bool:
	if computer_voice == null or automated_session or not automation.is_empty():
		return false
	return computer_voice.say(event)

func _voice_route(hard: bool) -> bool:
	if computer_voice == null or automated_session or not automation.is_empty():
		return false
	return computer_voice.say_route(hard)

func _apply_frost() -> void:
	if flight.apply_frost():
		if not automation.is_empty():
			automation_frost_events += 1
		hud.show_message("FROST / STEERING DAMPED FOR 2s / SHIFT REMAINS AVAILABLE" if flight.frost_slowdown else "FROST IMPACT / STEERING UNCHANGED")
		if flight.frost_slowdown:
			_voice_event("frost_hit")

func fire_primary() -> void:
	if flight.primary_level == 2:
		_trace_tachyon(true)
		sound.play_sound(sound.pulse)
		return
	var origin: Vector3 = camera.project_ray_origin(cursor)
	var direction: Vector3 = camera.project_ray_normal(cursor)
	var end: Vector3 = origin + direction * 490.0
	var query := PhysicsRayQueryParameters3D.create(origin, end, 7)
	query.collide_with_areas = true
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		end = result["position"]
		if flight.primary_level == 0:
			_strike(result, flight.weapon_damage)
	var origins: PackedVector3Array = _primary_origins()
	if flight.primary_level == 1:
		for muzzle in origins:
			var bolt := PlasmaBolt.new()
			bolt.position = muzzle
			bolt.direction = (end - muzzle).normalized()
			bolt.impacted.connect(func(hit: Dictionary) -> void: _strike(hit, 1))
			add_child(bolt)
			plasma_bolts.append(bolt)
		sound.play_sound(sound.pulse)
		return
	var strokes := PackedVector3Array()
	for muzzle in origins:
		strokes.append(muzzle)
		strokes.append(end)
	var beam := VectorArt.lines(strokes, Color("#ffc284"))
	add_child(beam)
	beams.append({"node": beam, "remaining": 0.07})
	sound.play_sound(sound.pulse)

func _primary_origins() -> PackedVector3Array:
	var origins := PackedVector3Array()
	for point in muzzle_points:
		var screen: Vector2 = CockpitInstruments.artwork_transform(get_viewport().get_visible_rect().size) * point
		origins.append(camera.project_ray_origin(screen) + camera.project_ray_normal(screen) * 3.5)
	return origins

func _advance_plasma(delta: float) -> void:
	for i in range(plasma_bolts.size() - 1, -1, -1):
		plasma_bolts[i].advance(delta)
		if not plasma_bolts[i].active:
			plasma_bolts[i].queue_free()
			plasma_bolts.remove_at(i)

func _update_tachyon(firing: bool) -> void:
	if flight.primary_level != 2 or not firing:
		if tachyon_beam != null:
			tachyon_beam.hide()
		return
	if tachyon_beam == null:
		tachyon_beam = TachyonBeam.new()
		add_child(tachyon_beam)
	tachyon_beam.update_path(_primary_origins(), _trace_tachyon(false))

func _tachyon_contact(origin: Vector3, direction: Vector3, excluded: Array[RID]) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var right: Vector3 = direction.cross(camera.global_basis.y).normalized()
	var up: Vector3 = right.cross(direction).normalized()
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = 7
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = excluded
	var nearest: Dictionary = {}
	var distance: float = INF
	# All aperture rays share the nearest obstruction; clear edges cannot bypass cover.
	for i in range(17):
		var angle: float = (i - 1) * TAU / 16.0
		var offset: Vector3 = Vector3.ZERO if i == 0 else (right * cos(angle) + up * sin(angle)) * TachyonBeam.RADIUS
		query.from = origin + offset
		query.to = query.from + direction * TachyonBeam.RANGE
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			var point: Vector3 = hit["position"]
			var depth: float = (point - origin).dot(direction)
			if depth < distance:
				nearest = hit
				distance = depth
	return nearest

func _trace_tachyon(damaging: bool) -> Vector3:
	var origin: Vector3 = camera.project_ray_origin(cursor)
	var direction: Vector3 = camera.project_ray_normal(cursor)
	var end: Vector3 = origin + direction * TachyonBeam.RANGE
	var excluded: Array[RID] = []
	var hit: bool = false
	while true:
		var contact: Dictionary = _tachyon_contact(origin, direction, excluded)
		if contact.is_empty():
			break
		var collider: Object = contact["collider"]
		var penetrable: bool = (collider is EnemyFighter and not collider.heavy) or collider is PirateSkirmisher
		if damaging:
			contact["direction"] = direction
			hit = _strike(contact, flight.weapon_damage, false, false) or hit
		if not penetrable:
			end = contact["position"]
			break
		excluded.append(contact["rid"])
	if damaging and hit:
		_record_weapon_hit()
	return end

func _disarm_primary() -> void:
	if tachyon_beam != null:
		tachyon_beam.hide()
	for bolt in plasma_bolts:
		bolt.dangerous = false

func _record_weapon_hit() -> void:
	flight.hits += 1
	flight.hit_flash = 0.1
	if is_campaign:
		campaign.stats["hits"] += 1

func _strike(result: Dictionary, damage: int, secondary_hit: bool = false, record_hit: bool = true) -> bool:
	var collider: Object = result["collider"]
	var at: Vector3 = result["position"]
	if collider is FallingIce:
		if collider.destroyed or collider.expired:
			return false
		if record_hit:
			_record_weapon_hit()
		var previous_armor: int = collider.armor
		var shattered: bool = collider.receive_hit(damage)
		_spawn_breakup(collider, shattered)
		_confirm_impact(result, previous_armor, shattered)
		if shattered:
			hud.show_message("RUIN BLOCK SHATTERED / SIDE LANE CLEAR" if collider is RuinFall else "FALLING ICE SHATTERED / SIDE LANE CLEAR")
		return true
	if collider is GateEmitter:
		if collider.destroyed:
			return false
		if record_hit:
			_record_weapon_hit()
		var previous_armor: int = collider.armor
		var killed: bool = collider.receive_hit(maxi(damage, collider.armor) if one_hit_kill else damage)
		_spawn_breakup(collider, killed)
		_confirm_impact(result, previous_armor, killed)
		if killed:
			hud.show_message("SIDE GATE EMITTER DISABLED / CENTER LANE REMAINS CLEAR")
		return true
	if collider is RangeTarget and not collider.destroyed:
		if (collider is EnemyFighter or collider is PirateSkirmisher) and collider.expired:
			return false
		if collider is BossPart and not collider.unlocked:
			hud.show_message(boss.objective() if boss != null else "TARGET SHIELDED")
			return false
		if collider is Asteroid and collider.indestructible:
			hud.show_message("IRON-CORE ASTEROID / EVADE, CANNOT BE DESTROYED")
			return false
		if collider is EnemyFighter and collider.has_directional_shield():
			if secondary_hit:
				collider.stun()
				stunned_gunships += 1
				hud.show_message("GUNSHIP STUNNED / SHIELD DISABLED")
			elif collider.shield_blocks(camera.global_position):
				collider.flash_shield()
				blocked_primary_hits += 1
				hud.show_message("DIRECTIONAL SHIELD / FLANK, WAIT FOR BANK, OR USE SECONDARY")
				return false
		if record_hit:
			_record_weapon_hit()
		var applied_damage: int = maxi(damage, collider.armor) if one_hit_kill and is_campaign else damage
		var previous_armor: int = collider.armor
		var killed: bool
		if collider is DestructibleTower:
			killed = collider.receive_hit_at(applied_damage, at, result.get("direction", camera.global_position.direction_to(at)))
		else:
			killed = collider.receive_hit(applied_damage)
		_confirm_impact(result, previous_armor, killed)
		if not collider is DestructibleTower and (killed or ImpactSpray.surface_for(collider) != ImpactSpray.Surface.FLESH):
			_spawn_breakup(collider, killed)
		if killed:
			flight.destroyed += 1
			if collider is GroundTurret:
				flight.turrets_destroyed += 1
			if collider is DestructibleTower:
				flight.towers_destroyed += 1
			if is_campaign:
				if collider is Asteroid:
					_resolve_asteroid(collider, false)
				elif collider is EggShip:
					campaign.stats["eggs"] += 1
					campaign.reward(8)
					if collider.infested:
						var hatchling := CanopyParasite.new()
						hatchling.launch(camera, at, -0.13 if parasites.size() % 2 == 0 else 0.19, settings["reduced_effects"])
						parasites.append(hatchling)
						hud.show_message("BROOD EGG RUPTURE / CANOPY PARASITE")
					elif collider.cargo:
						_spawn_mineral(collider.global_position, true)
				elif collider is WebNode:
					campaign.stats["webs"] += 1
					campaign.reward(15)
					hud.show_message("LASER WEB DISARMED / +15 CR")
				elif collider is RadarDish:
					campaign.stats["radars"] += 1
					var jammed: int = 0
					for turret in turrets:
						if not turret.destroyed and turret.travel >= collider.travel and turret.travel <= collider.travel + RadarDish.JAM_RANGE:
							turret.jam_tracking(RadarDish.JAM_DURATION)
							jammed += 1
					campaign.reward(60)
					hud.show_message("RADAR DESTROYED / %d DOWNSTREAM TURRETS JAMMED FOR 12s / +60 CR" % jammed)
				elif collider is PirateSkirmisher:
					campaign.stats["guardians" if collider.biological else "pirates"] += 1
					campaign.stats["enemies"] += 1
					var previous_credits: int = campaign.credits
					_award_combat_kill(PirateSkirmisher.BOUNTY)
					hud.show_message(("%s BOUNTY COLLECTED / +%d CR") % ["GUARDIAN" if collider.biological else "PIRATE", campaign.credits - previous_credits])
				elif collider is BossPart:
					if boss != null and collider.get_parent() == boss and boss.defeated() and boss.death_time < 0:
						_award_combat_kill(120)
						var bounty: int = boss.recon_bounty()
						if bounty > 0:
							campaign.reward(bounty)
							hud.show_message("INTACT TRACKING DATA / +%d CR" % bounty)
						campaign.stats["bosses"] += 1
						_start_boss_destruction()
					elif boss == null or boss.death_time < 0:
						campaign.reward(30)
						if collider is BossRadar:
							campaign.stats["radars"] += 1
						var explosion := DestructionEffect.new()
						explosion.reduced = settings["reduced_effects"]
						explosion.source = collider
						explosion.size = 4.0 if collider is BossTurret or collider is ThermalEmitter else 6.0
						add_child(explosion)
						explosions.append(explosion)
						hud.show_message("BOSS RADAR DESTROYED / TURRET INTERVAL +25% / +30 CR" if collider is BossRadar else (boss.part_label(collider) + " DESTROYED" if boss != null else "SECTION DESTROYED"))
				else:
					campaign.stats["enemies"] += 1
					_award_combat_kill(25 if collider is GroundTurret else 35 if collider is EnemyFighter and collider.has_directional_shield() else 20)
			_spawn_burst(at)
		return true
	elif collider is EnemyMissile and collider.receive_hit():
		if record_hit:
			_record_weapon_hit()
		flight.interceptions += 1
		_voice_event("interception")
		_spawn_burst(at)
		_confirm_impact(result, 0, true)
		return true
	return false

func _advance_parasites(delta: float) -> void:
	if parasites.is_empty():
		return
	var audible := false
	for i in range(parasites.size()-1, -1, -1):
		var hatchling := parasites[i]
		var bites := hatchling.advance(delta)
		if bites > 0 and flight.hull > 0:
			_apply_pilot_damage("CANOPY PARASITE", flight.max_hull * CanopyParasite.HULL_FRACTION * bites / CanopyParasite.BITES, true)
		audible = audible or hatchling.gripping()
		if hatchling.finished():
			hatchling.hide()
			hatchling.queue_free()
			parasites.remove_at(i)
	sound.set_parasite_audible(audible)

func _clear_parasites() -> void:
	for hatchling in parasites:
		hatchling.hide()
		hatchling.queue_free()
	parasites.clear()
	if sound != null:
		sound.set_parasite_audible(false)

func _confirm_impact(result: Dictionary, previous_armor: int, destroyed: bool) -> void:
	var target: Node3D = result["collider"]
	var at: Vector3 = result["position"]
	var toward_pilot := at.direction_to(camera.global_position)
	if toward_pilot.is_zero_approx():
		toward_pilot = camera.global_basis.z
	var normal: Vector3 = result.get("normal", Vector3.ZERO)
	if normal.is_zero_approx():
		normal = toward_pilot
	var surface := ImpactSpray.surface_for(target)
	var flash_color := Color("#ffc073") if surface == ImpactSpray.Surface.HULL else Color("#d5ac91") if surface == ImpactSpray.Surface.STONE else Color("#f65f65")
	combat_lights.flash(at + normal.normalized() * 1.7, flash_color, 19.0, 0.24, 3.0)
	if target is RangeTarget and not target.destroyed:
		target.mark_impact(at, -toward_pilot, surface == ImpactSpray.Surface.FLESH, previous_armor)
	if impact_sprays.size() >= ImpactSpray.MAX_BURSTS:
		impact_sprays.pop_front().queue_free()
	var spray := ImpactSpray.new()
	add_child(spray)
	var size := clampf(at.distance_to(camera.global_position) / 100.0, 1.0, 2.0)
	spray.build(at, normal.normalized(), surface, size, settings["reduced_effects"])
	impact_sprays.append(spray)
	if destroyed:
		sound.play_destruction(surface)
	else:
		sound.play_contact(surface)

func _award_combat_kill(base_credits: int) -> void:
	var previous_multiplier: int = campaign.combo_multiplier()
	campaign.record_combat_kill(base_credits)
	if campaign.combo_multiplier() > previous_multiplier:
		hud.show_message("COMBAT STREAK %dX / PROTECT YOUR HULL" % campaign.combo_multiplier())
		_voice_event("streak_ten" if campaign.combo_multiplier() == 4 else "streak_gain")

func _resolve_asteroid(rock: Asteroid, from_blast: bool) -> void:
	if rock.fragment:
		return
	_spawn_rock_fragments(rock)
	campaign.stats["asteroids"] += 1
	campaign.reward(8)
	if from_blast:
		campaign.stats["chain_rocks"] += 1
	if rock.mineral:
		_spawn_mineral(rock.global_position)
	if rock.volatile:
		var blast := VolatileBlast.new()
		blast.position = rock.global_position
		blast.detonated.connect(_detonate_volatile)
		add_child(blast)
		volatile_blasts.append(blast)
		hud.show_message("VOLATILE CORE IGNITED / CLEAR THE BLAST ZONE")

func _spawn_mineral(at: Vector3, biological: bool = false) -> void:
	if mineral_pickups.size() >= MAX_MINERAL_PICKUPS:
		mineral_pickups[0].queue_free()
		mineral_pickups.pop_front()
		hud.show_message("SALVAGE CLOUD FULL / OLDEST CORE DISPERSED")
	var pickup := MineralPickup.new()
	pickup.biological = biological
	pickup.position = at
	add_child(pickup)
	mineral_pickups.append(pickup)

func _detonate_volatile(blast: VolatileBlast) -> void:
	if not is_campaign:
		return
	if not blast.pilot_checked:
		blast.pilot_checked = true
		if camera.global_position.distance_to(blast.global_position) <= VolatileBlast.PILOT_RADIUS:
			if _apply_pilot_damage("VOLATILE BLAST", VolatileBlast.DAMAGE):
				sound.play_sound(sound.impact)
	for target in targets.duplicate():
		if not target is Asteroid or target.destroyed or target.indestructible:
			continue
		var distance: float = target.global_position.distance_to(blast.global_position)
		if distance <= VolatileBlast.ROCK_RADIUS + target.collision_radius():
			if target.receive_hit(target.armor):
				flight.destroyed += 1
				_spawn_breakup(target, true)
				_resolve_asteroid(target, true)
	sound.play_destruction(ImpactSpray.Surface.STONE)

func _advance_salvage(delta: float, previous_pilot: Vector3, pilot: Vector3) -> void:
	for i in range(volatile_blasts.size() - 1, -1, -1):
		volatile_blasts[i].advance(delta, pilot)
		if volatile_blasts[i].complete():
			volatile_blasts[i].queue_free()
			volatile_blasts.remove_at(i)
	if is_campaign and flight.hull <= 0:
		return
	for i in range(mineral_pickups.size() - 1, -1, -1):
		var pickup: MineralPickup = mineral_pickups[i]
		if pickup.advance(delta, previous_pilot, pilot, is_campaign and campaign.tractor):
			if is_campaign:
				campaign.collect_mineral()
				hud.show_message("MINERAL CORE RECOVERED / +%d CR" % MineralPickup.VALUE)
				sound.play_sound(sound.pulse)
		if not pickup.active:
			pickup.queue_free()
			mineral_pickups.remove_at(i)

func _clear_salvage() -> void:
	for pickup in mineral_pickups:
		pickup.queue_free()
	mineral_pickups.clear()
	for blast in volatile_blasts:
		blast.queue_free()
	volatile_blasts.clear()
	if hud != null:
		hud.salvage_contacts.clear()
		hud.blast_warning = false

func _start_thermal_sweep(emitter: ThermalEmitter) -> void:
	if mode != Mode.FLIGHT or not thermal_sweeps.is_empty():
		return
	var sweep := ThermalSweep.new()
	sweep.emitter = emitter
	sweep.aim = Basis.looking_at((camera.global_position - emitter.global_position).normalized(), Vector3.UP)
	add_child(sweep)
	thermal_sweeps.append(sweep)
	hud.show_message("THERMAL SWEEP CHARGING / DODGE VERTICALLY OR DESTROY THE PROJECTOR")

func _advance_thermal_hazards(delta: float, previous_pilot: Vector3, pilot: Vector3) -> void:
	var extra_heat: float = 0.0
	for vent in heat_vents:
		extra_heat += vent.advance(delta, previous_pilot, pilot)
	for i in range(thermal_sweeps.size() - 1, -1, -1):
		var sweep: ThermalSweep = thermal_sweeps[i]
		if sweep.advance(delta, previous_pilot, pilot, flight.collision_radius):
			extra_heat += ThermalSweep.HEAT
			if _apply_pilot_damage("THERMAL SWEEP", ThermalSweep.DAMAGE):
				sound.play_sound(sound.impact)
		if sweep.complete():
			sweep.queue_free()
			thermal_sweeps.remove_at(i)
	if extra_heat > 0.0 and flight.add_external_heat(extra_heat):
		hud.show_message("EXTERNAL HEAT OVERLOAD / TWO-SECOND VENT CYCLE")
		sound.play_sound(sound.hit)

func _spawn_breakup(source: Node3D, destroyed: bool) -> void:
	if source is Asteroid:
		if rock_debris.size() >= 8:
			rock_debris[0].queue_free()
			rock_debris.pop_front()
		var rocks := RockBreakup.new()
		add_child(rocks)
		rocks.build(source, destroyed)
		rock_debris.append(rocks)
		return
	if debris.size() >= 6:
		debris[0].queue_free()
		debris.pop_front()
	var effect := BreakupEffect.new()
	add_child(effect)
	var large_part: bool = source is BossPart and destroyed
	effect.build(source, destroyed, VectorArt.AMBER if source is GroundTurret or source is BossEncounter else VectorArt.CYAN,
		256 if large_part else 96, 3.2 if large_part else 2.6, 9.0 if large_part else 5.0)
	debris.append(effect)

func _advance_debris(delta: float) -> void:
	for i in range(impact_sprays.size() - 1, -1, -1):
		var spray := impact_sprays[i]
		spray.advance(delta)
		if spray.age >= ImpactSpray.LIFETIME:
			spray.queue_free()
			impact_sprays.remove_at(i)
	for i in range(rock_debris.size() - 1, -1, -1):
		rock_debris[i].advance(delta)
		if rock_debris[i].complete():
			rock_debris[i].queue_free()
			rock_debris.remove_at(i)
	for i in range(debris.size() - 1, -1, -1):
		debris[i].advance(delta)
		if debris[i].complete():
			debris[i].queue_free()
			debris.remove_at(i)

func _clear_debris() -> void:
	for spray in impact_sprays:
		spray.queue_free()
	impact_sprays.clear()
	for effect in rock_debris:
		effect.queue_free()
	rock_debris.clear()
	for fragment in rock_fragments:
		targets.erase(fragment)
		fragment.queue_free()
	rock_fragments.clear()
	for effect in debris:
		effect.queue_free()
	debris.clear()

func _spawn_rock_fragments(parent: Asteroid) -> void:
	for i in range(3):
		if rock_fragments.size() >= MAX_ROCK_FRAGMENTS:
			var oldest: Asteroid = rock_fragments.pop_front()
			oldest.destroyed = true
			oldest.collision_layer = 0
			oldest.hide()
			targets.erase(oldest)
			oldest.queue_free()
			hud.show_message("FRAGMENT CLOUD FULL / OLDEST CHUNK DISPERSED")
		var chunk := Asteroid.new()
		chunk.fragment = true
		chunk.radius = parent.radius * 0.42
		chunk.variant = (parent.variant + i) % AsteroidArt.VARIANTS
		chunk.phase = parent.phase + i * 2.1
		var direction := Vector3(cos(i * TAU / 3 + parent.phase), 0.4 * sin(i * 2.1 + 0.3), sin(i * TAU / 3 + parent.phase)).normalized()
		chunk.routed = true
		chunk.course_position = parent.global_position + direction * parent.radius * 0.5
		chunk.fragment_velocity = direction * (6 + i * 1.5)
		add_child(chunk)
		chunk.spin_rate *= 2.2
		rock_fragments.append(chunk)
		targets.append(chunk)

func _advance_rock_fragments(delta: float, previous_pilot: Vector3, pilot: Vector3) -> void:
	for i in range(rock_fragments.size() - 1, -1, -1):
		var chunk: Asteroid = rock_fragments[i]
		var before: Vector3 = chunk.global_position
		chunk.fragment_age += delta
		if not chunk.destroyed:
			chunk.global_position += chunk.fragment_velocity * delta
			var nearest: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3.ZERO, previous_pilot - before, pilot - chunk.global_position)
			if mode == Mode.FLIGHT and nearest.length() <= flight.collision_radius + chunk.collision_radius():
				if _apply_pilot_damage("ASTEROID FRAGMENT"):
					sound.play_sound(sound.impact)
				chunk.receive_hit(chunk.armor)
				_spawn_breakup(chunk, true)
		if chunk.destroyed or chunk.fragment_age >= Asteroid.FRAGMENT_LIFETIME:
			chunk.collision_layer = 0
			targets.erase(chunk)
			chunk.queue_free()
			rock_fragments.remove_at(i)

func _start_boss_destruction() -> void:
	boss.begin_destruction()
	for sweep in thermal_sweeps:
		sweep.queue_free()
	thermal_sweeps.clear()
	hud.thermal_warning = false
	var effect := DestructionEffect.new()
	effect.reduced = settings["reduced_effects"]
	effect.source = boss
	effect.size = 27.0 if boss.orbital else 22.0
	effect.fracture_requested.connect(func() -> void:
		if is_instance_valid(boss):
			combat_lights.flash(boss.global_position + Vector3.UP * 8, Color("#ff944a"), 88, 1.3, 6.0)
			var fragments := BreakupEffect.new()
			add_child(fragments)
			fragments.build(boss, true, VectorArt.AMBER, 1024, 4.0, 14.0)
			debris.append(fragments)
			sound.play_destruction(ImpactSpray.surface_for(boss.core)))
	add_child(effect)
	explosions.append(effect)
	sound.play_sound(sound.impact)

func _advance_storm(delta: float, previous: Vector3) -> void:
	var glow := 0.0
	var source := Vector3.UP
	for field in lightning_fields:
		field.reduced = settings["reduced_effects"]
		field.pilot_radius = 0.0 if flight.roll_remaining > 0.0 or god_mode else flight.collision_radius
		if field.advance(delta, previous, camera.global_position):
			if _apply_pilot_damage("STORM LIGHTNING", flight.hull + flight.shields):
				_storm_blast(camera.global_position - camera.global_basis.z * 3.0, 5.0)
		var brightness := field.cloud_brightness() * (1.0 - smoothstep(180.0, field.VIEW_RANGE, field.global_position.distance_to(camera.global_position)))
		if brightness > glow:
			glow = brightness
			source = camera.global_position.direction_to(field.to_global(field.paths[0][0]))
	var sky: ShaderMaterial = get_world_3d().environment.sky.sky_material
	sky.set_shader_parameter("storm_direction", source)
	sky.set_shader_parameter("storm_glow", glow)

func _storm_aim(field: StormLightning, cycle: int) -> void:
	# A leader picks a vicinity during warning. The actual discharge ray can
	# miss a moving fighter or be intercepted by another object on the way down.
	var kind := posmod(cycle + field.site, 4)
	if kind == 0:
		return
	var best := 125.0 * 125.0
	var candidates: Array = get_tree().get_nodes_in_group(&"offshore_platforms") if kind == 1 else towers if kind == 2 else targets
	for candidate in candidates:
		if candidate.is_queued_for_deletion() or not candidate.is_visible_in_tree():
			continue
		var at: Vector3
		if candidate is OffshorePlatform:
			at = candidate.to_global(Vector3.UP * 2.0)
		elif candidate is RangeTarget and not candidate.destroyed:
			if kind == 3 and (not candidate is EnemyFighter or candidate.expired):
				continue
			at = candidate.aim_point()
		else:
			continue
		var distance := field.global_position.distance_squared_to(at)
		if distance < best:
			best = distance
			field.landing = field.to_local(at) + Vector3.DOWN

func _storm_grounded(at: Vector3) -> void:
	combat_lights.flash(at + Vector3.UP * 4, Color("#a7caff"), 82.0, 0.43, 7.0)
	if camera.global_position.distance_to(at) < 360.0:
		sound.play_thunder()

func _storm_contact(body: CollisionObject3D, at: Vector3, direction: Vector3) -> void:
	# Weather kills never enter the player's weapon-hit and bounty pipeline.
	if body is OffshorePlatform:
		if body.collision_layer == 0:
			return
		_spawn_breakup(body, true)
		body.collision_layer = 0
		body.hide()
		_storm_blast(at, 10.0, body)
	elif body is DestructibleTower:
		if body.receive_hit_at(body.armor, at, direction):
			_storm_blast(at, 4.5, body)
	elif body is EnemyFighter or body is GroundTurret or body is RadarDish:
		if body.receive_hit(body.armor):
			_spawn_breakup(body, true)
			_storm_blast(at, 5.5, body)
	elif ground_branch != null and body == ground_branch.patrol.storm_hull:
		var patrol := ground_branch.patrol
		_spawn_breakup(patrol.carrier, true)
		_storm_blast(at, 5.5, body)
		hud.show_message(patrol.lose_carrier(campaign))

func _storm_blast(at: Vector3, radius: float, target: Node3D = null) -> void:
	var blast := DestructionEffect.new()
	blast.reduced = settings["reduced_effects"]
	blast.position = at
	blast.size = radius
	add_child(blast)
	explosions.append(blast)
	if target != null:
		sound.play_destruction(ImpactSpray.surface_for(target))
	else:
		sound.play_sound(sound.impact)

func _tower_fractured(tower: DestructibleTower) -> void:
	var effect := BreakupEffect.new()
	add_child(effect)
	effect.build(tower.fracture_source(), true, VectorArt.AMBER, 192, 3.0, 6.0)
	debris.append(effect)
	var blast := DestructionEffect.new()
	blast.reduced = settings["reduced_effects"]
	blast.position = tower.fracture_point()
	combat_lights.flash(blast.position + Vector3.UP * 2, Color("#ffaf68"), 33, 0.72, 4.5)
	blast.size = 4.0
	add_child(blast)
	explosions.append(blast)
	sound.play_sound(sound.impact)

func _advance_explosions(delta: float) -> void:
	combat_lights.advance(delta)
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i].advance(delta)
		if explosions[i].complete():
			explosions[i].queue_free()
			explosions.remove_at(i)

func fire_secondary() -> void:
	if not is_campaign or not campaign.owns_secondary(campaign.selected_secondary):
		hud.show_message("NO SECONDARY STATION / FIT ONE AT ASTRA MARKET")
		return
	var weapon: String = campaign.selected_secondary
	var cost: int = CampaignState.SECONDARIES[weapon]["ammo"]
	if not infinite_ammo and flight.ammo < cost:
		hud.show_message("INSUFFICIENT ORDNANCE / %s NEEDS %d" % [CampaignState.SECONDARIES[weapon]["name"].to_upper(), cost])
		if flight.ammo == 0:
			_voice_event("ordnance_empty")
		return
	if flight.secondary_cooldown > 0.0:
		return
	var locks: Array[RangeTarget] = []
	if weapon == "swarm":
		locks = _swarm_targets()
	if weapon == "swarm" and locks.is_empty():
		hud.show_message("NO CLEAR SWARM LOCK / FACE AN ENEMY")
		return
	var projectiles: int = 3 if weapon == "swarm" else 0 if weapon == "emp" else 1
	if torpedoes.size() + projectiles > MAX_PLAYER_ORDNANCE:
		hud.show_message("SECONDARY CHANNEL BUSY / WAIT FOR ACTIVE ROUNDS")
		return
	if not infinite_ammo:
		flight.ammo -= cost
	var shot_count: int = maxi(1, projectiles)
	flight.shots += shot_count
	campaign.stats["shots"] += shot_count
	flight.secondary_cooldown = 1.2 if weapon == "emp" else 0.8
	if weapon == "emp":
		_fire_emp()
	else:
		for i in range(projectiles):
			var torpedo := PlayerTorpedo.new()
			torpedo.position = camera.to_global(Vector3((i - 1) * 0.8 if weapon == "swarm" else 0.0, -0.35, -3.5))
			torpedo.direction = camera.project_ray_normal(cursor)
			if weapon == "swarm":
				torpedo.homing = true
				torpedo.speed = 155.0
				torpedo.homing_target = locks[i % locks.size()]
				torpedo.direction = (torpedo.homing_target.aim_point() - torpedo.position).normalized()
			var damage: int = 3 if weapon == "swarm" else 8
			torpedo.impacted.connect(func(result: Dictionary) -> void: _strike(result, damage, true))
			add_child(torpedo)
			torpedoes.append(torpedo)
		if weapon == "swarm":
			hud.show_message("SWARM AWAY / %d TARGET LOCKS / -2 ORDNANCE" % mini(3, locks.size()))
	sound.play_sound(sound.impact)
	_voice_event("ordnance_" + weapon)

func _secondary_visible(at: Vector3, radius: float, permitted_body: CollisionObject3D = null) -> bool:
	var distance: float = camera.global_position.distance_to(at)
	if distance < camera.near or distance > radius or camera.is_position_behind(at):
		return false
	if not get_viewport().get_visible_rect().has_point(camera.unproject_position(at)):
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, at, 1)
	var obstruction: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return obstruction.is_empty() or (permitted_body != null and obstruction["collider"] == permitted_body)

func _swarm_targets() -> Array[RangeTarget]:
	var locks: Array[RangeTarget] = []
	for target in targets:
		if target.destroyed or target.collision_layer == 0 or not target.guided_lockable:
			continue
		if not (target is EnemyFighter or target is GroundTurret or target is PirateSkirmisher or target is BossPart):
			continue
		if target is BossPart and not target.unlocked:
			continue
		if _secondary_visible(target.aim_point(), 450, target if target is GroundTurret else null):
			locks.append(target)
	locks.sort_custom(func(a: RangeTarget, b: RangeTarget) -> bool:
		return camera.global_position.distance_squared_to(a.aim_point()) < camera.global_position.distance_squared_to(b.aim_point()))
	return locks.slice(0, 3)

func _fire_emp() -> void:
	var cleared: int = 0
	var stunned: int = 0
	for missile in missiles:
		if missile.active and _secondary_visible(missile.global_position, EMPPulse.RANGE) and missile.receive_hit():
			cleared += 1
			_spawn_burst(missile.global_position)
			sound.play_destruction(ImpactSpray.surface_for(missile))
	for target in targets:
		if target.destroyed or target.collision_layer == 0 or not _secondary_visible(target.aim_point(), EMPPulse.RANGE, target if target is GroundTurret else null):
			continue
		if target is EnemyFighter or target is PirateSkirmisher:
			target.stun()
			stunned += 1
		elif target is GroundTurret:
			target.jam_tracking(FlightState.EMP_STUN_DURATION)
			stunned += 1
		elif target is GateEmitter:
			target.jam()
			stunned += 1
	if boss != null and not boss.defeated() and _secondary_visible(boss.core.aim_point(), EMPPulse.RANGE, boss.body):
		boss.stun()
		stunned += 1
		for sweep in thermal_sweeps:
			sweep.queue_free()
		thermal_sweeps.clear()
		hud.thermal_warning = false
	if cleared > 0 or stunned > 0:
		flight.hits += 1
		campaign.stats["hits"] += 1
		flight.hit_flash = 0.1
	flight.interceptions += cleared
	var pulse := EMPPulse.new()
	pulse.position = camera.to_global(Vector3(0, 0, -24))
	add_child(pulse)
	emp_pulses.append(pulse)
	hud.show_message("EMP NOVA / %d PROJECTILES CLEARED / %d SYSTEMS STUNNED" % [cleared, stunned])

func _advance_torpedoes(delta: float, colliding: bool = true) -> void:
	_advance_emp_pulses(delta)
	_advance_flare_clouds(delta)
	for i in range(torpedoes.size() - 1, -1, -1):
		torpedoes[i].advance(delta, colliding)
		if not torpedoes[i].active:
			torpedoes[i].queue_free()
			torpedoes.remove_at(i)

func _clear_torpedoes() -> void:
	for torpedo in torpedoes:
		torpedo.queue_free()
	torpedoes.clear()
	for pulse in emp_pulses:
		pulse.queue_free()
	emp_pulses.clear()
	for cloud in flare_clouds:
		cloud.queue_free()
	flare_clouds.clear()

func _advance_emp_pulses(delta: float) -> void:
	for i in range(emp_pulses.size() - 1, -1, -1):
		emp_pulses[i].advance(delta)
		if emp_pulses[i].complete():
			emp_pulses[i].queue_free()
			emp_pulses.remove_at(i)

func deploy_countermeasures() -> void:
	if mode != Mode.FLIGHT or not is_campaign:
		hud.show_message("COUNTERMEASURES REQUIRE ACTIVE MISSION FLIGHT")
		return
	if not campaign.countermeasures:
		hud.show_message("NO COUNTERMEASURE POD / FIT ONE AT ASTRA MARKET")
		return
	if campaign.flares <= 0:
		hud.show_message("FLARE POD EMPTY / RELOAD AT ASTRA MARKET")
		return
	if flight.countermeasure_cooldown > 0:
		hud.show_message("COUNTERMEASURES RECHARGING / %.1fs" % flight.countermeasure_cooldown)
		_voice_event("flare_cooldown")
		return
	var threats: Array[EnemyMissile] = []
	for missile in missiles:
		var relative: Vector3 = camera.global_position - missile.global_position
		if missile.active and not missile.diverted and relative.length() <= FlareCloud.RANGE and missile.direction.dot(relative.normalized()) > 0:
			threats.append(missile)
	threats.sort_custom(func(a: EnemyMissile, b: EnemyMissile) -> bool:
		return camera.global_position.distance_squared_to(a.global_position) < camera.global_position.distance_squared_to(b.global_position))
	if threats.is_empty():
		hud.show_message("NO NEARBY MISSILE LOCKS / FLARE CHARGE HELD")
		return
	var diverted: int = 0
	for i in range(mini(FlareCloud.MAX_DIVERTED, threats.size())):
		var escape: Vector3 = camera.global_basis.x * (-1 if i % 2 == 0 else 1) + camera.global_basis.y * 0.35
		if threats[i].divert(camera.global_position, escape):
			diverted += 1
	campaign.flares -= 1
	flight.countermeasure_cooldown = FlightState.COUNTERMEASURE_COOLDOWN
	flight.deflections += diverted
	var cloud := FlareCloud.new()
	add_child(cloud)
	cloud.global_transform = camera.global_transform
	cloud.carrier_velocity = -camera.global_basis.z * flight.speed
	flare_clouds.append(cloud)
	sound.play_sound(sound.hit)
	hud.show_message("CHAFF / FLARES DEPLOYED / %d MISSILES DIVERTED / %d CHARGES LEFT" % [diverted, campaign.flares])
	if diverted > 0:
		_voice_event("flare_deployed")

func _advance_flare_clouds(delta: float) -> void:
	for i in range(flare_clouds.size() - 1, -1, -1):
		flare_clouds[i].advance(delta)
		if flare_clouds[i].complete():
			flare_clouds[i].queue_free()
			flare_clouds.remove_at(i)

func _spawn_burst(at: Vector3) -> void:
	var rays := PackedVector3Array()
	for i in range(12):
		var angle: float = float(i) / 12.0 * TAU
		var direction := Vector3(cos(angle), sin(angle), sin(angle * 3.0) * 0.5)
		rays.append(at + direction * 0.5)
		rays.append(at + direction * 2.8)
	var burst := VectorArt.lines(rays, VectorArt.AMBER)
	add_child(burst)
	beams.append({"node": burst, "remaining": 0.24})

func _update_beams(delta: float) -> void:
	for i in range(beams.size() - 1, -1, -1):
		beams[i]["remaining"] -= delta
		if beams[i]["remaining"] <= 0.0:
			beams[i]["node"].queue_free()
			beams.remove_at(i)

func _clear_beams() -> void:
	combat_lights.clear()
	for beam in beams:
		beam["node"].queue_free()
	beams.clear()
	for bolt in plasma_bolts:
		bolt.queue_free()
	plasma_bolts.clear()
	if tachyon_beam != null:
		tachyon_beam.queue_free()
		tachyon_beam = null

func _launch_missile(origin: Vector3, direction: Vector3) -> void:
	if mode != Mode.FLIGHT or missiles.size() >= MAX_MISSILES:
		return
	var missile := EnemyMissile.new()
	missile.frost = is_campaign and campaign.sector == "cryo" and flight.missiles_launched % 3 == 1
	missile.biological = is_campaign and campaign.sector == "xylo"
	missile.position = origin
	missile.direction = direction
	missile.hit_pilot.connect(_missile_impact.bind(missile))
	add_child(missile)
	missiles.append(missile)
	flight.missiles_launched += 1
	_spawn_burst(origin)

func _missile_impact(missile: EnemyMissile = null) -> void:
	if flight.deflect_projectile():
		if is_instance_valid(missile):
			_spawn_burst(missile.global_position)
		hud.show_message("INCOMING MISSILE DEFLECTED")
	elif _apply_pilot_damage("MISSILE IMPACT", 18.0 if flight.training else EnemyMissile.DAMAGE):
		flight.missile_hits += 1
		if is_instance_valid(missile) and missile.frost:
			_apply_frost()
		sound.play_sound(sound.impact)

func _advance_missiles(delta: float, previous_pilot: Vector3, pilot: Vector3, dangerous: bool = true) -> void:
	for i in range(missiles.size() - 1, -1, -1):
		missiles[i].advance(delta, previous_pilot, pilot, flight.collision_radius, dangerous)
		if not missiles[i].active:
			missiles[i].queue_free()
			missiles.remove_at(i)

func _clear_missiles() -> void:
	for missile in missiles:
		missile.queue_free()
	missiles.clear()
	hud.incoming.clear()

func _update_contacts() -> void:
	var previous_vent_warning: bool = hud.vent_warning
	var previous_gate_warning: bool = hud.gate_warning
	var stealth_seen: bool = false
	hud.contacts.clear()
	hud.incoming.clear()
	hud.scan_flight_deck(camera, targets, missiles, mineral_pickups, ground_branch.supplies if ground_branch != null else [], director.tracked if is_instance_valid(director.tracked) else null)
	hud.salvage_contacts.clear()
	hud.blast_warning = false
	hud.tractor_active = false
	hud.web_warning = false
	hud.radar_jam = 0.0
	hud.thermal_warning = not thermal_sweeps.is_empty()
	hud.vent_warning = false
	hud.frost_warning = false
	hud.gate_warning = false
	hud.lightning_warning = false
	hud.acid_warning = false
	for field in xylo_fields:
		if field.kind == XyloField.Kind.ACID and (field.warning() or field.active(field.age)) and camera.global_position.distance_to(field.global_position) < 120 and not camera.is_position_behind(field.global_position):
			hud.acid_warning = true
	for gate in laser_gates:
		if (not gate.emitters[0].destroyed or not gate.emitters[1].destroyed) and camera.global_position.distance_to(gate.global_position) < 160 and not camera.is_position_behind(gate.global_position):
			hud.gate_warning = true
	for vent in heat_vents:
		if (vent.warning() or vent.erupting(vent.age)) and camera.global_position.distance_to(vent.global_position) < 120 and not camera.is_position_behind(vent.global_position):
			hud.vent_warning = true
	for frost in frost_fields:
		if (frost.warning() or frost.active(frost.age)) and camera.global_position.distance_to(frost.global_position) < 120 and not camera.is_position_behind(frost.global_position):
			hud.frost_warning = true
	for lightning in lightning_fields:
		var strike_point := lightning.to_global(lightning.landing)
		if (lightning.warning() or lightning.active(lightning.age)) and camera.global_position.distance_to(strike_point) < 240 and not camera.is_position_behind(strike_point):
			hud.lightning_warning = true
			hud.contacts.append({"screen": camera.unproject_position(strike_point + Vector3.UP * 3), "distance": camera.global_position.distance_to(strike_point), "color": VectorArt.AMBER, "label": "LIGHTNING / CLEAR STRIKE POINT"})
	for turret in turrets:
		if not turret.destroyed:
			hud.radar_jam = maxf(hud.radar_jam, turret.tracking_jammed)
	if mission_world != null:
		for web in mission_world.webs:
			if not web.disabled and camera.global_position.distance_to(web.global_position) < 120.0 and not camera.is_position_behind(web.global_position):
				hud.web_warning = true
	for target in targets:
		var distance: float = camera.position.distance_to(target.global_position)
		if target is Asteroid and (target.indestructible or distance > 140.0):
			continue
		if target is EggShip and distance > 140:
			continue
		if target.destroyed or distance < 8.0 or distance > 450.0 or camera.is_position_behind(target.global_position):
			continue
		if target is FallingIce and target.expired:
			continue
		var tint: Color = VectorArt.HOSTILE if target is GroundTurret else VectorArt.AMBER if target is BossPart and not target.core else VectorArt.CYAN
		if target is BossTurret:
			tint = VectorArt.HOSTILE
		elif target is ThermalEmitter:
			tint = Color("#ffb650")
		elif target is DroneBay:
			tint = VectorArt.HOSTILE
		elif target is BossRadar:
			tint = Color("#58f5bb")
		if target is WebNode:
			tint = VectorArt.AMBER
		elif target is RadarDish:
			tint = Color("#58f5bb")
		elif target is PirateSkirmisher:
			tint = VectorArt.HOSTILE
		if target is Asteroid or target is EggShip:
			tint = target.tint()
		if target is EnemyFighter and target.shield_blocks(camera.global_position):
			tint = Color("#52bcff")
		if not target.guided_lockable and target is EnemyFighter:
			tint = VesperaArt.SIGNAL.darkened(0.25)
			stealth_seen = stealth_seen or distance < 160
		var label: String = "SHIMMER" if not target.guided_lockable and target is EnemyFighter and distance < 160 else ("EMITTER" if distance < 160 else "") if target is GateEmitter else "DRONE BAY / STOP REINFORCEMENTS" if target is DroneBay else "THERMAL PROJECTOR" if target is ThermalEmitter else "RADAR / JAM TRACKING" if target is RadarDish else "WEB NODE" if target is WebNode else ""
		if target is PirateSkirmisher:
			label = ("GUARDIAN" if target.biological else "PIRATE") + (" / RETURNING FIRE" if target.engaged else " / OPTIONAL / 80 CR BASE")
		elif target is BossRadar:
			label = "RADAR"
		elif target is FallingIce:
			tint = VectorArt.AMBER
			label = ("RUIN" if target is RuinFall else "ICE") + (" / SHOOT OR KEEP CENTER" if target.warning() else " / FALLING / EVADE" if target.started else " / SHOOT TO CLEAR")
		elif target is EggShip:
			label = "BROOD EGG / HOLD FIRE" if target.infested else "NUTRIENT CARGO" if target.cargo else "EGG" if distance < 80 else ""
			if flight.elapsed > 12:
				_voice_event("xylo_egg")
		if target is BossPart and boss != null:
			label = boss.part_label(target)
		var contact := {"screen": camera.unproject_position(target.aim_point()), "distance": distance, "color": tint, "label": label}
		if target is BossPart:
			contact["boss_part"] = true
			contact["shielded"] = target.shield_cover != null and not target.unlocked
		hud.contacts.append(contact)
	if hud.vent_warning and not previous_vent_warning:
		_voice_event("ignis_vent")
	if hud.gate_warning and not previous_gate_warning:
		_voice_event("laser_gate")
	if stealth_seen and not voice_stealth_seen:
		_voice_event("stealth_fighter")
	voice_stealth_seen = stealth_seen
	if ground_branch != null and is_campaign and campaign.phase == "ground":
		for supply in ground_branch.supplies:
			var distance: float = camera.global_position.distance_to(supply.global_position)
			if supply.active and distance < 250 and not camera.is_position_behind(supply.global_position):
				hud.contacts.append({"screen": camera.unproject_position(supply.global_position), "distance": distance, "color": supply.color(), "label": supply.label() + " / FLY THROUGH"})
	for pickup in mineral_pickups:
		hud.tractor_active = hud.tractor_active or pickup.being_pulled
		if pickup.active and not camera.is_position_behind(pickup.global_position) and camera.position.distance_to(pickup.global_position) < 200:
			hud.salvage_contacts.append(camera.unproject_position(pickup.global_position))
	for blast in volatile_blasts:
		if not blast.fired and camera.global_position.distance_to(blast.global_position) < VolatileBlast.PILOT_RADIUS + 35.0:
			hud.blast_warning = true
	for missile in missiles:
		if missile.active and not missile.diverted:
			if camera.is_position_behind(missile.position):
				var local: Vector3 = camera.to_local(missile.position)
				var viewport: Vector2 = get_viewport().get_visible_rect().size
				hud.incoming.append(Vector2(viewport.x * (0.96 if local.x >= 0 else 0.04), viewport.y * 0.7))
			else:
				hud.incoming.append(camera.unproject_position(missile.position))

func _process(delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var frame_ms: float = float(now - last_frame_usec) / 1000.0 if last_frame_usec > 0 else 0.0
	last_frame_usec = now
	if hud == null:
		return
	if music != null and automation != "--music-test":
		var audio_mode := named_games_origin if mode == Mode.NAMED_GAMES else mode
		var scene: String = "title"
		if audio_mode == Mode.MARKET:
			scene = "station"
		elif is_campaign and campaign != null and audio_mode not in [Mode.TITLE, Mode.CAMPAIGN_COMPLETE]:
			scene = campaign.sector
		elif audio_mode in [Mode.FLIGHT, Mode.PAUSE, Mode.COMPLETE] and flight.training:
			scene = "ignis"
		music.request_scene(scene)
		music.set_paused(audio_mode in [Mode.PAUSE, Mode.DEBUG, Mode.SAVE_ERROR] or (audio_mode == Mode.TRANSITION and sequence.is_empty()))
		if automation_music and music.enabled():
			automation_music_peak = maxf(automation_music_peak, AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index(music.bus_name), 0))
	hud.fps = float(Engine.get_frames_per_second())
	if mode == Mode.TITLE:
		display_ship.rotate_object_local(Vector3.UP, delta * 0.13)
	elif mode == Mode.MARKET and station is StationHangar:
		station.advance(delta)
	if is_campaign and campaign != null:
		hud.campaign = campaign
	if boss != null and mode == Mode.FLIGHT:
		hud.objective = boss.objective()
		hud.boss_fraction = boss.health_fraction()
	var measuring_transit: bool = mode == Mode.TRANSITION and ((automation == "--launch-benchmark" and launch_approach != null) or (automation == "--orbit-benchmark" and sequence == "blockade_exit") or (automation == "--belt-benchmark" and mission_world != null and mission_world.phase == "asteroids") or (automation in ["--boss-benchmark", "--entry-benchmark"] and sequence in ["orbital_victory", "belt_transfer"]))
	var warmed: bool = flight.elapsed > 2.0 or (automation == "--launch-benchmark" and launch_approach != null and launch_approach.age > 2.0)
	if not automation.is_empty() and (mode == Mode.FLIGHT or measuring_transit) and warmed and frame_ms > 0.0:
		telemetry.append(frame_ms)
		minimum_render_size = minimum_render_size.min(get_viewport().get_texture().get_size())
		if profile_frames and frame_ms > 16.67:
			slow_frames.append({"wall": frame_ms, "physics": physics_cost_ms, "fire": fire_cost_ms, "debris": debris_cost_ms,
				"phase": campaign.phase if campaign != null else "training", "sequence": sequence, "elapsed": flight.elapsed,
				"cpu_render": RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()),
				"gpu_render": RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
				"ui_gpu": RenderingServer.viewport_get_measured_render_time_gpu(hud.instrument_viewport.get_viewport_rid()),
				"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "pieces": debris.size()})
	if not automation.is_empty():
		_run_automation(delta)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if FileAccess.file_exists("user://settings.cfg"):
		var error: Error = config.load("user://settings.cfg")
		if error != OK:
			push_error("Cannot read settings: " + error_string(error))
			hud.show_message("SETTINGS COULD NOT BE READ. DEFAULTS ARE ACTIVE.")
		else:
			for key: String in settings:
				var value: Variant = config.get_value("flight_lab", key, settings[key])
				if typeof(value) != typeof(settings[key]) or (key == "response" and (value < 0 or value > 2)) or (key in ["voice_volume", "music_volume"] and (value < 0 or value > 100)):
					push_warning("Invalid setting ignored: " + key)
					hud.show_message("INVALID SETTING: " + key.to_upper())
				else:
					settings[key] = value
	_apply_settings()

func _change_setting(key: String, value: Variant) -> void:
	settings[key] = value
	_apply_settings()
	if not automation.is_empty():
		return
	var config := ConfigFile.new()
	for name: String in settings:
		config.set_value("flight_lab", name, settings[name])
	var error: Error = config.save("user://settings.cfg")
	if error != OK:
		push_error("Cannot save settings: " + error_string(error))
		hud.show_message("SETTINGS COULD NOT BE SAVED.")

func _apply_settings() -> void:
	flight.response = FlightState.RESPONSE_RATES[int(settings["response"])]
	if is_campaign and campaign != null and not campaign.ship.is_empty():
		flight.response *= float(CampaignState.SHIPS[campaign.ship]["response"])
	VectorArt.set_reduced_effects(bool(settings["reduced_effects"]))
	combat_lights.reduced = settings["reduced_effects"]
	if ocean_material != null:
		_configure_ocean_material()
	if combat_lights.reduced:
		combat_lights.clear()
	if get_world_3d().environment != null:
		get_world_3d().environment.glow_enabled = not combat_lights.reduced
	surface_weather.configure(campaign.sector if is_campaign and campaign != null else "ignis", surface_flight, combat_lights.reduced)
	PrimaryArt.set_reduced_effects(bool(settings["reduced_effects"]))
	if launch_approach == null:
		for target in targets:
			if target is EnemyFighter and not target.destroyed and target.cloak != null:
				target.cloak.refresh()
		if boss != null and boss.death_time < 0 and boss.cloak != null:
			boss.cloak.refresh()
	AudioServer.set_bus_mute(0, bool(settings["mute"]) or not automation.is_empty())
	if computer_voice != null:
		computer_voice.set_level(int(settings["voice_volume"]), bool(settings["mute"]) or automated_session or not automation.is_empty())
	if music != null:
		if automation_music and not automation.is_empty():
			music.set_level(AmbientMusic.DEFAULT_VOLUME, false)
		else:
			music.set_level(int(settings["music_volume"]), bool(settings["mute"]) or automated_session or not automation.is_empty())

func _clear_stage() -> void:
	surface_flight = false
	surface_weather.hide()
	_clear_parasites()
	if launch_approach != null:
		launch_approach.queue_free()
		launch_approach = null
	launch_prepared = false
	camera.far = VectorArt.VIEW_DISTANCE
	if approaching_belt != null:
		approaching_belt.queue_free()
		approaching_belt = null
	if approaching_boss != null:
		approaching_boss.queue_free()
		approaching_boss = null
	if retired_world != null:
		retired_world.queue_free()
		retired_world = null
	_clear_beams()
	_clear_missiles()
	_clear_debris()
	_clear_torpedoes()
	_clear_salvage()
	for sweep in thermal_sweeps:
		sweep.queue_free()
	thermal_sweeps.clear()
	heat_vents.clear()
	frost_fields.clear()
	if not lightning_fields.is_empty():
		get_world_3d().environment.sky.sky_material.set_shader_parameter("storm_glow", 0.0)
	lightning_fields.clear()
	ocean_material = null
	falling_ice.clear()
	laser_gates.clear()
	city_traffic = null
	xylo_fields.clear()
	xylo_rovers = null
	voice_stealth_seen = false
	voice_nyx_cloaked = false
	targets.clear()
	turrets.clear()
	towers.clear()
	ground_chunks.clear()
	ground_horizon = null
	ground_branch = null
	director.ground_route = null
	for effect in explosions:
		effect.queue_free()
	explosions.clear()
	mission_world = null
	boss = null
	station = null
	hud.contacts.clear()
	hud.radar_contacts.clear()
	hud.web_warning = false
	hud.radar_jam = 0.0
	hud.thermal_warning = false
	hud.vent_warning = false
	hud.frost_warning = false
	hud.gate_warning = false
	hud.lightning_warning = false
	hud.acid_warning = false
	if world != null:
		remove_child(world)
		world.queue_free()
		world = null

func _stream_ground(distance: float) -> void:
	while not ground_chunks.is_empty() and float(ground_chunks[0].get_meta("start")) < distance - VectorArt.CHUNK_LENGTH * 3:
		ground_chunks[0].queue_free()
		ground_chunks.pop_front()
	while next_ground_chunk < distance + VectorArt.VIEW_DISTANCE + VectorArt.CHUNK_LENGTH:
		var chunk: Node3D
		if is_campaign and campaign != null and FrontierArt.is_frontier(campaign.sector):
			chunk = FrontierArt.terrain_chunk(next_ground_chunk, campaign.sector, ground_branch != null)
		elif is_campaign and campaign != null and campaign.sector == "xylo":
			chunk = XyloArt.terrain_chunk(next_ground_chunk, ground_branch != null)
		elif is_campaign and campaign != null and campaign.sector == "vespera":
			chunk = VesperaArt.terrain_chunk(next_ground_chunk, ground_branch != null)
		else:
			chunk = VectorArt.terrain_chunk(next_ground_chunk, ground_branch != null, is_campaign and campaign != null and campaign.sector == "cryo")
		chunk.set_meta("start", next_ground_chunk)
		if is_campaign:
			_add_ground_cover(chunk)
		world.add_child(chunk)
		_bind_ocean(chunk)
		ground_chunks.append(chunk)
		next_ground_chunk += VectorArt.CHUNK_LENGTH

func _add_ground_cover(chunk: Node3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1 # Shared by the swept pilot probe and missile cover ray.
	body.collision_mask = 0
	for surface in chunk.get_children():
		if surface is MultiMeshInstance3D and surface.material_override == GroundArt.foliage_material:
			continue
		var mesh: Mesh
		var transforms: Array[Transform3D] = []
		if surface is MultiMeshInstance3D:
			mesh = surface.multimesh.mesh
			transforms.assign(surface.multimesh.get_meta("placements"))
		elif surface is MeshInstance3D and surface.material_override != VectorArt.line_material:
			mesh = surface.mesh
			transforms.append(surface.transform)
		else:
			continue # Screen-space outline strokes are not solid terrain.
		if not mesh.has_meta("ground_cover"):
			var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
			shape.backface_collision = true
			mesh.set_meta("ground_cover", shape)
		if surface is MultiMeshInstance3D and campaign.sector == "thalassa":
			for placement in transforms:
				var platform := OffshorePlatform.new()
				platform.configure(mesh, placement)
				chunk.add_child(platform)
			chunk.remove_child(surface)
			surface.free()
			continue
		for placement in transforms:
			var collider := CollisionShape3D.new()
			collider.shape = mesh.get_meta("ground_cover")
			collider.transform = placement
			body.add_child(collider)
	chunk.add_child(body)

func _configure_ocean_material() -> void:
	# The orbital globe is still in the screen texture during descent. Reflect
	# local geometry once the flight scene owns the entire background.
	var reflect_scene: bool = launch_approach == null and not settings["reduced_effects"]
	ocean_material.shader = FrontierArt.WATER_REFLECTION if reflect_scene else FrontierArt.WATER
	ocean_material.set_shader_parameter("wave_time", ocean_age)

func _bind_ocean(node: Node3D) -> void:
	if ocean_material == null:
		return
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_override is ShaderMaterial and mesh.material_override.shader == FrontierArt.WATER:
			mesh.material_override = ocean_material

func _advance_ocean(delta: float) -> void:
	surface_weather.advance(delta)
	GroundArt.foliage_material.set_shader_parameter("wave_time", ocean_age + delta if ocean_material != null else surface_weather.age)
	if ocean_material == null:
		return
	ocean_age += delta
	ocean_material.set_shader_parameter("wave_time", ocean_age)
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.sky.sky_material.set_shader_parameter("weather_time", ocean_age)
	if launch_approach != null:
		for material in launch_approach.ground_shaders:
			if material.shader == FrontierArt.WATER_ARRIVAL:
				material.set_shader_parameter("wave_time", ocean_age)

func _set_ground_environment(ground: bool, update_sky: bool = true) -> void:
	surface_flight = ground
	surface_weather.configure(campaign.sector if is_campaign and campaign != null else "ignis", ground, settings["reduced_effects"])
	var icy: bool = is_campaign and campaign != null and campaign.sector == "cryo"
	var urban: bool = is_campaign and campaign != null and campaign.sector == "vespera"
	var swamp: bool = is_campaign and campaign != null and campaign.sector == "xylo"
	if update_sky:
		_set_sky_mix(1.0 if icy else 0.0, 1.0 if urban else 0.0, 1.0 if swamp else 0.0, 1.0 if is_campaign and campaign.sector == "thalassa" else 0.0, 1.0 if is_campaign and campaign.sector == "kharon" else 0.0)
		_set_sky_planet_visibility(0.0 if ground or (is_campaign and campaign != null and campaign.phase in ["market", "launch"]) else 1.0)
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.fog_enabled = ground
			child.environment.sky.sky_material.set_shader_parameter("atmosphere_mix", 1.0 if ground else 0.0)
			child.environment.fog_density = 0.0009
			child.environment.fog_light_color = _sector_fog()

func _sector_fog() -> Color:
	var sector: String = campaign.sector if is_campaign and campaign != null else "ignis"
	return {"ignis": Color("#1b1022"), "cryo": Color("#19384d"), "vespera": Color("#21102f"), "xylo": Color("#102b1c"), "thalassa": Color("#132f43"), "kharon": Color("#614329")}[sector]

func _set_sky_mix(value: float, city_value: float = 0.0, swamp_value: float = 0.0, ocean_value: float = 0.0, desert_value: float = 0.0) -> void:
	sky_icy_mix = value
	sky_city_mix = city_value
	sky_swamp_mix = swamp_value
	sky_ocean_mix = ocean_value
	sky_desert_mix = desert_value
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.sky.sky_material.set_shader_parameter("icy_mix", value)
			child.environment.sky.sky_material.set_shader_parameter("city_mix", city_value)
			child.environment.sky.sky_material.set_shader_parameter("swamp_mix", swamp_value)
			child.environment.sky.sky_material.set_shader_parameter("ocean_mix", ocean_value)
			child.environment.sky.sky_material.set_shader_parameter("desert_mix", desert_value)

func _set_sky_planet_visibility(value: float) -> void:
	sky_planet_visibility = value
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.sky.sky_material.set_shader_parameter("planet_visibility", value)

func _request_new_campaign() -> void:
	if FileAccess.file_exists(normal_save_path):
		hud.show_notice("REPLACE SAVED OPERATION?", "A new operation starts with a Rook Scout and zero credits.\nYour existing campaign checkpoint will be replaced. Training does not affect it.", [
			{"label": "CHOOSE NEW SECTOR", "action": _open_sector_map.bind(true)},
			{"label": "CANCEL", "action": show_title}])
	else:
		_open_sector_map(true)

func _open_sector_map(new_operation: bool) -> void:
	if not new_operation and (campaign == null or campaign.ship.is_empty()):
		_show_market("Obtain a replacement ship before choosing a departure.")
		return
	choosing_new_operation = new_operation
	hud.show_sector_map(null if new_operation else campaign)

func _choose_sector(destination: String) -> void:
	if not SectorCatalog.AVAILABLE.has(destination):
		hud.show_message("THAT SECTOR IS STILL IN DEVELOPMENT")
		return
	if choosing_new_operation and mode == Mode.TITLE:
		_new_campaign(destination)
	elif mode == Mode.MARKET:
		_depart_market(destination)
	else:
		hud.show_message("SECTOR SELECTION REQUIRES THE BRIEFING OR ASTRA MARKET")

func _new_campaign(destination: String = "ignis") -> void:
	if not SectorCatalog.AVAILABLE.has(destination):
		hud.show_message("THAT SECTOR IS STILL IN DEVELOPMENT")
		return
	choosing_new_operation = false
	computer_voice.stop_speech(true)
	computer_voice.pause_speech(false)
	infinite_ammo = false
	one_hit_kill = false
	store = CampaignStore.new(normal_save_path)
	var next := CampaignState.new()
	next.sector = destination
	next.phase = "launch"
	next.assisted = not automation.is_empty()
	if not automation.is_empty():
		next.ship = automation_ship
		next.primary_level = automation_primary
		next.hull = next.hull_capacity()
		next.shields = next.shield_capacity()
		if automation_tour > 1:
			print("AUTOMATION_FIXTURE: prior-tour completion baseline for capped-health playtest")
			next.tour = automation_tour
			next.replays_unlocked = true
			next.stats["sorties"] = (automation_tour - 1) * SectorCatalog.AVAILABLE.size()
			next.tour_start = next.totals()
	if _save_campaign(next, _new_campaign.bind(destination)):
		is_campaign = true
		god_mode = false
		_load_phase()

func _continue_campaign() -> void:
	computer_voice.stop_speech(true)
	computer_voice.pause_speech(false)
	infinite_ammo = false
	one_hit_kill = false
	store = CampaignStore.new(normal_save_path)
	if store.load_game() != OK:
		push_error(store.message)
		hud.show_notice("CANNOT RESUME", store.message, [{"label": "BACK", "action": show_title}])
		return
	campaign = store.state
	var migrated := store.migrated
	if migrated and not _save_campaign(campaign, _continue_campaign):
		return
	_resume_checkpoint()
	if migrated:
		hud.show_message("OLDER SAVE LOADED / EXISTING PROGRESS PRESERVED")

func _resume_checkpoint() -> void:
	is_campaign = true
	god_mode = false
	if campaign.phase == "market":
		_show_market()
		_voice_event("recovery" if campaign.last_result == "ejected" else "docking")
	else:
		_load_phase()

func _open_named_games() -> void:
	if mode not in [Mode.MARKET, Mode.PAUSE]:
		return
	named_games_origin = mode
	mode = Mode.NAMED_GAMES
	_named_games_menu()

func _named_games_menu(status: String = "") -> void:
	hud.show_named_games(store.slot_names(), is_campaign, status, _save_named_game, _request_named_load, _close_named_games)

func _close_named_games() -> void:
	mode = named_games_origin
	if mode == Mode.MARKET:
		hud.show_market(campaign)
	else:
		hud.show_menu("pause", settings)

func _save_named_game(text: String, overwrite: bool = false) -> void:
	var label := text.strip_edges()
	var slot := store.named_slot(label)
	if slot == null or not is_campaign:
		_named_games_menu("Enter a name using letters, numbers, spaces, - or _.")
		return
	if FileAccess.file_exists(slot.path) and not overwrite:
		hud.show_notice("OVERWRITE NAMED GAME?", "Replace \"%s\" with this checkpoint?" % label, [
			{"label": "OVERWRITE", "action": _save_named_game.bind(label, true)},
			{"label": "CANCEL", "action": _named_games_menu}])
		return
	# Live combat rewards must roll back with the rest of the phase on load.
	var checkpoint := CampaignStore.new(store.path)
	if checkpoint.load_game() != OK:
		_named_games_menu(checkpoint.message)
	elif slot.save_game(checkpoint.state) != OK:
		_named_games_menu(slot.message)
	else:
		_named_games_menu("Saved: " + label)

func _request_named_load(label: String) -> void:
	hud.show_notice("LOAD NAMED GAME?", "Load \"%s\" and replace the current automatic checkpoint? Unsaved flight progress will be lost." % label, [
		{"label": "LOAD GAME", "action": _load_named_game.bind(label)},
		{"label": "CANCEL", "action": _named_games_menu}])

func _load_named_game(label: String) -> void:
	var slot := store.named_slot(label)
	if slot == null or slot.load_game() != OK:
		_named_games_menu("Invalid save name." if slot == null else slot.message)
		return
	if store.save_game(slot.state) != OK:
		_named_games_menu(store.message)
		return
	computer_voice.stop_speech(true)
	computer_voice.pause_speech(false)
	zero_heat = false
	infinite_ammo = false
	one_hit_kill = false
	sequence = ""
	hud.autopilot = false
	campaign = slot.state
	if campaign.phase == "market":
		_clear_stage()
	_resume_checkpoint()

func _save_campaign(next: CampaignState, retry: Callable) -> bool:
	if store.save_game(next) != OK:
		mode = Mode.SAVE_ERROR
		_set_pointer(false)
		push_error(store.message)
		hud.show_notice("CHECKPOINT COULD NOT BE SAVED", store.message + "\nThe previous checkpoint remains in place.", [
			{"label": "RETRY SAVE", "action": retry},
			{"label": "TITLE / DISCARD UNSAVED PHASE PROGRESS", "action": show_title}])
		return false
	campaign = next
	hud.campaign = campaign
	if not store.migration_backup_path.is_empty():
		hud.show_message("PRE-UPGRADE CAMPAIGN BACKUP PRESERVED")
	return true

func _snapshot() -> CampaignState:
	var next: CampaignState = campaign.copy()
	next.hull = flight.hull
	next.shields = flight.shields
	next.ammo = flight.ammo
	next.power_mode = flight.power_mode
	return next

func _load_phase() -> void:
	mode = Mode.TRANSITION
	is_campaign = true
	sequence = ""
	docked = false
	_set_pointer(false)
	hud.show_notice("ENTERING " + campaign.phase.replace("_", " ").to_upper(), SectorCatalog.name_for(campaign.sector).to_upper() + " OPERATION / CHECKPOINT SAVED", [])
	await get_tree().process_frame
	_clear_stage()
	director = FlightDirector.new()
	_enter_phase(false)

func _enter_phase(continuous: bool) -> void:
	if campaign.phase == "launch":
		_prepare_launch()
		return
	hud.campaign = campaign
	var previous_camera: Transform3D = camera.global_transform
	var previous_flight: FlightState = flight
	var entry: Transform3D = director.frame
	var old_offset: Vector2 = flight.offset if continuous else Vector2.ZERO
	var canyon_distance: float = flight.distance if continuous else 90.0 * FlightState.SPEED
	flight = FlightState.new()
	flight.configure_campaign(campaign)
	flight.frost_slowdown = not (not automation.is_empty() and automation_frost_damage_only)
	if continuous:
		flight.inherit_evasion(previous_flight)
		flight.countermeasure_cooldown = previous_flight.countermeasure_cooldown
		flight.frost_remaining = previous_flight.frost_remaining
		flight.radar_static_remaining = previous_flight.radar_static_remaining
	flight.zero_heat = zero_heat
	flight.offset = old_offset
	_set_cockpit(campaign.ship, campaign.primary_level)
	flight.duration = FlightDirector.ASTEROID_DURATION if campaign.phase == "asteroids" else 90.0
	if campaign.phase.ends_with("_boss"):
		flight.duration = INF
	if campaign.phase == "ground_boss":
		flight.distance = canyon_distance
	if campaign.phase == "orbit":
		flight.speed = FlightDirector.DOGFIGHT_SPEED
	elif campaign.phase == "asteroids":
		flight.speed = FlightDirector.ASTEROID_SPEED
	director.begin_phase(campaign.phase, entry, flight.distance)
	hud.flight = flight
	hud.boss_fraction = -1.0
	_apply_settings()
	_set_ground_environment(campaign.phase.begins_with("ground"))
	if campaign.phase == "ground":
		if not launch_prepared:
			_build_world(false)
		launch_prepared = false
	elif campaign.phase == "ground_boss":
		falling_ice.clear()
		for gate in laser_gates:
			gate.queue_free()
		laser_gates.clear()
		for target in targets:
			target.collision_layer = 0
			target.queue_free()
		targets.clear()
		turrets.clear()
		towers.clear()
		_clear_missiles()
		if world == null:
			world = Node3D.new()
			add_child(world)
			next_ground_chunk = floorf(canyon_distance / VectorArt.CHUNK_LENGTH) * VectorArt.CHUNK_LENGTH - VectorArt.CHUNK_LENGTH
		_stream_ground(canyon_distance)
		boss = BossEncounter.new()
		boss.sector = campaign.sector
		boss.health_scale = campaign.health_multiplier()
		world.add_child(boss)
		boss.configure_pursuit(entry, canyon_distance, director.ground_course)
		boss.missile_requested.connect(_launch_missile)
		targets.assign(boss.parts)
	elif campaign.phase == "docking":
		_prepare_station()
		_begin_sequence("station_approach")
		return
	else:
		var scene: MissionWorld
		if continuous and ((campaign.phase == "asteroids" and approaching_belt != null) or (campaign.phase == "orbit_boss" and approaching_boss != null)):
			if campaign.phase == "orbit_boss":
				scene = approaching_boss
				approaching_boss = null
			else:
				scene = approaching_belt
				approaching_belt = null
			var previous_world: Node3D = world
			world = null
			_clear_stage()
			retired_world = previous_world
		else:
			if continuous:
				_clear_stage()
			scene = MissionWorld.new()
			scene.health_scale = campaign.health_multiplier()
			add_child(scene)
			scene.missile_requested.connect(_launch_missile)
			scene.sweep_requested.connect(_start_thermal_sweep)
			scene.build(campaign.phase, director.origin, campaign.sector)
		world = scene
		mission_world = scene
		targets = scene.targets
		boss = scene.boss
	var titles: Dictionary = {"ground": "GROUND ASSAULT / " + SectorCatalog.name_for(campaign.sector).to_upper(), "ground_boss": SectorCatalog.GROUND_BOSSES[campaign.sector].to_upper() + " / PURSUIT", "orbit": "ORBITAL DOGFIGHT / AUTO TRACKING", "orbit_boss": SectorCatalog.ORBITAL_BOSSES[campaign.sector].to_upper() + " / PURSUIT", "asteroids": "ASTEROID ESCAPE / AVOIDANCE ONLINE"}
	hud.phase_title = titles[campaign.phase]
	if campaign.phase == "asteroids" and campaign.sector == "xylo":
		hud.phase_title = "HIVE FLEET / EGG-SHIP SURVIVAL"
	hud.objective = "GOLD: MINE / CYAN: COLLECT / VIOLET: VOLATILE / RUST: EVADE" if campaign.phase == "asteroids" else "WEB NODES: SHOOT OR DODGE / RED RADAR: HOSTILES" if campaign.phase == "orbit" else "RADARS JAM TURRETS / AIM HIGH TO SHEAR A TOWER"
	if campaign.phase == "asteroids" and campaign.sector == "xylo":
		hud.objective = "DODGE EGG SHIPS / GOLD CARGO / GUARDIANS RETALIATE IF ATTACKED"
	display_ship.hide()
	if not continuous:
		cursor = get_viewport().get_visible_rect().size * 0.5
	fire_armed = false
	_update_camera()
	if continuous:
		largest_phase_jump = maxf(largest_phase_jump, previous_camera.origin.distance_to(camera.global_position))
		largest_phase_turn = maxf(largest_phase_turn, previous_camera.basis.get_rotation_quaternion().angle_to(camera.global_basis.get_rotation_quaternion()))
	phase_log.append(campaign.phase)
	print("PHASE_ENTERED ", campaign.phase)
	mode = Mode.FLIGHT
	resume_mode = Mode.FLIGHT
	hud.autopilot = false
	sequence = ""
	hud.show_menu("flight", settings)
	_set_pointer(true, not continuous)
	sound.stop_all()
	sound.pause_sounds(false)
	computer_voice.pause_speech(false)
	if campaign.phase.ends_with("_boss"):
		_voice_event("recon_" + campaign.sector + ("_orbit" if boss.orbital else "_ground"))
	elif campaign.phase == "ground" and campaign.sector in ["ignis", "vespera", "xylo"]:
		_voice_event(campaign.sector + "_arrival")
	elif campaign.phase == "asteroids" and campaign.sector == "xylo":
		_voice_event("xylo_hive")
	if automation.is_empty() and DisplayServer.get_name() != "headless" and not get_window().has_focus():
		pause_flight()
	if not automation.is_empty() and not screenshot_directory.is_empty():
		await get_tree().process_frame
		await _capture("phase-" + campaign.phase + ".png")

func _finish_phase() -> void:
	if not is_campaign:
		return
	var previous_phase: String = campaign.phase
	print("PHASE_FINISHED ", previous_phase, " active_seconds=", flight.elapsed)
	var next: CampaignState = _snapshot()
	var index: int = CampaignState.PHASES.find(previous_phase)
	next.phase = CampaignState.PHASES[index + 1]
	next.shields = next.shield_capacity()
	if not _save_campaign(next, _finish_phase):
		return
	_disarm_primary()
	match previous_phase:
		"ground": _enter_phase(true)
		"ground_boss": _begin_sequence("ground_victory")
		"orbit": _begin_sequence("blockade_exit")
		"orbit_boss": _begin_sequence("orbital_victory")
		"asteroids": _begin_sequence("belt_exit")

func _begin_sequence(kind: String) -> void:
	_disarm_primary()
	sequence = kind
	sequence_time = 0.0
	var duration: float = TRANSIT_LEGS[kind]
	transit_time_at_leg_start = duration
	var leg := kind
	while NEXT_LEG.has(leg):
		leg = NEXT_LEG[leg]
		transit_time_at_leg_start += TRANSIT_LEGS[leg]
	hud.transit_seconds = ceili(transit_time_at_leg_start)
	mode = Mode.TRANSITION
	hud.autopilot = true
	hud.boss_fraction = -1.0
	hud.show_menu("flight", settings)
	hud.phase_title = kind.replace("_", " ").to_upper()
	hud.objective = "FLIGHT COMPUTER / AUTOMATIC TRANSIT"
	sequence_log.append(kind)
	print("FLIGHT_SEQUENCE ", kind)
	var end: Transform3D = director.frame
	match kind:
		"station_departure":
			end = station.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 180))
			director.begin_transition(end, duration, 0, 36)
			hud.objective = "UNDOCKING / CLEARING ASTRA'S OUTER RING"
		"warp_alignment":
			director.begin_transition(launch_approach.alignment_frame, duration, 36, 180, false)
			hud.objective = "CLIMBING CLEAR OF ASTRA / HYPERDRIVE CHARGING"
		"hyperspace":
			director.begin_transition(launch_approach.descent_frame, duration, 180, 180, false)
			hud.objective = "HYPERSPACE / " + SectorCatalog.name_for(campaign.sector).to_upper() + " INBOUND"
			sound.play_sound(sound.warp)
		"planet_descent":
			end = director.ground_course * FlightState.rail_frame(0)
			director.begin_transition(end, duration, 180, FlightState.SPEED)
			hud.objective = "ATMOSPHERIC DESCENT / CANYON APPROACH"
		"ground_victory":
			director.begin_transition(end, duration, 0, 0)
			hud.objective = "HOLDING ON TARGET / CONFIRMING DESTRUCTION"
		"orbital_victory":
			end.origin -= end.basis.z * FlightState.SPEED * duration
			director.begin_transition(end, duration, FlightState.SPEED, FlightState.SPEED)
			hud.objective = "REACTOR CASCADE / CLEARING THE WRECKAGE"
			_prepare_belt(end)
		"ascent":
			end.origin += -end.basis.z * 620.0 + Vector3.UP * 560.0
			director.begin_transition(end, duration, flight.speed, FlightDirector.DOGFIGHT_SPEED)
			hud.objective = "CLIMBING THROUGH THE ATMOSPHERE / ORBIT AHEAD"
		"blockade_exit":
			mission_world.pending_webs = 0
			for web in mission_world.webs:
				web.disarm()
			hud.web_warning = false
			for target in targets:
				if target is EnemyFighter and not target.destroyed:
					target.spawn_position = target.global_position
					target.age = 0
					target.motion_age = 0
					target.velocity = -director.frame.basis.z * 90.0
					target.lifetime = 5.0
			end = FlightDirector.orbital_boss_entry(director.frame)
			approaching_boss = MissionWorld.new()
			approaching_boss.health_scale = campaign.health_multiplier()
			add_child(approaching_boss)
			approaching_boss.missile_requested.connect(_launch_missile)
			approaching_boss.sweep_requested.connect(_start_thermal_sweep)
			approaching_boss.build("orbit_boss", end, campaign.sector)
			director.begin_transition(end, duration, FlightDirector.DOGFIGHT_SPEED, FlightState.SPEED)
			hud.objective = "CAPITAL SHIP DETECTED / TURNING ONTO INTERCEPT COURSE"
		"belt_transfer":
			director.begin_transition(belt_entry, duration, FlightState.SPEED, FlightDirector.ASTEROID_SPEED)
			hud.objective = "PULLING UP INTO THE HIVE FLEET / SAFE CORRIDOR" if campaign.sector == "xylo" else "PULLING UP INTO THE BELT / COMPUTING A SAFE CORRIDOR"
		"belt_exit":
			for pirate in mission_world.pirates:
				pirate.retire()
			_clear_salvage()
			_clear_torpedoes()
			_prepare_station(true)
			hud.objective = "CLEARING THE LAST EGG SHIPS / ASTRA BEACON ACQUIRED" if campaign.sector == "xylo" else "CLEARING THE LAST ROCKS / ASTRA BEACON ACQUIRED"
		"belt_climb":
			end = station.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, 430))
			director.begin_transition(end, duration, FlightDirector.ASTEROID_SPEED, FlightDirector.ASTEROID_SPEED)
			hud.objective = "PULLING UP OUT OF THE BELT / ASTRA STATION AHEAD"
		"station_approach":
			end = station.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, 85))
			director.begin_transition(end, duration, FlightDirector.ASTEROID_SPEED, 18.0)
			hud.objective = "DOCKING CLEARANCE RECEIVED / ALIGNING WITH BAY"
		"docking":
			end = station.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -12))
			director.begin_transition(end, duration, 18.0, 0.0, false)
			hud.objective = "AUTODOCK ENGAGED / TURNING INTO THE DEPARTURE BERTH"

func _advance_sequence(delta: float) -> void:
	var duration: float = TRANSIT_LEGS[sequence]
	var carry: float = maxf(0.0, sequence_time + delta - duration)
	# Land exactly on the endpoint even when fixed ticks sum just short of it.
	if sequence_time + delta >= duration - 0.0000001:
		delta = duration - sequence_time
	if not parasites.is_empty():
		_advance_parasites(delta)
		if flight.hull <= 0:
			sequence = ""
			_eject.call_deferred()
			return
	sequence_time += delta
	hud.transit_seconds = ceili(snappedf(transit_time_at_leg_start - sequence_time, 0.0000001))
	if station is StationHangar:
		station.advance(delta)
	flight.advance_primary(delta, false)
	flight.frost_remaining = maxf(0, flight.frost_remaining - delta)
	flight.radar_static_remaining = maxf(0, flight.radar_static_remaining - delta)
	if flight.frost_remaining < 0.000001:
		flight.frost_remaining = 0.0
	flight.countermeasure_cooldown = maxf(0, flight.countermeasure_cooldown - delta)
	var recenter_time: float = flight.advance_evasion(delta)
	var previous: Vector3 = director.frame.origin
	var previous_transition_time: float = director.transition_time
	var finished: bool
	if sequence == "ground_victory":
		# Brake over the first second, leaving the wreck at a safe viewing distance.
		var before := maxf(0.0, 1.0 - (sequence_time - delta))
		var after := maxf(0.0, 1.0 - sequence_time)
		flight.distance += 0.5 * FlightState.SPEED * (before * before - after * after)
		director.frame = director.ground_course * FlightState.rail_frame(flight.distance)
		finished = sequence_time >= duration
	elif sequence == "belt_exit":
		flight.distance += FlightDirector.ASTEROID_SPEED * delta
		director.frame = director.origin * FlightDirector.asteroid_frame(flight.distance)
		finished = sequence_time >= duration
	else:
		finished = director.advance_transition(delta)
	flight.speed = director.frame.origin.distance_to(previous) / delta
	hud.boss_fraction = sequence_time / duration
	flight.offset.x = lerpf(flight.offset.x, 0.0, 1.0 - exp(-recenter_time * 1.5))
	flight.offset.y = lerpf(flight.offset.y, 0.0, 1.0 - exp(-delta * 1.5))
	if sequence == "ascent":
		var fraction: float = sequence_time / FlightDirector.ASCENT_DURATION
		_set_sky_planet_visibility(smoothstep(0.15, 0.9, fraction))
		for child in get_children():
			if child is WorldEnvironment:
				child.environment.fog_density = 0.0009 + sin(fraction * PI) * 0.009
				child.environment.sky.sky_material.set_shader_parameter("atmosphere_mix", 1.0 - clampf(fraction, 0, 1))
				child.environment.fog_light_color = _sector_fog().lerp(Color("#05060b"), fraction)
		if fraction > 0.88:
			world.hide()
	if sequence == "docking":
		_set_sky_planet_visibility(1.0 - smoothstep(0, FlightDirector.DOCK_DURATION, sequence_time))
	if sequence == "ground_victory":
		_stream_ground(flight.distance)
	if sequence in ["ground_victory", "ascent"]:
		_advance_ocean(delta)
		if xylo_rovers != null:
			xylo_rovers.advance(delta)
		for field in xylo_fields:
			field.advance(delta, director.frame.origin, director.frame.origin)
		if city_traffic != null:
			city_traffic.advance(delta, flight.distance)
		for vent in heat_vents:
			vent.advance(delta, director.frame.origin, director.frame.origin)
		for frost in frost_fields:
			frost.advance(delta, director.frame.origin, director.frame.origin)
	if mission_world != null and mission_world.phase == "asteroids":
		_advance_rock_fragments(delta, camera.global_position, director.frame.origin)
		mission_world.advance(delta, director.frame)
	if approaching_belt != null:
		approaching_belt.animate_belt(delta, director.frame)
	if approaching_boss != null:
		approaching_boss.boss.advance_visuals(director.transition_time - previous_transition_time)
	if sequence in ["blockade_exit", "orbital_victory", "belt_transfer"]:
		for target in targets:
			if target is EnemyFighter:
				target.advance(delta, director.frame.origin, Vector3.ZERO)
	if boss != null:
		boss.advance(delta, director.frame.origin, (director.frame.origin - previous) / delta)
	_advance_missiles(delta, previous, director.frame.origin, false)
	_advance_debris(delta)
	_advance_explosions(delta)
	_update_beams(delta)
	_advance_torpedoes(delta, false)
	_advance_plasma(delta)
	for tower in towers:
		tower.advance(delta)
	_update_camera()
	if boss != null and not boss.orbital and boss.death_time >= 0 and sequence in ["ground_victory", "ascent"]:
		var weight := smoothstep(0.0, 0.45, sequence_time) if sequence == "ground_victory" else 1.0 - smoothstep(0.0, 0.9, sequence_time)
		if weight > 0:
			var aim := camera.global_position.direction_to(boss.model.global_position)
			if aim.length_squared() > 0.0 and absf(aim.dot(director.ground_course.basis.y)) < 0.999:
				var toward_wreck := Basis.looking_at(aim, director.ground_course.basis.y)
				camera.global_basis = camera.global_basis.slerp(toward_wreck, weight)
	if launch_approach != null:
		_advance_ocean(delta)
		if xylo_rovers != null:
			xylo_rovers.advance(delta)
		if city_traffic != null:
			city_traffic.advance(delta, 0)
		var destination_mix: float = 1.0 if campaign.sector == "cryo" else 0.0
		var destination_city: float = 1.0 if campaign.sector == "vespera" else 0.0
		var destination_swamp: float = 1.0 if campaign.sector == "xylo" else 0.0
		var destination_ocean: float = 1.0 if campaign.sector == "thalassa" else 0.0
		var destination_desert: float = 1.0 if campaign.sector == "kharon" else 0.0
		if sequence == "hyperspace":
			var progress: float = smoothstep(0, LaunchApproach.HYPERSPACE_DURATION, sequence_time)
			_set_sky_mix(lerpf(launch_sky_start, destination_mix, progress), lerpf(launch_city_start, destination_city, progress), lerpf(launch_swamp_start, destination_swamp, progress), lerpf(launch_ocean_start, destination_ocean, progress), lerpf(launch_desert_start, destination_desert, progress))
		elif sequence == "planet_descent":
			_set_sky_mix(destination_mix, destination_city, destination_swamp, destination_ocean, destination_desert)
		var intensity: float = sin(clampf(sequence_time / LaunchApproach.HYPERSPACE_DURATION, 0, 1) * PI) if sequence == "hyperspace" else 0.0
		var descent: float = clampf(sequence_time / FlightDirector.DESCENT_DURATION, 0, 1) if sequence == "planet_descent" else 0.0
		var planet_reveal: float = smoothstep(0, 2.4, sequence_time) if sequence == "planet_descent" else 0.0
		var ground_reveal: float = launch_approach.terrain_reveal(camera.global_transform) if sequence == "planet_descent" else 0.0
		launch_approach.advance(delta, intensity, planet_reveal, ground_reveal, camera.global_transform)
		if sequence == "planet_descent":
			if ground_reveal == 1.0 and launch_approach.curvature == 0.0:
				launch_approach.restore_ground()
			camera.far = lerpf(LaunchApproach.VIEW_DISTANCE, VectorArt.VIEW_DISTANCE, smoothstep(0.1, 0.85, descent))
			for child in get_children():
				if child is WorldEnvironment:
					child.environment.fog_enabled = true
					child.environment.sky.sky_material.set_shader_parameter("atmosphere_mix", smoothstep(0.15, 0.8, descent))
					child.environment.fog_density = 0.0009 * smoothstep(0, 1, descent)
					child.environment.fog_light_color = _sector_fog()
	hud.contacts.clear()
	hud.radar_contacts.clear()
	hud.incoming.clear()
	if finished:
		var ended: String = sequence
		sequence = ""
		if NEXT_LEG.has(ended):
			_begin_sequence(NEXT_LEG[ended])
			if carry > 0.0000001:
				_advance_sequence(carry)
			return
		match ended:
			"planet_descent": _finish_launch()
			"ascent", "blockade_exit", "belt_transfer": _enter_phase(true)
			"docking": _complete_docking()

func _prepare_launch(reuse_station: bool = false) -> void:
	launch_sky_start = sky_icy_mix
	launch_city_start = sky_city_mix
	launch_swamp_start = sky_swamp_mix
	launch_ocean_start = sky_ocean_mix
	launch_desert_start = sky_desert_mix
	var departure_world: Node3D
	var departure_station: Node3D
	var start: Transform3D
	if reuse_station and is_instance_valid(station):
		departure_world = world
		departure_station = station
		start = camera.global_transform
		world = null
		_clear_stage()
	else:
		_clear_stage()
		departure_world = Node3D.new()
		add_child(departure_world)
		departure_station = MissionWorld.station()
		departure_world.add_child(departure_station)
		departure_station.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2200, 11000))
		start = departure_station.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -12))
	director = FlightDirector.new()
	director.frame = start
	flight = FlightState.new()
	flight.configure_campaign(campaign)
	flight.duration = INF
	flight.speed = 0
	flight.zero_heat = zero_heat
	hud.flight = flight
	hud.campaign = campaign
	_set_cockpit(campaign.ship, campaign.primary_level)
	_apply_settings()
	launch_approach = LaunchApproach.new()
	launch_approach.sector = campaign.sector
	add_child(launch_approach)
	launch_approach.configure(departure_station.global_transform)
	director.ground_course = launch_approach.ground_course
	_build_world(false)
	launch_approach.attach_ground(world, ground_horizon)
	retired_world = departure_world
	station = departure_station
	launch_prepared = true
	camera.far = LaunchApproach.VIEW_DISTANCE
	_set_ground_environment(false, false)
	_set_sky_planet_visibility(0)
	cursor = get_viewport().get_visible_rect().size * 0.5
	fire_armed = false
	display_ship.hide()
	docked = false
	_update_camera()
	_set_pointer(true, true)
	phase_log.append("launch")
	print("PHASE_ENTERED launch")
	sound.stop_all()
	sound.pause_sounds(false)
	_begin_sequence("station_departure")
	computer_voice.pause_speech(false)
	_voice_event("rescue_launch" if campaign.ship == "emergency" else ["primary_pulse", "primary_quad", "primary_tachyon"][campaign.primary_level])

func _finish_launch() -> void:
	var next: CampaignState = _snapshot()
	next.phase = "ground"
	if not _save_campaign(next, _finish_launch):
		return
	launch_approach.restore_ground()
	launch_approach.queue_free()
	launch_approach = null
	station = null
	camera.far = VectorArt.VIEW_DISTANCE
	_enter_phase(true)
	cursor = get_viewport().get_visible_rect().size * 0.5
	_set_pointer(true, true)

func _prepare_belt(clearance_end: Transform3D) -> void:
	var heading := Vector3(-clearance_end.basis.z.x, 0, -clearance_end.basis.z.z).normalized()
	# Anchor the preview to the reveal point, not the end of the timed wreckage coast.
	# The near side of the giant belt can protrude over 250 m before its entry frame.
	belt_entry = Transform3D(Basis.looking_at(heading), director.frame.origin + heading * (VectorArt.VIEW_DISTANCE + 320.0) + Vector3.UP * 550)
	var origin: Transform3D = belt_entry * Transform3D(FlightDirector.asteroid_frame(0).basis.inverse(), Vector3.ZERO)
	approaching_belt = MissionWorld.new()
	approaching_belt.health_scale = campaign.health_multiplier()
	add_child(approaching_belt)
	approaching_belt.missile_requested.connect(_launch_missile)
	approaching_belt.sweep_requested.connect(_start_thermal_sweep)
	var arrival: PackedVector3Array = FlightDirector.transition_path(clearance_end, belt_entry, FlightDirector.BELT_TRANSFER_DURATION, FlightState.SPEED, FlightDirector.ASTEROID_SPEED)
	approaching_belt.build("asteroids", origin, campaign.sector, arrival)

func _prepare_station(preserve_belt: bool = false) -> void:
	var entry: Transform3D = director.frame
	if not preserve_belt:
		_clear_stage()
		world = Node3D.new()
		add_child(world)
	station = MissionWorld.station()
	world.add_child(station)
	station.global_transform = FlightDirector.asteroid_station(director.origin, flight.distance) if preserve_belt else entry * Transform3D(Basis.IDENTITY, Vector3(0, 0, -500))
	docked = false
	display_ship.hide()
	_set_ground_environment(false)
	phase_log.append("docking")

func _complete_docking() -> void:
	var next: CampaignState = _snapshot()
	next.dock(true)
	if not _save_campaign(next, _complete_docking):
		return
	docked = true
	flight.offset = Vector2.ZERO
	flight.speed = 0.0
	print("DOCKING_COMPLETE local_position=", station.to_local(camera.global_position))
	_show_market()
	_voice_event("docking")

func _eject() -> void:
	_clear_parasites()
	sequence = ""
	var next: CampaignState = _snapshot()
	next.eject()
	if not _save_campaign(next, _eject):
		return
	mode = Mode.TRANSITION
	_set_pointer(false)
	_voice_event("ejection")
	hud.show_notice("PILOT EJECTED / POD TELEPORTING", "Your ship and fitted equipment are lost.\nEarned credits are retained. Astra recovery is standing by.", [])
	if not automation.is_empty():
		await _capture("ejection.png")
	await get_tree().create_timer(1.8).timeout
	_show_market()

func _show_market(error: String = "") -> void:
	_clear_parasites()
	computer_voice.pause_speech(false)
	_set_cockpit(campaign.ship, campaign.primary_level)
	if station == null:
		_clear_stage()
		world = Node3D.new()
		add_child(world)
		station = MissionWorld.station()
		station.position = Vector3(28, 15, -80)
		world.add_child(station)
		camera.global_transform = station.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -12))
		director.frame = camera.global_transform
		docked = true
	if phase_log.is_empty() or phase_log[-1] != "market":
		phase_log.append("market")
	mode = Mode.MARKET
	is_campaign = true
	display_ship.hide()
	_set_pointer(false)
	_set_ground_environment(false)
	sound.stop_all()
	if not campaign.tour_result.is_empty():
		_show_campaign_result()
	else:
		hud.show_market(campaign, error)

func _show_campaign_result() -> void:
	mode = Mode.CAMPAIGN_COMPLETE
	sequence = ""
	hud.autopilot = false
	_set_pointer(false)
	sound.stop_all()
	computer_voice.stop_speech(true)
	hud.show_campaign_result(campaign.tour_result, [
		{"label": "CONTINUE / BEGIN TOUR %d" % (campaign.tour + 1), "action": _confirm_next_tour},
		{"label": "RETIRE / RECORD AND RETURN TO TITLE", "action": _retire_campaign},
		{"label": "HALL OF FAME", "action": _show_hall_of_fame},
		{"label": "HOW RANKS ARE CALCULATED", "action": _show_rank_rules}
	], campaign.sector)

func _show_rank_rules() -> void:
	var ladder: Array[String] = []
	for i in range(CampaignHonors.RANKS.size()):
		ladder.append("%d: %s" % [CampaignHonors.THRESHOLDS[i], CampaignHonors.RANKS[i]])
	hud.show_notice("CAMPAIGN RATING / 1000 POINTS", "Accuracy: up to 300 (hit ratio; at least 20 shots).\nCombat: up to 300 (100,000 combat score reaches the cap).\nSurvival: 250 minus 75 per ejection and 1 per 4 hull damage; minimum zero.\nStreak: 6 per best consecutive kill, capped at 150 (25 kills).\nOnly this tour counts. Spending never lowers your rank.\nLegacy damage is unknown: no survival points until a fully tracked tour.\n\n" + "\n".join(ladder), [{"label": "BACK TO CAMPAIGN DEBRIEF", "action": _show_campaign_result}])

func _confirm_next_tour() -> void:
	var health: float = 100 * (1.0 + 0.25 * mini(campaign.tour, 4))
	hud.show_notice("BEGIN TOUR %d?" % (campaign.tour + 1), "Record this completed tour and begin a new six-world tour with fresh clears/statistics.\nKeep your ship, upgrades, credits, ammunition, lifetime totals and replay access.\nEnemy and boss health: %.0f%% (rounded up to whole hit points).\nFlight speed, enemy damage, projectiles, hazards, timers and rewards are unchanged." % health, [
		{"label": "RECORD RESULT AND BEGIN NEXT TOUR", "action": _begin_next_tour},
		{"label": "CANCEL", "action": _show_campaign_result}
	])

func _hall_store() -> HallOfFameStore:
	return HallOfFameStore.new("user://hall_of_fame.json" if store.path == "user://campaign.json" else store.path + ".hall-of-fame.json")

func _record_completed_tour(retry: Callable) -> bool:
	var hall: HallOfFameStore = _hall_store()
	if hall.record_tour(campaign.tour_result) == OK:
		return true
	mode = Mode.SAVE_ERROR
	push_error(hall.message)
	hud.show_notice("RESULT COULD NOT BE RECORDED", hall.message + "\nYour completed campaign checkpoint is retained.", [
		{"label": "RETRY", "action": retry},
		{"label": "BACK TO COMPLETED CAMPAIGN", "action": _show_campaign_result}
	])
	return false

func _retire_campaign() -> void:
	if _record_completed_tour(_retire_campaign):
		show_title()
		hud.show_message("RESULT RECORDED / COMPLETED CAMPAIGN REMAINS RESUMABLE")

func _begin_next_tour() -> void:
	var next: CampaignState = campaign.copy()
	var error: String = next.continue_tour()
	if not error.is_empty():
		hud.show_message(error)
		return
	if not _record_completed_tour(_begin_next_tour):
		return
	if _save_campaign(next, _begin_next_tour):
		_show_market()
		hud.show_message("TOUR %d READY / CHOOSE A SECTOR WHEN EQUIPPED" % campaign.tour)

func _show_hall_of_fame(assisted_records: bool = false) -> void:
	var back: Callable = _show_campaign_result if is_campaign and not campaign.tour_result.is_empty() else show_title
	var hall: HallOfFameStore = _hall_store()
	if hall.load_records() != OK:
		push_error(hall.message)
		hud.show_notice("HALL OF FAME NEEDS ATTENTION", hall.message + "\nExisting records have not been changed.", [{"label": "BACK", "action": back}])
		return
	hud.show_hall_of_fame(hall.ranked(assisted_records), assisted_records, back, _show_hall_of_fame.bind(not assisted_records))

func _market_purchase(item: String) -> void:
	var next: CampaignState = campaign.copy()
	var error: String = next.purchase(item)
	if not error.is_empty():
		_show_market(error)
		return
	if _save_campaign(next, func() -> void: _market_purchase(item)):
		_show_market()
		if item == "emergency":
			_voice_event("rescue_purchased")
		elif item == "primary":
			computer_voice.cancel_group("primary")
			_voice_event(["primary_pulse", "primary_quad", "primary_tachyon"][campaign.primary_level])
		elif item not in ["ammo", "flare_reload"]:
			_voice_event("upgrade")

func _select_secondary(weapon: String) -> void:
	if not is_campaign or mode not in [Mode.PAUSE, Mode.MARKET]:
		hud.show_message("SWITCH WEAPON STATIONS WHILE PAUSED OR DOCKED")
		return
	if mode == Mode.MARKET:
		var next: CampaignState = campaign.copy()
		var error: String = next.select_secondary(weapon)
		if not error.is_empty():
			_show_market(error)
		elif _save_campaign(next, func() -> void: _select_secondary(weapon)):
			_show_market()
	else:
		var error: String = campaign.select_secondary(weapon)
		if not error.is_empty():
			hud.show_message(error)
			return
		hud.show_menu("pause", settings)
		hud.show_message("%s SELECTED / %d ORDNANCE PER USE" % [CampaignState.SECONDARIES[weapon]["name"].to_upper(), CampaignState.SECONDARIES[weapon]["ammo"]])

func _depart_market(destination: String) -> void:
	var next: CampaignState = campaign.copy()
	var error: String = next.depart(destination)
	if not error.is_empty():
		_show_market(error)
		return
	if _save_campaign(next, _depart_market.bind(destination)):
		_prepare_launch(true)

func _toggle_debug() -> void:
	if mode == Mode.DEBUG:
		_debug_action("close")
	elif mode in [Mode.FLIGHT, Mode.PAUSE, Mode.MARKET, Mode.TITLE]:
		debug_previous = mode
		mode = Mode.DEBUG
		_set_pointer(false)
		sound.pause_sounds(true)
		computer_voice.pause_speech(true)
		hud.show_debug(god_mode, zero_heat, infinite_ammo, one_hit_kill)

func _debug_action(action: String) -> void:
	if action == "close":
		if debug_previous == Mode.MARKET:
			_show_market()
		elif debug_previous == Mode.FLIGHT:
			mode = Mode.PAUSE
			resume_flight()
		elif debug_previous == Mode.PAUSE:
			mode = Mode.PAUSE
			hud.show_menu("pause", settings)
		else:
			show_title()
		return
	var known: bool = action in ["credits", "credits_large", "reset_credits", "refill", "max", "god", "zero_heat", "infinite_ammo", "one_hit", "kill_boss", "rook", "hawk"]
	var sector_warp: bool = action.begins_with("sector:") and SectorCatalog.AVAILABLE.has(action.trim_prefix("sector:"))
	if not known and not sector_warp and not (action.begins_with("phase:") and CampaignState.PHASES.has(action.trim_prefix("phase:"))):
		hud.show_message("UNKNOWN DEVELOPER ACTION")
		return
	if action == "kill_boss" and (boss == null or boss.defeated()):
		hud.show_message("NO ACTIVE BOSS TO DEFEAT")
		return
	var new_debug_mission: bool = not is_campaign
	if new_debug_mission:
		store = CampaignStore.new("user://debug_campaign.json" if automation.is_empty() else normal_save_path)
		campaign = CampaignState.new()
		is_campaign = true
	var next: CampaignState = campaign.copy() if new_debug_mission or mode == Mode.MARKET or debug_previous == Mode.MARKET else _snapshot()
	if not next.tour_result.is_empty():
		hud.show_message("CONTINUE TO THE NEXT TOUR BEFORE CHANGING A COMPLETED RESULT")
		return
	var next_god: bool = not god_mode if action == "god" else god_mode
	var next_zero_heat: bool = not zero_heat if action == "zero_heat" else zero_heat
	var next_infinite_ammo: bool = not infinite_ammo if action == "infinite_ammo" else infinite_ammo
	var next_one_hit: bool = not one_hit_kill if action == "one_hit" else one_hit_kill
	next.assisted = true
	if next.ship.is_empty() and (sector_warp or action in ["max", "refill"] or (action.begins_with("phase:") and action != "phase:market")):
		next.ship = "rook"
	if action in ["rook", "hawk"]:
		next.ship = action
		next.ammo = mini(next.ammo, int(CampaignState.SHIPS[next.ship]["ammo"]))
	if action == "credits":
		next.reward(1000)
	elif action == "credits_large":
		next.reward(10000)
	elif action == "reset_credits":
		next.credits = 0
	elif action in ["max", "refill"]:
		next.secondary = true
		next.ammo = int(CampaignState.SHIPS[next.ship]["ammo"])
		if action == "max":
			next.primary_level = 2
			next.shield_level = 2
			next.heat_sink_level = 2
			next.hull_armor_level = 2
			next.tractor = true
			next.swarm_launcher = true
			next.emp_launcher = true
			next.countermeasures = true
		if next.countermeasures:
			next.flares = CampaignState.FLARE_CAPACITY
	if new_debug_mission or sector_warp or action in ["rook", "hawk", "refill", "max"]:
		next.hull = next.hull_capacity()
		next.shields = next.shield_capacity()
	if action.begins_with("phase:"):
		next.phase = action.trim_prefix("phase:")
		if next.phase == "market":
			next.dock(false)
	if sector_warp:
		next.sector = action.trim_prefix("sector:")
		next.phase = "launch"
		next.sortie_id += 1
		next.last_result = "departed"
		next.break_combo()
		next.sortie_start_shots = next.stats["shots"]
		next.sortie_start_hits = next.stats["hits"]
	if not _save_campaign(next, func() -> void: _debug_action(action)):
		return
	god_mode = next_god
	zero_heat = next_zero_heat
	infinite_ammo = next_infinite_ammo
	one_hit_kill = next_one_hit
	if action == "kill_boss":
		for part in [boss.parts[0], boss.parts[1], boss.core]:
			if not part.destroyed:
				part.unlocked = true
				part.receive_hit(part.armor)
				_spawn_breakup(part, true)
				flight.destroyed += 1
		campaign.stats["bosses"] += 1
		_start_boss_destruction()
		hud.show_message("DEVELOPER BOSS DEFEAT / NO COMBAT REWARD")
	_set_cockpit(campaign.ship, campaign.primary_level)
	if next.phase == "market":
		_show_market()
	elif new_debug_mission or sector_warp or action.begins_with("phase:"):
		_load_phase()
	else:
		flight.configure_campaign(campaign)
		flight.zero_heat = zero_heat
		_apply_settings()
		mode = Mode.DEBUG
		hud.show_debug(god_mode, zero_heat, infinite_ammo, one_hit_kill)

func _parse_automation() -> void:
	var reduced: bool = false
	for argument in OS.get_cmdline_user_args():
		if argument in preload("res://scripts/launch.gd").AUTOMATION:
			automation = argument
		elif argument.begins_with("--capture-dir="):
			screenshot_directory = argument.trim_prefix("--capture-dir=")
		elif argument == "--reduced-effects":
			reduced = true
		elif argument.begins_with("--campaign-save="):
			normal_save_path = argument.trim_prefix("--campaign-save=")
		elif argument == "--profile-frames":
			profile_frames = true
		elif argument == "--real-time":
			automation_realtime = true
		elif argument == "--with-music":
			automation_music = true
		elif argument == "--hazard-route":
			automation_hazard = true
		elif argument.begins_with("--validation-ship="):
			automation_ship = argument.trim_prefix("--validation-ship=")
		elif argument.begins_with("--validation-primary="):
			var value: String = argument.trim_prefix("--validation-primary=")
			if not value.is_valid_int() or int(value) not in [0, 1, 2]:
				push_error("Validation primary must be 0, 1 or 2.")
				get_tree().quit(1)
				return
			automation_primary = int(value)
		elif argument.begins_with("--validation-sector="):
			automation_sector = argument.trim_prefix("--validation-sector=")
		elif argument.begins_with("--validation-tour="):
			var value: String = argument.trim_prefix("--validation-tour=")
			if not value.is_valid_int() or int(value) < 1 or int(value) > 5:
				push_error("Validation tour must be from one through five.")
				get_tree().quit(1)
				return
			automation_tour = int(value)
		elif argument == "--frost-damage-only":
			automation_frost_damage_only = true
	if not automation.is_empty():
		automated_session = true
		if DisplayServer.get_name() != "headless":
			get_window().unresizable = true
			get_window().unfocusable = true
			get_window().mouse_passthrough = true
			get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
			get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
			get_window().content_scale_size = Vector2i(1920, 1080)
			get_window().content_scale_factor = 1.0
		if not CampaignState.SHIPS.has(automation_ship):
			push_error("Unknown validation ship: " + automation_ship)
			get_tree().quit(1)
			return
		if not SectorCatalog.AVAILABLE.has(automation_sector):
			push_error("Unknown validation sector: " + automation_sector)
			get_tree().quit(1)
			return
		if normal_save_path == "user://campaign.json":
			normal_save_path = "user://validation_campaign.json"
		settings["reduced_effects"] = reduced
		settings["response"] = 1
		_apply_settings()
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		AudioServer.set_bus_mute(0, true)
		print("VALIDATION_PROFILE resolution=1920x1080 reduced_effects=", reduced, " flight_response=", flight.response)
		print("VALIDATION_SCENARIO ship=", automation_ship, " primary=", automation_primary, " sector=", automation_sector, " tour=", automation_tour, " frost_slowdown=", not automation_frost_damage_only, " realtime=", automation_realtime, " max_fps=", Engine.max_fps)
		if profile_frames:
			RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
			RenderingServer.viewport_set_measure_render_time(hud.instrument_viewport.get_viewport_rid(), true)

func _run_automation(delta: float) -> void:
	automation_time += delta
	if automation == "--voice-test":
		_run_voice_test()
		return
	if automation == "--music-test":
		_run_music_test()
		return
	if automation == "--campaign-test":
		_run_campaign_automation()
		return
	if boss != null and boss.cloak != null:
		automation_saw_cloak = automation_saw_cloak or boss.cloak.active()
	if automation in ["--branch-benchmark", "--ground-benchmark"]:
		_run_branch_benchmark()
		return
	if automation == "--launch-benchmark":
		_run_launch_benchmark()
		return
	if automation in ["--orbit-benchmark", "--boss-benchmark", "--entry-benchmark"]:
		_run_space_benchmark()
		return
	if automation in ["--belt-benchmark", "--mining-test"]:
		_run_belt_automation()
		return
	if automation == "--mission-test":
		_run_mission_automation()
		return
	if automation_stage == 0 and automation_time > 1.0:
		automation_stage = 1
		await _capture("briefing.png")
		start_flight()
		AudioServer.set_bus_mute(0, true)
	if automation == "--benchmark":
		if mode == Mode.FLIGHT:
			_automated_aim()
		elif mode == Mode.COMPLETE:
			_finish_automation()
		return
	if automation_stage == 1 and automation_time > 5.0:
		automation_stage = 2
		await _capture("flight.png")
		pause_flight()
		pause_snapshot = flight.elapsed
	elif automation_stage == 2 and automation_time > 6.0:
		automation_stage = 3
		_check(is_equal_approx(flight.elapsed, pause_snapshot), "Pause freezes mission time")
		await _capture("pause.png")
		resume_flight()
	elif automation_stage == 3 and automation_time > 8.0:
		automation_stage = 4
		_check(flight.elapsed > pause_snapshot, "Resume advances mission time")
		_check(flight.offset.abs().x <= FlightState.CORRIDOR.x, "Ship remains inside corridor")
		_change_setting("reduced_effects", true)
		await _capture("reduced.png")
		_finish_automation()
	if mode == Mode.FLIGHT:
		_automated_aim()

func _run_music_test() -> void:
	if automation_stage != 0:
		return
	automation_stage = 1
	if DisplayServer.get_name() == "headless":
		_check(false, "Packaged music verification requires native audio")
		_finish_automation()
		return
	music.request_scene("xylo")
	music.set_level(70, false)
	music.set_paused(false)
	await get_tree().create_timer(5).timeout
	var bus: int = AudioServer.get_bus_index(music.bus_name)
	_check(music.current == "xylo" and music.players[music.active].get_playback_position() > 4 and AudioServer.get_bus_peak_volume_left_db(bus, 0) > -65, "Packaged Xylo soundtrack plays through its native audio bus")
	var position: float = music.players[music.active].get_playback_position()
	music.set_paused(true)
	await get_tree().create_timer(0.3).timeout
	_check(absf(music.players[music.active].get_playback_position() - position) < 0.06, "Packaged soundtrack pauses without advancing")
	music.set_paused(false)
	music.request_scene("station")
	await get_tree().create_timer(4.5).timeout
	_check(music.current == "station" and music.players[music.active].playing and not music.players[1 - music.active].playing, "Docking crossfades to Look Busy and releases the previous recording")
	music.set_level(0, false)
	_check(not music.players[0].playing and not music.players[1].playing, "Packaged music volume zero stops playback")
	_finish_automation()

func _run_voice_test() -> void:
	if DisplayServer.get_name() == "headless":
		_check(false, "Packaged speech validation requires native audio")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1:
		automation_stage = 1
		computer_voice.set_level(70, false)
		_check(computer_voice.failure_message.is_empty() and computer_voice.say("reactor_balanced"), "Packaged voice catalog and recording load successfully")
	if automation_stage == 1:
		var index: int = AudioServer.get_bus_index(computer_voice.bus_name)
		if index >= 0:
			automation_voice_peak = maxf(automation_voice_peak, AudioServer.get_bus_peak_volume_left_db(index, 0))
		if automation_time > 2:
			_check(computer_voice.player != null and computer_voice.player.get_playback_position() > 0.1 and automation_voice_peak > -65, "Packaged speech produces real processed audio while master output stays muted")
			_check(AudioServer.is_bus_mute(0) and not computer_voice.say_route(true), "Audio validation is inaudible and route banter cannot interrupt it")
			computer_voice.stop_speech()
			_finish_automation()

func _automated_aim() -> void:
	if is_campaign and campaign.phase == "ground" and ground_branch != null:
		if not ground_branch.route.locked and flight.distance > GroundRoute.FORK - 100:
			cursor = get_viewport().get_visible_rect().size * Vector2(0.65 if automation_hazard else 0.35, 0.5)
			Input.action_release("primary")
			return
		if ground_branch.route.selected:
			for supply in ground_branch.supplies:
				if supply.active and not camera.is_position_behind(supply.global_position) and camera.global_position.distance_to(supply.global_position) < 140:
					cursor = camera.unproject_position(supply.global_position)
					Input.action_release("primary")
					return
	if automation == "--boss-benchmark" and not thermal_sweeps.is_empty():
		cursor = get_viewport().get_visible_rect().size * Vector2(0.5, 0.1)
		Input.action_release("primary")
		automation_saw_sweep = automation_saw_sweep or thermal_sweeps[0].age >= ThermalSweep.WARNING
		return
	if is_campaign and campaign.phase == "asteroids":
		cursor = get_viewport().get_visible_rect().size * 0.5
		Input.action_release("primary")
		if automation == "--mission-test" and campaign.stats["guardians" if campaign.sector == "xylo" else "pirates"] == 0 and flight.heat < 72:
			for target in targets:
				if target is PirateSkirmisher and not target.destroyed and not target.expired and not camera.is_position_behind(target.global_position):
					cursor = camera.unproject_position(target.global_position)
					fire_armed = true
					Input.action_press("primary")
					break
		return
	if is_campaign:
		if flight.evade_cooldown <= 0.0:
			for incoming_missile in missiles:
				if incoming_missile.active and not incoming_missile.diverted and camera.position.distance_to(incoming_missile.position) < 55.0:
					var evade := InputEventAction.new()
					evade.action = "evade"
					evade.pressed = true
					_unhandled_input(evade)
					break
		if flight.heat > 72.0 or flight.overheat_remaining > 0.0:
			auto_burst_cooling = true
		elif flight.heat < 28.0:
			auto_burst_cooling = false
		if auto_burst_cooling:
			_automated_route("shields")
			var viewport: Vector2 = get_viewport().get_visible_rect().size
			cursor = Vector2(viewport.x * (0.5 + sin(flight.elapsed * 2.0) * 0.34), viewport.y * 0.2)
			Input.action_release("primary")
			return
		_automated_route("weapons")
		for missile in missiles:
			if missile.active and not missile.diverted and camera.position.distance_to(missile.position) < 230 and not camera.is_position_behind(missile.position):
				cursor = camera.unproject_position(missile.position).clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
				fire_armed = true
				Input.action_press("primary")
				return
	var candidates: Array[RangeTarget] = targets.duplicate()
	if ground_branch != null and campaign != null and campaign.phase == "ground" and ground_branch.route.selected:
		for turret in ground_branch.turrets:
			if not turret.destroyed and camera.global_position.distance_to(turret.global_position) < 350:
				candidates.erase(turret)
				candidates.push_front(turret)
	if boss != null:
		for turret in boss.turrets:
			candidates.erase(turret)
			candidates.push_front(turret)
		if boss.thermal_emitter != null:
			candidates.erase(boss.thermal_emitter)
			candidates.push_front(boss.thermal_emitter)
	if is_instance_valid(director.tracked):
		candidates.erase(director.tracked)
		candidates.push_front(director.tracked)
	if is_campaign and campaign.stats["radars"] == 0:
		for target in targets:
			if target is RadarDish and not target.destroyed and camera.global_position.distance_to(target.global_position) < 300 and not camera.is_position_behind(target.global_position):
				candidates.erase(target)
				candidates.push_front(target)
				break
	if mission_world != null:
		for web in mission_world.webs:
			if not web.disabled and camera.global_position.distance_to(web.global_position) < 150:
				candidates.erase(web.nodes[0])
				candidates.push_front(web.nodes[0])
	for target in candidates:
		if ground_branch != null and (target is GroundTurret or target is EnemyFighter) and not ground_branch.engages(target, flight.distance):
			continue
		if target is Asteroid and target.indestructible:
			continue
		if is_campaign and target is EnemyFighter and target.web_layer and campaign.stats["webs"] == 0:
			continue
		if automation == "--boss-benchmark" and target is ThermalEmitter and not automation_saw_sweep:
			continue
		if automation == "--boss-benchmark" and target is DroneBay and mission_world.drone_launches == 0:
			continue
		if not target.destroyed and camera.position.distance_to(target.global_position) > 20.0 and not camera.is_position_behind(target.global_position) and (not target is BossPart or target.unlocked):
			cursor = camera.unproject_position(target.aim_point()).clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
			break
	fire_armed = true
	Input.action_press("primary")

func _automated_route(power: String) -> void:
	if flight.power_mode == power:
		return
	var route := InputEventAction.new()
	route.action = "power_" + power
	route.pressed = true
	_unhandled_input(route)

func _run_branch_benchmark() -> void:
	if mode == Mode.SAVE_ERROR or mode == Mode.MARKET or automation_time > 140.0:
		_check(false, "Ground validation reached a save error, ejection or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1.0:
		automation_stage = 1
		automation_hazard = automation == "--branch-benchmark" or automation_hazard
		store = CampaignStore.new(normal_save_path)
		campaign = CampaignState.new()
		campaign.sector = automation_sector
		campaign.primary_level = automation_primary
		campaign.ship = automation_ship
		campaign.hull = campaign.hull_capacity()
		campaign.shields = campaign.shield_capacity()
		campaign.secondary = true
		campaign.countermeasures = true
		campaign.assisted = true
		is_campaign = true
		god_mode = false
		_load_phase()
	if mode == Mode.FLIGHT and campaign.phase == "ground":
		_automated_aim()
		for moment in [22, 36, 49, 65, 75]:
			var mark: String = "branch-%d" % moment
			if flight.elapsed > moment and not capture_marks.has(mark):
				capture_marks[mark] = true
				_capture(mark + ".png")
	elif mode == Mode.FLIGHT and campaign.phase == "ground_boss":
		_check(ground_branch.route.selected == automation_hazard and ground_branch.route.rewarded == automation_hazard, "The ground benchmark follows the requested safe/hazard route and reward policy")
		var collected: int = 0
		for supply in ground_branch.supplies:
			if not supply.active:
				collected += 1
		if automation_hazard:
			_check(collected == 3 and flight.ammo == 2 and campaign.flares == 1, "The live flight collects all three supplies into their distinct inventories")
		_check(flight.hull > 0 and not god_mode, "The ground course reaches its boss without invincibility")
		_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02, "Rejoining the canyon preserves the boss handoff")
		print("GROUND_RESULT hazard=%s pickups=%d ordnance=%d flares=%d hull=%.1f" % [automation_hazard, collected, flight.ammo, campaign.flares, flight.hull])
		_finish_automation()

func _run_belt_automation() -> void:
	if mode == Mode.SAVE_ERROR or automation_time > 240.0:
		_check(false, "Belt validation reached a save error or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1.0:
		automation_stage = 1
		store = CampaignStore.new(normal_save_path)
		campaign = CampaignState.new()
		campaign.sector = automation_sector
		campaign.primary_level = automation_primary
		campaign.phase = "asteroids"
		campaign.assisted = true
		campaign.tractor = automation == "--mining-test"
		is_campaign = true
		god_mode = false
		_load_phase()
	if mode == Mode.FLIGHT:
		cursor = get_viewport().get_visible_rect().size * 0.5
		Input.action_release("primary")
		if automation == "--mining-test" and flight.heat < 72:
			var needs_mineral: bool = campaign.stats["minerals"] == 0 and mineral_pickups.is_empty()
			var needs_chain: bool = campaign.stats["minerals"] > 0 and campaign.stats["chain_rocks"] == 0 and volatile_blasts.is_empty()
			for target in targets:
				if not (target is Asteroid or target is EggShip) or target.destroyed or not target.near_pass:
					continue
				var distance: float = camera.global_position.distance_to(target.global_position)
				if camera.is_position_behind(target.global_position) or distance < 55 or distance > 210:
					continue
				var useful: bool = needs_mineral and target.cargo if target is EggShip else (needs_mineral and target.mineral) or (needs_chain and target.volatile)
				if useful:
					cursor = camera.unproject_position(target.global_position)
					fire_armed = true
					Input.action_press("primary")
					break
		if automation == "--mining-test":
			for moment in [5.0, 25.0, 45.0]:
				var key: String = "belt-%.0f" % moment
				if flight.elapsed >= moment and not capture_marks.has(key):
					capture_marks[key] = true
					_capture(key + ".png")
		if hud.tractor_active and not capture_marks.has("tractor"):
			capture_marks["tractor"] = true
			_capture("tractor-collection.png")
		if not volatile_blasts.is_empty() and not capture_marks.has("volatile"):
			capture_marks["volatile"] = true
			_capture("volatile-chain.png")
	if mode == Mode.MARKET:
		_check(campaign.last_result == "completed" and is_equal_approx(flight.elapsed, 60.0), "Dense asteroid field lasts 60 active seconds and docks normally")
		_check(sequence_log.has("belt_climb") and mission_world != null and world == mission_world, "Belt pull-up retains the asteroid world all the way into docking")
		if automation == "--mining-test":
			_check(campaign.stats["minerals"] > 0 and campaign.mineral_credits > 0, "Visible mineral cores are mined and collected during real flight")
			if campaign.sector == "xylo":
				_check(campaign.stats["eggs"] > 0 and rock_fragments.is_empty(), "Biological cargo comes from egg ships without spawning asteroid fragments")
			else:
				_check(campaign.stats["chain_rocks"] > 0, "A shot volatile asteroid triggers a real chain reaction")
			var loaded := CampaignStore.new(store.path)
			_check(loaded.load_game() == OK and loaded.state.tractor and loaded.state.stats["minerals"] == campaign.stats["minerals"], "Tractor and mining totals persist after docking")
		else:
			_check(flight.impacts == 0, "Safe nominal autopilot route avoids the denser field")
		print("BELT_RESULT minerals=%d mineral_credits=%d chain_rocks=%d impacts=%d" % [campaign.stats["minerals"], campaign.mineral_credits, campaign.stats["chain_rocks"], flight.impacts])
		_finish_automation()
	elif mode == Mode.TRANSITION and sequence_time > 2.0:
		var key: String = "belt-transit-" + sequence
		if not screenshot_directory.is_empty() and not capture_marks.has(key):
			capture_marks[key] = true
			_capture(key + ".png")

func _run_space_benchmark() -> void:
	if mode == Mode.SAVE_ERROR or mode == Mode.MARKET or automation_time > 180.0:
		_check(false, "Orbital benchmark reached a save error, ejection, or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1.0:
		automation_stage = 1
		store = CampaignStore.new(normal_save_path)
		campaign = CampaignState.new()
		campaign.sector = automation_sector
		campaign.phase = "orbit" if automation == "--orbit-benchmark" else "orbit_boss"
		campaign.primary_level = automation_primary
		campaign.assisted = true
		is_campaign = true
		god_mode = false
		_load_phase()
	if mode == Mode.FLIGHT:
		if automation == "--orbit-benchmark" and campaign.phase == "orbit_boss" and flight.elapsed >= 5:
			_check(approaching_boss == null and boss == mission_world.boss and sequence_log.has("blockade_exit"), "Orbital benchmark reaches the already-visible boss after its automatic intercept turn")
			_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02 and retired_world == null, "Boss activation preserves camera continuity and retires only the departed dogfight scene")
			_finish_automation()
			return
		if automation == "--entry-benchmark" and campaign.phase == "asteroids" and flight.elapsed >= 5:
			_check(sequence_log.has("belt_transfer") and approaching_belt == null and retired_world == null and mission_world.phase == "asteroids", "Normal-speed pull-up reaches the prepared belt and retires only the distant wreckage")
			_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02 and flight.impacts == 0, "Belt entry remains continuous and collision-free")
			_finish_automation()
			return
		_automated_aim()
	elif mode == Mode.TRANSITION and sequence == "blockade_exit" and not capture_marks.has("orbital-stage-completed"):
		capture_marks["orbital-stage-completed"] = true
		_check(is_equal_approx(flight.elapsed, 90.0) and flight.hull > 0, "Full orbital stage completes at normal speed without invincibility")
		_check(campaign.stats["webs"] > 0, "Orbital benchmark includes real deployed and disabled tripwires")
		_check(flight.primary_level == automation_primary and flight.hits > 0 and flight.hits <= flight.shots and campaign.stats["hits"] <= campaign.stats["shots"], "Orbital benchmark uses the requested primary with bounded projectile/tick accuracy")
	elif automation == "--boss-benchmark" and mode == Mode.TRANSITION and sequence == "orbital_victory" and sequence_time >= FlightDirector.VICTORY_DURATION * 0.5:
		_check(boss.defeated() and flight.hull > 0, "Capital ship is defeated at normal speed without invincibility")
		if campaign.sector == "cryo":
			_check(mission_world.drone_launches >= 2, "Hydra benchmark includes launched drones and final destruction")
		elif campaign.sector == "vespera":
			_check(automation_saw_cloak, "Nyx benchmark includes an active cloak and normal primary-weapon victory")
		elif campaign.sector == "xylo":
			_check(flight.missiles_launched > 0, "Leviathan benchmark includes real biological projectile attacks and final destruction")
		elif campaign.sector == "ignis":
			_check(automation_saw_sweep, "Boss benchmark includes a charged, active thermal sweep and final destruction")
		_finish_automation()

func _run_launch_benchmark() -> void:
	if mode == Mode.SAVE_ERROR or mode == Mode.MARKET or automation_time > 100:
		_check(false, "Launch validation reached a save error, ejection, or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1:
		automation_stage = 1
		_new_campaign(automation_sector)
	if mode == Mode.TRANSITION and not sequence.is_empty():
		_capture_launch_moments()
	elif mode == Mode.FLIGHT:
		_automated_aim()
		if flight.elapsed >= 5:
			_check(campaign.phase == "ground" and sequence_log.has("hyperspace") and sequence_log.has("planet_descent") and launch_approach == null, "Normal-speed launch reaches active ground combat through hyperspace and descent")
			_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02 and retired_world == null, "Launch handoff preserves camera continuity and retires only distant scenery")
			_finish_automation()

func _capture_launch_moments() -> void:
	if screenshot_directory.is_empty():
		return
	if sequence == "planet_descent" and sequence_time > 2.0 and not capture_marks.has("launch-orbit-view"):
		capture_marks["launch-orbit-view"] = true
		_capture("launch-orbit-view.png")
	var mark: String = sequence
	var moment: float = 1.1
	if sequence == "hyperspace":
		moment = LaunchApproach.HYPERSPACE_DURATION * 0.5
	elif sequence == "planet_descent":
		moment = FlightDirector.DESCENT_DURATION - 1.0
	if sequence_time > moment and not capture_marks.has("launch-" + mark):
		capture_marks["launch-" + mark] = true
		_capture("launch-" + mark + ".png")

func _run_mission_automation() -> void:
	if mode == Mode.SAVE_ERROR or automation_time > 1500.0:
		_check(false, "Mission validation reached a save error or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1.0:
		automation_stage = 1
		Engine.time_scale = 1.0 if automation_realtime else 4.0
		_new_campaign(automation_sector)
	if mode == Mode.FLIGHT:
		_automated_aim()
		if ground_branch != null and campaign.phase == "ground" and ground_branch.route.rewarded:
			capture_marks["route-completed"] = true
		if is_campaign and flight.elapsed > 12.0 and not capture_marks.has(campaign.phase):
			capture_marks[campaign.phase] = true
			_capture("action-" + campaign.phase + ".png")
		if is_campaign and campaign.phase.ends_with("_boss") and flight.elapsed > 20.0 and not capture_marks.has("close-" + campaign.phase):
			capture_marks["close-" + campaign.phase] = true
			_capture("close-" + campaign.phase + ".png")
	if mode == Mode.TRANSITION and not sequence.is_empty() and sequence_time > minf(1.1, TRANSIT_LEGS[sequence] * 0.5) and not capture_marks.has(sequence):
		capture_marks[sequence] = true
		_capture("transit-" + sequence + ".png")
	if launch_approach != null:
		_capture_launch_moments()
	if mode == Mode.TRANSITION and sequence == "belt_transfer" and sequence_time > FlightDirector.BELT_TRANSFER_DURATION - 1.0 and not capture_marks.has("belt-near"):
		capture_marks["belt-near"] = true
		_capture("belt-pullup-near.png")
	if mode == Mode.TRANSITION and sequence == "belt_climb":
		for moment in [4.0, 8.0]:
			var mark: String = "belt-climb-%d" % int(moment)
			if sequence_time >= moment and not capture_marks.has(mark):
				capture_marks[mark] = true
				_capture(mark + ".png")
	if automation_stage == 1 and mode == Mode.MARKET:
		_check(campaign.last_result == "completed" and campaign.sector == automation_sector, "Full %s operation completed without invincibility" % SectorCatalog.name_for(automation_sector))
		print("FROST_COMPARISON sector=%s slowdown=%s events=%d hull_damage=%.1f elapsed=%.2f" % [automation_sector, not automation_frost_damage_only, automation_frost_events, automation_hull_damage, automation_time])
		_check(campaign.primary_level == automation_primary and campaign.stats["hits"] <= campaign.stats["shots"], "The full mission retains its requested primary and valid accuracy accounting")
		_check(capture_marks.has("route-completed") == automation_hazard, "The full mission follows its requested safe/hazard route")
		_check(campaign.stats["bosses"] == 2, "Both mandatory bosses defeated")
		_check(campaign.best_streak >= 10 and campaign.combo_bonus_credits > 0 and campaign.combat_score > 0, "Live combat earns the 4x streak tier and persistent score")
		_check(flight.evasions > 0, "Automatic test pilot uses the player's Shift maneuver")
		_check(campaign.stats["radars"] > 0 and campaign.stats["webs"] > 0 and campaign.stats["guardians" if campaign.sector == "xylo" else "pirates"] > 0, "Full mission completes radar suppression, tripwire disarm, and its optional guardian/pirate bounty")
		_check(campaign.debrief["accuracy"] > 0 and campaign.debrief["completion"] == 350, "Docking pays the displayed accuracy and completion bonuses")
		print("MISSION_OBJECTIVES radars=%d webs=%d pirates=%d debrief=%s" % [campaign.stats["radars"], campaign.stats["webs"], campaign.stats["pirates"], JSON.stringify(campaign.debrief)])
		print("MISSION_TACTICS evasions=%d deflections=%d best_streak=%d combo_bonus=%d score=%d shield_blocks=%d" % [flight.evasions, flight.deflections, campaign.best_streak, campaign.combo_bonus_credits, campaign.combat_score, blocked_primary_hits])
		_check(docked and station.to_local(camera.global_position).z < 0.0, "Market opens only after entering the station hangar")
		_check(sequence_log.has("ascent") and sequence_log.has("docking"), "Mission includes continuous ascent and automatic docking")
		_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02, "Phase boundaries preserve the pilot's position and orientation")
		print("PHASE_CONTINUITY max_jump_m=", largest_phase_jump, " max_turn_rad=", largest_phase_turn)
		_check(campaign.hull == campaign.hull_capacity() and campaign.shields == campaign.shield_capacity(), "Market repairs hull and shields for free")
		if campaign.last_result != "completed":
			_finish_automation()
			return
		automation_stage = 2
		await _capture("market.png")
		var catalog_budget: int = 4080
		if campaign.credits < catalog_budget:
			print("AUTOMATION_FIXTURE: adding ", catalog_budget - campaign.credits, " credits for full catalog checks after the earned-reward playthrough")
			campaign.reward(catalog_budget - campaign.credits)
		_market_purchase("hawk")
		if campaign.primary_level == 0:
			_market_purchase("primary")
		_market_purchase("secondary")
		_check(campaign.ship == "hawk" and campaign.primary_level == maxi(1, automation_primary) and campaign.secondary, "Market purchases change the saved loadout without discarding an advanced primary")
		_check(cockpit_skin == "hawk", "Hull purchase selects the interceptor cockpit without moving its instruments")
		_check(gun_level_displayed == campaign.primary_level, "The retained or purchased primary selects its matching gun artwork")
		await _capture("gun-after-hull-swap.png")
		if campaign.primary_level < 2:
			_market_purchase("primary")
		_check(campaign.primary_level == 2 and gun_level_displayed == 2, "The final primary tier equips the tachyon cannon and its visible barrels")
		_market_purchase("cooling")
		_check(campaign.heat_sink_level == 1, "Cooling-vent purchase is applied and saved")
		_market_purchase("tractor")
		_check(campaign.tractor, "Tractor-beam purchase is applied and saved")
		_market_purchase("armor")
		_check(campaign.hull_armor_level == 1 and campaign.hull == campaign.hull_capacity(), "Hull plating purchase increases and saves usable hull")
		_market_purchase("swarm")
		_market_purchase("emp")
		_market_purchase("countermeasures")
		_select_secondary("swarm")
		_check(campaign.swarm_launcher and campaign.emp_launcher and campaign.selected_secondary == "swarm" and campaign.ammo <= int(CampaignState.SHIPS[campaign.ship]["ammo"]), "New secondary stations are purchased and selected without expanding the shared bay")
		_check(campaign.countermeasures and campaign.flares == CampaignState.FLARE_CAPACITY, "Countermeasure pod is purchased with its separate flare inventory")
		await _capture("gun-tier-2.png")
		var loaded := CampaignStore.new(store.path)
		_check(loaded.load_game() == OK and loaded.state.to_dict() == campaign.to_dict(), "Market checkpoint reloads exactly")
		_depart_market("cryo" if campaign.sector == "ignis" else "ignis")
	elif automation_stage == 2 and mode == Mode.FLIGHT and flight.elapsed > 0.3:
		automation_stage = 3
		var before: int = flight.ammo
		fire_secondary()
		_check(flight.ammo == before - 2 and torpedoes.size() == 3, "Purchased swarm fires three guided rockets for two shared units")
	elif automation_stage == 3 and mode == Mode.FLIGHT and flight.secondary_cooldown <= 0.0:
		automation_stage = 4
		pause_flight()
		_select_secondary("emp")
		resume_flight()
		var before: int = flight.ammo
		fire_secondary()
		_check(flight.ammo == before - 3 and not emp_pulses.is_empty(), "Paused switching equips EMP and consumes three shared units (station=%s, ammo=%d->%d)" % [campaign.selected_secondary, before, flight.ammo])
	elif automation_stage == 4 and mode == Mode.FLIGHT and flight.secondary_cooldown <= 0.0:
		automation_stage = 5
		print("AUTOMATION_FIXTURE: nearby hostile missile for the purchased countermeasure pod")
		_launch_missile(camera.to_global(Vector3(0, 0, -60)), camera.global_basis.z)
		var flare_before: int = campaign.flares
		var ordnance_before: int = flight.ammo
		var countermeasure_key := InputEventKey.new()
		countermeasure_key.physical_keycode = KEY_C
		countermeasure_key.pressed = true
		_unhandled_input(countermeasure_key)
		_check(campaign.flares == flare_before - 1 and flight.ammo == ordnance_before and not flare_clouds.is_empty(), "Purchased countermeasures deploy through C without using weapon ordnance")
		pause_flight()
		_select_secondary("concussion")
		resume_flight()
		var before: int = flight.ammo
		fire_secondary()
		_check(flight.ammo == before - 1 and not torpedoes.is_empty(), "The original concussion station still fires for one shared unit")
		campaign.credits = 0
		campaign.assisted = true
		flight.hull = 0.0
	elif automation_stage == 5 and mode == Mode.MARKET:
		automation_stage = 6
		_check(campaign.ship.is_empty() and campaign.primary_level == 0 and campaign.ammo == 0 and campaign.heat_sink_level == 0 and campaign.hull_armor_level == 0 and not campaign.tractor and not campaign.swarm_launcher and not campaign.emp_launcher and not campaign.countermeasures and campaign.flares == 0, "Ejection removes ship, weapon stations, flare pod and all charges")
		_market_purchase("emergency")
		_check(campaign.ship == "emergency" and campaign.credits == 0, "No-money pilot receives a free emergency ship")
		_check(cockpit_skin == "emergency", "Emergency replacement selects the Rescue Skiff cockpit")
		print("MISSION_PHASE_LOG ", phase_log)
		_finish_automation()

func _run_campaign_automation() -> void:
	if mode == Mode.SAVE_ERROR or automation_time > 6000:
		_check(false, "Campaign playtest reached a save error or timeout")
		_finish_automation()
		return
	if automation_stage == 0 and automation_time > 1:
		automation_stage = 1
		Engine.time_scale = 1.0 if automation_realtime else 4.0
		_new_campaign("ignis")
	if mode == Mode.FLIGHT:
		_automated_aim()
	if automation_stage == 1 and mode == Mode.MARKET:
		if campaign.last_result != "completed":
			_check(false, "Campaign pilot must finish each planet without invincibility or replacement")
			_finish_automation()
			return
		print("CAMPAIGN_PLANET_COMPLETE sector=", campaign.sector, " tour=", campaign.tour, " totals=", JSON.stringify(campaign.tour_totals()))
		for sector in SectorCatalog.AVAILABLE:
			if not campaign.cleared_sectors.has(sector):
				_depart_market(sector)
				break
	elif automation_stage == 1 and mode == Mode.CAMPAIGN_COMPLETE:
		automation_stage = 2
		var result: Dictionary = campaign.tour_result.duplicate(true)
		var frozen: Dictionary = campaign.to_dict()
		_check(result["totals"]["sorties"] == SectorCatalog.AVAILABLE.size() and result["totals"]["bosses"] == SectorCatalog.AVAILABLE.size() * 2 and not god_mode and not one_hit_kill, "Every actual planet loop and its two bosses complete without invincibility or instant kills")
		_check(is_equal_approx(result["totals"]["hull_damage"], automation_hull_damage), "Final hull damage equals actual damage observed throughout all six flights")
		_check(largest_phase_jump < 0.25 and largest_phase_turn < 0.02, "All campaign phase handoffs remain continuous")
		print("CAMPAIGN_FINAL_RESULT ", JSON.stringify(result))
		await _capture("campaign-debrief.png")
		_show_rank_rules()
		await _capture("campaign-rank-rules.png")
		_show_campaign_result()
		_confirm_next_tour()
		await _capture("campaign-continue-confirmation.png")
		_show_campaign_result()
		_retire_campaign()
		_check(mode == Mode.TITLE and hud.can_resume, "Exported retirement records the result while keeping Continue Saved Operation available")
		await _capture("campaign-retired-title.png")
		_continue_campaign()
		_check(campaign.to_dict() == frozen and mode == Mode.CAMPAIGN_COMPLETE, "Retired campaign resumes its exact frozen result, loadout and wallet")
		_show_hall_of_fame(true)
		await _capture("campaign-hall-assisted.png")
		var hall: HallOfFameStore = _hall_store()
		_check(hall.load_records() == OK and hall.ranked(true).size() == 1 and hall.ranked(false).is_empty(), "Automated campaign is recorded only in the assisted Hall of Fame")
		_show_campaign_result()
		_begin_next_tour()
		_check(mode == Mode.MARKET and campaign.tour == automation_tour + 1 and campaign.cleared_sectors.is_empty() and campaign.tour_result.is_empty(), "Continue starts exactly one new tour and resets all six clears")
		_check(campaign.totals() == result["lifetime"] and campaign.tour_totals()["combat_score"] == 0 and campaign.tour_totals()["hull_damage"] == 0 and campaign.credits == result["loadout"]["credits"], "New tour preserves lifetime statistics and credits without carrying old tour scores")
		_check(hall.load_records() == OK and hall.records.size() == 1, "Continue after retirement does not duplicate the same tour record")
		var next: Dictionary = campaign.to_dict()
		show_title()
		_continue_campaign()
		_check(campaign.to_dict() == next and mode == Mode.MARKET, "Next-tour market reloads exactly from its on-disk checkpoint")
		await _capture("campaign-next-tour-market.png")
		_depart_market("cryo")
	elif automation_stage == 2 and mode == Mode.FLIGHT and campaign.phase == "ground" and flight.elapsed > 0.2:
		automation_stage = 3
		var checked: bool = false
		for target in targets:
			if target is EnemyFighter:
				checked = target.health_scale == campaign.health_multiplier()
				break
		_check(checked and campaign.health_multiplier() <= 2.0, "Next-tour departure constructs enemies at the correct capped health")
		_finish_automation()

func _capture(filename: String) -> void:
	if screenshot_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var error: Error = get_viewport().get_texture().get_image().save_png(screenshot_directory.path_join(filename))
	if error != OK:
		push_error("Screenshot failed: " + error_string(error))
		automation_failures += 1

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		automation_failures += 1

func _finish_automation() -> void:
	var benchmark: bool = automation in ["--benchmark", "--belt-benchmark", "--orbit-benchmark", "--boss-benchmark", "--entry-benchmark", "--launch-benchmark", "--branch-benchmark", "--ground-benchmark"]
	var training_benchmark: bool = automation == "--benchmark"
	if automation_music:
		_check(music.enabled() and automation_music_peak > -65 and AudioServer.is_bus_mute(0), "Validation played real ambient music during gameplay while keeping master output muted")
		print("MUSIC_GAMEPLAY_PEAK_DB=", automation_music_peak)
	automation = ""
	Input.action_release("primary")
	if profile_frames:
		slow_frames.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["wall"] > b["wall"])
		for sample in slow_frames.slice(0, 12):
			print("SLOW_FRAME ", JSON.stringify(sample))
	telemetry.sort()
	if benchmark:
		_check(telemetry.size() > 500, "Benchmark captured enough actual rendered frames")
	if not telemetry.is_empty():
		var total: float = 0.0
		for sample in telemetry:
			total += sample
		print("FRAME_TIMES_MS samples=%d mean=%.2f p95=%.2f p99=%.2f max=%.2f" % [telemetry.size(), total / telemetry.size(), telemetry[int(telemetry.size() * 0.95)], telemetry[int(telemetry.size() * 0.99)], telemetry.back()])
		if benchmark:
			_check(minimum_render_size.x >= 1920 and minimum_render_size.y >= 1080, "Benchmark used a full 1920x1080 render target (minimum observed: %dx%d)" % [int(minimum_render_size.x), int(minimum_render_size.y)])
			_check(telemetry[int(telemetry.size() * 0.99)] <= 1000.0 / 30.0, "99th-percentile frame time meets the 30 FPS minimum budget")
	if training_benchmark:
		_check(flight.complete() and is_equal_approx(flight.elapsed, FlightState.DURATION), "Entire 75-second course completes")
		_check(flight.destroyed > 0 and flight.hits <= flight.shots, "Full-course combat records valid hits")
		_check(flight.missiles_launched > 0, "Ground turrets fire missiles during the course")
	print("FLIGHT_RESULT shots=%d hits=%d destroyed=%d impacts=%d elapsed=%.3f" % [flight.shots, flight.hits, flight.destroyed, flight.impacts, flight.elapsed])
	print("GROUND_COMBAT launched=%d intercepted=%d missile_hits=%d turrets_destroyed=%d" % [flight.missiles_launched, flight.interceptions, flight.missile_hits, flight.turrets_destroyed])
	print("PILOT_SYSTEMS power=%s heat=%.2f overheats=%d cooling=%d" % [flight.power_mode, flight.heat, flight.overheat_events, flight.heat_sink_level])
	print("TACTICS evasions=%d deflections=%d shield_blocks=%d gunship_stuns=%d" % [flight.evasions, flight.deflections, blocked_primary_hits, stunned_gunships])
	print("AUTOMATION_FAILURES=", automation_failures)
	get_tree().quit(automation_failures)

func _exit_tree() -> void:
	_set_pointer(false)
