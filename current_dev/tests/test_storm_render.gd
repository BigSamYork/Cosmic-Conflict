extends SceneTree

var failures := 0
var captures := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	var game = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.campaign.sector = "thalassa"
	game.campaign.phase = "ground"
	await game._load_phase()
	var field: StormLightning = game.lightning_fields[0]
	field.age = StormLightning.CYCLE + 0.8
	field.advance(0.01, field.global_position, field.global_position)
	var destination := field.to_global(field.landing)
	var rig: OffshorePlatform
	for platform: OffshorePlatform in get_nodes_in_group(&"offshore_platforms"):
		if platform.global_position.distance_to(destination) < 4.0:
			rig = platform
	assert(rig != null)
	game.camera.global_position = destination + Vector3(35, 15, 110)
	game.camera.look_at(destination + Vector3.UP * 33)
	game._update_contacts()
	await physics_frame
	await physics_frame
	var bright := -1
	var leader := -1
	var returned := -1
	var fading := -1
	for i in range(79):
		game._advance_storm(1.0 / 30.0, game.camera.global_position)
		game._advance_debris(1.0 / 30.0)
		game._advance_explosions(1.0 / 30.0)
		game._advance_ocean(1.0 / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		# Isolate the upper, cloud-side channel from the impact and the ocean.
		var a: Vector2 = game.camera.unproject_position(field.to_global(field.paths[0][0]))
		var b: Vector2 = game.camera.unproject_position(field.to_global(field.paths[0][5]))
		var region := Rect2i(Rect2(a, Vector2.ZERO).expand(b).grow(14)).intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
		if i in [15, 21, 26, 28]:
			var luminous := 0
			for y in range(region.position.y, region.end.y):
				for x in range(region.position.x, region.end.x):
					var color := frame.get_pixel(x, y)
					luminous += int(color.b > 0.57 and color.g > 0.43)
			match i:
				15: leader = luminous
				21: bright = luminous
				26: fading = luminous
				28: returned = luminous
		if not captures.is_empty():
			frame.save_png(captures.path_join("strike-%03d.png" % i))
	check(bright > leader + 15 and returned > fading + 10, "The native bolt brightens on the first and return strokes (%d, %d, %d, %d)" % [leader, bright, fading, returned])
	check(not rig.visible and rig.collision_layer == 0 and not game.explosions.is_empty(), "A normal storm cycle detonates its offshore structure in the rendered scene")
	game.settings["reduced_effects"] = true
	game._apply_settings()
	field.age = StormLightning.CYCLE * 2 + StormLightning.WARNING - 0.02
	game._advance_storm(0.04, game.camera.global_position)
	var sky: ShaderMaterial = game.get_world_3d().environment.sky.sky_material
	check(field.channel.visible and field.ink.get_shader_parameter("quiet") and is_zero_approx(sky.get_shader_parameter("storm_glow")), "Reduced effects keeps the strike readable without cloud flashes")
	game.sound.stop_all()
	game.free()
	await process_frame
	print("STORM_RENDER_FAILURES=", failures)
	quit(failures)

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
