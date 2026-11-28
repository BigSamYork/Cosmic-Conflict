class_name ComputerVoice
extends Node

signal speaking_changed(active: bool)
signal line_started(id: String, text: String, event: String)
signal fault(message: String)

const CATALOG: String = VoiceCatalog.DEFAULT_PATH
const RULES: Dictionary = {
	"recon_ignis_ground": Vector2i(90, 0),
	"recon_ignis_orbit": Vector2i(90, 0),
	"recon_cryo_ground": Vector2i(90, 0),
	"recon_cryo_orbit": Vector2i(90, 0),
	"recon_vespera_ground": Vector2i(90, 0),
	"recon_vespera_orbit": Vector2i(90, 0),
	"recon_xylo_ground": Vector2i(90, 0),
	"recon_xylo_orbit": Vector2i(90, 0),
	"recon_thalassa_ground": Vector2i(90, 0),
	"recon_thalassa_orbit": Vector2i(90, 0),
	"recon_kharon_ground": Vector2i(90, 0),
	"recon_kharon_orbit": Vector2i(90, 0),
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
var pending_recon := ""
var arrival_reply: Dictionary = {}
var boarding_lines: Dictionary = {}
var story_speakers := {"lark": "Lark", "attendant": "Station attendant"}
var playback_available: bool = false

func _init() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/boarding.json"))
	for line: Dictionary in manifest.cues: boarding_lines[line.id] = line
	var rescue_book: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/rescues.json"))
	for role: String in rescue_book.cast: story_speakers[role] = rescue_book.cast[role].name
	for line: Dictionary in rescue_book.cues:
		line.folder = "rescues"
		boarding_lines[line.id] = line

func _ready() -> void:
	rng.randomize()
	playback_available = DisplayServer.get_name() != "headless"
	var error: String = _load_catalog()
	if not error.is_empty():
		_fail(error)
		return
	bus_name = create_radio_bus("ComputerVoice-%d" % get_instance_id())
	player = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	player.finished.connect(_finished)
	set_level(volume_percent, suppressed)

static func create_radio_bus(label: String) -> String:
	var index: int = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(index, label)
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
	return label

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
		if not pending_recon.is_empty() and not policy.speaking:
			var briefing := pending_recon
			pending_recon = ""
			say(briefing)

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
		if event.begins_with("recon_") and policy.speaking:
			pending_recon = event
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
	arrival_reply.clear()
	player.bus = bus_name
	player.stream = streams[id]
	player.play()
	policy.started(event, rule.x, rule.y)
	line_next_allowed[id] = policy.clock + selected["cooldown_seconds"]
	last_line = id
	speaking_changed.emit(true)
	line_started.emit(id, selected["text"], event)
	return true

func panic_at_breach() -> void:
	const EVENT := "canopy_panic"
	if not enabled() or paused or not policy.can_start(EVENT, 98):
		return
	arrival_reply.clear()
	player.stop()
	player.bus = "Master"
	player.stream = preload("res://assets/voice/canopy_panic.wav")
	player.play()
	policy.started(EVENT, 98, 8.0)
	last_line = EVENT
	speaking_changed.emit(true)
	line_started.emit(EVENT, "Aah! Get it off me! Get it off!", EVENT)

func say_arrival(quarter: int, headlight: bool) -> bool:
	if not enabled() or paused or policy.speaking:
		return false
	var name := String(CampaignState.SKY_TIMES[quarter]).to_lower()
	var answer := "midnight_fitted" if name == "midnight" and headlight else name + "_lark"
	var book: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/arrival.json"))
	var pilot: Dictionary = {}
	for cue: Dictionary in book.cues:
		if cue.id == name + "_vale":
			pilot = cue
		elif cue.id == answer:
			arrival_reply = cue
	return _play_arrival_line(pilot)

func say_boarding(id: String) -> void:
	if not enabled() or paused: return
	if policy.speaking and policy.priority >= 80: return # The caption remains available during a critical warning.
	var recording := "res://assets/%s/%s.wav" % [boarding_lines[id].get("folder", "boarding"), id]
	if not ResourceLoader.exists(recording):
		push_warning("No boarding recording for " + id)
		return
	arrival_reply.clear()
	player.stop()
	player.stream = load(recording)
	player.bus = bus_name
	player.play()
	policy.started("vespera_boarding", 45, 0)
	last_line = id
	speaking_changed.emit(true)
	line_started.emit(id, boarding_lines[id].text, "vespera_boarding")

func _play_arrival_line(cue: Dictionary) -> bool:
	if cue.is_empty():
		return false
	player.stream = load("res://assets/arrival/%s.wav" % cue.id)
	player.bus = "Master" if cue.speaker == "vale" else bus_name
	player.play()
	policy.started("sector_arrival", 40, 0)
	last_line = cue.id
	speaking_changed.emit(true)
	line_started.emit(cue.id, cue.text, "sector_arrival")
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
	arrival_reply.clear()
	pending_recon = ""
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
	if not arrival_reply.is_empty() and enabled():
		var reply := arrival_reply
		arrival_reply = {}
		_play_arrival_line(reply)
		return
	policy.finished()
	speaking_changed.emit(false)

func _fail(message: String) -> void:
	failure_message = message
	push_error(message)
	stop_speech()
	fault.emit(message)

func _exit_tree() -> void:
	stop_speech()
	release_radio_bus(bus_name)

static func release_radio_bus(label: String) -> void:
	if not label.is_empty():
		var index: int = AudioServer.get_bus_index(label)
		if index >= 0:
			AudioServer.remove_bus(index)
