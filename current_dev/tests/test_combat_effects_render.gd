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
	await check_organic_rupture()
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("COMBAT_EFFECTS_RENDER_FAILURES=", failures)
	quit(failures)

func check_organic_rupture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480, 320)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.environment = Environment.new()
	camera.environment.background_mode = Environment.BG_COLOR
	camera.environment.background_color = Color(0.42, 0.42, 0.42)
	camera.position = Vector3(0, 0, 14)
	viewport.add_child(camera)
	var organ := BossPart.new()
	organ.biological = true
	organ.core = true
	viewport.add_child(organ)
	organ.receive_hit(organ.armor)
	var rupture := DestructionEffect.new()
	rupture.source = organ
	rupture.size = 4.8
	viewport.add_child(rupture)
	rupture.advance(0.43)
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := viewport.get_texture().get_image()
	if not capture_dir.is_empty():
		check(frame.save_png(capture_dir.path_join("xylo-rupture.png")) == OK, "Saved Xylo rupture")
	var blood_pixels := 0
	var fire_pixels := 0
	for y in range(0, frame.get_height(), 2):
		for x in range(0, frame.get_width(), 2):
			var color := frame.get_pixel(x, y)
			blood_pixels += int(color.r > color.g + 0.10 and color.g < 0.40)
			fire_pixels += int(color.r > 0.78 and color.g > 0.49 and color.b < 0.37)
	check(blood_pixels > 100 and fire_pixels == 0, "A ruptured organ ejects visible blood without incandescent sparks")
	organ.free()
	rupture.free()
	for orbital in [false, true]:
		await check_heart_seep(viewport, camera, orbital)
	viewport.queue_free()

func check_heart_seep(viewport: SubViewport, camera: Camera3D, orbital: bool) -> void:
	var boss := BossEncounter.new()
	boss.sector = "xylo"
	boss.orbital = orbital
	viewport.add_child(boss)
	var core := boss.core
	camera.position = core.global_position + Vector3(0, 1, 30)
	camera.look_at(core.global_position)
	boss.advance(0.3, camera.position, Vector3.ZERO)
	check(not boss.breaches.has(core), "The sealed heart has no visible bleed")
	if not capture_dir.is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(capture_dir.path_join("xylo-%s-sealed.png" % ("orbital" if orbital else "ground")))
	if orbital:
		for i in range(3):
			boss.turrets[i].receive_hit(999)
	else:
		boss.parts[0].receive_hit(999)
		boss.parts[1].receive_hit(999)
	boss.advance(0.16, camera.position, Vector3.ZERO)
	check(core.unlocked and core.armor == core.maximum_armor and boss.breaches.has(core), "Opening the torso immediately exposes a bleeding, undamaged heart")
	if boss.breaches.has(core):
		var seep := boss.breaches[core]
		check(is_equal_approx(seep.get_instance_shader_parameter(&"heart_phase"), core.cardiac_phase), "Seep follows cardiac systole")
		await process_frame
		await RenderingServer.frame_post_draw
		var bleeding := viewport.get_texture().get_image()
		if not capture_dir.is_empty():
			bleeding.save_png(capture_dir.path_join("xylo-%s-exposed.png" % ("orbital" if orbital else "ground")))
		seep.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var dry := viewport.get_texture().get_image()
		var center := Vector2i(camera.unproject_position(seep.global_position))
		var changed := 0
		for y in range(maxi(0, center.y - 36), mini(viewport.size.y, center.y + 56)):
			for x in range(maxi(0, center.x - 36), mini(viewport.size.x, center.x + 36)):
				var wet_pixel := bleeding.get_pixel(x, y)
				var dry_pixel := dry.get_pixel(x, y)
				if maxf(absf(wet_pixel.r - dry_pixel.r), absf(wet_pixel.g - dry_pixel.g)) > 0.06:
					changed += 1
		check(changed > 4, "Blood is visible through the opened rib cage")
	boss.free()

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		push_error(description)
		failures += 1
