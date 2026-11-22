class_name VoiceDocument
extends RefCounted

var data: Dictionary = {}
var path: String = ""
var disk_hash: String = ""
var saved_json: String = ""

func open_file(candidate_path: String) -> String:
	var catalog := VoiceCatalog.new()
	var error: String = catalog.read_catalog(candidate_path, ComputerVoice.RULES)
	if not error.is_empty():
		return error
	data = catalog.data
	path = candidate_path
	disk_hash = FileAccess.get_sha256(path)
	saved_json = JSON.stringify(data)
	return ""

func new_game_file() -> String:
	var error: String = open_file(VoiceCatalog.DEFAULT_PATH)
	if error.is_empty():
		path = ProjectSettings.globalize_path(VoiceCatalog.USER_PATH)
		disk_hash = ""
		saved_json = ""
	return error

func has_changes() -> bool:
	return not data.is_empty() and JSON.stringify(data) != saved_json

func add_line(section_index: int, event: String, text: String) -> String:
	if section_index < 0 or section_index >= data.get("sections", []).size():
		return "Choose a category for the new saying."
	if not ComputerVoice.RULES.has(event):
		return "Choose an existing game event for the new saying."
	if text.strip_edges().is_empty():
		return "Enter the words for the new saying."
	var ids: Dictionary = {}
	for section in data["sections"]:
		for line in section["lines"]:
			ids[line["id"]] = true
	var number: int = 1
	var id: String = "%s_%02d" % [event, number]
	while ids.has(id):
		number += 1
		id = "%s_%02d" % [event, number]
	data["sections"][section_index]["lines"].append({
		"id": id, "event": event, "added": true, "text": text,
		"chance_percent": 25 if event.begins_with("route_") else 100,
		"cooldown_seconds": 0.0
	})
	return ""

func save_file(destination: String) -> String:
	var catalog := VoiceCatalog.new()
	var error: String = catalog.validate_data(data.duplicate(true), ComputerVoice.RULES)
	if not error.is_empty():
		return error
	var exists: bool = FileAccess.file_exists(destination)
	if _path_key(destination) == _path_key(path) and ((exists and FileAccess.get_sha256(destination) != disk_hash) or (not exists and not disk_hash.is_empty())):
		return "This file changed outside the editor. Reopen it, or use Save as to keep your edits in a different file."
	var temporary: String = destination + ".editing-%d.tmp" % OS.get_process_id()
	error = VoiceCatalog.write_text(temporary, JSON.stringify(data, "\t", false) + "\n")
	if error.is_empty() and exists:
		var backup_error: Error = DirAccess.copy_absolute(destination, destination + ".bak")
		if backup_error != OK:
			error = "Cannot back up the original voice file: " + error_string(backup_error)
	if error.is_empty():
		var replace_error: Error = DirAccess.rename_absolute(temporary, destination)
		if replace_error != OK:
			error = "Cannot save the voice file: " + error_string(replace_error)
	if not error.is_empty():
		if FileAccess.file_exists(temporary):
			var cleanup_error: Error = DirAccess.remove_absolute(temporary)
			if cleanup_error != OK:
				error += "\nCannot remove temporary file %s: %s" % [temporary, error_string(cleanup_error)]
		return error
	path = destination
	disk_hash = FileAccess.get_sha256(path)
	saved_json = JSON.stringify(data)
	return ""

func _path_key(value: String) -> String:
	var absolute: String = ProjectSettings.globalize_path(value).replace("\\", "/").simplify_path()
	return absolute.to_lower() if OS.get_name() == "Windows" else absolute
