class_name GroundBranch
extends Node3D

var route := GroundRoute.new()
var turrets: Array[GroundTurret] = []
var towers: Array[DestructibleTower] = []
var supplies: Array[SupplyPickup] = []
var announced: bool = false
var sector: String = "ignis"
var health_scale: float = 1.0
var patrol := SurfacePatrol.new()

func _ready() -> void:
	add_child(patrol)
	var guides := GeometryBatch.new()
	for distance in range(int(GroundRoute.FORK), int(GroundRoute.REJOIN), 12):
		var current: Transform3D = GroundRoute.frame(distance)
		var next: Transform3D = GroundRoute.frame(distance + 12)
		for side in [-1.0, 1.0]:
			guides.line(current * Vector3(side * 8, -10, 0), next * Vector3(side * 8, -10, 0), VectorArt.AMBER)
			if distance % 48 == 12:
				guides.line(current * Vector3(side * 9, -10, 0), current * Vector3(side * 9, -5, 0), VectorArt.AMBER)
	add_child(guides.build())
	for i in range(4):
		var turret := GroundTurret.new()
		turret.sector = sector
		turret.health_scale = health_scale
		turret.travel = 1730.0 + i * 210
		turret.phase = i * 0.35
		add_child(turret)
		turret.transform = GroundRoute.frame(turret.travel)
		turret.position += turret.basis.x * (-14 if i % 2 == 0 else 14)
		turret.position.y = 0.1
		turret.armor = ceili(6 * health_scale)
		turret.fire_interval = 1.9
		turrets.append(turret)
	for i in range(8):
		var tower := DestructibleTower.new()
		tower.sector = sector
		tower.travel = 1740.0 + i * 100
		tower.lane.x = -3.2 if i % 2 == 0 else 3.2
		tower.transform = GroundRoute.frame(tower.travel)
		tower.position += tower.basis * Vector3(tower.lane.x, -4, 0)
		if sector in ["vespera", "xylo", "thalassa", "kharon"]:
			tower.position.y = 4.5
		add_child(tower)
		towers.append(tower)
	for i in range(3):
		var supply := SupplyPickup.new()
		supply.kind = ["shield", "ordnance", "flare"][i]
		supply.transform = GroundRoute.frame(2020.0 + i * 220)
		add_child(supply)
		supplies.append(supply)

func engages(target: RangeTarget, distance: float) -> bool:
	if target is GroundTurret and turrets.has(target):
		return route.selected and distance >= GroundRoute.FORK and distance < GroundRoute.REJOIN
	if target.travel >= GroundRoute.FORK + GroundRoute.TURN_LENGTH and target.travel <= GroundRoute.REJOIN - GroundRoute.TURN_LENGTH:
		return not route.selected
	return true

func advance(delta: float, previous: Vector3, pilot: Vector3, campaign: CampaignState, flight: FlightState) -> Array[String]:
	var messages: Array[String] = []
	var contract := patrol.advance(delta, previous, pilot, campaign, flight, route)
	if not contract.is_empty():
		messages.append(contract)
	if not announced and flight.distance >= GroundRoute.FORK - 480:
		announced = true
		messages.append("FORK AHEAD / FLY LEFT FOR SAFE / RIGHT FOR HAZARD")
	for supply in supplies:
		var message: String = supply.advance(delta, previous, pilot, route.selected, campaign, flight)
		if not message.is_empty():
			messages.append(message)
	var bonus: int = route.claim_bonus(flight.distance, flight.hull > 0)
	if bonus > 0:
		campaign.reward(bonus)
		messages.append("HAZARD TRENCH COMPLETE / +100 CR / REJOINING MAIN ROUTE")
	return messages

func objective(distance: float) -> String:
	if not patrol.prompt.is_empty():
		return patrol.prompt
	if distance >= GroundRoute.REJOIN:
		return "MAIN ROUTE / BOSS APPROACH"
	if route.selected:
		return "HAZARD TRENCH / COLLECT SUPPLIES / +100 CR AT REJOIN"
	if route.locked:
		return "SAFE ROUTE / STANDARD REWARDS"
	return "FORK: FLY LEFT FOR SAFE / RIGHT FOR HAZARD"
