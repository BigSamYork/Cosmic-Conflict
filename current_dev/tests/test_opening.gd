extends SceneTree

var failures := 0
var native := false
var captures := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	native = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			captures = arg.trim_prefix("--capture-dir=")
	if native:
		root.size = Vector2i(1280, 720)
		root.unfocusable = true
		root.mouse_passthrough = true
	change_scene_to_file("res://launch.tscn" if native else "res://opening.tscn")
	await scene_changed
	if native:
		await scene_changed
	var intro = current_scene
	check(intro.scene_file_path == "res://opening.tscn", "Player boot opens the prologue")
	check(intro.score.stream.resource_path.ends_with("/Fanfare for Space.ogg"), "The narrated prologue opens with Fanfare for Space")
	intro.set_process(false)
	var seen := {}
	var voices_heard := {}
	for cue: Dictionary in intro.cues:
		check(intro.stage.shot == cue.shot and intro.dialogue.stream.get_length() > 1, "Recorded cue and live set for " + cue.id)
		intro._update_frame(intro.lead + 0.1)
		if cue.id == "knock":
			# Jumping time crosses both the hull taps and the first voice onset.
			check(intro.next_knock == 3, "The distress signal has three knocks")
		check(intro.get_node("Overlay/Caption").text == cue.text, "Speaker subtitles follow " + cue.id)
		if native and intro.voice_on and not voices_heard.has(cue.speaker):
			await create_timer(0.18).timeout
			check(intro.dialogue.playing and intro.dialogue.get_playback_position() > 0, "Audio device plays " + cue.speaker)
			voices_heard[cue.speaker] = true
		var start: Vector3 = intro.stage.camera.position
		intro.stage.advance(0.6)
		check(start.distance_to(intro.stage.camera.position) > 0, "Live camera moves in " + cue.shot)
		if not seen.has(cue.shot) and native:
			await capture(cue.shot)
		seen[cue.shot] = true
		intro.dialogue.stop()
		if cue.id == "home":
			intro._update_frame(intro.duration - intro.clock - 0.45)
			check(intro.next_knock == 2 and intro.get_node("Overlay/Caption").text == "[Two knocks in reply]", "Vale answers the ferry's signal")
		intro._process(intro.duration - intro.clock + 0.05)
	for sector in SectorCatalog.AVAILABLE:
		check(seen.has(sector) and SectorCatalog.DISTRESS.has(sector) and SectorCatalog.DISPATCH.has(sector), "Mission and rescue dispatch for " + sector)
	await scene_changed
	check(current_scene.scene_file_path == "res://main.tscn" and current_scene.hud.mode == "title", "Natural completion reaches the briefing")
	current_scene.hud.opening_requested.emit()
	await scene_changed
	check(current_scene.index == 0, "Replay starts with the ferry")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	root.push_input(esc, true)
	await scene_changed
	check(current_scene.scene_file_path == "res://main.tscn", "Escape hands control back to the title")
	print("OPENING_FAILURES=", failures)
	quit(failures)

func capture(id: String) -> void:
	if captures.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(captures.path_join(id + ".png")) == OK, "Captured " + id)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
