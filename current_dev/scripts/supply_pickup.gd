class_name SupplyPickup
extends Node3D

const RADIUS: float = 3.2
var kind: String = "shield"
var active: bool = true
var age: float = 0.0
var model: Node3D

func _ready() -> void:
	assert(kind in ["shield", "ordnance", "flare"])
	var batch := GeometryBatch.new()
	var tint: Color = color()
	batch.box(Vector3.ZERO, Vector3(1.8, 1.8, 1.8), tint, Color("#172a34"))
	batch.ring(Vector3.ZERO, 2.8, tint, 6 if kind == "shield" else 4 if kind == "ordnance" else 8)
	if kind == "shield":
		batch.line(Vector3(-0.65, 0, 1), Vector3(0.65, 0, 1), tint)
		batch.line(Vector3(0, -0.65, 1), Vector3(0, 0.65, 1), tint)
	else:
		for i in range(2 if kind == "ordnance" else 1):
			batch.box(Vector3((i - 0.5) * 0.65 if kind == "ordnance" else 0.0, 0, 1), Vector3(0.25, 1.1, 0.2), tint)
	model = batch.build()
	add_child(model)

func color() -> Color:
	return VectorArt.CYAN if kind == "shield" else VectorArt.AMBER if kind == "ordnance" else Color("#f49dce")

func label() -> String:
	return "SHIELD +25" if kind == "shield" else "ORDNANCE +2" if kind == "ordnance" else "FLARE +1"

func advance(delta: float, previous: Vector3, pilot: Vector3, enabled: bool, campaign: CampaignState, flight: FlightState) -> String:
	if not active:
		return ""
	age += delta
	model.rotation.y = age * 0.8
	if not enabled or flight.hull <= 0:
		return ""
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(global_position, previous, pilot)
	if closest.distance_to(global_position) > RADIUS + flight.collision_radius:
		return ""
	active = false
	hide()
	match kind:
		"shield":
			var amount: float = minf(25.0, flight.max_shields - flight.shields)
			flight.shields += amount
			return "SHIELD SUPPLY / +%d SHIELDS" % int(amount) if amount > 0 else "SHIELD SUPPLY / ALREADY FULL"
		"ordnance":
			if not (campaign.secondary or campaign.swarm_launcher or campaign.emp_launcher):
				return "ORDNANCE SUPPLY / NO LAUNCHER EQUIPPED"
			var amount: int = mini(2, int(CampaignState.SHIPS[campaign.ship]["ammo"]) - flight.ammo)
			flight.ammo += amount
			return "ORDNANCE SUPPLY / +%d SHARED UNITS" % amount if amount > 0 else "ORDNANCE SUPPLY / BAY ALREADY FULL"
		"flare":
			if not campaign.countermeasures:
				return "FLARE SUPPLY / NO POD EQUIPPED"
			var amount: int = mini(1, CampaignState.FLARE_CAPACITY - campaign.flares)
			campaign.flares += amount
			return "FLARE SUPPLY / +1 DEDICATED CHARGE" if amount > 0 else "FLARE SUPPLY / POD ALREADY FULL"
	assert(false, "Unknown supply kind")
	return ""
