class_name SynthAudio
extends Node

var voices: Array[AudioStreamPlayer] = []
var reactor_blast: AudioStreamWAV
const ImpactSpray := preload("res://scripts/impact_spray.gd")
const ORGANIC_RUPTURE := preload("res://assets/sfx/organic_rupture.wav")
const TARGET_IGNITION := preload("res://assets/sfx/target_ignition.wav")
const GENERATED_DIR := "res://audio/generated_sfx/"
const CONTACT_CUES := {
	ImpactSpray.Surface.HULL: "contact_hull",
	ImpactSpray.Surface.STONE: "contact_stone",
	ImpactSpray.Surface.FLESH: "contact_flesh",
}
static var cue_streams: Dictionary = {}
var contact_thuds: Dictionary = {}
var last_contact_usec := -100000
var last_glass_frame := -1
var parasite_voice := AudioStreamPlayer.new()
var engine_voice := AudioStreamPlayer.new()
var engine_cue := ""
var last_cue_frame: Dictionary = {}
var voice_index: int = 0
var playback_enabled: bool = true

func _ready() -> void:
	playback_enabled = DisplayServer.get_name() != "headless"
	if not playback_enabled:
		print("HEADLESS: Audio playback disabled; native validation covers the audio path.")
	for surface in CONTACT_CUES:
		var contact := cue_stream(CONTACT_CUES[surface])
		contact_thuds[surface] = contact if contact != null else make_contact_thud(surface)
	parasite_voice.stream = preload("res://assets/sfx/canopy_parasite.wav")
	parasite_voice.volume_db = -8.0
	add_child(parasite_voice)
	engine_voice.volume_db = -28.0
	add_child(engine_voice)
	for _i in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -10.0
		add_child(player)
		voices.append(player)

static func cue_stream(id: String) -> AudioStream:
	if not cue_streams.has(id):
		var path := GENERATED_DIR + id + ".ogg"
		cue_streams[id] = load(path) if ResourceLoader.exists(path) else null
		if cue_streams[id] == null:
			push_warning("Missing generated sound effect: " + path)
	return cue_streams[id]

func play_cue(id: String) -> void:
	var frame := Engine.get_physics_frames()
	if playback_enabled and last_cue_frame.get(id, -1) != frame:
		last_cue_frame[id] = frame
		play_sound(cue_stream(id))

# Menu input must remain audible when flight voices are paused or stopped.
# Keeping the player on the scene root lets a click finish across a scene change.
static func play_ui(tree: SceneTree, id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var clip := cue_stream(id)
	if clip == null:
		return
	var player := tree.root.get_node_or_null("InterfaceSound") as AudioStreamPlayer
	if player == null:
		# A focus-loss pause can arrive while the root is adding a scene.
		_start_ui.call_deferred(tree, id, clip)
		return
	_play_ui_clip(tree, player, id, clip)

static func _start_ui(tree: SceneTree, id: String, clip: AudioStream) -> void:
	if not is_instance_valid(tree) or tree.root == null:
		return
	var player := tree.root.get_node_or_null("InterfaceSound") as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "InterfaceSound"
		tree.root.add_child(player)
	_play_ui_clip(tree, player, id, clip)

static func _play_ui_clip(tree: SceneTree, player: AudioStreamPlayer, id: String, clip: AudioStream) -> void:
	if id == "ui_adjust" and player.playing and player.stream == clip and player.get_playback_position() < 0.065:
		return
	player.volume_db = -18.0 if tree.get_meta("interface_audio_ducked", false) else -13.0
	player.stream = clip
	player.play()

func play_sound(stream: AudioStream) -> void:
	if not playback_enabled or stream == null:
		return
	var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice.stream = stream
	voice.play()
	voice_index += 1

func play_thunder() -> void:
	play_sound(preload("res://assets/sfx/thunder_crack.wav"))

func play_glass_break() -> void:
	var frame := Engine.get_physics_frames()
	if last_glass_frame != frame:
		last_glass_frame = frame
		play_sound(preload("res://assets/sfx/canopy_fracture.wav"))

func play_reactor_blast() -> void:
	var generated := cue_stream("reactor_blast")
	if generated != null:
		play_sound(generated)
		return
	if reactor_blast == null:
		const RATE := 22050
		var rng := RandomNumberGenerator.new()
		rng.seed = 7118
		var pcm := PackedByteArray()
		pcm.resize(int(1.4 * RATE) * 2)
		var rumble := 0.0
		for i in range(pcm.size() / 2):
			var t := float(i) / RATE
			var noise := rng.randf_range(-1.0, 1.0)
			rumble = lerpf(rumble, noise, 0.021)
			var roll := 0.58 + 0.42 * cos(13.0 * t + 1.7 * sin(t * 8.0))
			var sample := noise * exp(-48.0 * t) * 0.44 + rumble * 4.2 * roll * exp(-2.6 * t)
			pcm.encode_s16(i * 2, roundi(32767 * clampf(sample, -0.98, 0.98)))
		reactor_blast = AudioStreamWAV.new()
		reactor_blast.format = AudioStreamWAV.FORMAT_16_BITS
		reactor_blast.mix_rate = RATE
		reactor_blast.data = pcm
	play_sound(reactor_blast)

func play_contact(surface: ImpactSpray.Surface) -> void:
	# Coincident plasma bolts and piercing hits share one cockpit confirmation.
	var now := Time.get_ticks_usec()
	if now - last_contact_usec >= 45000:
		play_sound(contact_thuds[surface])
		last_contact_usec = now

func play_destruction(surface: ImpactSpray.Surface) -> void:
	play_sound(ORGANIC_RUPTURE if surface == ImpactSpray.Surface.FLESH else TARGET_IGNITION)

func update_engine(cue: String, speed: float) -> void:
	if not playback_enabled:
		return
	if cue != engine_cue:
		engine_voice.stop()
		engine_cue = cue
		if not cue.is_empty():
			var stream := cue_stream(cue) as AudioStreamOggVorbis
			if stream != null:
				stream.loop = true
				engine_voice.stream = stream
				engine_voice.play()
	if engine_voice.playing:
		engine_voice.pitch_scale = clampf(0.78 + speed * 0.005, 0.78, 1.3)

func pause_sounds(paused: bool) -> void:
	parasite_voice.stream_paused = paused
	engine_voice.stream_paused = paused
	for voice in voices:
		voice.stream_paused = paused

func stop_all() -> void:
	last_cue_frame.clear()
	parasite_voice.stop()
	engine_voice.stop()
	engine_cue = ""
	for voice in voices:
		voice.stop()
		voice.stream = null

func set_ducked(active: bool) -> void:
	get_tree().set_meta("interface_audio_ducked", active)
	var ui := get_tree().root.get_node_or_null("InterfaceSound") as AudioStreamPlayer
	if ui != null:
		ui.volume_db = -18.0 if active else -13.0
	parasite_voice.volume_db = -13.0 if active else -8.0
	engine_voice.volume_db = -34.0 if active else -28.0
	for voice in voices:
		voice.volume_db = -15.0 if active else -10.0

func set_parasite_audible(active: bool) -> void:
	if active and playback_enabled and not parasite_voice.playing:
		parasite_voice.play()
	elif not active and parasite_voice.playing:
		parasite_voice.stop()

func _exit_tree() -> void:
	stop_all()

static func make_contact_thud(surface: ImpactSpray.Surface) -> AudioStreamWAV:
	const RATE := 22050
	var pcm := PackedByteArray()
	var count := int(0.23 * RATE)
	pcm.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 28463 + surface
	var flesh := surface == ImpactSpray.Surface.FLESH
	var hull := surface == ImpactSpray.Surface.HULL
	var phase := 0.0
	var grain := 0.0
	for i in range(count):
		var t := float(i) / RATE
		phase += TAU * (62.0 + 104.0 * exp(-t * 42.0)) / RATE
		grain = lerpf(grain, noise.randf_range(-1.0, 1.0), 0.20 if flesh else 0.57)
		var body := sin(phase) * exp(-t * 22.0) * 0.65
		var attack := grain * (0.48 if flesh else 0.76) * exp(-t * (48.0 if hull else 29.0))
		if hull:
			attack += (sin(t * TAU * 693.0) + sin(t * TAU * 1049.0) * 0.4) * exp(-t * 46.0) * 0.18
		elif flesh:
			attack += grain * exp(-absf(t - 0.038) * 112.0) * 0.65
		var sample := clampf((body + attack) * minf(1.0, t * 1500.0), -0.97, 0.97)
		pcm.encode_s16(i * 2, roundi(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	return stream
