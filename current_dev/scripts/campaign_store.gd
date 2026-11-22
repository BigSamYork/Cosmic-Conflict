class_name CampaignStore
extends RefCounted

var path: String
var state: CampaignState
var message: String = ""
var migrated: bool = false
var migration_backup_path: String = ""
var loaded_schema: int = CampaignState.SCHEMA

func _init(save_path: String = "user://campaign.json") -> void:
	path = save_path

func named_slot(label: String) -> CampaignStore:
	if label.is_empty() or label.length() > 40 or label != label.strip_edges():
		return null
	for character in label:
		if not (character.is_valid_ascii_identifier() or character.is_valid_int() or character in [" ", "-"]):
			return null
	return CampaignStore.new(path + ".slot-" + label + ".json")

func slot_names() -> PackedStringArray:
	var names := PackedStringArray()
	var prefix := path.get_file() + ".slot-"
	for filename in DirAccess.get_files_at(path.get_base_dir()):
		if filename.begins_with(prefix) and filename.ends_with(".json"):
			var label := filename.trim_prefix(prefix).trim_suffix(".json")
			if named_slot(label) != null:
				names.append(label)
	names.sort()
	return names

func load_game() -> Error:
	state = null
	message = ""
	migrated = false
	loaded_schema = CampaignState.SCHEMA
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		message = "Cannot open campaign save: " + error_string(FileAccess.get_open_error())
		return FileAccess.get_open_error()
	var text: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		message = "Cannot read campaign save: " + error_string(read_error)
		return read_error
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		message = "Campaign save is not valid JSON."
		return ERR_PARSE_ERROR
	var candidate := CampaignState.new()
	message = candidate.restore(json.data)
	if not message.is_empty():
		return ERR_INVALID_DATA
	state = candidate
	loaded_schema = int(json.data["schema"])
	migrated = loaded_schema != CampaignState.SCHEMA
	return OK

func save_game(candidate: CampaignState) -> Error:
	migration_backup_path = ""
	var validation := CampaignState.new()
	message = validation.restore(candidate.to_dict())
	if not message.is_empty():
		return ERR_INVALID_DATA
	if migrated and FileAccess.file_exists(path):
		var backup: String = path + ".v%d-%d-%d.bak" % [loaded_schema, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
		var backup_error: Error = DirAccess.copy_absolute(path, backup)
		if backup_error != OK:
			message = "Cannot preserve the pre-upgrade save: " + error_string(backup_error)
			return backup_error
		migration_backup_path = backup
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "Cannot write checkpoint: " + error_string(FileAccess.get_open_error())
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(candidate.to_dict(), "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		message = "Checkpoint write failed: " + error_string(error)
		return error
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		message = "Cannot replace checkpoint: " + error_string(error)
		return error
	message = ""
	migrated = false
	loaded_schema = CampaignState.SCHEMA
	return OK
