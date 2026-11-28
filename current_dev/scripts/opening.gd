extends Node

const SCRIPT_PATH := "res://assets/voice/opening.json"
const AMBER := Color("#f1bd84")
const BLUE := Color("#8cdee1")
const LEAD := 0.16
const STAGE_SCRIPT := preload("res://scripts/opening_stage.gd")
var book: Dictionary
var cues: Array
var index := -1
var clock := 0.0
var duration := 0.0
var lead := LEAD
var spoken := false
var caption_pages := PackedStringArray()
var page_starts := PackedFloat32Array()
var caption_page := -1
var feed_views: Array[SubViewport] = []
var feed_tick := 0.0
var music_gain := 0.0
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
@onready var drone: AudioStreamPlayer = $Drone

func _ready() -> void:
	book = JSON.parse_string(FileAccess.get_file_as_string(SCRIPT_PATH))
	cues = book.cues
	var config := ConfigFile.new()
	if FileAccess.file_exists("user://settings.cfg"):
		config.load("user://settings.cfg")
	sound_on = DisplayServer.get_name() != "headless" and not bool(config.get_value("flight_lab", "mute", false))
	var voice_level := clampi(int(config.get_value("flight_lab", "voice_volume", 70)), 0, 100)
	var music_level := clampi(int(config.get_value("flight_lab", "music_volume", AmbientMusic.DEFAULT_VOLUME)), 0, 100)
	reduced = bool(config.get_value("flight_lab", "reduced_effects", false)) or "--reduced-effects" in OS.get_cmdline_user_args()
	stage.reduced = reduced
	stage.get_world_3d().environment.glow_enabled = not reduced
	VectorArt.set_reduced_effects(reduced)
	voice_on = sound_on and voice_level > 0
	radio_bus = ComputerVoice.create_radio_bus("LarkOpening-%d" % get_instance_id())
	dialogue.volume_db = linear_to_db(maxf(0.001, voice_level / 100.0)) - 3.0
	hull.stream = SynthAudio.cue_stream("bulkhead_knock")
	if hull.stream == null:
		hull.stream = _bulkhead_knock()
	hull.volume_db = -12
	music_gain = AmbientMusic.MIX_GAIN * music_level / 100.0
	drone.stream = _pulse_drone()
	if sound_on and music_gain > 0:
		drone.volume_db = linear_to_db(music_gain)
		drone.play()
	$Overlay/Title.text = book.title
	$Overlay/Skip.pressed.connect(_skip)
	if OS.has_feature("android"):
		$Overlay/Skip.text = "Skip"
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
		$Overlay/Location.text = stage.LOCATIONS[cue.shot].to_upper()
		_show_telemetry(cue.shot)
		if cue.shot == "departure":
			stage.mount_holo_table(feed_views)
			if sound_on and music_gain > 0:
				score.volume_db = -60
				score.play()
				var mix := create_tween().set_parallel()
				mix.tween_property(score, "volume_db", linear_to_db(music_gain) - 3.0, 1.4)
				mix.tween_property(drone, "volume_db", -60.0, 1.4)
	var actor: Dictionary = book.cast[cue.speaker]
	$Overlay/Speaker.text = String(cue.get("source", actor.name)).to_upper()
	$Overlay/Speaker.modulate = BLUE if cue.speaker == "lark" else AMBER
	$Overlay/Title.visible = index == 0
	$Overlay/Caption.text = ""
	clock = 0.0
	lead = 1.22 if index == 0 else LEAD if cut else 0.06
	lead = float(cue.get("lead", lead))
	spoken = false
	dialogue.bus = radio_bus if cue.speaker == "lark" else "Master"
	dialogue.stream = load("res://assets/opening/%s.wav" % cue.id)
	# Keep deliberate breaths from the recording. Only nudge unusually slow takes.
	var words_per_minute: float = String(cue.text).split(" ", false).size() * 60 / dialogue.stream.get_length()
	dialogue.pitch_scale = clampf(158.0 / words_per_minute, 1.0, 1.065)
	var speech_length := dialogue.stream.get_length() / dialogue.pitch_scale
	_paginate(cue.text, speech_length)
	var speech_end := lead + speech_length
	duration = speech_end + (1.35 if index == cues.size() - 1 else 0.20)
	knocks.clear()
	next_knock = 0
	if index == 0:
		knocks = PackedFloat32Array([0.18, 0.52, 0.86])
	elif index == cues.size() - 1:
		knocks = PackedFloat32Array([speech_end + 0.22, speech_end + 0.63])
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
	if $Overlay/Feeds.visible:
		feed_tick += delta
		if feed_tick >= 0.24:
			for view in feed_views:
				view.get_child(0).advance(feed_tick)
				view.render_target_update_mode = SubViewport.UPDATE_ONCE
			feed_tick = 0
	var cue: Dictionary = cues[index]
	while next_knock < knocks.size() and clock >= knocks[next_knock]:
		next_knock += 1
		if sound_on:
			hull.play()
		$Overlay/Speaker.hide()
		$Overlay/Caption.text = "[Three metallic pings]" if index == 0 else "[Two metallic pings in reply]"
	if not spoken and clock >= lead:
		spoken = true
		$Overlay/Speaker.show()
		if voice_on:
			dialogue.play()
	elif not spoken:
		$Overlay/Speaker.hide()
	if spoken and (index != cues.size() - 1 or next_knock == 0):
		var speech_time := maxf(0, clock - lead)
		while caption_page + 1 < page_starts.size() and speech_time >= page_starts[caption_page + 1]:
			caption_page += 1
			$Overlay/Caption.text = caption_pages[caption_page]
	var first_in_shot: bool = index == 0 or cues[index - 1].shot != cue.shot
	var last_in_shot: bool = index == cues.size() - 1 or cues[index + 1].shot != cue.shot
	var dark := 1.0 - smoothstep(0, LEAD, clock) if first_in_shot else 0.0
	if last_in_shot:
		dark = maxf(dark, smoothstep(duration - (0.37 if index == cues.size() - 1 else 0.1), duration, clock))
	$Overlay/Fade.color.a = dark

func _paginate(line: String, speech_length: float) -> void:
	caption_pages.clear()
	page_starts.clear()
	caption_page = -1
	var page := ""
	var consumed := 0
	for word in line.split(" ", false):
		if page.length() + word.length() > 83 or (page.length() >= 29 and page.right(1) in [".", "?", "!"]):
			caption_pages.append(page)
			page_starts.append(float(consumed) / line.length() * speech_length)
			consumed += page.length() + 1
			page = ""
		page += ("" if page.is_empty() else " ") + word
	caption_pages.append(page)
	page_starts.append(float(consumed) / line.length() * speech_length)

func _show_telemetry(shot: String) -> void:
	var is_feed: bool = shot in stage.FEEDS
	$Overlay/Feeds.visible = is_feed
	if is_feed and feed_views.is_empty():
		for i in stage.FEEDS.size():
			var view := SubViewport.new()
			view.size = Vector2i(288, 144)
			view.own_world_3d = true
			view.render_target_update_mode = SubViewport.UPDATE_ONCE
			add_child(view)
			var feed := STAGE_SCRIPT.new()
			feed.miniature = true
			feed.reduced = true
			view.add_child(feed)
			feed.stage(stage.FEEDS[i])
			feed_views.append(view)
			var screen := TextureRect.new()
			screen.texture = view.get_texture()
			screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
			screen.anchor_right = 1
			screen.anchor_top = i * 0.25
			screen.anchor_bottom = (i + 1) * 0.25 - 0.008
			$Overlay/Feeds.add_child(screen)
			var caption := Label.new()
			caption.text = SectorCatalog.NAMES[stage.FEEDS[i]].to_upper()
			caption.add_theme_font_size_override("font_size", 15)
			caption.add_theme_constant_override("outline_size", 4)
			caption.position = Vector2(6, 3)
			screen.add_child(caption)
	if is_feed:
		for i in feed_views.size():
			$Overlay/Feeds.get_child(i).modulate = Color.WHITE if stage.FEEDS[i] == shot else Color(0.52, 0.68, 0.7)
	elif shot == "answer":
		for screen in $Overlay/Feeds.get_children():
			screen.free()
		for view in feed_views:
			view.free()
		feed_views.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_skip()

func _skip() -> void:
	if sound_on and not exiting:
		SynthAudio.play_ui(get_tree(), "ui_click")
	_finish()

func _finish() -> void:
	if exiting:
		return
	exiting = true
	dialogue.stop()
	hull.stop()
	score.stop()
	drone.stop()
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

func _pulse_drone() -> AudioStreamWAV:
	# Integer cycles close the loop cleanly under the three-ping distress signal.
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = 22050
	clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
	clip.loop_end = clip.mix_rate * 2
	var pcm := PackedByteArray()
	pcm.resize(clip.loop_end * 2)
	for frame in clip.loop_end:
		var t := float(frame) / clip.mix_rate
		var beat := 0.42 + 0.58 * pow((1.0 - cos(TAU * t)) * 0.5, 2)
		var note := sin(TAU * 55 * t) * 0.48 + sin(TAU * 82.5 * t) * 0.23 + sin(TAU * 110 * t) * 0.12
		pcm.encode_s16(frame * 2, roundi(note * beat * 30000))
	clip.data = pcm
	return clip
