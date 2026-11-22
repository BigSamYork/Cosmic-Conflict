extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Xylo appearance requires a native renderer.")
		quit(1)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	await verify_hive()
	await verify_geysers()
	await verify_swamp()
	await process_frame
	print("XYLO_RENDER_FAILURES=", failures)
	quit(failures)

func verify_hive() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 78
	camera.far = VectorArt.VIEW_DISTANCE
	scene.add_child(camera)
	camera.make_current()
	var world := MissionWorld.new()
	scene.add_child(world)
	var entry := Transform3D(Basis(Vector3.UP, 0.6), Vector3(2100, 700, -1200))
	var course: Transform3D = entry * Transform3D(FlightDirector.asteroid_frame(0).basis.inverse(), Vector3.ZERO)
	var from: Transform3D = entry
	from.origin += entry.basis.z * 1350 - Vector3.UP * 550
	world.build("asteroids", course, "xylo", FlightDirector.transition_path(from, entry, FlightDirector.BELT_TRANSFER_DURATION, FlightState.SPEED, FlightDirector.ASTEROID_SPEED))
	var mothers: int = 0
	var eggs: int = 0
	for body in world.backdrop.rocks:
		mothers += int(body["kind"] == "mother")
		eggs += int(body["kind"] == "egg")
	check(mothers > 0 and eggs > 0 and world.targets.all(func(target: RangeTarget) -> bool: return target is EggShip), "Both large mothers and egg ships populate the field without asteroid models")
	print("HIVE_POPULATION mothers=%d background_eggs=%d physical_eggs=%d" % [mothers, eggs, world.targets.size()])
	var exit_time: float = 60.0 + FlightDirector.BELT_COAST_DURATION
	for time in [10.0, 30.0, 55.0, exit_time]:
		camera.transform = course * FlightDirector.asteroid_frame(time * FlightDirector.ASTEROID_SPEED)
		world.visual_time = time
		world.animate_belt(0, camera.global_transform)
		var frame: Image = await image("xylo-hive-%02d.png" % int(time))
		var pixels: int = 0
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var color: Color = frame.get_pixel(x, y)
				pixels += int(color.r + color.g + color.b > 0.08)
		if is_equal_approx(time, exit_time):
			check(pixels == 0, "All hive/egg bodies clear the forward rendered view before the docking pull-up (%d pixels)" % pixels)
		else:
			check(pixels > 60000, "The biological fleet is substantially visible at %.0fs (%d pixels)" % [time, pixels])
	scene.queue_free()
	await process_frame

func verify_geysers() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 7, 24)
	camera.fov = 60
	scene.add_child(camera)
	camera.make_current()
	var field := XyloField.new()
	scene.add_child(field)
	field.age = 1.0
	field.advance(0, Vector3.ZERO, Vector3.ZERO)
	var warning: Image = await image("xylo-acid-warning.png")
	field.age = 2.5
	field.advance(0, Vector3.ZERO, Vector3.ZERO)
	var eruption: Image = await image("xylo-acid-eruption.png")
	check(changed(warning, eruption, Rect2i(700, 100, 520, 800)) > 500, "The corrosive eruption visibly grows beyond its warning ring")
	field.queue_free()
	await process_frame
	var spores := XyloField.new()
	spores.kind = XyloField.Kind.SPORES
	scene.add_child(spores)
	spores.age = 2.5
	spores.advance(0, Vector3.ZERO, Vector3.ZERO)
	await image("xylo-spore-cloud.png")
	scene.queue_free()
	await process_frame

func verify_swamp() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.automation = "--native-fixture"
	game.set_process(false)
	game.set_physics_process(false)
	game.screenshot_directory = capture_dir
	game.campaign = CampaignState.new()
	game.campaign.sector = "xylo"
	game.is_campaign = true
	await game._load_phase()
	game.flight.distance = 700
	game.flight.elapsed = 700 / FlightState.SPEED
	game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._stream_ground(game.flight.distance)
	game._update_camera()
	game._update_contacts()
	await game._capture("xylo-swamp.png")
	game.hud.incoming.append(Vector2(400, 200))
	await create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	var normal: Image = game.hud.instrument_viewport.get_texture().get_image()
	game.flight.apply_spores()
	await create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	var static_frame: Image = game.hud.instrument_viewport.get_texture().get_image()
	check(changed(normal, static_frame, Rect2i(512, 128, 256, 224)) > 100, "Spore interference visibly changes the actual radar instrument")
	check(changed(normal, static_frame, Rect2i(0, 0, 512, 352)) == 0, "Spore static leaves critical warnings, hull/shields and weapon instruments unchanged")
	await game._capture("xylo-radar-static.png")
	game.pause_flight()
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "Pause/settings, including the separate voice control, fit the viewport")
	await game._capture("xylo-pause-voice-control.png")
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	game.flight.elapsed = 28
	game.flight.distance += 28 * FlightState.SPEED
	game.director.advance("ground_boss", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._stream_ground(game.flight.distance)
	game.boss.age = 28
	game.boss.advance(0, game.camera.global_position, Vector3.ZERO)
	game._update_contacts()
	game.hud.objective = game.boss.objective()
	await game._capture("xylo-goliath.png")
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	game.flight.elapsed = 28
	game.flight.distance = 28 * FlightState.SPEED
	game.director.advance("orbit_boss", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game.boss.age = 28
	game.boss.advance(0, game.camera.global_position, Vector3.ZERO)
	game._update_contacts()
	game.hud.objective = game.boss.objective()
	await game._capture("xylo-leviathan.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func image(filename: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == Vector2i(1920, 1080), "Hive inspection uses actual 1920x1080 rendering")
	if not capture_dir.is_empty():
		check(frame.save_png(capture_dir.path_join(filename)) == OK, "Biological field capture saved")
	return frame

func changed(a: Image, b: Image, region: Rect2i) -> int:
	var count: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var first: Color = a.get_pixel(x, y)
			var second: Color = b.get_pixel(x, y)
			if absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b) > 0.01:
				count += 1
	return count

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
