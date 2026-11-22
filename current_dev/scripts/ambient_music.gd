class_name AmbientMusic
extends Node

signal fault(message: String)
const TRACKS: Array[String] = ["station", "ignis", "cryo", "vespera", "xylo", "thalassa", "kharon", "travel", "boss"]
const CROSSFADE: float = 4.0
const DEFAULT_VOLUME: int = 35
var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var bus_name: String = ""
var failure_message: String = ""
var requested: String = "station"
var current: String = ""
var active: int = 0
var fade_time: float = CROSSFADE
var volume_percent: int = DEFAULT_VOLUME
var suppressed: bool = true
var paused: bool = false
var ducked: bool = false
var duck_gain: float = 1.0
var applied_gain: float = -1.0

func _ready() -> void:
	for id in TRACKS:
		var path: String = "res://assets/music/%s.wav" % id
		if not ResourceLoader.exists(path):
			_fail("Ambient soundtrack is missing: " + path + ". Run tools/generate-music.gd.")
			return
		var source: AudioStreamWAV = load(path) as AudioStreamWAV
		if source == null or source.get_length() < 60:
			_fail("Ambient recording is invalid: " + path)
			return
		var stream := source.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(source.get_length() * source.mix_rate)
		streams[id] = stream
	bus_name = "AmbientMusic-%d" % get_instance_id()
	var index: int = AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	for _i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = bus_name
		player.volume_db = -80
		add_child(player)
		players.append(player)
	set_level(volume_percent, suppressed)

func enabled() -> bool:
	return DisplayServer.get_name() != "headless" and not suppressed and volume_percent > 0 and failure_message.is_empty()

func set_level(percent: int, suppress: bool) -> void:
	assert(percent >= 0 and percent <= 100)
	volume_percent = percent
	suppressed = suppress
	if not enabled():
		for player in players:
			player.stop()
			player.stream = null
		current = ""
		fade_time = CROSSFADE
	_apply_gain()

func request_scene(scene: String) -> void:
	if not TRACKS.has(scene):
		_fail("Unknown ambient scene: " + scene)
		return
	requested = scene

func set_paused(value: bool) -> void:
	if value == paused:
		return
	paused = value
	for player in players:
		player.stream_paused = value

func set_ducked(value: bool) -> void:
	ducked = value

func _process(delta: float) -> void:
	if paused or not enabled():
		return
	if current != requested and fade_time >= CROSSFADE:
		active = 1 - active
		players[active].stop()
		players[active].stream = streams[requested]
		players[active].volume_db = -80
		players[active].play()
		current = requested
		fade_time = 0
	if fade_time < CROSSFADE:
		fade_time = minf(CROSSFADE, fade_time + delta)
		var amount: float = smoothstep(0, CROSSFADE, fade_time)
		players[active].volume_db = linear_to_db(maxf(0.0001, amount))
		players[1 - active].volume_db = linear_to_db(maxf(0.0001, 1.0 - amount))
		if fade_time >= CROSSFADE and players[1 - active].playing:
			players[1 - active].stop()
			players[1 - active].stream = null
	duck_gain = lerpf(duck_gain, 0.28 if ducked else 1.0, 1 - exp(-delta * (12.0 if ducked else 2.0)))
	_apply_gain()

func _apply_gain() -> void:
	if bus_name.is_empty():
		return
	var gain: float = maxf(0.0001, volume_percent / 100.0 * duck_gain)
	if is_equal_approx(gain, applied_gain):
		return
	var index: int = AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(gain))
		applied_gain = gain

func _fail(message: String) -> void:
	failure_message = message
	push_error(message)
	set_level(0, true)
	fault.emit(message)

func _exit_tree() -> void:
	for player in players:
		player.stop()
	if not bus_name.is_empty():
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			AudioServer.remove_bus(index)
