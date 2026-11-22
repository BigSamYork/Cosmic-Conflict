extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Secondary weapon appearance requires a native renderer.")
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
	game.automation = "--native-fixture"
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game.camera.global_transform = Transform3D.IDENTITY
	game._set_ground_environment(false)
	game.campaign = CampaignState.new()
	game.campaign.secondary = true
	game.campaign.swarm_launcher = true
	game.campaign.emp_launcher = true
	game.campaign.ship = "hawk"
	game.campaign.hull = game.campaign.hull_capacity()
	game.campaign.shields = game.campaign.shield_capacity()
	game.campaign.ammo = 8
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game._set_cockpit("hawk")
	game.hud.phase_title = "ORBITAL DOGFIGHT / TACTICAL STATIONS"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	game.mode = game.Mode.PAUSE
	game._select_secondary("swarm")
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "Tactical weapon switching fits inside the pause menu")
	await game._capture("tactical-station-selector.png")
	game.mode = game.Mode.FLIGHT
	game.hud.show_menu("flight", game.settings)
	game.hud.phase_title = "SWARM ROCKETS / MULTI-TARGET LOCK"
	for i in range(3):
		var fighter := EnemyFighter.new()
		fighter.new_design = true
		fighter.winged = i == 1
		fighter.delta_wing = i == 2
		game.world.add_child(fighter)
		fighter.global_position = Vector3((i - 1) * 13, 3 if i == 1 else 0, -75 - i * 6)
		game.targets.append(fighter)
	await physics_frame
	await physics_frame
	game.fire_secondary()
	game._advance_torpedoes(0.1)
	game._update_contacts()
	check(game.torpedoes.size() == 3 and game.flight.ammo == 6, "Native swarm launches three visible rockets from two ordnance units")
	await game._capture("swarm-rockets-in-flight.png")
	for _i in range(100):
		game._advance_torpedoes(1.0 / 60.0)
		await physics_frame
		if game.torpedoes.is_empty():
			break
	check(game.flight.destroyed == 3 and game.flight.hits == 3, "Rendered homing rockets reach their three separate enemy targets")
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	var boss := BossEncounter.new()
	boss.orbital = true
	boss.position = Vector3(0, 0, -150)
	game.world.add_child(boss)
	game.boss = boss
	game.targets.assign(boss.parts)
	boss.advance(0.1, game.camera.global_position, Vector3.ZERO)
	game._launch_missile(Vector3(-12, 0, -50), Vector3.BACK)
	game._launch_missile(Vector3(10, 4, -65), Vector3.BACK)
	game._start_thermal_sweep(boss.thermal_emitter)
	game.mode = game.Mode.PAUSE
	game._select_secondary("emp")
	game.mode = game.Mode.FLIGHT
	game.hud.show_menu("flight", game.settings)
	game.hud.phase_title = "EMP NOVA / CAPITAL SYSTEMS DISABLED"
	game.flight.secondary_cooldown = 0
	await physics_frame
	await physics_frame
	game.fire_secondary()
	game._advance_emp_pulses(0.06)
	game._update_contacts()
	check(game.flight.ammo == 3 and boss.stun_remaining > 0 and not game.missiles[0].active and not game.missiles[1].active and game.thermal_sweeps.is_empty(), "Native EMP clears visible missiles and cancels the capital beam without destroying generators")
	await game._capture("emp-nova-capital-stun.png")
	game.campaign.ammo = game.flight.ammo
	game.campaign.dock(true)
	game._show_market()
	await process_frame
	await process_frame
	var scroll: ScrollContainer = game.hud.menu.find_child("EquipmentScroll", true, false)
	check(scroll != null, "Market exposes the equipment scroller")
	if scroll != null:
		scroll.set_deferred("scroll_vertical", 300)
	await process_frame
	await process_frame
	check(scroll != null and scroll.scroll_vertical > 0, "New secondary cards can be reached by scrolling the market")
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "Market station selection and new weapon cards fit the screen")
	await game._capture("tactical-market-weapons.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("SECONDARY_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
