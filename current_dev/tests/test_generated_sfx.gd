extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var catalog_dir := "res://data"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sfx-catalog-dir="):
			catalog_dir = arg.trim_prefix("--sfx-catalog-dir=")
	var count := 0
	for filename in ["sfx_core.json", "sfx_gameplay.json"]:
		var catalog = JSON.parse_string(FileAccess.get_file_as_string(catalog_dir.path_join(filename)))
		check(catalog is Dictionary and not catalog.is_empty(), "Missing catalog " + filename)
		if catalog is Dictionary:
			for id: String in catalog:
				var clip := SynthAudio.cue_stream(id)
				check(clip is AudioStreamOggVorbis and clip.get_length() > 0, "Missing or empty packaged cue " + id)
				count += 1
	print("Loaded ", count, " generated audio resources")
	if DisplayServer.get_name() != "headless" and failures == 0:
		await verify_playback()
	print("GENERATED_SFX_FAILURES=", failures)
	quit(failures)

func verify_playback() -> void:
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	var bus := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus, "SfxProbe")
	var sound := SynthAudio.new()
	root.add_child(sound)
	for voice in sound.voices:
		voice.bus = "SfxProbe"
	sound.engine_voice.bus = "SfxProbe"
	sound.play_cue("gun_pulse")
	sound.play_cue("gun_pulse")
	check(sound.voice_index == 1 and sound.voices[0].playing, "A same-frame volley should start one SFX voice")
	sound.update_engine("engine_surface", 42)
	var pitch := sound.engine_voice.pitch_scale
	sound.update_engine("engine_surface", 85)
	check(sound.engine_voice.playing and sound.engine_voice.pitch_scale > pitch, "Engine pitch should follow flight speed")
	await create_timer(0.20).timeout
	var peak := AudioServer.get_bus_peak_volume_left_db(bus, 0)
	check(peak > -65 and sound.engine_voice.get_playback_position() > 0, "Engine should produce audible samples before master mute")
	sound.update_engine("engine_space", 65)
	check(sound.engine_voice.stream == SynthAudio.cue_stream("engine_space") and sound.engine_voice.stream.loop, "Orbital flight should switch to the looping space engine")
	sound.pause_sounds(true)
	var hud := FlightHUD.new()
	root.add_child(hud)
	var button := hud._add_button(hud, "Test", func() -> void: pass)
	button.pressed.emit()
	var ui := root.get_node_or_null("InterfaceSound") as AudioStreamPlayer
	check(ui != null and ui.playing and ui.stream == SynthAudio.cue_stream("ui_click"), "Pressing a menu button should play its click while flight is paused")
	if ui != null:
		check(not ui.stream_paused and sound.engine_voice.stream_paused and AudioServer.is_bus_mute(0) and ui.bus == &"Master", "Master mute must cover independent menu and flight voices")
		var ui_level := ui.volume_db
		var engine_level := sound.engine_voice.volume_db
		sound.set_ducked(true)
		check(ui.volume_db < ui_level and sound.engine_voice.volume_db < engine_level, "Dialogue should duck both UI and engine")
		sound.set_ducked(false)
		check(ui.volume_db == ui_level and sound.engine_voice.volume_db == engine_level, "Ending dialogue should restore the mix")
	sound.pause_sounds(false)
	var slot := sound.voice_index % sound.voices.size()
	sound.play_cue("bulkhead_knock")
	check(sound.voices[slot].stream == SynthAudio.cue_stream("bulkhead_knock"), "The story knock should play the opening's generated clip")
	sound.stop_all()
	check(not sound.engine_voice.playing, "Leaving flight should stop its engine")
	sound.queue_free()
	hud.queue_free()
	await process_frame
	AudioServer.remove_bus(bus)
	print("Native SFX mix peak ", peak, " dB")
