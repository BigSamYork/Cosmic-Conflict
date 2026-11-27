extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Primary beam measurements require a native renderer.")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	root.size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	await measure_profiles()
	await verify_convergence()
	await verify_cockpit()
	await process_frame
	print("PRIMARY_RENDER_FAILURES=", failures)
	quit(failures)

func measure_profiles() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	camera.fov = 78
	scene.add_child(camera)
	camera.make_current()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	scene.add_child(environment)
	for reduced in [false, true]:
		VectorArt.set_reduced_effects(reduced)
		PrimaryArt.set_reduced_effects(reduced)
		var reference: Dictionary = {}
		for level in range(3):
			var effect: Node3D
			if level == 0:
				effect = VectorArt.lines(PackedVector3Array([Vector3(-7, 0, -25), Vector3(7, 0, -25)]), Color("#ffc284"))
				scene.add_child(effect)
			elif level == 1:
				var bolt := PlasmaBolt.new()
				bolt.direction = Vector3.RIGHT
				bolt.position = Vector3(7, 0, -25)
				scene.add_child(bolt)
				effect = bolt
			else:
				var beam := TachyonBeam.new()
				scene.add_child(beam)
				beam.update_path(PackedVector3Array([Vector3(-7, 0, -25)]), Vector3(7, 0, -25))
				effect = beam
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var profile: Array[float] = []
			var peak: float = 0
			var energy: float = 0
			for y in range(508, 572):
				var brightness: float = 0
				for x in range(928, 993, 8):
					var color: Color = image.get_pixel(x, y)
					brightness += color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
				brightness /= 9.0
				profile.append(brightness)
				peak = maxf(peak, brightness)
				energy += brightness
			var width: int = 0
			for brightness in profile:
				if brightness >= maxf(0.01, peak * 0.5):
					width += 1
			print("PRIMARY_PIXELS level=%d reduced=%s width=%d peak=%.4f energy=%.4f" % [level, reduced, width, peak, energy])
			if level == 0:
				reference = {"width": width, "peak": peak, "energy": energy}
				check(width > 0 and peak > 0.1, "The baseline pulse is actually rendered for measurement")
			else:
				check(width >= reference["width"] * (2 if level == 1 else 3), "Native tier %d beam is at least %dx wider with reduced effects %s" % [level, 2 if level == 1 else 3, reduced])
				check(peak >= reference["peak"] * 1.2 and energy >= reference["energy"] * (2 if level == 1 else 3), "Native tier %d has a brighter core and substantially more visible light with reduced effects %s" % [level, reduced])
			if not capture_dir.is_empty():
				check(image.save_png(capture_dir.path_join("beam-profile-%d-%s.png" % [level, "reduced" if reduced else "normal"])) == OK, "Beam comparison image is saved")
			effect.queue_free()
			await process_frame
	scene.queue_free()
	await process_frame

func verify_convergence() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.make_current()
	camera.position = Vector3(-270, 130, 1600)
	camera.rotation = Vector3(0.24, 1.17, -0.31)
	var beam := TachyonBeam.new()
	scene.add_child(beam)
	var origins := PackedVector3Array()
	var placement := CockpitInstruments.artwork_transform(root.get_visible_rect().size)
	for muzzle in GunAppearance.muzzle_points(2):
		origins.append(camera.project_ray_origin(placement * muzzle) + camera.project_ray_normal(placement * muzzle) * 3.5)
	for reduced in [false, true]:
		PrimaryArt.set_reduced_effects(reduced)
		for aim in [Vector2(960, 540), Vector2(1230, 350)]:
			for distance in [12.0, TachyonBeam.RANGE]:
				beam.update_path(origins, camera.global_position + camera.project_ray_normal(aim) * distance)
				await process_frame
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				if not capture_dir.is_empty():
					image.save_png(capture_dir.path_join("convergence-%d-%d-%s.png" % [aim.x, distance, reduced]))
				for muzzle in GunAppearance.muzzle_points(2):
					var aligned := true
					for fraction in [0.1, 0.5, 0.85]:
						var pixel := Vector2i((placement * muzzle).lerp(aim, fraction))
						aligned = aligned and image.get_pixelv(pixel).b > 0.85
					check(aligned, "Tachyon core from %s stays on course to %s at %.0fm (reduced=%s)" % [muzzle, aim, distance, reduced])
	scene.queue_free()
	await process_frame

func verify_cockpit() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	game.automation = "--native-fixture"
	game.normal_save_path = "user://primary-render-%d.json" % OS.get_process_id()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game.automation = "--native-fixture"
	game.settings["reduced_effects"] = false
	game._apply_settings()
	AudioServer.set_bus_mute(0, true)
	game.screenshot_directory = capture_dir
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game._set_ground_environment(false)
	game.camera.global_transform = Transform3D.IDENTITY
	game.cursor = root.get_visible_rect().size * 0.5
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.mode = game.Mode.FLIGHT
	game.hud.campaign = game.campaign
	game.hud.show_menu("flight", game.settings)
	for level in [1, 2]:
		game.campaign.primary_level = level
		game.flight = FlightState.new()
		game.flight.configure_campaign(game.campaign)
		game.hud.flight = game.flight
		game._set_cockpit("rook", level)
		game.hud.phase_title = "ADVANCED PRIMARY / " + game.flight.primary_name().to_upper()
		game.hud.objective = "HEAT-POWERED / SECONDARY ORDNANCE UNCHANGED"
		game.fire_primary()
		if level == 1:
			game._advance_plasma(0.06)
			check(game.plasma_bolts.size() == 4, "Four bright plasma bolts are visible with the correct gun artwork")
		else:
			game._update_tachyon(true)
			check(game.tachyon_beam.visible and game.tachyon_beam.segments.size() == 4, "Four wide muzzle beams form the continuous tachyon effect")
		await process_frame
		await game._capture("primary-cockpit-%d.png" % level)
		game._clear_beams()
	game.pause_flight()
	await process_frame
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "Named advanced-primary inventory fits the pause overlay")
	await game._capture("primary-pause.png")
	game.campaign.primary_level = 1
	game.campaign.dock(false)
	game._show_market()
	await process_frame
	await process_frame
	check(game.hud.menu.get_global_rect().end.y <= game.hud.size.y, "The tachyon upgrade card fits the market")
	await game._capture("primary-market.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
