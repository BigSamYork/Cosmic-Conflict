extends Node

const SCRIPT_PATH := "res://assets/voice/opening.json"
const AMBER := Color("#f1bd84")
const BLUE := Color("#8cdee1")
const LEAD := 0.48
var book: Dictionary
var cues: Array
var index := -1
var clock := 0.0
var duration := 0.0
var lead := LEAD
var spoken := false
var knocks := PackedFloat32Array()
var next_knock := 0
var exiting := false
var sound_on := true
var voice_on := true
var reduced := false
var radio_bus := ""
@onready var stage = $Stage
@onready var dialogue: AudioStreamPlayer = $Dialogue
@onready var hull: AudioStreamPlayer = $Hull
@onready var score: AudioStreamPlayer = $Score

func _ready() -> void:
	book = JSON.parse_string(FileAccess.get_file_as_string(SCRIPT_PATH))
	cues = book.cues
	var config := ConfigFile.new()
	if FileAccess.file_exists("user://settings.cfg"):
		config.load("user://settings.cfg")
	sound_on = not bool(config.get_value("flight_lab", "mute", false))
	var voice_level := clampi(int(config.get_value("flight_lab", "voice_volume", 70)), 0, 100)
	var music_level := clampi(int(config.get_value("flight_lab", "music_volume", AmbientMusic.DEFAULT_VOLUME)), 0, 100)
	reduced = bool(config.get_value("flight_lab", "reduced_effects", false)) or "--reduced-effects" in OS.get_cmdline_user_args()
	stage.reduced = reduced
	stage.get_world_3d().environment.glow_enabled = not reduced
	VectorArt.set_reduced_effects(reduced)
	voice_on = sound_on and voice_level > 0
	radio_bus = ComputerVoice.create_radio_bus("LarkOpening-%d" % get_instance_id())
	dialogue.volume_db = linear_to_db(maxf(0.001, voice_level / 100.0)) - 3.0
	hull.stream = _bulkhead_knock()
	hull.volume_db = -12
	if sound_on and music_level > 0:
		score.volume_db = linear_to_db(music_level / 100.0) - 12.0
		score.finished.connect(score.play.bind(0.0))
		score.play()
	$Overlay/Title.text = book.title
	$Overlay/Skip.pressed.connect(_finish)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_next_cue()

func _next_cue() -> void:
	index += 1
	if index >= cues.size():
		_finish()
		return
	var cue: Dictionary = cues[index]
	var cut: bool = stage.shot != cue.shot
	if cut:
		stage.stage(cue.shot)
		var place: String = SectorCatalog.NAMES.get(cue.shot, stage.LOCATIONS.get(cue.shot, ""))
		$Overlay/Location.text = place.to_upper()
	var actor: Dictionary = book.cast[cue.speaker]
	$Overlay/Speaker.text = String(cue.get("source", actor.name)).to_upper()
	$Overlay/Speaker.modulate = BLUE if cue.speaker == "lark" else AMBER
	$Overlay/Title.visible = index == 0
	$Overlay/Caption.text = ""
	clock = 0.0
	lead = 2.1 if index == 0 else LEAD if cut else 0.12
	lead = float(cue.get("lead", lead))
	spoken = false
	dialogue.bus = radio_bus if cue.speaker == "lark" else "Master"
	dialogue.stream = load("res://assets/opening/%s.wav" % cue.id)
	var speech_end := lead + dialogue.stream.get_length()
	duration = speech_end + (2.8 if index == cues.size() - 1 else 0.52)
	knocks.clear()
	next_knock = 0
	if index == 0:
		knocks = PackedFloat32Array([0.5, 0.94, 1.48])
	elif index == cues.size() - 1:
		knocks = PackedFloat32Array([speech_end + 0.48, speech_end + 1.2])
	_update_frame(0)

func _process(delta: float) -> void:
	if exiting:
		return
	_update_frame(delta)
	if clock >= duration and not dialogue.playing:
		_next_cue()

func _update_frame(delta: float) -> void:
	clock += delta
	stage.advance(delta)
	var cue: Dictionary = cues[index]
	while next_knock < knocks.size() and clock >= knocks[next_knock]:
		next_knock += 1
		if sound_on:
			hull.play()
		$Overlay/Speaker.hide()
		$Overlay/Caption.text = "[Three knocks through metal]" if index == 0 else "[Two knocks in reply]"
	if not spoken and clock >= lead:
		spoken = true
		$Overlay/Speaker.show()
		$Overlay/Caption.text = cue.text
		if voice_on:
			dialogue.play()
	elif not spoken:
		$Overlay/Speaker.hide()
	var first_in_shot: bool = index == 0 or cues[index - 1].shot != cue.shot
	var last_in_shot: bool = index == cues.size() - 1 or cues[index + 1].shot != cue.shot
	var dark := 1.0 - smoothstep(0, LEAD, clock) if first_in_shot else 0.0
	if last_in_shot:
		dark = maxf(dark, smoothstep(duration - 0.4, duration, clock))
	$Overlay/Fade.color.a = dark

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_finish()

func _finish() -> void:
	if exiting:
		return
	exiting = true
	dialogue.stop()
	hull.stop()
	score.stop()
	get_tree().change_scene_to_file("res://main.tscn")

func _exit_tree() -> void:
	ComputerVoice.release_radio_bus(radio_bus)

func _bulkhead_knock() -> AudioStreamWAV:
	# Three decaying resonances give the ferry and the reply the same metal voice.
	var pcm := PackedByteArray()
	var rate := 22050
	var frames := roundi(rate * 0.42)
	pcm.resize(frames * 2)
	for frame in frames:
		var t := float(frame) / rate
		var ring := 0.55 * sin(TAU * 157 * t) * exp(-22 * t) + 0.27 * sin(TAU * 437 * t) * exp(-35 * t) + 0.17 * sin(TAU * 1193 * t) * exp(-61 * t)
		pcm.encode_s16(frame * 2, roundi(ring * minf(1.0, t * 1200) * 32000))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.data = pcm
	return clip
