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
	"ignis": "Open a launch lane for the night shift making ferry heat shields.",
	"cryo": "Get the greenhouse ward and its newborns through the blockade.",
	"vespera": "Clear a quiet boarding lane. Three groups wait under chemical flares at Vespera Terminal.",
	"xylo": "Bring the clinic patients and their air reeds aboard together.",
	"thalassa": "Clear the orbital approach so a tug can reach the Aegis-4.",
	"kharon": "Escort the transports carrying the hardwired jump coordinates."
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
