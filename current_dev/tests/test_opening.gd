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
	check(intro.drone.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and intro.score.stream.resource_path.ends_with("/Fanfare for Space.ogg"), "A pulsing synth bed leads into the launch fanfare")
	intro.set_process(false)
	var seen := {}
	var voices_heard := {}
	for cue: Dictionary in intro.cues:
		check(intro.stage.shot == cue.shot and intro.dialogue.stream.get_length() > 1, "Recorded cue and live set for " + cue.id)
		intro._update_frame(intro.lead + 0.1)
		if cue.id == "knock":
			# Jumping time crosses both the hull taps and the first voice onset.
			check(intro.next_knock == 3, "The distress signal has three knocks")
		check(" ".join(intro.caption_pages) == cue.text and intro.get_node("Overlay/Caption").text == intro.caption_pages[0], "Legible subtitle pages preserve the entire line for " + cue.id)
		for page in intro.caption_pages:
			check(page.length() <= 84, "Subtitle page fits the cockpit view")
		if cue.id == "beacon":
			check(intro.dialogue.bus == intro.radio_bus and intro.get_node("Overlay/Speaker").text == "SPOOFED BEACON", "The false clearance uses Lark's radio voice")
		if cue.shot in intro.stage.FEEDS:
			check(intro.feed_views.size() == 4 and intro.get_node("Overlay/Feeds").visible, "Four live tactical feeds on the holo-table")
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
			check(intro.next_knock == 2 and intro.get_node("Overlay/Caption").text == "[Two metallic pings in reply]", "Vale answers the Aegis-4's signal")
		intro._process(intro.duration - intro.clock + 0.05)
	check(seen.keys() == ["aegis", "blockade", "ignis", "cryo", "vespera", "kharon", "departure", "answer"], "All eight sets appear in script order")
	await scene_changed
	check(current_scene.scene_file_path == "res://main.tscn" and current_scene.hud.mode == "title", "Natural completion reaches the briefing")
	current_scene.hud.opening_requested.emit()
	await scene_changed
	check(current_scene.index == 0, "Replay starts aboard the Aegis-4")
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
