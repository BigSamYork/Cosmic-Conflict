class_name CampaignHonors
extends RefCounted

const RANKS: Array[String] = [
	"First Lieutenant Loser", "Ensign Space Cadet", "Flight Officer Rookie",
	"Captain Star-Strider", "Commander Void-Hunter", "Commodore Ace Pilot",
	"Admiral Nova-Vanguard", "General Grandmaster"
]
const THRESHOLDS: Array[int] = [0, 200, 350, 500, 625, 750, 850, 950]
const MEDALS: Array[String] = [
	"Surviving Hardware", "First Light", "Orbital Pathfinder", "Four-World Star",
	"Void Compass", "Stellar Crest", "Nova Laureate", "Cosmic Apex"
]
const COUNTERS: Array[String] = [
	"enemies", "bosses", "asteroids", "shots", "hits", "ejections", "sorties",
	"minerals", "chain_rocks", "radars", "webs", "pirates", "eggs", "guardians",
	"earned", "spent", "combat_score", "combo_bonus_credits", "mineral_credits",
	"accuracy_bonus_credits", "best_streak"
]
const LOADOUT_COUNTERS: Array[String] = [
	"credits", "primary_level", "shield_level", "heat_sink_level", "hull_armor_level", "ammo", "flares"
]
const LOADOUT_FLAGS: Array[String] = [
	"secondary", "swarm_launcher", "emp_launcher", "countermeasures", "tractor"
]

static func score_parts(metrics: Dictionary, damage_complete: bool) -> Dictionary:
	var accuracy: int = floori(300.0 * clampf(float(metrics["hits"]) / metrics["shots"], 0, 1)) if metrics["shots"] >= 20 else 0
	var combat: int = floori(300.0 * minf(metrics["combat_score"], 100000) / 100000.0)
	var survival: int = maxi(0, 250 - int(metrics["ejections"]) * 75 - floori(metrics["hull_damage"] / 4.0)) if damage_complete else 0
	var streak: int = mini(int(metrics["best_streak"]), 25) * 6
	return {"accuracy": accuracy, "combat": combat, "survival": survival, "streak": streak}

static func rating(metrics: Dictionary, damage_complete: bool) -> int:
	var total: int = 0
	for value: int in score_parts(metrics, damage_complete).values():
		total += value
	return total

static func rank_for(score: int) -> int:
	var rank: int = 0
	for i in range(THRESHOLDS.size()):
		if score >= THRESHOLDS[i]:
			rank = i
	return rank

static func validate_metrics(metrics: Variant) -> String:
	if not metrics is Dictionary:
		return "Missing campaign totals."
	for key in COUNTERS:
		if not metrics.has(key) or not CampaignState._whole(metrics[key]):
			return "Invalid campaign total: " + key
	if not metrics.has("hull_damage") or not (metrics["hull_damage"] is float or metrics["hull_damage"] is int) or not is_finite(float(metrics["hull_damage"])) or metrics["hull_damage"] < 0 or metrics["hull_damage"] > 1000000000:
		return "Invalid cumulative hull damage."
	if metrics["guardians"] > metrics["enemies"] or metrics["pirates"] > metrics["enemies"] or metrics["chain_rocks"] > metrics["asteroids"]:
		return "Inconsistent campaign encounter totals."
	return ""

static func validate_record(record: Variant) -> String:
	if not record is Dictionary:
		return "Invalid Hall of Fame record."
	for key in ["operation_id", "completed_at"]:
		if not record.has(key) or not record[key] is String or record[key].is_empty():
			return "Missing record identity or completion date."
	if not valid_operation_id(record["operation_id"]):
		return "Invalid record operation identity."
	for key in ["tour", "rating", "rank"]:
		if not record.has(key) or not CampaignState._whole(record[key]):
			return "Invalid record field: " + key
	if record["tour"] < 1 or record["rating"] > 1000 or record["rank"] >= RANKS.size():
		return "Record rating or tour is out of range."
	for key in ["assisted", "damage_complete", "lifetime_damage_complete"]:
		if not record.has(key) or not record[key] is bool:
			return "Invalid record flag: " + key
	for key in ["totals", "lifetime"]:
		var error: String = validate_metrics(record.get(key))
		if not error.is_empty():
			return error
	for key: String in record["totals"]:
		if not record["lifetime"].has(key) or record["totals"][key] > record["lifetime"][key]:
			return "Tour totals exceed lifetime totals."
	if record.has("sectors") and (not record["sectors"] is Array or (record["sectors"] != SectorCatalog.LEGACY and record["sectors"] != SectorCatalog.AVAILABLE)):
		return "Invalid completed-tour sector scope."
	if record["totals"]["sorties"] < record_sectors(record).size():
		return "Completed tour has fewer successful sorties than required worlds."
	if record["rating"] != rating(record["totals"], record["damage_complete"]) or record["rank"] != rank_for(record["rating"]):
		return "Record rank does not match its performance."
	var loadout: Variant = record.get("loadout")
	if not loadout is Dictionary or not loadout.has("ship") or not loadout["ship"] is String or not CampaignState.SHIPS.has(loadout["ship"]):
		return "Invalid final ship."
	for key in LOADOUT_COUNTERS:
		if not loadout.has(key) or not CampaignState._whole(loadout[key]):
			return "Invalid final loadout counter: " + key
	for key in LOADOUT_FLAGS:
		if not loadout.has(key) or not loadout[key] is bool:
			return "Invalid final loadout flag: " + key
	for key in ["primary_level", "shield_level", "heat_sink_level", "hull_armor_level"]:
		if loadout[key] > 2:
			return "Final equipment level is out of range."
	if loadout["ammo"] > CampaignState.SHIPS[loadout["ship"]]["ammo"] or loadout["flares"] > CampaignState.FLARE_CAPACITY or (not loadout["countermeasures"] and loadout["flares"] != 0):
		return "Invalid final ammunition."
	if not loadout.has("power_mode") or not loadout["power_mode"] is String or not CampaignState.POWER_MODES.has(loadout["power_mode"]):
		return "Invalid final reactor mode."
	var selected: Variant = loadout.get("selected_secondary")
	if not selected is String or not CampaignState.SECONDARIES.has(selected):
		return "Invalid final secondary selection."
	var owned: Dictionary = {"concussion": loadout["secondary"], "swarm": loadout["swarm_launcher"], "emp": loadout["emp_launcher"]}
	var has_secondary: bool = loadout["secondary"] or loadout["swarm_launcher"] or loadout["emp_launcher"]
	if (has_secondary and not owned[selected]) or (not has_secondary and (selected != "concussion" or loadout["ammo"] != 0)):
		return "Final secondary selection is not equipped."
	return ""

static func valid_operation_id(value: Variant) -> bool:
	return value is String and value.length() == 32 and value.is_valid_hex_number(false)

static func normalized_metrics(metrics: Dictionary) -> Dictionary:
	var result: Dictionary = metrics.duplicate()
	for key in COUNTERS:
		result[key] = int(metrics[key])
	result["hull_damage"] = float(metrics["hull_damage"])
	return result

static func normalized_record(record: Dictionary) -> Dictionary:
	# Godot's JSON parser reads all numbers as floats; snapshots use typed counters.
	var result: Dictionary = record.duplicate(true)
	for key in ["tour", "rank", "rating"]:
		result[key] = int(record[key])
	for key in ["totals", "lifetime"]:
		result[key] = normalized_metrics(record[key])
	for key in LOADOUT_COUNTERS:
		result["loadout"][key] = int(record["loadout"][key])
	return result

static func record_id(record: Dictionary) -> String:
	return "%s:%d" % [record["operation_id"], record["tour"]]

static func record_sectors(record: Dictionary) -> Array:
	return record.get("sectors", SectorCatalog.LEGACY)

static func loadout_text(loadout: Dictionary) -> String:
	var equipment: Array[String] = []
	for key in LOADOUT_FLAGS:
		if loadout[key]:
			equipment.append({"secondary": "Concussion", "swarm_launcher": "Swarm", "emp_launcher": "EMP", "countermeasures": "Flare pod", "tractor": "Tractor"}[key])
	return "%s / %s / %d CR\nShield Lv %d / Cooling Lv %d / Armor Lv %d / Ordnance %d / Flares %d\n%s" % [
		CampaignState.SHIPS[loadout["ship"]]["name"], FlightState.PRIMARY_NAMES[loadout["primary_level"]], loadout["credits"],
		loadout["shield_level"], loadout["heat_sink_level"], loadout["hull_armor_level"], loadout["ammo"], loadout["flares"],
		", ".join(equipment) if not equipment.is_empty() else "No optional equipment"]
