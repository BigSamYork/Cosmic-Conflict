class_name ComputerVoice
extends Node

signal speaking_changed(active: bool)
signal line_started(id: String, text: String, event: String)
signal fault(message: String)

const CATALOG: String = VoiceCatalog.DEFAULT_PATH
const RULES: Dictionary = {
	"reactor_weapons": Vector2i(20, 12), "reactor_shields": Vector2i(20, 12),
	"reactor_engines": Vector2i(20, 12), "reactor_balanced": Vector2i(20, 12),
	"reactor_routing": Vector2i(20, 12),
	"overheat": Vector2i(65, 18), "cooling": Vector2i(20, 20),
	"primary_tachyon": Vector2i(40, 10), "primary_quad": Vector2i(40, 10), "primary_pulse": Vector2i(30, 30),
	"streak_gain": Vector2i(30, 16), "streak_ten": Vector2i(45, 25),
	"streak_break": Vector2i(45, 20), "interception": Vector2i(15, 30),
	"shields_empty": Vector2i(85, 20), "shields_regen": Vector2i(20, 25),
	"hull_damage": Vector2i(55, 20), "hull_critical": Vector2i(95, 25),
	"ignis_arrival": Vector2i(40, 90), "ignis_vent": Vector2i(45, 30),
	"frost_hit": Vector2i(65, 20), "vespera_arrival": Vector2i(40, 90),
	"laser_gate": Vector2i(40, 30), "stealth_fighter": Vector2i(40, 30),
	"nyx_cloak": Vector2i(50, 25), "xylo_arrival": Vector2i(40, 90),
	"xylo_spores": Vector2i(45, 25), "xylo_acid": Vector2i(65, 20),
	"xylo_hive": Vector2i(40, 90), "xylo_egg": Vector2i(25, 30),
	"ordnance_swarm": Vector2i(30, 18), "ordnance_emp": Vector2i(45, 18),
	"ordnance_concussion": Vector2i(25, 18), "flare_deployed": Vector2i(60, 16),
	"flare_cooldown": Vector2i(30, 18), "ordnance_empty": Vector2i(65, 20),
	"ejection": Vector2i(100, 25), "recovery": Vector2i(60, 30),
	"rescue_purchased": Vector2i(45, 30), "rescue_launch": Vector2i(40, 45),
	"upgrade": Vector2i(30, 12), "docking": Vector2i(45, 35),
	"route_easy": Vector2i(10, 0), "route_hard": Vector2i(10, 0)
}

var policy := VoicePolicy.new()
var rng := RandomNumberGenerator.new()
var player: AudioStreamPlayer
var lines: Array[Dictionary] = []
var streams: Dictionary = {}
var recording_paths: Dictionary = {}
var line_next_allowed: Dictionary = {}
var catalog_path: String = ""
var cache_directory: String = "user://voice-cache"
var last_line: String = ""
var bus_name: String = ""
var failure_message: String = ""
var volume_percent: int = 70
var suppressed: bool = true
var paused: bool = false
var playback_available: bool = false

func _ready() -> void:
	rng.randomize()
	playback_available = DisplayServer.get_name() != "headless"
	var error: String = _load_catalog()
	if not error.is_empty():
		_fail(error)
		return
	bus_name = "ComputerVoice-%d" % get_instance_id()
	var index: int = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	var high := AudioEffectHighPassFilter.new()
	high.cutoff_hz = 200
	AudioServer.add_bus_effect(index, high)
	var low := AudioEffectLowPassFilter.new()
	low.cutoff_hz = 5500
	AudioServer.add_bus_effect(index, low)
	var pitch := AudioEffectPitchShift.new()
	pitch.pitch_scale = 0.97
	AudioServer.add_bus_effect(index, pitch)
	var chorus := AudioEffectChorus.new()
	chorus.voice_count = 1
	chorus.dry = 0.92
	chorus.wet = 0.08
	chorus.set("voice/1/delay_ms", 12.0)
	chorus.set("voice/1/rate_hz", 0.7)
	chorus.set("voice/1/depth_ms", 0.6)
	chorus.set("voice/1/level_db", -4.0)
	chorus.set("voice/1/pan", 0.0)
	AudioServer.add_bus_effect(index, chorus)
	player = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	player.finished.connect(_finished)
	set_level(volume_percent, suppressed)

func _load_catalog() -> String:
	if catalog_path.is_empty():
		catalog_path = CATALOG if OS.has_feature("editor") else VoiceCatalog.USER_PATH
	if catalog_path == VoiceCatalog.USER_PATH and not FileAccess.file_exists(catalog_path):
		var write_error: String = VoiceCatalog.write_text(catalog_path, FileAccess.get_file_as_string(CATALOG))
		if not write_error.is_empty():
			return write_error
	var catalog := VoiceCatalog.new()
	var error: String = catalog.load_catalog(catalog_path, RULES, cache_directory)
	if error.is_empty():
		lines = catalog.lines
		recording_paths = catalog.recording_paths
	return error

func _process(delta: float) -> void:
	if not paused:
		policy.advance(delta)

func set_level(percent: int, suppress: bool) -> void:
	assert(percent >= 0 and percent <= 100)
	volume_percent = percent
	suppressed = suppress
	if player != null:
		player.volume_db = linear_to_db(maxf(0.001, percent / 100.0)) - 6.0
	if not enabled():
		stop_speech()

func enabled() -> bool:
	return playback_available and not suppressed and volume_percent > 0 and failure_message.is_empty()

func pause_speech(value: bool) -> void:
	paused = value
	if player != null:
		player.stream_paused = value

func say(event: String) -> bool:
	if not RULES.has(event):
		_fail("Unknown computer voice event: " + event)
		return false
	if not enabled() or paused:
		return false
	if event.begins_with("route_") and not policy.route_allowed():
		return false
	var rule: Vector2i = RULES[event]
	var silence: float = 4.0 if event.begins_with("route_") else 6.0
	if not policy.can_start(event, rule.x, silence):
		return false
	var selected: Dictionary = _choose_line(event)
	if selected.is_empty():
		return false
	var id: String = selected["id"]
	if not streams.has(id):
		var path: String = recording_paths[id]
		var stream: AudioStream = load(path) if path.begins_with("res://") else AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
		if stream == null or stream.get_length() <= 0:
			_fail("Cannot load computer voice recording: " + id)
			return false
		streams[id] = stream
	player.stop()
	player.stream = streams[id]
	player.play()
	policy.started(event, rule.x, rule.y)
	line_next_allowed[id] = policy.clock + selected["cooldown_seconds"]
	last_line = id
	speaking_changed.emit(true)
	line_started.emit(id, selected["text"], event)
	return true

func _choose_line(event: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for line in lines:
		if line["chance_percent"] == 0 or policy.clock + 0.000001 < float(line_next_allowed.get(line["id"], 0.0)):
			continue
		if line["event"] == event or (event.begins_with("reactor_") and line["event"] == "reactor_routing"):
			candidates.append(line)
	if candidates.is_empty():
		return {}
	if candidates.size() > 1:
		candidates = candidates.filter(func(line: Dictionary) -> bool: return line["id"] != last_line)
	var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	return selected if rng.randi_range(0, 99) < selected["chance_percent"] else {}

func say_route(hard: bool) -> bool:
	return say("route_hard" if hard else "route_easy")

func cancel_group(group: String) -> void:
	if policy.speaking and VoicePolicy.group_for(policy.event) == group:
		stop_speech()

func stop_speech(reset: bool = false) -> void:
	if player != null:
		player.stop()
		player.stream = null
	var was_speaking: bool = policy.speaking
	if reset:
		policy.reset()
	elif was_speaking:
		policy.finished()
	if was_speaking:
		speaking_changed.emit(false)

func _finished() -> void:
	policy.finished()
	speaking_changed.emit(false)

func _fail(message: String) -> void:
	failure_message = message
	push_error(message)
	stop_speech()
	fault.emit(message)

func _exit_tree() -> void:
	stop_speech()
	if not bus_name.is_empty():
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			AudioServer.remove_bus(index)
