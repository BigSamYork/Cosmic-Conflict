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
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	var game: Node3D = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.settings["reduced_effects"] = false
	for sector in ["ignis", "cryo", "vespera", "xylo", "thalassa", "kharon"]:
		game.campaign.sector = sector
		game.campaign.phase = "ground"
		await game._load_phase()
		game.flight.distance = 690.0
		game.flight.elapsed = game.flight.distance / FlightState.SPEED
		game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
		game._stream_ground(game.flight.distance)
		game._update_camera()
		game._update_contacts()
		game.surface_weather.advance(3.2)
		check(game.surface_weather.visible and game.surface_weather.climate == sector, sector + " has its own cockpit weather")
		await snapshot("surface-" + sector + ".png")
	game.settings["reduced_effects"] = true
	game._apply_settings()
	check(not game.surface_weather.visible, "Reduced effects removes close particles")
	await snapshot("surface-kharon-reduced.png")
	game.sound.stop_all()
	game.free()
	await process_frame
	# Isolate the pass to prove actual GPU visibility and steady motion.
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.make_current()
	var weather := SurfaceWeather.new()
	camera.add_child(weather)
	weather.configure("cryo", true, true)
	var bare := await snapshot("")
	weather.configure("cryo", true, false)
	var snow := await snapshot("")
	weather.advance(1.7)
	var moved := await snapshot("")
	check(different(bare, snow) > 20 and different(snow, moved) > 25, "Sector particles illuminate real pixels and travel between frames")
	weather.configure("cryo", false, false)
	var space := await snapshot("")
	check(different(bare, space) == 0, "Particles clear immediately on the transition to space")
	scene.free()
	print("SURFACE_WEATHER_RENDER_FAILURES=", failures)
	quit(failures)

func snapshot(filename: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not filename.is_empty() and not captures.is_empty():
		check(image.save_png(captures.path_join(filename)) == OK, "Save " + filename)
	return image

func different(first: Image, second: Image) -> int:
	var a := first.get_data()
	var b := second.get_data()
	var count := 0
	for i in a.size():
		if absi(a[i] - b[i]) > 3:
			count += 1
	return count

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
