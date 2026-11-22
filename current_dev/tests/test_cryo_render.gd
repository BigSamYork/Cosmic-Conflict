extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Cryo coverage requires a native renderer.")
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
	await verify_coverage()
	await verify_game()
	await process_frame
	print("CRYO_RENDER_FAILURES=", failures)
	quit(failures)

func verify_coverage() -> void:
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
	var backdrop := BeltBackdrop.new()
	scene.add_child(backdrop)
	var entry := Transform3D(Basis(Vector3.UP, 0.6), Vector3(2100, 700, -1200))
	var course: Transform3D = entry * Transform3D(FlightDirector.asteroid_frame(0).basis.inverse(), Vector3.ZERO)
	var approach: Transform3D = entry
	approach.origin += entry.basis.z * 1350 - Vector3.UP * 550
	backdrop.build(course, true, FlightDirector.transition_path(approach, entry, 18, FlightState.SPEED, FlightDirector.ASTEROID_SPEED))
	print("CRYO_BACKDROP_ROCKS=", backdrop.rocks.size())
	for child in backdrop.get_children():
		if not child.get_meta("giant", false):
			child.hide()
	var minimum: float = 1.0
	for time in [0.0, 7.0, 15.0, 23.0, 30.0, 37.0, 45.0, 52.0, 59.0]:
		camera.transform = course * FlightDirector.asteroid_frame(time * FlightDirector.ASTEROID_SPEED)
		if time in [7.0, 23.0, 37.0, 52.0]:
			camera.position += camera.basis * Vector3(12 if time < 30 else -12, 7.2 if time in [7.0, 37.0] else -7.2, 0)
		backdrop.animate(time, camera.global_position)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		check(image.get_size() == Vector2i(1920, 1080), "Coverage measures an actual 1920x1080 render target")
		if time == 7.0:
			verify_giant_uploads(backdrop, camera.global_position)
		var covered: int = 0
		var samples: int = 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var horizontal: float = absf((x + 0.5) / image.get_width() * 2 - 1)
				var vertical: float = absf((y + 0.5) / image.get_height() * 2 - 1)
				if horizontal < 0.42 and vertical < 0.42:
					continue
				samples += 1
				var color: Color = image.get_pixel(x, y)
				if color.r + color.g + color.b > 0.08:
					covered += 1
		var coverage: float = float(covered) / samples
		if time <= 52.0:
			minimum = minf(minimum, coverage)
		else:
			check(coverage > 0 and coverage < minimum, "The finite field opens naturally near its end while the last rocks are still passing")
		print("CRYO_PERIPHERY time=%.1f covered=%.5f pixels=%d/%d" % [time, coverage, covered, samples])
		if not capture_dir.is_empty():
			check(image.save_png(capture_dir.path_join("cryo-periphery-%02d.png" % int(time))) == OK, "Peripheral coverage capture saved")
	check(minimum >= 0.995, "Giant oblong rocks fill at least 99.5 percent of the periphery throughout the main field, before its finite exit")
	for child in backdrop.get_children():
		child.show()
	var coast_time: float = FlightDirector.ASTEROID_DURATION + FlightDirector.BELT_COAST_DURATION
	camera.transform = course * FlightDirector.asteroid_frame(coast_time * FlightDirector.ASTEROID_SPEED)
	backdrop.animate(coast_time, camera.global_position)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var cleared: Image = root.get_texture().get_image()
	var rock_pixels: int = 0
	for y in range(cleared.get_height()):
		for x in range(cleared.get_width()):
			var color: Color = cleared.get_pixel(x, y)
			if color.r + color.g + color.b > 0.08:
				rock_pixels += 1
	check(rock_pixels == 0, "All giant and ordinary outer asteroids clear the rendered forward view before the pull-up (%d rock pixels)" % rock_pixels)
	if not capture_dir.is_empty():
		check(cleared.save_png(capture_dir.path_join("cryo-cleared-before-pullup.png")) == OK, "Pre-pull-up clearance capture saved")
	scene.queue_free()
	await process_frame

func verify_giant_uploads(backdrop: BeltBackdrop, pilot: Vector3) -> void:
	var slowest: float = INF
	var fastest: float = 0.0
	var aligned: bool = true
	var stable: bool = true
	var camera: Camera3D = backdrop.get_viewport().get_camera_3d()
	for batch in backdrop.batches:
		if not batch["giant"] or pilot.distance_to(batch["center"]) > VectorArt.VIEW_DISTANCE:
			continue
		var meshes: Array[MultiMesh] = batch["meshes"]
		var original: Array[Transform3D] = batch["transforms"]
		for i in range(original.size()):
			if camera.is_position_behind(backdrop.global_transform * original[i].origin):
				continue
			var uploaded: Transform3D = meshes[0].get_instance_transform(i)
			var angle: float = original[i].basis.orthonormalized().get_rotation_quaternion().angle_to(uploaded.basis.orthonormalized().get_rotation_quaternion())
			slowest = minf(slowest, angle)
			fastest = maxf(fastest, angle)
			aligned = aligned and uploaded.is_equal_approx(meshes[1].get_instance_transform(i))
			stable = stable and uploaded.origin.is_equal_approx(original[i].origin) and uploaded.basis.get_scale().is_equal_approx(original[i].basis.get_scale())
	check(slowest > 0.1 and fastest > slowest * 4, "Rendered giants actually rotate at distinct rates")
	check(aligned and stable, "Giant solids and crater strokes tumble together without changing their scale or centers")

func verify_game() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.automation = "--native-fixture"
	game.set_process(false)
	game.set_physics_process(false)
	game.screenshot_directory = capture_dir
	game._open_sector_map(true)
	await process_frame
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y and game.hud.menu.get_global_rect().end.x <= game.hud.size.x, "The sector-selection interface fits the native viewport")
	await game._capture("sector-selection.png")
	game.campaign = CampaignState.new()
	game.campaign.sector = "cryo"
	game.campaign.phase = "ground"
	game.is_campaign = true
	await game._load_phase()
	game.flight.distance = 500
	game.flight.elapsed = 500.0 / FlightState.SPEED
	game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._stream_ground(game.flight.distance)
	game._update_contacts()
	await game._capture("cryo-frozen-river.png")
	game.flight.apply_frost()
	await create_timer(0.05).timeout
	await game._capture("cryo-frost-warning.png")
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	game.flight.elapsed = 28
	game.flight.distance += 28 * FlightState.SPEED
	game.director.advance("ground_boss", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._stream_ground(game.flight.distance)
	game.boss.age = 28
	game.boss._update_pursuit()
	game._update_contacts()
	check(game.boss.drill != null, "The Glacier Bore-Mech has a real animated drill assembly")
	await game._capture("cryo-bore-mech.png")
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	game.flight.elapsed = 28
	game.flight.distance = 28 * FlightState.SPEED
	game.director.advance("orbit_boss", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game.boss.age = 28
	game.boss._update_pursuit()
	game.boss.advance(0.1, game.camera.global_position, Vector3.ZERO)
	game.mission_world.advance(3.1, game.director.frame)
	game._update_contacts()
	check(game.boss.drone_bay != null and game.mission_world.carrier_drones.size() == 2, "The Hydra renders its distinct carrier hull and launched drones")
	await game._capture("cryo-hydra.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
