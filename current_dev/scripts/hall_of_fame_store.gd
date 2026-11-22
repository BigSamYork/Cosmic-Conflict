class_name HallOfFameStore
extends RefCounted

var path: String
var records: Array[Dictionary] = []
var message: String = ""

func _init(record_path: String = "user://hall_of_fame.json") -> void:
	path = record_path

func load_records() -> Error:
	message = ""
	records.clear()
	if not FileAccess.file_exists(path):
		return OK
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		message = "Cannot open the Hall of Fame: " + error_string(FileAccess.get_open_error())
		return FileAccess.get_open_error()
	var text: String = file.get_as_text()
	var error: Error = file.get_error()
	file.close()
	if error != OK and error != ERR_FILE_EOF:
		message = "Cannot read the Hall of Fame: " + error_string(error)
		return error
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		message = "The Hall of Fame is not valid JSON. Its file has not been replaced."
		return ERR_PARSE_ERROR
	var data: Dictionary = json.data
	if data.get("schema") != 1 or not data.get("records") is Array:
		message = "Unsupported or malformed Hall of Fame format."
		return ERR_INVALID_DATA
	var ids: Dictionary = {}
	var candidates: Array[Dictionary] = []
	for record: Variant in data["records"]:
		message = CampaignHonors.validate_record(record)
		if not message.is_empty():
			return ERR_INVALID_DATA
		var id: String = CampaignHonors.record_id(record)
		if ids.has(id):
			message = "Duplicate completed tour in the Hall of Fame."
			return ERR_INVALID_DATA
		ids[id] = true
		candidates.append(CampaignHonors.normalized_record(record))
	records = candidates
	return OK

func record_tour(record: Dictionary) -> Error:
	message = CampaignHonors.validate_record(record)
	if not message.is_empty():
		return ERR_INVALID_DATA
	record = CampaignHonors.normalized_record(record)
	var error: Error = load_records()
	if error != OK:
		return error
	var id: String = CampaignHonors.record_id(record)
	for existing in records:
		if CampaignHonors.record_id(existing) == id:
			if existing != record:
				message = "This tour already has a different recorded result. The original is preserved."
				return ERR_INVALID_DATA
			return OK
	var next: Array[Dictionary] = records.duplicate(true)
	next.append(record.duplicate(true))
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "Cannot save the Hall of Fame: " + error_string(FileAccess.get_open_error())
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema": 1, "records": next}, "\t"))
	file.flush()
	error = file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		message = "Cannot replace the Hall of Fame: " + error_string(error)
		return error
	records = next
	return OK

func ranked(assisted: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record in records:
		if record["assisted"] == assisted:
			result.append(record.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["rating"] != b["rating"]:
			return a["rating"] > b["rating"]
		return CampaignHonors.record_id(a) < CampaignHonors.record_id(b))
	return result
