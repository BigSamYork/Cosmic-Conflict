extends SceneTree

var failures := 0
var capture_dir := ""

func _initialize() -> void:
	call_deferred("run")

func shot(filename: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if not capture_dir.is_empty():
		check(frame.save_png(capture_dir.path_join(filename)) == OK, "Saved " + filename)
	return frame

func brighter(a: Image, b: Image) -> int:
	var count := 0
	for y in range(225, 755, 3):
		for x in range(460, 1460, 3):
			count += int(b.get_pixel(x, y).get_luminance() - a.get_pixel(x, y).get_luminance() > 0.035)
	return count

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = root.content_scale_size
	root.unfocusable = true
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	var game = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.campaign = CampaignState.new()
	game.campaign.sector = "thalassa"
	game.campaign.phase = "ground_boss"
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.world = Node3D.new()
	game.add_child(game.world)
	game.boss = BossEncounter.new()
	game.boss.sector = "thalassa"
	game.world.add_child(game.boss)
	game._set_ground_environment(true)
	game.hud.show_menu("flight", game.settings)
	game.hud.campaign = game.campaign
	game.hud.phase_title = "TEMPEST WALKER"
	game.mode = game.Mode.FLIGHT
	game.camera.position = Vector3(23, 14, 54)
	game.camera.look_at(Vector3(0, 4, 0))
	game.targets.assign(game.boss.parts)
	game.boss.advance_visuals(0.4)
	game._update_contacts()
	var intact: Image = await shot("tempest-intact.png")
	var at: Vector3 = game.boss.parts[0].aim_point() + Vector3(0, 2.0, 1)
	game.combat_lights.flash(at, Color("#ff9a4e"), 36, 0.8, 6.0)
	var hot: Image = await shot("tempest-impact-light.png")
	check(brighter(intact, hot) > 80, "A local flash visibly illuminates the intact armor")
	var effect := DestructionEffect.new()
	effect.position = at
	effect.size = 9.0
	game.world.add_child(effect)
	effect.advance(0.68)
	var plume: Image = await shot("tempest-plume.png")
	check(brighter(hot, plume) > 80, "Incandescent particles appear at the world-space contact")
	game.settings["reduced_effects"] = true
	game._apply_settings()
	check(not game.get_world_3d().environment.glow_enabled and not game.surface_weather.visible and not game.combat_lights.lamps[0].visible, "Reduced effects disable bloom, weather and flash lights")
	await shot("tempest-reduced.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("COMBAT_EFFECTS_RENDER_FAILURES=", failures)
	quit(failures)

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		push_error(description)
		failures += 1
