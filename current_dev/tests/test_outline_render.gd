extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Encounter visibility requires a native renderer.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game._build_world(false)
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.hud.show_menu("flight", game.settings)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	var dish: RadarDish
	for target in game.targets:
		if target is RadarDish:
			dish = target
			break
	game.camera.global_transform = FlightState.rail_frame(dish.travel - 110)
	game.hud.phase_title = "RADAR / OPTIONAL TURRET SUPPRESSION"
	game._update_contacts()
	await physics_frame
	await physics_frame
	await game._capture("radar-objective.png")
	game.cursor = game.camera.unproject_position(dish.aim_point())
	for _i in range(5):
		game.fire_primary()
	check(dish.destroyed and game.campaign.stats["radars"] == 1 and game.campaign.credits == 60, "Actual reticle fire destroys a visible canyon radar and awards its objective")
	game._update_contacts()
	check(game.hud.radar_jam > 0, "Cockpit displays downstream turret suppression")
	await game._capture("radar-jammed.png")
	game._clear_stage()
	game._set_ground_environment(false)
	var world := MissionWorld.new()
	game.add_child(world)
	game.world = world
	game.mission_world = world
	world.build("orbit")
	game.targets = world.targets
	for target in world.targets:
		target.collision_layer = 0
		target.hide()
	game.camera.global_transform = Transform3D.IDENTITY
	world.pilot_frame = Transform3D.IDENTITY
	var drone := EnemyFighter.new()
	drone.web_layer = true
	drone.dogfight = true
	drone.new_design = true
	drone.spawn_position = Vector3(7, 5, -55)
	drone.velocity = Vector3.FORWARD * 8
	drone.spawn_frame = Transform3D.IDENTITY
	world.add_child(drone)
	drone.cooldown = 0.1
	drone.web_requested.connect(world._request_web)
	drone.advance(0.2, Vector3.ZERO, Vector3.FORWARD * 24)
	world.advance(0.01, Transform3D.IDENTITY)
	check(world.webs.size() == 1, "The visible web-layer drone deploys an actual tripwire")
	var web: LaserWeb = world.webs[0]
	game.hud.phase_title = "WEB-LAYER / SHOOT A NODE OR DODGE"
	game._update_contacts()
	await game._capture("laser-web-warning.png")
	world.advance_webs(1.3, Vector3.ZERO, Vector3.ZERO, 0.6)
	check(web.beam.visible and game.hud.web_warning, "An armed tripwire and its cockpit warning are visible")
	await game._capture("laser-web-active.png")
	game.cursor = game.camera.unproject_position(web.nodes[1].global_position)
	await physics_frame
	await physics_frame
	game.fire_primary()
	game.fire_primary()
	check(web.disabled and not web.beam.visible and game.campaign.stats["webs"] == 1, "Real primary shots disable either visible node and the complete beam")
	world.advance_webs(0.01, Vector3.ZERO, Vector3.ZERO, 0.6)
	game._update_contacts()
	game._update_beams(1.0)
	await game._capture("laser-web-disabled.png")
	game._clear_stage()
	var belt := MissionWorld.new()
	game.add_child(belt)
	game.world = belt
	game.mission_world = belt
	belt.build("asteroids")
	game.targets = belt.targets
	belt.advance(10.0, FlightDirector.asteroid_frame(480))
	game.camera.global_transform = FlightDirector.asteroid_frame(480)
	game.hud.phase_title = "PIRATE BOUNTY / OPTIONAL ENGAGEMENT"
	var pirate: PirateSkirmisher = belt.pirates[0]
	game._update_contacts()
	await game._capture("pirate-skirmisher.png")
	game.cursor = game.camera.unproject_position(pirate.global_position)
	await physics_frame
	await physics_frame
	for _i in range(5):
		game.fire_primary()
	check(pirate.destroyed and game.campaign.stats["pirates"] == 1, "The nearby belt pirate is visible, targetable, and pays its bounty")
	game.campaign.dock(true)
	game.hud.show_market(game.campaign)
	await game._capture("outline-market-debrief.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("OUTLINE_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
