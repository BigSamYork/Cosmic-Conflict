class_name CampaignState
extends RefCounted

const SCHEMA: int = 12
const MINERAL_VALUE: int = 50
const FLARE_CAPACITY: int = 3
const SECONDARIES: Dictionary = {
	"concussion": {"name": "Concussion", "ammo": 1},
	"swarm": {"name": "Swarm Rockets", "ammo": 2},
	"emp": {"name": "EMP Nova", "ammo": 3}
}
const POWER_MODES: Array[String] = ["balanced", "weapons", "shields", "engines"]
const PHASES: Array[String] = ["launch", "ground", "ground_boss", "orbit", "orbit_boss", "asteroids", "docking", "market"]
const SHIPS: Dictionary = {
	"rook": {"name": "Rook Scout", "cost": 300, "shield": 100.0, "hull": 100.0, "response": 1.0, "ammo": 6, "radius": 0.6},
	"hawk": {"name": "Vector Hawk", "cost": 900, "shield": 80.0, "hull": 80.0, "response": 1.35, "ammo": 8, "radius": 0.48},
	"titan": {"name": "Aegis Titan", "cost": 2400, "shield": 160.0, "hull": 240.0, "response": 0.7, "ammo": 12, "radius": 0.85},
	"bastion": {"name": "Nova Bastion", "cost": 3600, "shield": 220.0, "hull": 200.0, "response": 0.8, "ammo": 16, "radius": 0.78},
	"emergency": {"name": "Rescue Skiff", "cost": 0, "shield": 45.0, "hull": 50.0, "response": 0.85, "ammo": 3, "radius": 0.55}
}

var phase: String = "ground"
var sector: String = "ignis"
var cleared_sectors: Array[String] = []
var required_sectors: Array[String] = SectorCatalog.AVAILABLE.duplicate()
var replays_unlocked: bool = false
var operation_id: String = Crypto.new().generate_random_bytes(16).hex_encode()
var tour: int = 1
var tour_start: Dictionary = {}
var tour_best_streak: int = 0
var hull_damage: float = 0.0
var damage_history_complete: bool = true
var tour_damage_complete: bool = true
var tour_result: Dictionary = {}
var ship: String = "rook"
var credits: int = 0
var earned: int = 0
var spent: int = 0
var primary_level: int = 0
var shield_level: int = 0
var heat_sink_level: int = 0
var hull_armor_level: int = 0
var power_mode: String = "balanced"
var secondary: bool = false
var swarm_launcher: bool = false
var emp_launcher: bool = false
var selected_secondary: String = "concussion"
var countermeasures: bool = false
var flares: int = 0
var ammo: int = 0
var hull: float = 100.0
var shields: float = 100.0
var sortie_id: int = 1
var settled_sortie_id: int = 0
var last_result: String = "new"
var assisted: bool = false
var combo_kills: int = 0
var best_streak: int = 0
var combat_score: int = 0
var combo_bonus_credits: int = 0
var tractor: bool = false
var mineral_credits: int = 0
var stats: Dictionary = {"enemies": 0, "bosses": 0, "asteroids": 0, "shots": 0, "hits": 0, "ejections": 0, "sorties": 0, "minerals": 0, "chain_rocks": 0, "radars": 0, "webs": 0, "pirates": 0, "eggs": 0, "guardians": 0}
var sortie_start_shots: int = 0
var sortie_start_hits: int = 0
var accuracy_bonus_credits: int = 0
var debrief: Dictionary = {"completion": 0, "hull": 0, "accuracy": 0, "shots": 0, "hits": 0}

func shield_capacity() -> float:
	return 0.0 if ship.is_empty() else float(SHIPS[ship]["shield"]) + shield_level * 25.0

func hull_capacity() -> float:
	return 0.0 if ship.is_empty() else float(SHIPS[ship]["hull"]) + hull_armor_level * 25.0

func owns_secondary(weapon: String) -> bool:
	match weapon:
		"concussion": return secondary
		"swarm": return swarm_launcher
		"emp": return emp_launcher
	return false

func select_secondary(weapon: String) -> String:
	if not tour_result.is_empty():
		return "Continue to the next tour before changing the completed loadout."
	if not SECONDARIES.has(weapon):
		return "Unknown secondary weapon station."
	if ship.is_empty() or not owns_secondary(weapon):
		return "Purchase that weapon station at Astra Market first."
	selected_secondary = weapon
	return ""

func reward(amount: int) -> void:
	assert(amount >= 0)
	credits += amount
	earned += amount

func combo_multiplier() -> int:
	return 4 if combo_kills >= 10 else 2 if combo_kills >= 5 else 1

func record_combat_kill(base_credits: int) -> int:
	assert(base_credits > 0)
	combo_kills += 1
	best_streak = maxi(best_streak, combo_kills)
	tour_best_streak = maxi(tour_best_streak, combo_kills)
	var payout: int = base_credits * combo_multiplier()
	reward(payout)
	combat_score += payout * 10
	combo_bonus_credits += payout - base_credits
	return payout

func break_combo() -> void:
	combo_kills = 0

func collect_mineral() -> void:
	stats["minerals"] += 1
	mineral_credits += MINERAL_VALUE
	reward(MINERAL_VALUE)

func dock(completed: bool) -> void:
	if settled_sortie_id != sortie_id:
		debrief = {"completion": 0, "hull": 0, "accuracy": 0, "shots": stats["shots"] - sortie_start_shots, "hits": stats["hits"] - sortie_start_hits}
		if completed:
			debrief["completion"] = 350
			debrief["hull"] = int(hull)
			if debrief["shots"] >= 20:
				debrief["accuracy"] = floori(clampf(float(debrief["hits"]) / debrief["shots"], 0, 1) * 200)
			accuracy_bonus_credits += debrief["accuracy"]
			reward(debrief["completion"] + debrief["hull"] + debrief["accuracy"])
			stats["sorties"] += 1
			if not cleared_sectors.has(sector):
				cleared_sectors.append(sector)
			if tour_complete():
				replays_unlocked = true
		settled_sortie_id = sortie_id
		last_result = "completed" if completed else "ejected"
	phase = "market"
	break_combo()
	hull = hull_capacity()
	shields = shield_capacity()
	if completed and tour_complete() and tour_result.is_empty():
		_seal_tour()

func tour_complete() -> bool:
	for id in required_sectors:
		if not cleared_sectors.has(id):
			return false
	return true

func health_multiplier() -> float:
	return 1.0 + 0.25 * mini(tour - 1, 4)

func totals() -> Dictionary:
	var result: Dictionary = stats.duplicate()
	for key in ["earned", "spent", "combat_score", "combo_bonus_credits", "mineral_credits", "accuracy_bonus_credits", "best_streak", "hull_damage"]:
		result[key] = get(key)
	return result

func tour_totals() -> Dictionary:
	var result: Dictionary = totals()
	for key: String in result:
		result[key] -= tour_start.get(key, 0)
	result["best_streak"] = tour_best_streak
	return result

func _seal_tour() -> void:
	var loadout: Dictionary = {"ship": ship, "power_mode": power_mode, "selected_secondary": selected_secondary}
	for key in CampaignHonors.LOADOUT_COUNTERS + CampaignHonors.LOADOUT_FLAGS:
		loadout[key] = get(key)
	var metrics: Dictionary = tour_totals()
	var score: int = CampaignHonors.rating(metrics, tour_damage_complete)
	tour_result = {
		"operation_id": operation_id, "tour": tour, "completed_at": Time.get_datetime_string_from_system(true) + "Z",
		"assisted": assisted, "damage_complete": tour_damage_complete, "lifetime_damage_complete": damage_history_complete,
		"totals": metrics, "lifetime": totals(), "loadout": loadout, "rating": score, "rank": CampaignHonors.rank_for(score),
		"sectors": required_sectors.duplicate()
	}

func continue_tour() -> String:
	if phase != "market" or tour_result.is_empty():
		return "Complete every planet in this tour and dock before continuing."
	if tour >= 1000000000:
		return "The saved tour counter has reached its supported limit."
	tour_start = totals()
	tour += 1
	tour_best_streak = 0
	tour_damage_complete = true
	tour_result = {}
	required_sectors = SectorCatalog.AVAILABLE.duplicate()
	cleared_sectors.clear()
	last_result = "new"
	break_combo()
	sortie_start_shots = stats["shots"]
	sortie_start_hits = stats["hits"]
	debrief = {"completion": 0, "hull": 0, "accuracy": 0, "shots": 0, "hits": 0}
	return ""

func eject() -> void:
	if ship.is_empty() or not tour_result.is_empty():
		return
	stats["ejections"] += 1
	ship = ""
	primary_level = 0
	shield_level = 0
	heat_sink_level = 0
	hull_armor_level = 0
	power_mode = "balanced"
	secondary = false
	swarm_launcher = false
	emp_launcher = false
	selected_secondary = "concussion"
	countermeasures = false
	flares = 0
	ammo = 0
	tractor = false
	dock(false)

func can_visit(destination: String) -> bool:
	return SectorCatalog.AVAILABLE.has(destination) and (not cleared_sectors.has(destination) or replays_unlocked)

func depart(destination: String) -> String:
	if phase != "market":
		return "Choose a destination while docked at Astra Market."
	if not tour_result.is_empty():
		return "Choose Continue in the campaign debrief before departing on the next tour."
	if ship.is_empty():
		return "Obtain a replacement ship before leaving the station."
	if not SectorCatalog.AVAILABLE.has(destination):
		return "That sector is not available in this build."
	if not can_visit(destination):
		return "Clear the remaining available sectors before starting a replay."
	sector = destination
	sortie_id += 1
	phase = "launch"
	last_result = "departed"
	break_combo()
	sortie_start_shots = stats["shots"]
	sortie_start_hits = stats["hits"]
	return ""

func price(item: String) -> int:
	match item:
		"rook", "hawk", "titan", "bastion", "emergency": return int(SHIPS[item]["cost"])
		"primary": return 250 * (primary_level + 1)
		"shield": return 200 + shield_level * 100
		"cooling": return 180 + heat_sink_level * 120
		"secondary": return 220
		"swarm": return 500
		"emp": return 650
		"countermeasures": return 240
		"flare_reload": return 60
		"ammo": return 75
		"tractor": return 400
		"armor": return 240 + hull_armor_level * 120
	return -1

func purchase(item: String) -> String:
	if phase != "market":
		return "Purchases are only available at Astra Market."
	if not tour_result.is_empty():
		return "Continue to the next tour before changing the completed loadout."
	var cost: int = price(item)
	if cost < 0:
		return "Unknown market item."
	if item == "emergency" and (not ship.is_empty() or credits >= int(SHIPS["rook"]["cost"])):
		return "The free rescue ship is available only when no replacement is affordable."
	if item == ship:
		return "This ship is already equipped."
	if not SHIPS.has(item) and ship.is_empty():
		return "Obtain a ship before purchasing equipment."
	if item == "primary" and primary_level >= 2:
		return "Primary weapon is already at maximum level."
	if item == "shield" and shield_level >= 2:
		return "Shield capacity is already at maximum level."
	if item == "cooling" and heat_sink_level >= 2:
		return "Cooling vents are already at maximum level."
	if item == "armor" and hull_armor_level >= 2:
		return "Hull armor is already at maximum level."
	if item == "secondary" and secondary:
		return "Concussion launcher is already fitted."
	if item in ["swarm", "emp"] and owns_secondary(item):
		return "That secondary weapon station is already fitted."
	if item == "tractor" and tractor:
		return "Tractor beam is already fitted."
	if item == "countermeasures" and countermeasures:
		return "Countermeasure pod is already fitted."
	if item == "flare_reload" and not countermeasures:
		return "Fit a countermeasure pod first."
	if item == "flare_reload" and flares >= FLARE_CAPACITY:
		return "Countermeasure pod is already full."
	if item == "ammo" and not (secondary or swarm_launcher or emp_launcher):
		return "Fit a secondary weapon station first."
	if item == "ammo" and ammo >= int(SHIPS[ship]["ammo"]):
		return "Secondary ammunition bay is full."
	if credits < cost:
		return "Not enough credits: this item costs %d." % cost
	credits -= cost
	spent += cost
	if SHIPS.has(item):
		ship = item
		ammo = mini(ammo, int(SHIPS[ship]["ammo"]))
	elif item == "primary":
		primary_level += 1
	elif item == "shield":
		shield_level += 1
	elif item == "cooling":
		heat_sink_level += 1
	elif item == "secondary":
		secondary = true
		ammo = mini(ammo + 3, int(SHIPS[ship]["ammo"]))
	elif item in ["swarm", "emp"]:
		if item == "swarm":
			swarm_launcher = true
		else:
			emp_launcher = true
		ammo = mini(ammo + 3, int(SHIPS[ship]["ammo"]))
		if not owns_secondary(selected_secondary):
			selected_secondary = item
	elif item == "ammo":
		ammo = mini(ammo + 6, int(SHIPS[ship]["ammo"]))
	elif item == "tractor":
		tractor = true
	elif item == "armor":
		hull_armor_level += 1
	elif item == "countermeasures":
		countermeasures = true
		flares = FLARE_CAPACITY
	elif item == "flare_reload":
		flares = FLARE_CAPACITY
	hull = hull_capacity()
	shields = shield_capacity()
	return ""

func to_dict() -> Dictionary:
	return {"schema": SCHEMA, "phase": phase, "sector": sector, "cleared_sectors": cleared_sectors.duplicate(), "replays_unlocked": replays_unlocked, "ship": ship, "credits": credits, "earned": earned, "spent": spent,
		"primary_level": primary_level, "shield_level": shield_level, "heat_sink_level": heat_sink_level, "power_mode": power_mode, "secondary": secondary, "ammo": ammo,
		"hull": hull, "shields": shields, "sortie_id": sortie_id, "settled_sortie_id": settled_sortie_id,
		"last_result": last_result, "assisted": assisted, "stats": stats.duplicate(),
		"combo_kills": combo_kills, "best_streak": best_streak, "combat_score": combat_score, "combo_bonus_credits": combo_bonus_credits,
		"tractor": tractor, "mineral_credits": mineral_credits, "hull_armor_level": hull_armor_level,
		"sortie_start_shots": sortie_start_shots, "sortie_start_hits": sortie_start_hits,
		"accuracy_bonus_credits": accuracy_bonus_credits, "debrief": debrief.duplicate(),
		"swarm_launcher": swarm_launcher, "emp_launcher": emp_launcher, "selected_secondary": selected_secondary,
		"countermeasures": countermeasures, "flares": flares,
		"operation_id": operation_id, "tour": tour, "tour_start": tour_start.duplicate(true),
		"tour_best_streak": tour_best_streak, "hull_damage": hull_damage,
		"damage_history_complete": damage_history_complete, "tour_damage_complete": tour_damage_complete,
		"tour_result": tour_result.duplicate(true), "required_sectors": required_sectors.duplicate()}

func copy() -> CampaignState:
	var result := CampaignState.new()
	var error: String = result.restore(to_dict())
	assert(error.is_empty(), error)
	return result

func restore(source: Dictionary) -> String:
	var data: Dictionary = source.duplicate(true)
	if not data.has("schema") or not _whole(data["schema"]) or int(data["schema"]) < 1 or int(data["schema"]) > SCHEMA:
		return "Unsupported or missing save version."
	var source_schema: int = int(data["schema"])
	if source_schema == 1:
		data["heat_sink_level"] = 0
		data["power_mode"] = "balanced"
	if source_schema < 3:
		data["combo_kills"] = 0
		data["best_streak"] = 0
		data["combat_score"] = 0
		data["combo_bonus_credits"] = 0
	if source_schema < 4:
		data["tractor"] = false
		data["mineral_credits"] = 0
		if data.has("stats") and data["stats"] is Dictionary:
			data["stats"]["minerals"] = 0
			data["stats"]["chain_rocks"] = 0
	if source_schema < 5:
		data["hull_armor_level"] = 0
		data["accuracy_bonus_credits"] = 0
		data["debrief"] = {"completion": 0, "hull": 0, "accuracy": 0, "shots": 0, "hits": 0}
		if data.has("stats") and data["stats"] is Dictionary:
			data["sortie_start_shots"] = data["stats"].get("shots", 0)
			data["sortie_start_hits"] = data["stats"].get("hits", 0)
			for key in ["radars", "webs", "pirates"]:
				data["stats"][key] = 0
	if source_schema < 6:
		data["swarm_launcher"] = false
		data["emp_launcher"] = false
		data["selected_secondary"] = "concussion"
	if source_schema < 7:
		data["countermeasures"] = false
		data["flares"] = 0
	if source_schema < 8:
		data["sector"] = "ignis"
		data["cleared_sectors"] = []
		if data.has("stats") and data["stats"] is Dictionary and _whole(data["stats"].get("sorties", -1)) and data["stats"]["sorties"] > 0:
			data["cleared_sectors"] = ["ignis"]
	if source_schema < 9:
		data["replays_unlocked"] = data.has("cleared_sectors") and data["cleared_sectors"] is Array and data["cleared_sectors"].has("ignis") and data["cleared_sectors"].has("cryo")
	if source_schema < 10 and data.has("stats") and data["stats"] is Dictionary:
		data["stats"]["eggs"] = 0
		data["stats"]["guardians"] = 0
	if source_schema < 11:
		data["operation_id"] = JSON.stringify(source).sha256_text().left(32)
		data["tour"] = 1
		data["tour_start"] = {}
		data["tour_best_streak"] = data.get("best_streak", 0)
		data["hull_damage"] = 0.0
		data["damage_history_complete"] = false
		data["tour_damage_complete"] = false
		data["tour_result"] = {}
	if source_schema < 12:
		if source_schema == 11 and data.get("phase") == "market" and data.get("cleared_sectors") is Array and data["cleared_sectors"].size() == 4 and data.get("ship", "") != "" and data.get("tour_result") is Dictionary and data["tour_result"].is_empty():
			return "Completed legacy campaign is missing its frozen result."
		data["required_sectors"] = SectorCatalog.AVAILABLE.duplicate()
		if data.get("tour_result") is Dictionary and not data["tour_result"].is_empty():
			data["required_sectors"] = SectorCatalog.LEGACY.duplicate()
		elif source_schema < 11 and data.get("phase") == "market" and data.get("cleared_sectors") is Array and data["cleared_sectors"].size() == 4 and data.get("ship", "") != "":
			data["required_sectors"] = SectorCatalog.LEGACY.duplicate()
	data["schema"] = SCHEMA
	for key in ["phase", "sector", "ship", "last_result", "power_mode", "selected_secondary"]:
		if not data.has(key) or not data[key] is String:
			return "Invalid save field: " + key
	if not PHASES.has(data["phase"]) or (data["ship"] != "" and not SHIPS.has(data["ship"])):
		return "Unknown phase or ship in save."
	if not SectorCatalog.AVAILABLE.has(data["sector"]):
		return "Unknown or unavailable sector in save."
	if source_schema < 12 and (not SectorCatalog.LEGACY.has(data["sector"]) or data["ship"] in ["titan", "bastion"]):
		return "Sector or player battleship was unavailable in this save version."
	if source_schema < 9 and data["sector"] not in ["ignis", "cryo"]:
		return "Sector was unavailable in this save version."
	if source_schema < 10 and data["sector"] == "xylo":
		return "Xylo-Mire was unavailable in this save version."
	if not data.has("cleared_sectors") or not data["cleared_sectors"] is Array:
		return "Missing cleared-sector progress."
	var seen: Array[String] = []
	for destination in data["cleared_sectors"]:
		if not destination is String or not SectorCatalog.AVAILABLE.has(destination) or seen.has(destination):
			return "Invalid or duplicate cleared sector."
		if source_schema < 9 and destination not in ["ignis", "cryo"]:
			return "Cleared sector was unavailable in this save version."
		if source_schema < 10 and destination == "xylo":
			return "Xylo-Mire completion is invalid for this save version."
		if source_schema < 12 and not SectorCatalog.LEGACY.has(destination):
			return "Expansion sector completion is invalid for this save version."
		seen.append(destination)
	if not data.get("required_sectors") is Array or (data["required_sectors"] != SectorCatalog.AVAILABLE and data["required_sectors"] != SectorCatalog.LEGACY):
		return "Invalid tour sector requirements."
	if not ["new", "departed", "completed", "ejected"].has(data["last_result"]):
		return "Unknown sortie result."
	if not POWER_MODES.has(data["power_mode"]):
		return "Unknown reactor power mode."
	if not SECONDARIES.has(data["selected_secondary"]):
		return "Unknown secondary weapon station."
	for key in ["credits", "earned", "spent", "primary_level", "shield_level", "heat_sink_level", "hull_armor_level", "ammo", "flares", "sortie_id", "settled_sortie_id", "combo_kills", "best_streak", "combat_score", "combo_bonus_credits", "mineral_credits", "sortie_start_shots", "sortie_start_hits", "accuracy_bonus_credits"]:
		if not data.has(key) or not _whole(data[key]):
			return "Invalid save counter: " + key
	for key in ["secondary", "swarm_launcher", "emp_launcher", "countermeasures", "assisted", "tractor", "replays_unlocked"]:
		if not data.has(key) or not data[key] is bool:
			return "Invalid save flag: " + key
	if not data.has("tour") or not _whole(data["tour"]) or data["tour"] < 1:
		return "Invalid campaign tour."
	if data["replays_unlocked"] and data["tour"] == 1 and not (seen.has("ignis") and seen.has("cryo")):
		return "Replay access requires the original sector clears."
	if seen.size() == data["required_sectors"].size() and not data["replays_unlocked"]:
		return "Completed available sectors must retain replay access."
	if source_schema == 9 and seen.size() == 3 and not data["replays_unlocked"]:
		return "Completed legacy sectors must retain their replay entitlement."
	for key in ["hull", "shields"]:
		if not data.has(key) or not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or float(data[key]) < 0.0:
			return "Invalid ship health: " + key
	if not data.has("stats") or not data["stats"] is Dictionary:
		return "Missing campaign statistics."
	for key: String in stats:
		if not data["stats"].has(key) or not _whole(data["stats"][key]):
			return "Invalid statistic: " + key
	if seen.size() > data["stats"]["sorties"]:
		return "Cleared sectors exceed completed sorties."
	if data["stats"]["guardians"] > data["stats"]["enemies"]:
		return "Guardian defeats exceed total enemy defeats."
	if data["primary_level"] > 2 or data["shield_level"] > 2 or data["heat_sink_level"] > 2 or data["hull_armor_level"] > 2 or data["sortie_id"] < 1 or data["settled_sortie_id"] > data["sortie_id"]:
		return "Save progression is out of range."
	if data["best_streak"] < data["combo_kills"] or data["combo_bonus_credits"] > data["earned"]:
		return "Invalid combat streak or bonus totals."
	if data["mineral_credits"] > data["earned"] or data["stats"]["chain_rocks"] > data["stats"]["asteroids"]:
		return "Invalid mining reward totals."
	if data["sortie_start_shots"] > data["stats"]["shots"] or data["sortie_start_hits"] > data["stats"]["hits"] or data["accuracy_bonus_credits"] > data["earned"] or data["stats"]["pirates"] > data["stats"]["enemies"]:
		return "Invalid sortie or encounter totals."
	if not data.has("debrief") or not data["debrief"] is Dictionary:
		return "Missing sortie debrief."
	for key: String in debrief:
		if not data["debrief"].has(key) or not _whole(data["debrief"][key]):
			return "Invalid sortie debrief: " + key
	if int(data["debrief"]["completion"]) not in [0, 350] or data["debrief"]["hull"] > (150 if source_schema < 12 else 290) or data["debrief"]["accuracy"] > 200 or data["debrief"]["accuracy"] > data["accuracy_bonus_credits"]:
		return "Invalid debrief rewards."
	if data["phase"] == "market" and data["combo_kills"] != 0:
		return "A docked campaign cannot have an active combat streak."
	var owned: Dictionary = {"concussion": data["secondary"], "swarm": data["swarm_launcher"], "emp": data["emp_launcher"]}
	var has_secondary: bool = data["secondary"] or data["swarm_launcher"] or data["emp_launcher"]
	if data["flares"] > FLARE_CAPACITY or (not data["countermeasures"] and data["flares"] != 0):
		return "Invalid countermeasure inventory."
	if (has_secondary and not owned[data["selected_secondary"]]) or (not has_secondary and data["selected_secondary"] != "concussion"):
		return "Selected secondary station is not installed."
	var saved_ship: String = data["ship"]
	if saved_ship.is_empty():
		if data["phase"] != "market" or data["ammo"] != 0 or has_secondary or data["countermeasures"] or data["tractor"] or data["primary_level"] != 0 or data["shield_level"] != 0 or data["heat_sink_level"] != 0 or data["hull_armor_level"] != 0 or data["hull"] != 0 or data["shields"] != 0:
			return "Invalid ejection recovery state."
	else:
		if data["hull"] > float(SHIPS[saved_ship]["hull"]) + float(data["hull_armor_level"]) * 25.0 or data["shields"] > float(SHIPS[saved_ship]["shield"]) + float(data["shield_level"]) * 25.0 or data["ammo"] > SHIPS[saved_ship]["ammo"]:
			return "Equipment exceeds this ship's capacity."
		if not has_secondary and data["ammo"] != 0:
			return "Ammo without a secondary launcher."
		if data["phase"] != "market" and data["hull"] <= 0:
			return "Destroyed ship outside recovery."
	phase = data["phase"]
	sector = data["sector"]
	cleared_sectors.assign(seen)
	required_sectors.assign(data["required_sectors"])
	replays_unlocked = data["replays_unlocked"]
	ship = saved_ship
	last_result = data["last_result"]
	power_mode = data["power_mode"]
	for key in ["credits", "earned", "spent", "primary_level", "shield_level", "heat_sink_level", "hull_armor_level", "ammo", "flares", "sortie_id", "settled_sortie_id", "combo_kills", "best_streak", "combat_score", "combo_bonus_credits", "mineral_credits", "sortie_start_shots", "sortie_start_hits", "accuracy_bonus_credits"]:
		set(key, int(data[key]))
	for key: String in debrief:
		debrief[key] = int(data["debrief"][key])
	secondary = data["secondary"]
	swarm_launcher = data["swarm_launcher"]
	emp_launcher = data["emp_launcher"]
	selected_secondary = data["selected_secondary"]
	countermeasures = data["countermeasures"]
	assisted = data["assisted"]
	tractor = data["tractor"]
	hull = float(data["hull"])
	shields = float(data["shields"])
	for key: String in stats:
		stats[key] = int(data["stats"][key])
	if not CampaignHonors.valid_operation_id(data.get("operation_id")):
		return "Invalid campaign operation identity."
	for key in ["damage_history_complete", "tour_damage_complete"]:
		if not data.has(key) or not data[key] is bool:
			return "Invalid damage tracking flag."
	if not data.has("tour_best_streak") or not _whole(data["tour_best_streak"]) or data["tour_best_streak"] > best_streak or data["tour_best_streak"] < combo_kills:
		return "Invalid tour best streak."
	if not data.has("hull_damage") or not (data["hull_damage"] is int or data["hull_damage"] is float) or not is_finite(float(data["hull_damage"])) or data["hull_damage"] < 0 or data["hull_damage"] > 1000000000:
		return "Invalid cumulative hull damage."
	operation_id = data["operation_id"]
	tour = int(data["tour"])
	tour_best_streak = int(data["tour_best_streak"])
	hull_damage = float(data["hull_damage"])
	damage_history_complete = data["damage_history_complete"]
	tour_damage_complete = data["tour_damage_complete"]
	if not data.has("tour_start") or not data["tour_start"] is Dictionary:
		return "Missing tour baseline."
	tour_start = data["tour_start"].duplicate(true)
	if tour == 1 and not tour_start.is_empty():
		return "The first tour cannot have an earlier tour baseline."
	if tour > 1:
		var baseline_error: String = CampaignHonors.validate_metrics(tour_start)
		if not baseline_error.is_empty():
			return baseline_error
		tour_start = CampaignHonors.normalized_metrics(tour_start)
		if not replays_unlocked or tour_start["sorties"] < (tour - 1) * 4:
			return "Later tours require completed earlier tours and retained replay access."
		for key: String in tour_start:
			if not totals().has(key) or tour_start[key] > totals()[key]:
				return "Tour baseline exceeds lifetime totals."
	var totals_error: String = CampaignHonors.validate_metrics(tour_totals())
	if not totals_error.is_empty():
		return totals_error
	if seen.size() > tour_totals()["sorties"]:
		return "Tour clears exceed successful sorties in this tour."
	if not data.has("tour_result") or not data["tour_result"] is Dictionary:
		return "Missing campaign completion state."
	tour_result = data["tour_result"].duplicate(true)
	if not tour_result.is_empty():
		var result_error: String = CampaignHonors.validate_record(tour_result)
		if not result_error.is_empty():
			return result_error
		tour_result = CampaignHonors.normalized_record(tour_result)
		if phase != "market" or not tour_complete() or CampaignHonors.record_sectors(tour_result) != required_sectors or tour_result["operation_id"] != operation_id or tour_result["tour"] != tour:
			return "Completed tour does not match the campaign checkpoint."
		if tour_result["totals"] != tour_totals() or tour_result["lifetime"] != totals() or tour_result["assisted"] != assisted or tour_result["damage_complete"] != tour_damage_complete or tour_result["lifetime_damage_complete"] != damage_history_complete:
			return "Completed tour statistics do not match the frozen result."
		for key: String in tour_result["loadout"]:
			if tour_result["loadout"][key] != get(key):
				return "Completed tour loadout does not match the frozen result."
	elif source_schema < 11 and phase == "market" and tour_complete() and not ship.is_empty():
		_seal_tour()
	elif required_sectors == SectorCatalog.LEGACY:
		return "Only a completed legacy tour may retain four-world requirements."
	elif phase == "market" and tour_complete() and not ship.is_empty():
		return "A completed campaign is missing its final result."
	return ""

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) <= 1000000000 and floor(float(value)) == float(value)
