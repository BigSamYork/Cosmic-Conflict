class_name VoiceCatalog
extends RefCounted

const DEFAULT_PATH: String = "res://assets/voice/lines.json"
const USER_PATH: String = "user://computer-voice.json"
const RECORDING_INDEX: String = "res://assets/voice/generated-voice.json"
const GENERATOR: String = "res://assets/voice/generate-voice.ps1"

var lines: Array[Dictionary] = []
var recording_paths: Dictionary = {}
var data: Dictionary = {}

func read_catalog(path: String, rules: Dictionary) -> String:
	data.clear()
	lines.clear()
	recording_paths.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Cannot open computer voice catalog %s: %s" % [path, error_string(FileAccess.get_open_error())]
	var source: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return "Cannot read computer voice catalog: " + error_string(read_error)
	var parser := JSON.new()
	if parser.parse(source) != OK or not parser.data is Dictionary:
		return "Invalid computer voice JSON in %s at line %d: %s" % [path, parser.get_error_line(), parser.get_error_message()]
	var error: String = validate_data(parser.data, rules)
	if not error.is_empty():
		return error + " File: " + path
	data = parser.data
	return ""

func load_catalog(path: String, rules: Dictionary, cache_directory: String = "user://voice-cache") -> String:
	var error: String = read_catalog(path, rules)
	if not error.is_empty():
		return error
	var proof := JSON.new()
	if not FileAccess.file_exists(RECORDING_INDEX) or proof.parse(FileAccess.get_file_as_string(RECORDING_INDEX)) != OK or not proof.data is Dictionary or not proof.data.get("clips") is Array:
		return "Computer voice recording index is missing or invalid."
	var recorded: Dictionary = {}
	for clip in proof.data["clips"]:
		if not clip is Dictionary or not clip.get("id") is String or not clip.get("text_sha256") is String:
			return "Computer voice recording index needs regeneration with tools\\generate-voice.ps1 -Overwrite."
		recorded[clip["id"]] = clip["text_sha256"]
	var pending: Array[Dictionary] = []
	for line in lines:
		if line["chance_percent"] == 0:
			continue
		var id: String = line["id"]
		var text_hash: String = line["text"].sha256_text()
		if proof.data.get("voice") == data["voice"] and recorded.get(id) == text_hash:
			var recording: String = "res://assets/voice/%s.wav" % id
			if not ResourceLoader.exists(recording):
				return "Computer voice recording is missing: " + recording
			recording_paths[id] = recording
		else:
			var cache_id: String = "line_" + (data["voice"] + "\n" + line["text"]).sha256_text()
			var recording: String = cache_directory.path_join(cache_id + ".wav")
			recording_paths[id] = recording
			if not FileAccess.file_exists(recording) and not pending.any(func(item: Dictionary) -> bool: return item["id"] == cache_id):
				pending.append({"id": cache_id, "event": line["event"], "text": line["text"]})
	if not pending.is_empty():
		error = _generate(data["voice"], pending, cache_directory)
		if not error.is_empty():
			return error
	return ""

func validate_data(candidate: Dictionary, rules: Dictionary) -> String:
	lines.clear()
	if not candidate.get("voice") is String or candidate["voice"].strip_edges().is_empty():
		return "Computer voice name is missing."
	if not candidate.get("sections") is Array or candidate["sections"].is_empty():
		return "Computer voice catalog has no sections."
	var ids: Dictionary = {}
	var id_pattern := RegEx.new()
	id_pattern.compile("^[a-z][a-z0-9_]*$")
	for section in candidate["sections"]:
		if not section is Dictionary or not section.get("lines") is Array:
			return "Computer voice section is malformed."
		for item in section["lines"]:
			if not item is Dictionary or not item.get("id") is String or not item.get("event") is String or not item.get("text") is String:
				return "Computer voice line requires an id, event and text."
			var id: String = item["id"]
			if ids.has(id) or id_pattern.search(id) == null or not rules.has(item["event"]) or item["text"].strip_edges().is_empty():
				return "Computer voice line has an invalid or duplicate ID, event or text: " + id
			var chance: Variant = item.get("chance_percent", 25 if item["event"].begins_with("route_") else 100)
			var cooldown: Variant = item.get("cooldown_seconds", 0)
			if not _number_between(chance, 0, 100) or float(chance) != floorf(float(chance)):
				return "Computer voice chance_percent must be a whole number from 0 to 100: " + id
			if not _number_between(cooldown, 0, 86400):
				return "Computer voice cooldown_seconds must be from 0 to 86400: " + id
			item["chance_percent"] = int(chance)
			item["cooldown_seconds"] = float(cooldown)
			ids[id] = true
			lines.append(item)
	if lines.is_empty():
		return "Computer voice catalog has no lines."
	return ""

func _number_between(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

static func write_text(path: String, text: String) -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Cannot write %s: %s" % [path, error_string(FileAccess.get_open_error())]
	file.store_string(text)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return "" if error == OK else "Cannot write %s: %s" % [path, error_string(error)]

func _generate(voice: String, pending: Array[Dictionary], cache_directory: String) -> String:
	if OS.get_name() != "Windows":
		return "Edited computer voice text requires Windows with the selected offline voice installed."
	if not FileAccess.file_exists(GENERATOR):
		return "The bundled computer voice generator is missing."
	var error: Error = DirAccess.make_dir_recursive_absolute(cache_directory)
	if error != OK:
		return "Cannot create computer voice cache: " + error_string(error)
	var job: String = cache_directory.path_join("generation-%d-%d" % [OS.get_process_id(), get_instance_id()])
	error = DirAccess.make_dir_recursive_absolute(job)
	if error != OK:
		return "Cannot create computer voice generation folder: " + error_string(error)
	var script_path: String = job.path_join("generate-voice.ps1")
	var request_path: String = job.path_join("request.json")
	var message: String = write_text(script_path, FileAccess.get_file_as_string(GENERATOR))
	if message.is_empty():
		message = write_text(request_path, JSON.stringify({"voice": voice, "sections": [{"lines": pending}]}))
	if message.is_empty():
		var output: Array = []
		var powershell: String = OS.get_environment("SystemRoot").path_join("System32\\WindowsPowerShell\\v1.0\\powershell.exe")
		var exit_code: int = OS.execute(powershell, PackedStringArray([
			"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(script_path),
			"-CatalogPath", ProjectSettings.globalize_path(request_path), "-OutputDirectory", ProjectSettings.globalize_path(job)
		]), output, true)
		if exit_code != 0:
			message = "Computer voice generation failed (exit %d). Check Windows voice '%s'. %s" % [exit_code, voice, "\n".join(output)]
		else:
			for line in pending:
				var filename: String = line["id"] + ".wav"
				error = DirAccess.rename_absolute(job.path_join(filename), cache_directory.path_join(filename))
				if error != OK:
					message = "Cannot cache edited computer voice recording: " + error_string(error)
					break
	# Only this job's known files are removed, never another game's cache.
	var temporary: Array[String] = [script_path, request_path, job.path_join("generated-voice.json")]
	for line in pending:
		temporary.append(job.path_join(line["id"] + ".wav"))
	for path in temporary:
		if FileAccess.file_exists(path):
			error = DirAccess.remove_absolute(path)
			if error != OK:
				message += " Cannot remove voice generation file %s: %s" % [path, error_string(error)]
	error = DirAccess.remove_absolute(job)
	if error != OK:
		message += " Cannot remove voice generation folder: " + error_string(error)
	return message
