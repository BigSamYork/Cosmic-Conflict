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
	"ignis": "Volcanic canyon / erupting cones / thermal weapons",
	"cryo": "Glacial canyon / frost weapons / giant oblong asteroid belt",
	"vespera": "Neon city / side laser gates / stealth dreadnought",
	"xylo": "Alien swamp / acid and spores / living hive fleet",
	"thalassa": "Storm ocean / offshore platforms / lightning / manta interceptors",
	"kharon": "Desert ruins / broken arches / falling pillars / scarab fighters"
}

const DISTRESS := {
	"ignis": "Open a launch lane for the night shift making ferry heat shields.",
	"cryo": "Get the greenhouse ward and its newborns through the blockade.",
	"vespera": "Reach the families keeping candles in the hotel windows.",
	"xylo": "Bring the clinic patients and their air reeds aboard together.",
	"thalassa": "Free the lighthouse channel so a tug can reach the Lantern.",
	"kharon": "Escort the pilots carrying the last paper charts to Astra."
}
const DISPATCH := {
	"ignis": "Foundry tug aboard. The last worker down the ramp was still wearing his pouring gloves.",
	"cryo": "Ward aboard. A nurse asked us to log one more passenger. He was born on the way up.",
	"vespera": "Hotel ferry aboard. The porter turned out the last light himself.",
	"xylo": "Clinic aboard. There's mud on the deck and every last patient is breathing.",
	"thalassa": "Lantern under tow. Your sister wants her wrench back, Tomas. She says you know which one.",
	"kharon": "Chart pilots aboard. The keeper kept one ration card. She'd like you both to sign it."
}

static func name_for(sector: String) -> String:
	assert(NAMES.has(sector), "Unknown sector: " + sector)
	return NAMES[sector]
