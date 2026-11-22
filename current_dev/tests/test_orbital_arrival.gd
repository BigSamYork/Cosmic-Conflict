extends SceneTree

var failures: int = 0
var capture_dir: String = ""
var game: Node3D
var save_path: String

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred("run")

func run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.unfocusable = true
	root.mouse_passthrough = true
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	save_path = "user://orbital-arrival-test-%d.json" % OS.get_process_id()
	game = load("res://main.tscn").instantiate()
	game.normal_save_path = save_path
	game.automation = "--unit-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	for sector in SectorCatalog.AVAILABLE:
		for fps in [30, 45, 120]:
			await verify_turn(sector, fps)
		if DisplayServer.get_name() != "headless":
			await verify_render(sector)
	await verify_cleanup()
	game.queue_free()
	await process_frame
	if FileAccess.file_exists(save_path):
		check(DirAccess.remove_absolute(save_path) == OK, "Isolated orbital-approach checkpoint removed")
	print("ORBITAL_ARRIVAL_FAILURES=", failures)
	quit(failures)

func prepare(sector: String, frame: Transform3D = Transform3D.IDENTITY) -> void:
	game.campaign = CampaignState.new()
	game.campaign.sector = sector
	game.campaign.phase = "orbit"
	game.campaign.assisted = true
	game.store = CampaignStore.new(save_path)
	await game._load_phase()
	game.flight.elapsed = 90
	game.flight.distance = FlightDirector.DOGFIGHT_SPEED * 90
	game.director.frame = frame
	game._update_camera()

func verify_turn(sector: String, fps: int) -> void:
	var pitch: float = -0.5 if fps == 30 else 0.5 if fps == 45 else 0
	var frame := Transform3D(Basis.from_euler(Vector3(pitch, 0.8, 0)), Vector3(1500, 700, -3300))
	await prepare(sector, frame)
	game.flight.offset = Vector2(9, -5)
	game.flight.request_evasion()
	game._update_camera()
	var start: Transform3D = game.camera.global_transform
	var dogfight: MissionWorld = game.mission_world
	game._finish_phase()
	var preview: MissionWorld = game.approaching_boss
	check(preview != null and preview.boss != null and game.world == dogfight, "%s prepares its real boss before the automatic turn at %dHz" % [sector, fps])
	if preview == null:
		return
	var prepared: BossEncounter = preview.boss
	var boss_pose: Transform3D = prepared.global_transform
	var hull: float = game.flight.hull
	var credits: int = game.campaign.credits
	var shots: int = game.campaign.stats["shots"]
	var weapons: Array[int] = [0]
	preview.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: weapons[0] += 1)
	preview.sweep_requested.connect(func(_emitter: ThermalEmitter) -> void: weapons[0] += 1)
	var paused: bool = false
	var visible_frames: int = 0
	var max_step: float = 0
	var max_turn: float = 0
	var previous: Transform3D = start
	for _i in range(fps * 10):
		if game.mode == game.Mode.FLIGHT:
			break
		if not paused and game.sequence_time >= 0.5:
			paused = true
			game.pause_flight()
			var visual_time: float = prepared.visual_age
			var camera_before: Transform3D = game.camera.global_transform
			var cloak_time: float = prepared.cloak.age if prepared.cloak != null else 0
			game._physics_process(3)
			check(game.hud.transit_seconds == 1 and camera_before.is_equal_approx(game.camera.global_transform) and prepared.visual_age == visual_time and prepared.global_transform.is_equal_approx(boss_pose) and (prepared.cloak == null or prepared.cloak.age == cloak_time), "Pause freezes the %s countdown, turn, boss appearance and cloak without advancing combat" % sector)
			game.resume_flight()
		game._physics_process(1.0 / fps)
		var current: Transform3D = game.camera.global_transform
		max_step = maxf(max_step, previous.origin.distance_to(current.origin))
		max_turn = maxf(max_turn, previous.basis.get_rotation_quaternion().angle_to(current.basis.get_rotation_quaternion()))
		previous = current
		if game.mode == game.Mode.TRANSITION and game.camera.is_position_in_frustum(prepared.core.aim_point()):
			visible_frames += 1
	check(game.mode == game.Mode.FLIGHT and game.campaign.phase == "orbit_boss" and game.boss == prepared and game.world == preview and game.mission_world == preview, "The %s handoff reuses the already-visible boss and world" % sector)
	check(visible_frames >= fps / 3 and start.basis.get_rotation_quaternion().angle_to(game.camera.global_basis.get_rotation_quaternion()) > 1.4, "A real quarter-turn brings %s into view during the one-second intercept" % sector)
	check(max_step < 80.0 / fps and max_turn < 4.5 / fps and game.largest_phase_jump < 0.001 and game.largest_phase_turn < 0.002, "%s turning motion and activation remain continuous at %dHz (%.3fm / %.4frad)" % [sector, fps, max_step, max_turn])
	check(prepared.global_transform.is_equal_approx(boss_pose) and prepared.age == 0 and is_equal_approx(prepared.visual_age, FlightDirector.BOSS_TURN_DURATION) and game.flight.elapsed == 0 and is_inf(game.flight.duration), "The %s preview animates without consuming pursuit time or relocating at activation" % sector)
	check(weapons[0] == 0 and preview.drone_launches == 0 and preview.drone_clock == 3 and not prepared.core.unlocked and not prepared.parts[0].unlocked, "The %s preview cannot attack, launch drones or bypass the boss protection rules" % sector)
	check(game.flight.hull == hull and game.campaign.credits == credits and game.campaign.stats["shots"] == shots and game.retired_world == dogfight, "The intercept turn preserves damage/rewards and retains departed scenery through handoff")
	var saved := CampaignStore.new(save_path)
	check(saved.load_game() == OK and saved.state.phase == "orbit_boss", "The upcoming boss remains the saved phase if the player leaves during the turn")
	var visual_before: float = prepared.visual_age
	game.cursor = root.get_visible_rect().size * 0.5
	game._physics_process(1.0 / fps)
	check(prepared.global_position.distance_to(boss_pose.origin) < 1 and prepared.visual_age > visual_before and game.flight.elapsed > 0, "The first active %s frame starts normal pursuit without a boss jump or visual-clock reset" % sector)
	await process_frame

func verify_render(sector: String) -> void:
	await prepare(sector)
	var without: Image = await image("")
	game._finish_phase()
	var preview: MissionWorld = game.approaching_boss
	var prepared: BossEncounter = preview.boss
	var before: Image = await image(sector + "-turn-start.png")
	check(changed(without, before, Rect2i(180, 300, 1560, 460)) == 0, "%s preparation changes no forward-canopy pixels before the turn" % sector)
	for moment in [0.25, 0.5, 0.75]:
		while game.sequence_time < moment:
			game._physics_process(1.0 / 60)
		await image("%s-turn-%02d.png" % [sector, int(moment * 100)])
	var with_boss: Image = await image("")
	preview.hide()
	var hidden: Image = await image("")
	preview.show()
	var visible: int = changed(with_boss, hidden, Rect2i(180, 290, 1560, 490))
	check(visible > 250, "%s boss is genuinely rendered during the turn, not only present as a node (%d pixels)" % [sector, visible])
	var remaining: float = game.director.transition_duration - game.director.transition_time
	game.director.advance_transition(remaining)
	prepared.advance_visuals(remaining)
	game._update_camera()
	var layers: Array[CanvasLayer] = []
	for child in game.get_children():
		if child is CanvasLayer and child.visible:
			layers.append(child)
			child.hide()
	var pose: Transform3D = prepared.global_transform
	var visual_time: float = prepared.visual_age
	var handoff_before: Image = await image(sector + "-handoff-before.png")
	game._enter_phase(true)
	var handoff_after: Image = await image(sector + "-handoff-after.png")
	var pixels: int = changed(handoff_before, handoff_after, Rect2i(180, 290, 1560, 490))
	check(pixels == 0 and game.boss == prepared and pose.is_equal_approx(prepared.global_transform) and visual_time == prepared.visual_age, "%s boss activation changes zero canopy pixels and preserves the exact pose/appearance (%d changes)" % [sector, pixels])
	for layer in layers:
		layer.show()
	await image(sector + "-pursuit-active.png")

func verify_cleanup() -> void:
	await prepare("cryo")
	game._finish_phase()
	var preview: MissionWorld = game.approaching_boss
	game.show_title()
	await process_frame
	check(game.approaching_boss == null and not is_instance_valid(preview), "Returning to title removes an unfinished boss preview")
	game._continue_campaign()
	await process_frame
	await process_frame
	check(game.campaign.phase == "orbit_boss" and game.boss != null and game.approaching_boss == null and game.boss.age == 0, "Reloading the boss checkpoint creates one normal fresh pursuit without a stale preview")
	await prepare("xylo")
	game._finish_phase()
	preview = game.approaching_boss
	game.campaign.phase = "ground"
	await game._load_phase()
	await process_frame
	check(game.approaching_boss == null and not is_instance_valid(preview), "Changing phases cleans up the prepared boss scene")

func image(filename: String) -> Image:
	game.hud.next_instrument_update = 0
	game.hud._process(0)
	game.hud.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Image = root.get_texture().get_image()
	check(result.get_size() == Vector2i(1920, 1080), "Orbital approach proof renders at actual 1920x1080")
	if not filename.is_empty() and not capture_dir.is_empty():
		check(result.save_png(capture_dir.path_join(filename)) == OK, "Saved orbital approach image: " + filename)
	return result

func changed(first: Image, second: Image, region: Rect2i) -> int:
	var count: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var a: Color = first.get_pixel(x, y)
			var b: Color = second.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.02:
				count += 1
	return count

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
