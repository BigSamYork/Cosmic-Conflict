class_name AmbientMusic
extends Node

signal fault(message: String)
const BOSS_BATTLE := "boss_battle"
const ENRAGED := "boss_enraged"
const TRACKS := {
	"title": "Evening Melodrama", "station": "Fanfare for Space",
	BOSS_BATTLE: "Final Count", ENRAGED: "Failing Defense",
	"ignis": "Five Armies", "cryo": "Constancy Part Three", "vespera": "Clenched Teeth",
	"xylo": "Grave Matters", "thalassa": "Mighty and Meek", "kharon": "Americana",
}
const MIX_GAIN := 0.16
const SHIP_LOSS := "ship_loss"
const LOSS_TRACK := "Grave Matters"
const CROSSFADE: float = 4.0
const DEFAULT_VOLUME: int = 60
var players: Array[AudioStreamPlayer] = []
var bus_name: String = ""
var failure_message: String = ""
var requested: String = "title"
var current: String = ""
var active: int = 0
var fade_time: float = CROSSFADE
var fade_duration: float = CROSSFADE
var volume_percent: int = DEFAULT_VOLUME
var suppressed: bool = true
var paused: bool = false
var ducked: bool = false
var duck_gain: float = 1.0
var applied_gain: float = -1.0

func _ready() -> void:
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
		fade_time = fade_duration
	_apply_gain()

func request_scene(scene: String) -> void:
	if scene != SHIP_LOSS and not TRACKS.has(scene):
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
	var death_cue := requested == SHIP_LOSS
	if current != requested and (death_cue or fade_time >= fade_duration):
		var path := "res://assets/music/licensed/%s.ogg" % (LOSS_TRACK if death_cue else TRACKS[requested])
		var stream := load(path) as AudioStreamOggVorbis
		if stream == null:
			_fail("Soundtrack recording is missing: " + path)
			return
		stream.loop = true
		active = 1 - active
		players[active].stop()
		players[active].stream = stream
		players[active].volume_db = -80
		players[active].play()
		current = requested
		fade_duration = 1.25 if current == ENRAGED else CROSSFADE
		fade_time = 0
		if death_cue:
			# The ejection is a hard musical cut, even during a world crossfade.
			players[1 - active].stop()
			players[1 - active].stream = null
			players[active].volume_db = 0
			fade_time = fade_duration
	if fade_time < fade_duration:
		fade_time = minf(fade_duration, fade_time + delta)
		var amount: float = smoothstep(0, fade_duration, fade_time)
		players[active].volume_db = linear_to_db(maxf(0.0001, amount))
		players[1 - active].volume_db = linear_to_db(maxf(0.0001, 1.0 - amount))
		if fade_time >= fade_duration and players[1 - active].playing:
			players[1 - active].stop()
			players[1 - active].stream = null
	var dialogue_gain := 0.65 if death_cue else 0.28
	duck_gain = lerpf(duck_gain, dialogue_gain if ducked else 1.0, 1 - exp(-delta * (12.0 if ducked else 2.0)))
	_apply_gain()

func _apply_gain() -> void:
	if bus_name.is_empty():
		return
	var mix_gain := 0.38 if current == SHIP_LOSS else MIX_GAIN
	var gain: float = maxf(0.0001, mix_gain * volume_percent / 100.0 * duck_gain)
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
