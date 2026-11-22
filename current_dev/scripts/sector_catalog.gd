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

static func name_for(sector: String) -> String:
	assert(NAMES.has(sector), "Unknown sector: " + sector)
	return NAMES[sector]
