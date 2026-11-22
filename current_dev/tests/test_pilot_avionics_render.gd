extends SceneTree

var failures := 0
var captures := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Avionics compositing requires a native renderer.")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(1920, 1080)
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	var game := preload("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.campaign = CampaignState.new()
	game.campaign.phase = "orbit"
	await game._load_phase()
	game.cursor = root.get_visible_rect().get_center()
	game.hud.cursor = game.cursor
	game.settings["reduced_effects"] = false
	game.settings["shake"] = true
	game.flight.primary_level = 1
	game._set_cockpit("rook", 1)
	game._update_camera()
	game._update_contacts()
	var at_rest := await capture("avionics-cruise.png")
	game.flight.shields = 32
	game.flight.request_shield_surge()
	game.flight.fire_cooldown = 0.23
	game.flight.heat = 80
	game.flight.hull = 24
	game.hud.gate_warning = true
	press(game, "radar_range")
	press(game, "heat_governor")
	game._update_contacts()
	check(game.hud.sensors.range_m == 720.0 and game.flight.heat_governor, "Scope and governor are available through the real flight input handler")
	var active := await capture("avionics-damage.png")
	var placement := CockpitInstruments.artwork_transform(root.get_visible_rect().size)
	var rail := Rect2i(Vector2i(placement * Vector2(126, 574)), Vector2i(Vector2(188, 88) * placement.get_scale()))
	check(at_rest.get_region(rail).get_data() != active.get_region(rail).get_data(), "Weapon light reaches the inner cockpit sill")
	var plate := Rect2i(Vector2i(placement * Vector2(440, 718)), Vector2i(Vector2(115, 32) * placement.get_scale()))
	check(at_rest.get_region(plate).get_data() != active.get_region(plate).get_data(), "The physical annunciator responds to shield condition")
	var normal: Basis = game.camera.global_basis
	press(game, "barrel_roll")
	game.flight.advance(FlightState.ROLL_DURATION * 0.5, false)
	game._update_camera()
	check(normal.y.dot(game.camera.global_basis.y) < -0.98, "The roll key inverts the actual camera")
	await capture("avionics-barrel-roll.png")
	game.settings["reduced_effects"] = true
	game._update_camera()
	check(normal.y.dot(game.camera.global_basis.y) > 0.98 and game.flight.deflect_projectile(), "Reduced motion keeps the canopy level and preserves roll protection")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("PILOT_AVIONICS_RENDER_FAILURES=", failures)
	quit(failures)

func press(game: Node, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game._unhandled_input(event)

func capture(filename: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not captures.is_empty():
		check(image.save_png(captures.path_join(filename)) == OK, "Saved " + filename)
	return image

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)
