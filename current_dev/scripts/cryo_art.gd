class_name CryoArt
extends RefCounted

const ICE := Color("#a5dce9")
const STEEL := Color("#688fae")
const HULL := Color("#1b3047")

static func warm_cache() -> void:
	for factory in [ice_pylon, tank_base, fighter, bore_mech, hydra, drill, drone_bay, frost_plume]:
		var model: Node3D = factory.call()
		model.free()
	for variant in AsteroidArt.GIANT_VARIANTS:
		var rock: Node3D = AsteroidArt.create(variant, Color("#9bb6cb"), true, true)
		rock.free()
	for variant in range(AsteroidArt.VARIANTS):
		var rock: Node3D = AsteroidArt.create(variant, Color("#91b2cb"), true, true)
		rock.free()

static func ice_pylon() -> Node3D:
	return GroundArt.tower("cryo")

static func tank_base() -> Node3D:
	return FleetArt.model("mount_cryo", "ground")

static func fighter() -> Node3D:
	return FleetArt.model("cryo")

static func bore_mech() -> Node3D:
	return FleetArt.model("glacier_bore", "ground")

static func drill() -> Node3D:
	return FleetArt.model("ice_auger", "ground")

static func hydra() -> Node3D:
	return FleetArt.model("hydra")

static func drone_bay() -> Node3D:
	return FleetArt.model("boss_drone_hangar")

static func frost_plume() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("cryo_frost_plume")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	for i in range(9):
		var angle: float = i * 2.4
		batch.crystal(Vector3(cos(angle) * 2.5, 1 + (i % 3) * 4, sin(angle) * 2.5), 0.35, 2.5, ICE)
		batch.line(Vector3(cos(angle) * 3, 0.3, sin(angle) * 3), Vector3(cos(angle + 0.6) * 1.7, 14, sin(angle + 0.6) * 1.7), STEEL)
	return VectorArt.remember_model("cryo_frost_plume", batch.build())
