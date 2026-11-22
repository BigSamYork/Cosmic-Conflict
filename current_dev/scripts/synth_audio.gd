class_name SynthAudio
extends Node

var voices: Array[AudioStreamPlayer] = []
var pulse: AudioStreamWAV
var hit: AudioStreamWAV
var impact: AudioStreamWAV
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
