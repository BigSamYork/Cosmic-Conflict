extends RefCounted

const SOURCE := "res://assets/voice/bosses.json"
const AUDIO_DIR := "res://assets/voice/bosses/"
const EVENTS := ["arrival", "hurt_1", "hurt_2", "hurt_3"]
static var transcripts: Dictionary = {}

static func cue(sector: String, orbital: bool, event: String) -> Dictionary:
	if transcripts.is_empty():
		transcripts = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var role := "%s_%s" % [sector, "orbit" if orbital else "ground"]
	if not transcripts.has(role) or not event in EVENTS:
		return {}
	var id := role + "_" + event
	var names := SectorCatalog.ORBITAL_BOSSES if orbital else SectorCatalog.GROUND_BOSSES
	return {"id": id, "text": transcripts[role][event], "audio": AUDIO_DIR + id + ".wav", "speaker": names[sector]}
