extends SceneTree

var failures: int = 0

class RecordingVoice extends ComputerVoice:
	var requests: Array[String] = []
	func _ready() -> void:
		pass
	func say(key: String) -> bool:
		requests.append(key)
		return true
	func say_route(hard: bool) -> bool:
		requests.append("route_hard" if hard else "route_easy")
		return true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	verify_policy()
	verify_catalog()
	verify_editable_catalog()
	verify_frequency()
	await verify_events()
	await process_frame
	print("COMPUTER_VOICE_FAILURES=", failures)
	quit(failures)

func verify_policy() -> void:
	var policy := VoicePolicy.new()
	policy.started("reactor_weapons", 20, 12)
	policy.advance(10)
	check(not policy.route_allowed(), "Route banter cannot interrupt speech, even after four seconds have elapsed")
	policy.finished()
	policy.advance(3.99)
	check(not policy.route_allowed(), "Route quips wait for four full seconds after the previous utterance finishes")
	policy.advance(0.01)
	check(policy.route_allowed(), "A route quip is eligible after exactly four seconds of silence")
	policy.started("route_easy", 10, 0)
	check(policy.can_start("hull_critical", 95), "Critical hull warnings can interrupt low-priority banter")
	policy.started("hull_critical", 95, 25)
	check(not policy.can_start("shields_empty", 85) and not policy.can_start("overheat", 65), "Lower-priority warnings cannot overlap or replace a critical warning")
	check(policy.can_start("ejection", 100), "Ejection has priority over other warnings")
	policy.reset()
	policy.started("reactor_weapons", 20, 12)
	policy.finished()
	policy.advance(7)
	check(not policy.can_start("reactor_shields", 20), "Rapid routing changes share one anti-spam cooldown")
	policy.advance(5)
	check(policy.can_start("reactor_shields", 20), "Routing speech becomes available after its cooldown and quiet interval")

func verify_catalog() -> void:
	var parser := JSON.new()
	check(parser.parse(FileAccess.get_file_as_string(ComputerVoice.CATALOG)) == OK, "The editable voice catalog is valid JSON")
	var supplied: int = 0
	var additions: int = 0
	var route_easy: int = 0
	var route_hard: int = 0
	var sections_valid: bool = true
	var assets_valid: bool = true
	for section in parser.data["sections"]:
		var added: int = 0
		for line in section["lines"]:
			if section["id"] == "routes":
				route_easy += int(line["event"] == "route_easy")
				route_hard += int(line["event"] == "route_hard")
			elif line["added"]:
				added += 1
				additions += 1
			else:
				supplied += 1
			var stream: AudioStream = load("res://assets/voice/%s.wav" % line["id"])
			assets_valid = assets_valid and stream != null and stream.get_length() > 0.5 and ComputerVoice.RULES.has(line["event"])
		if section["id"] != "routes":
			sections_valid = sections_valid and added >= 3
	check(supplied == 50 and additions >= 21 and sections_valid, "All fifty supplied lines and at least three additions per original section are retained; extra user sayings are allowed")
	check(route_easy >= 6 and route_hard >= 6, "At least twelve separate easy/hard route quips are available")
	check(assets_valid, "Every editable quip maps to a known event and a nonempty offline audio stream")
	var voice := ComputerVoice.new()
	root.add_child(voice)
	check(voice.failure_message.is_empty(), "Recording fingerprints match the editable catalog")
	voice.set_level(0, false)
	check(not voice.say("ejection") and not voice.player.playing, "Zero voice volume suppresses even urgent speech")
	voice.set_level(70, true)
	check(not voice.say("hull_critical") and not voice.player.playing, "Automation/master suppression cannot produce unsolicited speech")
	var before: float = voice.policy.clock
	voice.pause_speech(true)
	voice._process(4)
	check(voice.policy.clock == before, "Pause freezes speech-policy timing")
	voice.free()

func verify_events() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.computer_voice.queue_free()
	var recorder := RecordingVoice.new()
	game.add_child(recorder)
	game.computer_voice = recorder
	game.automation = ""
	game.automated_session = false
	game.is_campaign = true
	game.campaign = CampaignState.new()
	var path: String = "user://voice-event-test-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	await game._load_phase()
	recorder.requests.clear()
	game.flight.distance = GroundRoute.FORK - 1
	game.flight.elapsed = game.flight.distance / FlightState.SPEED
	game.flight.offset.x = 3
	game.cursor = game.get_viewport().get_visible_rect().size * 0.5
	Input.action_release("primary")
	game._physics_process(1.0 / 30)
	game._physics_process(1.0 / 30)
	check(recorder.requests.count("route_hard") == 1, "Flying right requests a hard-route quip once")
	await game._load_phase()
	recorder.requests.clear()
	game.flight.distance = GroundRoute.FORK - 1
	game.flight.offset.x = -3
	game.flight.elapsed = game.flight.distance / FlightState.SPEED
	game.cursor = game.get_viewport().get_visible_rect().size * 0.5
	Input.action_release("primary")
	game._physics_process(1.0 / 30)
	game._physics_process(1.0 / 30)
	check(recorder.requests.count("route_easy") == 1 and not recorder.requests.has("route_hard"), "Flying left requests the easy-route quip once at commitment")
	recorder.requests.clear()
	var action := InputEventAction.new()
	action.action = "power_weapons"
	action.pressed = true
	game._unhandled_input(action)
	game._unhandled_input(action)
	check(recorder.requests.count("reactor_weapons") == 1, "Only an actual reactor-routing change requests commentary")
	game.flight.shields = 0
	game.flight.hull = 30
	game.flight.impact_cooldown = 0
	game._apply_pilot_damage("VOICE TEST", 10)
	check(recorder.requests.has("hull_critical"), "Crossing the critical hull threshold requests the urgent warning")
	game.campaign.sector = "thalassa"
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	check(recorder.requests.count("recon_thalassa_ground") == 1, "Encounter entry identifies the Tempest Walker and briefs its ballast failure")
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	check(recorder.requests.count("recon_thalassa_orbit") == 1, "Orbital entry briefs the Storm Ark instead of the surface walker")
	game.automation = "--unit-fixture"
	recorder.requests.clear()
	game._voice_event("ejection")
	game._voice_route(true)
	check(recorder.requests.is_empty(), "Game automation suppresses both ordinary speech and route quips before playback")
	game.sound.stop_all()
	game.queue_free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	await process_frame

func verify_editable_catalog() -> void:
	var source := JSON.new()
	source.parse(FileAccess.get_file_as_string(ComputerVoice.CATALOG))
	var data: Dictionary = source.data
	var fixture: String = "user://voice edit test-%d" % OS.get_process_id()
	check(DirAccess.make_dir_recursive_absolute(fixture) == OK, "An isolated voice-edit fixture can be created")
	var path: String = fixture.path_join("lines.json")
	var cache: String = fixture.path_join("cache")
	var original: Dictionary = data["sections"][0]["lines"][0].duplicate()
	data["sections"][0]["lines"][0]["chance_percent"] = 37
	data["sections"][0]["lines"][0]["cooldown_seconds"] = 90.5
	check(VoiceCatalog.write_text(path, JSON.stringify(data)).is_empty(), "Edited frequency settings can be saved")
	var catalog := VoiceCatalog.new()
	var error: String = catalog.load_catalog(path, ComputerVoice.RULES, cache)
	check(error.is_empty() and catalog.lines[0]["chance_percent"] == 37 and catalog.lines[0]["cooldown_seconds"] == 90.5, "Frequency-only edits load without regenerating audio: " + error)
	check(catalog.recording_paths.get(original["id"], "").begins_with("res://") and not DirAccess.dir_exists_absolute(cache), "Frequency edits retain the original packaged recordings")
	var legacy := data.duplicate(true)
	legacy["voice"] = VoiceCatalog.DESKTOP
	VoiceCatalog.write_text(path, JSON.stringify(legacy))
	error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
	check(error.is_empty() and catalog.recording_paths.size() == catalog.lines.size() and not DirAccess.dir_exists_absolute(cache), "Existing pilot catalogs reuse the new recordings")
	for invalid in [
		["chance_percent", -1], ["chance_percent", 101], ["chance_percent", 0.5], ["chance_percent", "25"],
		["chance_percent", true], ["cooldown_seconds", -0.01], ["cooldown_seconds", 86401],
		["cooldown_seconds", "60"], ["text", "  "], ["event", "not_an_event"], ["id", "../outside"]
	]:
		var broken: Dictionary = data.duplicate(true)
		broken["sections"][0]["lines"][0][invalid[0]] = invalid[1]
		VoiceCatalog.write_text(path, JSON.stringify(broken))
		error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
		check(not error.is_empty() and error.contains(path), "Invalid %s=%s is reported with the editable file path" % [invalid[0], invalid[1]])
	VoiceCatalog.write_text(path, "{broken")
	check(catalog.load_catalog(path, ComputerVoice.RULES, cache).contains("JSON"), "Malformed JSON is reported instead of falling back to old sayings")
	data["sections"][0]["lines"][0]["text"] = "Edited voice test: caf\u00e9. Pilot says \"ready\". <This is plain text>, not a command."
	data["sections"][0]["lines"][0]["chance_percent"] = 0
	VoiceCatalog.write_text(path, JSON.stringify(data))
	error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
	check(error.is_empty() and not DirAccess.dir_exists_absolute(cache), "Disabled sayings do not require synthesis even when their text changes")
	data["sections"][0]["lines"][0]["chance_percent"] = 37
	VoiceCatalog.write_text(path, JSON.stringify(data))
	error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
	check(error.is_empty(), "Changed text automatically generates offline audio without a rebuild: " + error)
	if error.is_empty():
		var recording: String = catalog.recording_paths[original["id"]]
		var sample := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(recording))
		check(recording.begins_with(cache) and sample != null and sample.get_length() > 0.5, "The changed line uses a real generated WAV rather than its old recording")
		var engine_voice: String = VoiceCatalog.DESKTOP if OS.get_environment("COSMIC_TTS_PYTHON").is_empty() else VoiceCatalog.TURBO
		var expected_name: String = "line_" + (engine_voice + "\n" + data["sections"][0]["lines"][0]["text"]).sha256_text() + ".wav"
		check(recording.get_file() == expected_name, "Cache identity covers the exact voice and UTF-8 text")
		var written: int = FileAccess.get_modified_time(recording)
		error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
		check(error.is_empty() and FileAccess.get_modified_time(recording) == written, "Restarting reuses the edited recording without synthesizing it again")
		data["sections"][0]["lines"][0] = original
		VoiceCatalog.write_text(path, JSON.stringify(data))
		error = catalog.load_catalog(path, ComputerVoice.RULES, cache)
		check(error.is_empty() and catalog.recording_paths[original["id"]].begins_with("res://"), "Restoring the original text returns to the packaged recording")
		check(DirAccess.remove_absolute(recording) == OK, "The generated test recording is removed")
	if DirAccess.dir_exists_absolute(cache):
		check(DirAccess.remove_absolute(cache) == OK, "The isolated test cache is empty and removed")
	check(DirAccess.remove_absolute(path) == OK and DirAccess.remove_absolute(fixture) == OK, "Voice-edit fixtures are cleaned without changing player settings")

func verify_frequency() -> void:
	var voice := ComputerVoice.new()
	root.add_child(voice)
	voice.set_process(false)
	voice.playback_available = true
	voice.set_level(70, false)
	var chosen: Dictionary = voice.lines.filter(func(line: Dictionary) -> bool: return line["id"] == "reactor_09")[0]
	voice.lines = [chosen]
	chosen["chance_percent"] = 0
	check(not voice.say("reactor_weapons") and voice.failure_message.is_empty() and not voice.policy.speaking, "Zero percent disables a saying without an error or cooldown")
	chosen["chance_percent"] = 100
	chosen["cooldown_seconds"] = 60.5
	check(voice.say("reactor_weapons"), "One hundred percent always speaks when a matching line is eligible")
	voice.stop_speech(true)
	voice.policy.advance(60.49)
	check(not voice.say("reactor_shields"), "A per-line cooldown survives phase resets and applies across shared reactor events")
	voice.policy.advance(0.01)
	check(voice.say("reactor_shields"), "The saying becomes available at its exact fractional repeat-cooldown boundary")
	voice.stop_speech(true)
	voice.line_next_allowed.clear()
	chosen["chance_percent"] = 25
	voice.rng.seed = 24680
	var count: int = 0
	for attempt in range(10000):
		count += int(not voice._choose_line("reactor_balanced").is_empty())
	check(count >= 2300 and count <= 2700, "A configured 25 percent produces roughly one quarter of eligible attempts, not a weighted always-speak choice (%d/10000)" % count)
	chosen["chance_percent"] = 100
	check(voice.say("reactor_engines"), "A successful chance check starts speech")
	voice.stop_speech()
	voice.line_next_allowed.clear()
	voice.policy.advance(6)
	check(not voice.say("reactor_weapons"), "Existing shared event anti-spam cooldowns still apply")
	chosen["event"] = "route_easy"
	chosen["cooldown_seconds"] = 0
	var routes_started: int = 0
	for attempt in range(20):
		voice.stop_speech(true)
		voice.line_next_allowed.clear()
		routes_started += int(voice.say_route(false))
	check(routes_started == 20, "A route saying set to 100 percent is not limited by the old hard-coded 25 percent gate")
	voice.stop_speech()
	voice.policy.advance(3.99)
	check(not voice.say_route(false), "A 100 percent route saying still respects its four-second quiet interval")
	voice.stop_speech(true)
	for quarter in 4:
		for fitted in [false, true]:
			var name := String(CampaignState.SKY_TIMES[quarter]).to_lower()
			check(voice.say_arrival(quarter, fitted) and voice.last_line == name + "_vale" and voice.player.bus == "Master", "Vale opens the %s arrival" % name)
			voice._finished()
			var reply := "midnight_fitted" if quarter == 3 and fitted else name + "_lark"
			check(voice.last_line == reply and voice.player.bus == voice.bus_name and voice.player.stream.get_length() > 0, "Lark answers with recorded cue %s" % reply)
			voice.stop_speech(true)
	voice.free()

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
