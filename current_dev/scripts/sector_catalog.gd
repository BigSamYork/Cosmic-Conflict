class_name SectorCatalog
extends RefCounted

const LEGACY: Array[String] = ["ignis", "cryo", "vespera", "xylo"]
const AVAILABLE: Array[String] = ["ignis", "cryo", "vespera", "xylo", "thalassa", "kharon"]
const NAMES: Dictionary = {
	"ignis": "Ignis Prime",
	"cryo": "Cryo-Vex",
	"vespera": "Vespera-9",
	"xylo": "Xylo-Mire",
	"thalassa": "Thalassa Reach",
	"kharon": "Kharon Dunes"
}
const GROUND_BOSSES: Dictionary = {"ignis": "Vulcan Siege Runner", "cryo": "Glacier Bore-Mech", "vespera": "Overlord Defense Core", "xylo": "Bio-Titan Goliath", "thalassa": "Tempest Walker", "kharon": "Sunforge Colossus"}
const ORBITAL_BOSSES: Dictionary = {"ignis": "Solar Flare Cruiser", "cryo": "Cryo-Carrier Hydra", "vespera": "Stealth Dreadnought Nyx", "xylo": "Hive Mother Leviathan", "thalassa": "Storm Ark", "kharon": "Obelisk Sovereign"}
const ACCENTS: Dictionary = {"ignis": Color("#ff984b"), "cryo": Color("#6eebed"), "vespera": Color("#e88ce9"), "xylo": Color("#98cf64"), "thalassa": Color("#72d8ff"), "kharon": Color("#e8bf65")}
const DESCRIPTIONS: Dictionary = {
	"ignis": "Volcanic canyon / flowing lava / volcanic bombs",
	"cryo": "Glacial ruptures / rare Glacier Mauler / ice belt",
	"vespera": "Neon city / falling maglevs / ringed orbital giant",
	"xylo": "Alien swamp / canopy predator / living hive fleet",
	"thalassa": "Storm ocean / offshore platforms / lightning / manta interceptors",
	"kharon": "Desert ruins / meteor impacts / siege walkers"
}

const DISTRESS := {
	"ignis": "THE LAST POUR / Every freighter has a shield. Find a way home for the workers who made them.",
	"cryo": "ONE MORE PASSENGER / Meet the repair tender. The greenhouse ward needs power all the way to orbit.",
	"vespera": "Clear a quiet boarding lane. Three groups wait under chemical flares at Vespera Terminal.",
	"xylo": "BRING THE REEDS / The clinic keeper needs a skiff and a quiet passage through the hive.",
	"thalassa": "THE WRENCH / Reach the Aegis-4 and find out why its engineer won't cut a compartment loose.",
	"kharon": "THE LAST COORDINATE / Protect the pad courier or disable the walker at the wired relay."
}
const DISPATCH := {
	"ignis": "Foundry tug aboard. The last worker down the ramp was still wearing his pouring gloves.",
	"cryo": "Ward aboard. A nurse asked us to log one more passenger. He was born on the way up.",
	"vespera": "Last manifest checked. The boarding crew picked up the flares until only the ramp light was left.",
	"xylo": "Clinic aboard. There's mud on the deck and every last patient is breathing.",
	"thalassa": "Aegis-4 under tow. Your sister wants her wrench back, Tomas. She says you know which one.",
	"kharon": "All three transports jumped on the director's coordinates. She finally let go of the cable."
}

static func name_for(sector: String) -> String:
	assert(NAMES.has(sector), "Unknown sector: " + sector)
	return NAMES[sector]

static func dispatch_for(sector: String, boarding: String) -> String:
	if sector == "vespera" and not boarding.is_empty():
		return ("The covered ramp got all three groups aboard." if boarding == "covered" else "All three groups crossed the quiet lane.") + " Only the ramp light is still on."
	return DISPATCH.get(sector, "")

static func home_report(sector: String, arrivals: Dictionary, boarding: String = "") -> String:
	var method: String = arrivals.get(sector, "")
	var detail := {
		"mold":"The apprentice brought the mold across.", "converter":"The converter held through launch.",
		"cradle":"Every compartment made the short tow.", "relay":"The disabled walker still leans over the relay.",
		"courier":"The courier delivered the third pad.", "detour":"The clinic boat took the outside passage.",
		"brood_passage":"The guardians stayed with the brood."
	}
	var backups := {"ignis":"They used the service tunnel.", "cryo":"The battery cart made the transfer.",
		"kharon":"The crew copied the relay cartridge aboard.", "thalassa":"The long tow cable held."}
	var prefix: String = backups.get(sector, "") if method == "backup" else detail.get(method, "")
	return (prefix + " " if not prefix.is_empty() else "") + dispatch_for(sector, method if sector == "vespera" and not method.is_empty() else boarding)
