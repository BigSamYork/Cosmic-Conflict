class_name SupplyPickup
extends Node3D

signal sound_requested(id: String)

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

func _available(campaign: CampaignState, flight: FlightState) -> float:
	match kind:
		"shield":
			return clampf(flight.max_shields - flight.shields, 0, 25)
		"ordnance":
			if campaign.secondary or campaign.swarm_launcher or campaign.emp_launcher:
				return clampi(int(CampaignState.SHIPS[campaign.ship]["ammo"]) - flight.ammo, 0, 2)
		"flare":
			if campaign.countermeasures:
				return clampi(CampaignState.FLARE_CAPACITY - campaign.flares, 0, 1)
	return 0

func _description(amount: float, campaign: CampaignState) -> String:
	match kind:
		"shield":
			if amount > 0 and amount < 1:
				return "SHIELD SUPPLY / TOP OFF SHIELDS"
			return "SHIELD SUPPLY / +%d SHIELDS" % roundi(amount) if amount > 0 else "SHIELD SUPPLY / ALREADY FULL"
		"ordnance":
			if amount > 0:
				return "ORDNANCE SUPPLY / +%d SHARED UNITS" % int(amount)
			return "ORDNANCE SUPPLY / BAY ALREADY FULL" if campaign.secondary or campaign.swarm_launcher or campaign.emp_launcher else "ORDNANCE SUPPLY / NO LAUNCHER EQUIPPED"
		"flare":
			if amount > 0:
				return "FLARE SUPPLY / +1 DEDICATED CHARGE"
			return "FLARE SUPPLY / POD ALREADY FULL" if campaign.countermeasures else "FLARE SUPPLY / NO POD EQUIPPED"
	return ""

func label(campaign: CampaignState, flight: FlightState) -> String:
	var amount := _available(campaign, flight)
	var detail := _description(amount, campaign)
	return detail + " / FLY THROUGH" if amount > 0 else detail

func advance(delta: float, previous: Vector3, pilot: Vector3, enabled: bool, campaign: CampaignState, flight: FlightState) -> String:
	if not active:
		return ""
	visible = enabled
	age += delta
	model.rotation.y = age * 0.8
	if not enabled or flight.hull <= 0:
		return ""
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(global_position, previous, pilot)
	if closest.distance_to(global_position) > RADIUS + flight.collision_radius:
		return ""
	active = false
	hide()
	var amount := _available(campaign, flight)
	match kind:
		"shield":
			flight.shields += amount
		"ordnance":
			flight.ammo += int(amount)
		"flare":
			campaign.flares += int(amount)
	sound_requested.emit("supply_" + kind if amount > 0 else "supply_full")
	return _description(amount, campaign)
