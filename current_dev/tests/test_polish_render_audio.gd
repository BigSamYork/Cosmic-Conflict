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
	music.request_scene("station")
	music.set_level(70, false)
	var bus: int = AudioServer.get_bus_index(music.bus_name)
	var recording := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus, recording)
	recording.set_recording_active(true)
	await create_timer(5).timeout
	check(music.failure_message.is_empty() and music.players[music.active].stream.resource_path.ends_with("Fanfare for Space.ogg") and music.players[music.active].get_playback_position() > 4, "Astra Market plays its station theme")
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
	music.players[music.active].seek(music.players[music.active].stream.get_length() - 0.2)
	await create_timer(0.6).timeout
	check(music.players[music.active].playing and music.players[music.active].get_playback_position() < 1, "The imported recording loops through its actual end without stopping")
	var active_slot := music.active
	music.request_scene("cryo")
	await create_timer(0.3).timeout
	check(music.active == active_slot and music.players[music.active].get_playback_position() > 0.3, "Staying on a world preserves its playback position")
	recording.set_recording_active(false)
	if not folder.is_empty():
		var sample: AudioStreamWAV = recording.get_recording()
		check(sample != null and sample.get_length() > 12 and sample.save_to_wav(folder.path_join("ambient-preview.wav")) == OK, "Preview captures the music bus with master output muted")
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
	var sound: SynthAudio = game.sound
	var slot := sound.voice_index % sound.voices.size()
	game._strike({"collider": ice, "position": ice.global_position}, ice.armor)
	check(sound.voices[slot].playing and sound.voices[slot].stream == SynthAudio.TARGET_IGNITION, "Shattering ice plays the isolated ignition")
	var egg := EggShip.new()
	egg.course_position = game.camera.to_global(Vector3(0, 0, -24))
	game.add_child(egg)
	slot = sound.voice_index % sound.voices.size()
	game._strike({"collider": egg, "position": egg.global_position}, egg.armor)
	check(sound.voices[slot].playing and sound.voices[slot].stream == SynthAudio.ORGANIC_RUPTURE, "Rupturing an egg plays the isolated splash")
	var after_kill := sound.voice_index
	game._strike({"collider": egg, "position": egg.global_position}, 1)
	check(sound.voice_index == after_kill, "Hitting a destroyed egg cannot replay its splash")
	game.campaign.countermeasures = true
	game.campaign.flares = CampaignState.FLARE_CAPACITY
	game.pause_flight()
	await capture(game, "music-paused-settings")
	check(game.get_viewport().get_visible_rect().encloses(game.hud.menu.get_global_rect()), "Pause statistics, music controls and resume buttons fit the native viewport")
	await verify_boss_score(game)
	await verify_boss_radio(game)
	game.queue_free()
	await process_frame

func verify_boss_score(game: Node3D) -> void:
	game.campaign.sector = "ignis"
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	var music: AmbientMusic = game.music
	music.set_level(70, false)
	game._process(0.01)
	music._process(AmbientMusic.CROSSFADE)
	check(music.current == AmbientMusic.BOSS_BATTLE and music.players[music.active].stream.resource_path.ends_with("/Final Count.ogg"), "The pursuit opens with Final Count")
	var opening_player := music.players[music.active]
	var boss: BossEncounter = game.boss
	boss.advance(30, game.camera.global_position, Vector3.ZERO)
	boss.parts[0].receive_hit(boss.parts[0].armor)
	boss.advance(0.02, game.camera.global_position, Vector3.ZERO)
	game._process(0.01)
	music._process(0.01)
	check(boss.rage_stage == 1 and music.players[music.active] == opening_player, "Final Count continues through the first retaliation")
	boss.parts[1].receive_hit(boss.parts[1].armor)
	boss.advance(0.02, game.camera.global_position, Vector3.ZERO)
	game._process(0.01)
	await create_timer(0.25).timeout
	var player := music.players[music.active]
	check(boss.rage_stage == 2 and player.stream.resource_path.ends_with("/Failing Defense.ogg") and player.get_playback_position() > 0, "Real boss damage starts Failing Defense")
	game.pause_flight()
	game._process(0.01)
	check(player.stream_paused, "Pausing the fight pauses the enraged score")
	game.resume_flight()
	game._process(0.01)
	music._process(music.fade_duration)
	check(not player.stream_paused and player == music.players[music.active], "Resuming continues the same battle recording")
	boss.core.receive_hit(boss.core.armor)
	game._process(0.01)
	music._process(AmbientMusic.CROSSFADE)
	check(music.current == "ignis" and not player.playing, "Victory returns to the sector soundtrack")

func verify_boss_radio(game: Node3D) -> void:
	game.automation = ""
	game.automated_session = false
	game.campaign.sector = "xylo"
	game.campaign.phase = "orbit_boss"
	game.settings["mute"] = false
	game.settings["voice_volume"] = 70
	var voice: ComputerVoice = game.computer_voice
	voice.stop_speech(true)
	await game._load_phase()
	game.resume_flight()
	check(voice.policy.event == "recon_xylo_orbit", "The pilot hears the tactical briefing when resuming a boss checkpoint")
	await finish_recording(voice.player)
	var radio := voice.boss_player
	check(voice.last_line == "xylo_orbit_arrival" and radio.playing, "The Hive Mother transmits her own recorded arrival speech")
	check(not game.hud.radio_speaker.is_empty() and not game.hud.radio_caption.is_empty(), "The live radio subtitle identifies the speaker")
	if voice.boss_cue.is_empty():
		return
	await capture(game, "hive-mother-radio")
	radio.seek(2.0)
	# The speech can have a pause at any individual audio mix tick.
	var bus := AudioServer.get_bus_index(radio.bus)
	var peak := -100.0
	for _sample in range(18):
		await create_timer(0.05).timeout
		peak = maxf(peak, AudioServer.get_bus_peak_volume_left_db(bus, 0))
	var mark := radio.get_playback_position()
	check(mark >= 2.0 and peak > -65, "The boss recording produces audio on the voice channel (%.1f dB, %.2f s)" % [peak, mark])
	var solo_db := radio.volume_db
	check(game._voice_event("hull_critical"), "A critical warning starts during the boss transmission")
	await create_timer(0.20).timeout
	check(voice.player.playing and radio.playing and radio.get_playback_position() > mark and not game.hud.radio_caption.is_empty(), "The two voices play together and captions follow the uninterrupted radio")
	check(radio.volume_db <= solo_db - 15 and voice.player.volume_db == solo_db, "Only the boss drops in level under the cockpit warning")
	game.pause_flight()
	var paused_at := radio.get_playback_position()
	await create_timer(0.25).timeout
	check(voice.player.stream_paused and radio.stream_paused and absf(radio.get_playback_position() - paused_at) < 0.08, "Pausing holds both voices mid-sentence")
	game.resume_flight()
	await finish_recording(voice.player)
	await create_timer(0.4).timeout
	check(radio.playing and is_equal_approx(radio.volume_db, solo_db) and voice.mix_speaking, "The foreground warning ends and the boss regains its solo level while the soundtrack stays ducked")
	game.boss.advance(60, game.camera.global_position, Vector3.ZERO)
	var sac: BossPart = game.boss.parts[0]
	for _i in range(3):
		game._strike({"collider": sac, "position": sac.aim_point()}, 1)
	await finish_recording(radio)
	check(voice.last_line == "xylo_orbit_hurt_1" and radio.playing and voice.boss_reactions.is_empty(), "Three real hits produce one voiced injury reaction")
	game._start_boss_destruction()
	check(not radio.playing and not voice.mix_speaking and voice.boss_sector.is_empty() and game.hud.radio_caption.is_empty(), "Boss defeat clears both radio and subtitles")

func finish_recording(player: AudioStreamPlayer) -> void:
	if player.playing:
		player.seek(maxf(0.0, player.stream.get_length() - 0.10))
	await create_timer(0.45).timeout

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
