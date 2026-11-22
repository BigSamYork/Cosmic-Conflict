extends SceneTree

const RATE: int = 22050
const DURATION: float = 64.0
const THEMES: Dictionary = {
	"station": {"root": 50, "steps": [0, 5, 2, 7], "third": 4, "bell": 0.025},
	"ignis": {"root": 43, "steps": [0, 3, 5, 2], "third": 3, "bell": 0.018},
	"cryo": {"root": 54, "steps": [0, 7, 5, 2], "third": 3, "bell": 0.032},
	"vespera": {"root": 47, "steps": [0, 5, 3, 7], "third": 3, "bell": 0.027},
	"xylo": {"root": 45, "steps": [0, 2, 7, 5], "third": 3, "bell": 0.020},
	"thalassa": {"root": 46, "steps": [0, 7, 3, 5], "third": 3, "bell": 0.022},
	"kharon": {"root": 49, "steps": [0, 1, 7, 5], "third": 3, "bell": 0.024},
	"travel": {"root": 48, "steps": [0, 7, 2, 5], "third": 4, "bell": 0.015},
	"boss": {"root": 40, "steps": [0, 2, 3, 5], "third": 3, "bell": 0.012}
}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var folder: String = ProjectSettings.globalize_path("res://assets/music")
	var error: Error = DirAccess.make_dir_recursive_absolute(folder)
	if error != OK:
		push_error("Cannot create original music output: " + error_string(error))
		quit(1)
		return
	var index: Dictionary = {"generator": "original ambient score v1", "sample_rate": RATE, "seconds": DURATION, "tracks": []}
	for name: String in THEMES:
		var stream: AudioStreamWAV = compose(THEMES[name], name == "boss")
		var path: String = folder.path_join(name + ".wav")
		error = stream.save_to_wav(path)
		if error != OK:
			push_error("Cannot save music " + name + ": " + error_string(error))
			quit(1)
			return
		index["tracks"].append({"id": name, "sha256": FileAccess.get_sha256(path), "bytes": FileAccess.get_file_as_bytes(path).size()})
		print("ORIGINAL_AMBIENT_GENERATED ", name, " seconds=", stream.get_length())
	var file := FileAccess.open(folder.path_join("generated-music.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write music recording index: " + error_string(FileAccess.get_open_error()))
		quit(1)
		return
	index["generator_sha256"] = FileAccess.get_sha256(get_script().resource_path)
	file.store_string(JSON.stringify(index, "\t"))
	file.close()
	print("MUSIC_GENERATION_FAILURES=0")
	quit(0)

static func compose(theme: Dictionary, pressure: bool) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	var count: int = int(DURATION * RATE)
	pcm.resize(count * 4)
	var frequencies: Array[PackedFloat64Array] = []
	for step: int in theme["steps"]:
		var chord := PackedFloat64Array()
		for interval: int in [0, int(theme["third"]), 7, 14]:
			chord.append(440.0 * pow(2.0, (int(theme["root"]) + step + interval - 69) / 12.0))
		frequencies.append(chord)
	for i in range(count):
		var time: float = float(i) / RATE
		var left: float = 0.0
		var right: float = 0.0
		for chord in range(4):
			var age: float = fposmod(time - chord * 16.0, DURATION)
			if age >= 22.0:
				continue
			var envelope: float = smoothstep(0, 5, age) * (1.0 - smoothstep(15, 22, age))
			var breath: float = 0.9 + 0.1 * sin(age * TAU / 11)
			for voice in range(4):
				var phase: float = age * frequencies[chord][voice] * TAU
				var level: float = envelope * breath * (0.036 if voice < 3 else 0.019)
				left += (sin(phase) + sin(phase * 2.001) * 0.12) * level * (0.85 if voice % 2 == 0 else 0.65)
				right += (sin(phase * 1.0008) + sin(phase * 1.999) * 0.12) * level * (0.65 if voice % 2 == 0 else 0.85)
			var low: float = sin(age * frequencies[chord][0] * PI) * envelope * 0.04
			left += low
			right += low
		for note in range(8):
			var age: float = fposmod(time - note * 8.0, DURATION)
			if age >= 6.0:
				continue
			var hz: float = frequencies[note / 2][[2, 3, 1, 3, 2, 1, 3, 0][note]] * 2.0
			var envelope: float = smoothstep(0, 0.12, age) * exp(-age * 0.8) * (1 - smoothstep(4, 6, age))
			var bell: float = (sin(age * hz * TAU) + 0.15 * sin(age * hz * TAU * 2.4)) * envelope * float(theme["bell"])
			left += bell * (0.8 if note % 2 == 0 else 0.4)
			right += bell * (0.4 if note % 2 == 0 else 0.8)
		if pressure:
			var pulse_age: float = fposmod(time, 4)
			var pulse: float = sin(pulse_age * TAU * 44) * smoothstep(0, 0.08, pulse_age) * exp(-pulse_age * 2.0) * (1 - smoothstep(3, 4, pulse_age)) * 0.025
			left += pulse
			right += pulse
		pcm.encode_s16(i * 4, roundi(clampf(left, -0.85, 0.85) * 32767))
		pcm.encode_s16(i * 4 + 2, roundi(clampf(right, -0.85, 0.85) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = true
	stream.data = pcm
	return stream
