extends SceneTree

var failures: int = 0
var preview_path: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Voice playback verification requires native audio.")
		quit(1)
		return
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--voice-preview="):
			preview_path = argument.trim_prefix("--voice-preview=")
	var voice := ComputerVoice.new()
	root.add_child(voice)
	voice.set_level(70, false)
	check(voice.failure_message.is_empty() and voice.say("reactor_balanced"), "An offline Lark recording starts through the native voice player")
	await create_timer(0.5).timeout
	var index: int = AudioServer.get_bus_index(voice.bus_name)
	var peak: float = AudioServer.get_bus_peak_volume_left_db(index, 0)
	check(voice.player.get_playback_position() > 0.1 and peak > -65, "The isolated processed voice bus contains real playing audio (%.2f dB)" % peak)
	voice.pause_speech(true)
	var position: float = voice.player.get_playback_position()
	var clock: float = voice.policy.clock
	await create_timer(0.3).timeout
	check(absf(voice.player.get_playback_position() - position) < 0.05 and voice.policy.clock == clock, "Pausing holds both the spoken recording and its policy timer")
	voice.pause_speech(false)
	check(voice.say("hull_critical") and voice.policy.event == "hull_critical", "A real urgent line replaces active banter without overlapping players")
	check(not voice.say_route(true) and voice.policy.event == "hull_critical", "Route quips never interrupt actual critical playback")
	voice.stop_speech()
	check(not voice.say_route(false), "A stopped utterance does not manufacture four seconds of silence")
	await create_timer(4.1).timeout
	for seed_value in range(100):
		voice.rng.seed = seed_value
		if not voice._choose_line("route_easy").is_empty():
			voice.rng.seed = seed_value
			break
	check(voice.say_route(false) and voice.policy.event == "route_easy", "An eligible one-in-four route outcome starts after actual four-second silence")
	voice.set_level(0, false)
	check(not voice.player.playing and not voice.say("ejection"), "The voice volume control stops playback and keeps it off")
	voice.set_level(70, false)
	for sector in SectorCatalog.AVAILABLE:
		for encounter in ["ground", "orbit"]:
			voice.stop_speech(true)
			var key: String = "recon_" + sector + "_" + encounter
			check(voice.say(key) and voice.player.stream.get_length() > 3.0 and voice.policy.event == key, "Boss recon recording plays for " + key)
	if not preview_path.is_empty():
		voice.set_level(70, false)
		voice.stop_speech(true)
		var recording := AudioEffectRecord.new()
		AudioServer.add_bus_effect(index, recording)
		recording.set_recording_active(true)
		check(voice.say("docking"), "A complete processed voice preview starts")
		await voice.player.finished
		await create_timer(0.2).timeout
		recording.set_recording_active(false)
		var sample: AudioStreamWAV = recording.get_recording()
		check(sample != null and sample.get_length() > 3 and sample.save_to_wav(preview_path) == OK, "The preview records only the game's own processed voice bus")
	voice.queue_free()
	await process_frame
	await verify_edited_audio()
	print("COMPUTER_VOICE_AUDIO_FAILURES=", failures)
	quit(failures)

func verify_edited_audio() -> void:
	var fixture: String = "user://edited voice audio-%d" % OS.get_process_id()
	check(DirAccess.make_dir_recursive_absolute(fixture) == OK, "Native edited-voice fixture is isolated")
	var path: String = fixture.path_join("lines.json")
	var cache: String = fixture.path_join("cache")
	var text: String = "Custom computer saying. This recording was generated from the editable file without rebuilding the game."
	var data: Dictionary = {"voice": "Microsoft Zira Desktop", "sections": [{"lines": [
		{"id": "reactor_07", "event": "reactor_balanced", "text": text, "chance_percent": 100, "cooldown_seconds": 60}
	]}]}
	check(VoiceCatalog.write_text(path, JSON.stringify(data)).is_empty(), "A custom saying can be written")
	var voice := ComputerVoice.new()
	voice.catalog_path = path
	voice.cache_directory = cache
	root.add_child(voice)
	voice.set_level(70, false)
	check(voice.failure_message.is_empty() and voice.say("reactor_balanced"), "An edited saying starts via the real processed audio player: " + voice.failure_message)
	if voice.failure_message.is_empty():
		await create_timer(0.5).timeout
		var index: int = AudioServer.get_bus_index(voice.bus_name)
		check(voice.player.get_playback_position() > 0.1 and AudioServer.get_bus_peak_volume_left_db(index, 0) > -65, "The generated saying produces audible samples on the isolated voice bus while master output remains muted")
		var recording: String = voice.recording_paths["reactor_07"]
		voice.stop_speech()
		check(DirAccess.remove_absolute(recording) == OK, "The custom audio test recording is removed")
	voice.free()
	if DirAccess.dir_exists_absolute(cache):
		check(DirAccess.remove_absolute(cache) == OK, "The native test cache is removed")
	check(DirAccess.remove_absolute(path) == OK and DirAccess.remove_absolute(fixture) == OK, "Native test files are cleaned")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
