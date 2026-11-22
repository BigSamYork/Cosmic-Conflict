extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Countermeasure rendering requires a native renderer.")
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
	game.campaign.assisted = true
	game.campaign.countermeasures = true
	game.campaign.flares = 3
	game.campaign.secondary = true
	game.campaign.ammo = 6
	game.campaign.reward(1000)
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.hud.phase_title = "COUNTERMEASURES / BREAKING MISSILE LOCKS"
	game.hud.show_menu("flight", game.settings)
	game.mode = game.Mode.FLIGHT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	for i in range(4):
		game._launch_missile(Vector3((i - 1.5) * 5, (i % 2) * 3, -45 - i * 7), Vector3.BACK)
	game._launch_missile(Vector3(0, 0, -180), Vector3.BACK)
	await physics_frame
	await physics_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = true
	game._unhandled_input(key)
	var previous: Vector3 = game.camera.global_position
	game.camera.global_position += Vector3.FORWARD * 42 * 0.15
	game._advance_missiles(0.15, previous, game.camera.global_position)
	game._advance_flare_clouds(0.15)
	game._update_contacts()
	check(game.campaign.flares == 2 and game.flight.ammo == 6 and game.flare_clouds.size() == 1 and game.hud.incoming.size() == 1, "Native C deployment visibly breaks four locks while keeping separate ordnance unchanged")
	await game._capture("countermeasure-diversion.png")
	game.pause_flight()
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "Pause inventory displays flare charges and cooldown without clipping")
	await game._capture("countermeasure-inventory.png")
	var path: String = "user://countermeasure-render-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	game.campaign = game._snapshot()
	game.campaign.dock(false)
	game._show_market()
	game._market_purchase("flare_reload")
	check(game.campaign.flares == 3 and game.campaign.ammo == 6, "Native market reload refills only the dedicated flare pod")
	await process_frame
	await process_frame
	var scroll: ScrollContainer = game.hud.menu.find_child("EquipmentScroll", true, false)
	check(scroll != null, "Countermeasure market cards have a reachable scroller")
	if scroll != null:
		scroll.set_deferred("scroll_vertical", 10000)
	await process_frame
	await process_frame
	await game._capture("countermeasure-market.png")
	game._toggle_debug()
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "The expanded developer controls fit the screen")
	await game._capture("expanded-debug-controls.png")
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("COUNTERMEASURE_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
