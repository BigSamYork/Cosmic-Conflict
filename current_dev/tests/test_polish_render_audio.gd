extends SceneTree

var failures: int = 0
var folder: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Polish presentation verification requires native rendering and audio.")
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
			folder = argument.trim_prefix("--capture-dir=")
	await verify_audio()
	await verify_visuals()
	await process_frame
	print("POLISH_RENDER_AUDIO_FAILURES=", failures)
	quit(failures)

func verify_audio() -> void:
	var music := AmbientMusic.new()
	root.add_child(music)
	music.set_level(70, false)
	var bus: int = AudioServer.get_bus_index(music.bus_name)
	var recording := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus, recording)
	recording.set_recording_active(true)
	await create_timer(5).timeout
	check(music.failure_message.is_empty() and music.players[music.active].playing and music.players[music.active].get_playback_position() > 4, "The original station soundtrack produces real native playback")
	var peak: float = AudioServer.get_bus_peak_volume_left_db(bus, 0)
	check(peak > -60 and peak < -10, "Native soundtrack signal is restrained rather than silent or clipped (%.2fdB)" % peak)
	music.request_scene("cryo")
	await create_timer(0.5).timeout
	check(music.players[0].playing and music.players[1].playing and music.current == "cryo", "Sector music crossfades through two actual playing recordings")
	var fade: float = music.fade_time
	var position: float = music.players[music.active].get_playback_position()
	music.set_paused(true)
	await create_timer(0.3).timeout
	check(music.fade_time == fade and absf(music.players[music.active].get_playback_position() - position) < 0.06, "Pause freezes both music playback and its crossfade")
	music.set_paused(false)
	await create_timer(4).timeout
	check(not music.players[1 - music.active].playing, "A finished crossfade stops the old stream")
	var voice := ComputerVoice.new()
	voice.speaking_changed.connect(music.set_ducked)
	root.add_child(voice)
	voice.set_level(70, false)
	var before: float = AudioServer.get_bus_volume_db(bus)
	check(voice.say("hull_critical"), "A real computer warning starts over the soundtrack")
	await create_timer(0.5).timeout
	check(AudioServer.get_bus_volume_db(bus) < before - 9, "Actual computer speech ducks music by more than nine decibels")
	voice.stop_speech()
	await create_timer(2).timeout
	check(AudioServer.get_bus_volume_db(bus) > before - 1, "Ambient level recovers smoothly after the voice finishes")
	music.players[music.active].seek(63.8)
	await create_timer(0.6).timeout
	check(music.players[music.active].playing and music.players[music.active].get_playback_position() < 1, "The imported recording loops through its actual end without stopping")
	music.request_scene("boss")
	await create_timer(4.5).timeout
	check(music.current == "boss" and music.players[music.active].playing, "Boss encounters use the restrained pressure theme")
	recording.set_recording_active(false)
	if not folder.is_empty():
		var sample: AudioStreamWAV = recording.get_recording()
		check(sample != null and sample.get_length() > 12 and sample.save_to_wav(folder.path_join("ambient-preview.wav")) == OK, "Preview records only the game's own original music bus with master output muted")
	music.set_level(0, false)
	check(not music.players[0].playing and not music.players[1].playing, "Zero music volume stops both soundtrack streams")
	music.set_level(70, true)
	await create_timer(0.1).timeout
	check(not music.players[0].playing and not music.players[1].playing, "Master-mute/automation suppression keeps the soundtrack off")
	voice.queue_free()
	music.queue_free()
	await process_frame

func verify_visuals() -> void:
	var game: Node3D = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	game.normal_save_path = "user://polish-native-%d.json" % OS.get_process_id()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.hud.can_resume = true
	game.hud.show_menu("title", game.settings)
	await capture(game, "music-title-settings")
	check(game.get_viewport().get_visible_rect().encloses(game.hud.menu.get_global_rect()), "The added music control leaves every title action inside the native viewport")
	game.campaign = CampaignState.new()
	game.campaign.sector = "cryo"
	game.campaign.phase = "ground"
	game.is_campaign = true
	await game._load_phase()
	var ice: FallingIce = game.falling_ice[0]
	game.flight.distance = ice.travel - 100
	game.flight.elapsed = game.flight.distance / FlightState.SPEED
	game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._stream_ground(game.flight.distance)
	ice.started = true
	ice.age = 0.6
	ice._update_pose()
	game._update_contacts()
	await capture(game, "ice-warning")
	check(ice.marker.visible and ice.warning() and not game.camera.is_position_behind(ice.global_position), "The two-second side-lane warning and hanging chunk are in the real forward view")
	var before: Vector2 = game.camera.unproject_position(ice.global_position)
	ice.age = 3.2
	ice._update_pose()
	game._update_contacts()
	var after: Vector2 = game.camera.unproject_position(ice.global_position)
	check(after.y > before.y + 35 and ice.position.y < 17, "The visible chunk actually falls toward the side lane rather than only flashing a warning")
	await capture(game, "ice-falling")
	game.campaign.countermeasures = true
	game.campaign.flares = CampaignState.FLARE_CAPACITY
	game.pause_flight()
	await capture(game, "music-paused-settings")
	check(game.get_viewport().get_visible_rect().encloses(game.hud.menu.get_global_rect()), "Pause statistics, music controls and resume buttons fit the native viewport")
	game.queue_free()
	await process_frame

func capture(game: Node3D, name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == Vector2i(1920, 1080), "Polish verification uses actual 1920x1080 rendering")
	if not folder.is_empty():
		check(image.save_png(folder.path_join(name + ".png")) == OK, "Saved native polish screen: " + name)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
