extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Vespera appearance requires a native renderer.")
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
	await verify_effects()
	await verify_city()
	await process_frame
	print("VESPERA_RENDER_FAILURES=", failures)
	quit(failures)

func verify_effects() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 78
	camera.position = Vector3(0, 0, 30)
	scene.add_child(camera)
	camera.make_current()
	var gate := CityLaserGate.new()
	scene.add_child(gate)
	var warning: Image = await image("vespera-gate-warning.png")
	gate.age = 2.5
	gate.advance(0, Vector3.ZERO, Vector3.ZERO, 0.6)
	var active: Image = await image("vespera-gate-active.png")
	var warning_pixels: int = 0
	var active_pixels: int = 0
	var center_pixels: int = 0
	for y in range(120, 960):
		for x in range(90, 900):
			warning_pixels += int(warning.get_pixel(x, y).v > 0.5)
			active_pixels += int(active.get_pixel(x, y).v > 0.5)
		for x in range(928, 992):
			center_pixels += int(active.get_pixel(x, y).v > 0.1)
	check(active_pixels > warning_pixels * 1.25, "Active gate beams are visibly fuller than their dashed warning (%d vs %d pixels)" % [active_pixels, warning_pixels])
	check(center_pixels == 0, "The rendered gate leaves a genuinely empty central flight opening")
	gate.queue_free()
	await process_frame
	camera.position = Vector3(0, 6, 180)
	var boss := BossEncounter.new()
	boss.sector = "vespera"
	boss.orbital = true
	scene.add_child(boss)
	boss.advance(0, camera.global_position, Vector3.ZERO)
	boss.cloak.reveal()
	var revealed: Image = await image("vespera-nyx-revealed.png")
	boss.cloak.revealed_remaining = 0
	boss.cloak.age = 3
	boss.cloak.refresh()
	var cloaked: Image = await image("vespera-nyx-shimmer.png")
	boss.model.hide()
	var hidden: Image = await image("")
	var shimmer_pixels: int = changed_pixels(cloaked, hidden)
	var changed: int = changed_pixels(revealed, cloaked)
	print("NYX_RENDER shimmer_pixels=%d changed_on_reveal=%d" % [shimmer_pixels, changed])
	check(shimmer_pixels > 500, "A cloaked Nyx hull remains visibly present rather than disappearing")
	check(changed > 500, "Revealing Nyx materially changes its rendered hull, not just targeting state")
	scene.queue_free()
	await process_frame

func verify_city() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.automation = "--native-fixture"
	game.set_process(false)
	game.set_physics_process(false)
	game.screenshot_directory = capture_dir
	game.campaign = CampaignState.new()
	game.campaign.sector = "vespera"
	game.is_campaign = true
	await game._load_phase()
	game.flight.distance = 700
	game.flight.elapsed = 700 / FlightState.SPEED
	game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._stream_ground(game.flight.distance)
	game._update_camera()
	game.city_traffic.advance(8, game.flight.distance)
	game._update_contacts()
	await game._capture("vespera-city.png")
	var first: Transform3D = game.city_traffic.meshes[0].get_instance_transform(0)
	game.city_traffic.advance(1, game.flight.distance)
	await process_frame
	check(not first.is_equal_approx(game.city_traffic.meshes[0].get_instance_transform(0)), "Native traffic instances actually move above the city")
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	game.flight.elapsed = 28
	game.flight.distance += 28 * FlightState.SPEED
	game.director.advance("ground_boss", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._stream_ground(game.flight.distance)
	game.boss.age = 27.75
	game.boss.advance(0.25, game.camera.global_position, Vector3.ZERO)
	game.hud.objective = game.boss.objective()
	game._update_contacts()
	await game._capture("vespera-overlord.png")
	check(game.boss.core_rings.size() == 3 and game.boss.core_rings[0].rotation.y != game.boss.core_rings[1].rotation.y, "The layered Overlord has independently rotating machinery rings")
	game.hud.show_sector_map(game.campaign)
	await process_frame
	await process_frame
	check(game.hud.menu.get_global_rect().end.x <= game.hud.size.x and game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "The three-sector navigation menu fits the viewport")
	await game._capture("vespera-sector-map.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func image(filename: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Image = root.get_texture().get_image()
	check(result.get_size() == Vector2i(1920, 1080), "Native effect comparison uses actual 1920x1080 rendering")
	if not filename.is_empty() and not capture_dir.is_empty():
		check(result.save_png(capture_dir.path_join(filename)) == OK, "Vespera render capture saved")
	return result

func changed_pixels(a: Image, b: Image) -> int:
	var count: int = 0
	for y in range(360, 700):
		for x in range(540, 1380):
			var first: Color = a.get_pixel(x, y)
			var second: Color = b.get_pixel(x, y)
			if absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b) > 0.025:
				count += 1
	return count

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
