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
	game.campaign.phase = "asteroids"
	await game._load_phase()
	var brood: EggShip
	for egg in game.targets:
		if egg is EggShip and egg.infested:
			brood = egg
			break
	brood.global_position = game.camera.to_global(Vector3(4, 1, -32))
	game.cursor = game.camera.unproject_position(brood.global_position)
	game._update_contacts()
	var shell: Image = await image("xylo-brood-shell.png")
	game._strike({"collider": brood, "position": brood.global_position}, brood.armor)
	game._advance_explosions(1.0)
	game._advance_parasites(CanopyParasite.LEAP + 0.6)
	var latch: Image = await image("xylo-canopy-latch.png")
	check(changed(shell, latch, Rect2i(760, 280, 395, 220)) > 40000, "The main body fills the upper central windshield")
	check(game.sound.parasite_voice.playing and game.sound.parasite_voice.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "The attached parasite plays a looping growl")
	var hatchling: CanopyParasite = game.parasites[0]
	var bounds := hatchling.body.get_aabb()
	var body_clears_guns := true
	for i in range(8):
		var corner: Vector3 = game.camera.to_local(hatchling.body.to_global(bounds.get_endpoint(i)))
		for muzzle in game._primary_origins():
			body_clears_guns = body_clears_guns and corner.z > game.camera.to_local(muzzle).z
	check(body_clears_guns, "The entire latched body sits inside the gun muzzles")
	var art := CockpitInstruments.artwork_transform(root.get_visible_rect().size)
	var highest_gun := INF
	for tier in range(3):
		for muzzle in GunAppearance.muzzle_points(tier):
			highest_gun = minf(highest_gun, (art * muzzle).y)
	var mouth: Vector2 = game.camera.unproject_position(hatchling.to_global(CanopyParasite.MOUTH))
	check(mouth.distance_to(Vector2(912, 343)) < 6.0, "The mouth lands at the marked position in the 1080p cockpit")
	hatchling.hide()
	await RenderingServer.frame_post_draw
	var empty_pane: Image = root.get_texture().get_image()
	hatchling.show()
	var silhouette := changed_bounds(latch, empty_pane)
	print("CANOPY_SILHOUETTE ", silhouette)
	check(absf(silhouette.position.x - 434) < 55 and absf(silhouette.end.x - 1668) < 55 and silhouette.position.y < 36, "The visible grip spans the marked upper windshield")
	check(silhouette.end.y > 550 and silhouette.end.y < highest_gun - 8.0, "The entire rendered grip reaches the lower edge of the outline and clears all three gun mounts")
	var planted_toe: Node3D = hatchling.toe_prints.get_child(0)
	var footprint := planted_toe.global_position
	check(not hatchling.breached and not hatchling.tongue.visible, "The glass is intact when the body first latches")
	game.computer_voice.set_level(75, false)
	game._advance_parasites(CanopyParasite.BREACH_TIME - 0.6 + 0.5)
	game.cursor = Vector2(960, 535)
	game.fire_primary()
	var extended: Image = await image("xylo-canopy-breach.png")
	# Hold the camera, wet skin and tongue at the same instant. Releasing
	# just the two lobe poses should change both silhouettes independently.
	for side in [-1.0, 1.0]:
		var parameter := &"left_lobe" if side < 0.0 else &"right_lobe"
		var pose: Vector3 = hatchling.body.get_instance_shader_parameter(parameter)
		hatchling.body.set_instance_shader_parameter(parameter, Vector3.ZERO)
		await RenderingServer.frame_post_draw
		var relaxed: Image = root.get_texture().get_image()
		var center: Vector2 = game.camera.unproject_position(hatchling.to_global(Vector3(0.31 * side, -0.84, 0.31)))
		var other: Vector2 = game.camera.unproject_position(hatchling.to_global(Vector3(-0.31 * side, -0.84, 0.31)))
		var patch_size := Vector2i(30, 30)
		check(changed(extended, relaxed, Rect2i(Vector2i(center) - patch_size/2, patch_size)) > 65, "The lower lobe visibly deforms under the tongue's pull")
		check(changed(extended, relaxed, Rect2i(Vector2i(other) - patch_size/2, patch_size)) < 8, "Releasing one lobe leaves the other lobe planted at its own pose")
		hatchling.body.set_instance_shader_parameter(parameter, pose)
		await RenderingServer.frame_post_draw
	check(hatchling.tongue.get_child_count() == 4 and float(hatchling.muscle.get_shader_parameter(&"aperture")) > 0.8, "Four hooks spread open during the reach")
	check(game.sound.voices.any(func(voice: AudioStreamPlayer) -> bool: return voice.stream == preload("res://assets/sfx/canopy_fracture.wav")), "The first puncture plays Small Glass Pane Shatter")
	hatchling.tongue.hide()
	await RenderingServer.frame_post_draw
	var hidden: Image = root.get_texture().get_image()
	var wrist: Vector3 = hatchling.muscle.get_shader_parameter(&"tip")
	var wrist_pixel: Vector2 = game.camera.unproject_position(hatchling.to_global(wrist))
	check(changed(extended, hidden, Rect2i(Vector2i(wrist_pixel) - Vector2i(60, 60), Vector2i(120, 120))) > 1200, "The grasping tip actually renders on the pilot's side of the opening")
	hatchling.tongue.show()
	check(hatchling.wound.visible and hatchling.tongue.visible, "The tongue extends through the fractured side pane")
	var tip: Vector3 = hatchling.transform * Vector3(hatchling.muscle.get_shader_parameter(&"tip"))
	check(footprint.is_equal_approx(planted_toe.global_position) and absf(game.camera.to_local(footprint).z-hatchling.wound.position.z) < 0.005, "The toes stay planted against the punctured pane during the lunge")
	check(game.camera.unproject_position(game.camera.to_global(tip)).y < highest_gun - 20.0, "The tongue grasps at eye level above the weapons")
	check(tip.z > hatchling.wound.position.z + 0.22 and tip.z < -game.camera.near, "The tongue reaches through the glass toward the pilot and stays inside the camera view")
	check(game.computer_voice.last_line == "canopy_panic", "The breach triggers the pilot's recorded scream")
	game._advance_parasites(0.5)
	check(float(hatchling.muscle.get_shader_parameter(&"aperture")) < 0.1, "The hooks close around the grasp")
	await image("xylo-canopy-grasp.png")
	game.pause_flight()
	check(game.sound.parasite_voice.stream_paused, "Pause silences the attached parasite")
	game.resume_flight()
	check(not game.sound.parasite_voice.stream_paused, "Resuming flight resumes the growl")
	game._advance_parasites(CanopyParasite.LATCH + CanopyParasite.SLIDE)
	check(game.parasites.is_empty() and not game.sound.parasite_voice.playing, "Releasing the glass ends the growl")
	check(game.camera.has_node("PortPuncture"), "The broken glass stays in the pane after the parasite departs")
	game._clear_parasites()
	check(not game.camera.has_node("PortPuncture"), "Leaving the cockpit clears the broken pane")
	game.flight.hull = game.flight.max_hull * 0.65
	game.sound.stop_all()
	game._apply_pilot_damage("CANOPY IMPACT", game.flight.max_hull * 0.04, true)
	check(game.sound.voices.any(func(voice: AudioStreamPlayer) -> bool: return voice.stream == preload("res://assets/sfx/canopy_fracture.wav")), "The first damage fracture also plays the glass recording")
	game.sound.stop_all()
	game._apply_pilot_damage("CANOPY IMPACT", game.flight.max_hull * 0.04, true)
	check(game.sound.voices.all(func(voice: AudioStreamPlayer) -> bool: return voice.stream != preload("res://assets/sfx/canopy_fracture.wav")), "Damage to an already cracked pane does not replay its shatter")
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

func changed_bounds(a: Image, b: Image) -> Rect2i:
	# A few isolated pixels also change on the moving egg fleet behind the
	# canopy. Measure patches of solid coverage at twelve-pixel resolution.
	const TILE := 12
	var first := a.get_size()
	var last := Vector2i.ZERO
	for y in range(0, a.get_height() - TILE + 1, TILE):
		for x in range(0, a.get_width() - TILE + 1, TILE):
			var covered := 0
			for dy in range(1, TILE, 3):
				for dx in range(1, TILE, 3):
					var delta := a.get_pixel(x + dx, y + dy) - b.get_pixel(x + dx, y + dy)
					if absf(delta.r) + absf(delta.g) + absf(delta.b) > 0.28:
						covered += 1
			if covered >= 7:
				var center := Vector2i(x + TILE/2, y + TILE/2)
				first = first.min(center)
				last = last.max(center)
	return Rect2i(first, last - first)

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
