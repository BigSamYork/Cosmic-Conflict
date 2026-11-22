class_name SynthAudio
extends Node

var voices: Array[AudioStreamPlayer] = []
var pulse: AudioStreamWAV
var hit: AudioStreamWAV
var impact: AudioStreamWAV
const ImpactSpray := preload("res://scripts/impact_spray.gd")
var contact_thuds: Dictionary = {}
var last_contact_usec := -100000
var warp: AudioStreamWAV
var voice_index: int = 0
var playback_enabled: bool = true

func _ready() -> void:
	playback_enabled = DisplayServer.get_name() != "headless"
	if not playback_enabled:
		print("HEADLESS: Audio playback disabled; native validation covers the audio path.")
	pulse = make_tone(0.12, 920.0, 160.0, 0.22)
	hit = make_tone(0.18, 320.0, 80.0, 0.4)
	impact = make_tone(0.3, 90.0, 22.0, 0.5)
	for surface in ImpactSpray.Surface.values():
		contact_thuds[surface] = make_contact_thud(surface)
	warp = make_tone(1.6, 90.0, 1100.0, 0.25)
	for _i in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -10.0
		add_child(player)
		voices.append(player)

func play_sound(stream: AudioStreamWAV) -> void:
	if not playback_enabled:
		return
	var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice.stream = stream
	voice.play()
	voice_index += 1

func play_contact(surface: ImpactSpray.Surface) -> void:
	# Coincident plasma bolts and piercing hits share one cockpit confirmation.
	var now := Time.get_ticks_usec()
	if now - last_contact_usec >= 45000:
		play_sound(contact_thuds[surface])
		last_contact_usec = now

func pause_sounds(paused: bool) -> void:
	for voice in voices:
		voice.stream_paused = paused

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func set_ducked(active: bool) -> void:
	for voice in voices:
		voice.volume_db = -15.0 if active else -10.0

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

static func make_tone(duration: float, start_hz: float, end_hz: float, volume: float) -> AudioStreamWAV:
	const RATE: int = 22050
	var pcm := PackedByteArray()
	var count: int = int(duration * RATE)
	pcm.resize(count * 2)
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		phase += TAU * lerpf(start_hz, end_hz, t) / float(RATE)
		var envelope: float = minf(t * 40.0, 1.0) * pow(1.0 - t, 2.0)
		var sample: float = (sin(phase) + sin(phase * 1.99) * 0.2) * envelope * volume
		pcm.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	return stream
