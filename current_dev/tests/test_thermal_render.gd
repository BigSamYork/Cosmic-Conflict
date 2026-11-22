extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Thermal effects require a native renderer.")
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
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game._build_world(false)
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.hud.show_menu("flight", game.settings)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	game.camera.global_transform = FlightState.rail_frame(400)
	var vent: HeatVent = game.heat_vents[0]
	game.camera.look_at(vent.global_position + Vector3.UP * 10, Vector3.UP)
	vent.advance(0.2, game.camera.global_position, game.camera.global_position)
	game.hud.phase_title = "IGNIS VENT / WARNING"
	game._update_contacts()
	await game._capture("heat-vent-warning.png")
	await RenderingServer.frame_post_draw
	var initial: Image = root.get_texture().get_image()
	var buildup_pixels: int = 0
	var peak_pixels: int = 0
	var at := Vector2i(game.camera.unproject_position(vent.global_position + Vector3.UP * 14))
	var region := Rect2i(at - Vector2i(250, 260), Vector2i(500, 500)).intersection(Rect2i(Vector2i.ZERO, initial.get_size()))
	for stage in [[1.2, "lava-buildup"], [2.0, "rising-column"], [3.2, "ash-burst"], [5.8, "subsiding"]]:
		vent.age = stage[0]
		vent.advance(0, game.camera.global_position, game.camera.global_position)
		game.hud.phase_title = "VOLCANIC CONE / " + String(stage[1]).replace("-", " ").to_upper()
		game._update_contacts()
		await game._capture("volcano-" + stage[1] + ".png")
		await RenderingServer.frame_post_draw
		var pixels: int = ash_pixels(root.get_texture().get_image(), initial, region)
		print("VOLCANIC_ASH stage=", stage[1], " changed_pixels=", pixels)
		if stage[1] == "lava-buildup":
			buildup_pixels = pixels
		elif stage[1] == "ash-burst":
			peak_pixels = pixels
			check(peak_pixels > 800 and peak_pixels > buildup_pixels * 1.8, "Native eruption develops substantially broader billowing ash than the smoke warning")
		elif stage[1] == "subsiding":
			check(pixels < peak_pixels * 0.7, "Native ash visibly dissipates after the hot eruption")
	vent.age = 2.0
	vent.advance(0, game.camera.global_position, game.camera.global_position)
	game._update_contacts()
	check(vent.plume.visible and game.hud.vent_warning, "Active heat plume and cockpit caution are rendered")
	await game._capture("heat-vent-eruption.png")
	game._clear_stage()
	game._set_ground_environment(false)
	var world := MissionWorld.new()
	game.add_child(world)
	game.world = world
	game.mission_world = world
	world.build("orbit_boss")
	game.boss = world.boss
	game.boss.pursuing = false
	game.targets = world.targets
	game.camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 7, 140))
	game.mode = game.Mode.FLIGHT
	world.sweep_requested.connect(game._start_thermal_sweep)
	game.boss.advance(4.1, game.camera.global_position, Vector3.ZERO)
	game.hud.phase_title = "SOLAR FLARE CRUISER / THERMAL PROJECTOR"
	game._update_contacts()
	check(game.thermal_sweeps.size() == 1 and game.hud.thermal_warning, "Boss projector starts a visible charged sweep warning")
	if game.thermal_sweeps.is_empty():
		game.queue_free()
		await process_frame
		quit(1)
		return
	await game._capture("thermal-sweep-warning.png")
	game._advance_thermal_hazards(2.2, game.camera.global_position + Vector3.UP * 5, game.camera.global_position + Vector3.UP * 5)
	check(game.thermal_sweeps[0].beam.visible, "Charged thermal beam becomes visible after the warning")
	await game._capture("thermal-sweep-active.png")
	var emitter: ThermalEmitter = game.boss.thermal_emitter
	game.cursor = game.camera.unproject_position(emitter.aim_point())
	await physics_frame
	await physics_frame
	for _i in range(emitter.maximum_armor):
		game.fire_primary()
	check(emitter.destroyed and not emitter.visible, "Actual primary rays destroy the separate thermal projector")
	game._advance_thermal_hazards(0.02, game.camera.global_position, game.camera.global_position)
	check(game.thermal_sweeps.is_empty(), "Destroying the projector removes its live beam")
	game._update_contacts()
	game._advance_debris(0.5)
	game._advance_explosions(0.8)
	await game._capture("thermal-projector-destroyed.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("THERMAL_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func ash_pixels(image: Image, initial: Image, region: Rect2i) -> int:
	var count: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var color: Color = image.get_pixel(x, y)
			var before: Color = initial.get_pixel(x, y)
			var light: float = (color.r + color.g + color.b) / 3.0
			if light > 0.14 and absf(color.r - color.g) < 0.15 and absf(color.g - color.b) < 0.15 and light > (before.r + before.g + before.b) / 3.0 + 0.05:
				count += 1
	return count
