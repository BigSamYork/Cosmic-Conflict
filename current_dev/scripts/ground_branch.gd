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
const Boarding := preload("res://scripts/vespera_boarding.gd")
signal boarding_cue(id: String)
var boarding: Boarding
const RescueRun := preload("res://scripts/rescue_run.gd")
signal hull_knock
signal battery_missile(origin: Vector3, direction: Vector3)
var rescue: RescueRun

func _ready() -> void:
	add_child(patrol)
	var guides := GeometryBatch.new()
	# Mark the entrances with solid lamps. The terrain between them stays open.
	for distance: float in [GroundRoute.FORK + 100.0, GroundRoute.REJOIN - 100.0]:
		var frame := GroundRoute.frame(distance)
		for side in [-1.0, 1.0]:
			var at := frame * Vector3(side * 8.0, 0, 0)
			at.y = FrontierArt.SEA_LEVEL if sector == "thalassa" else -1.0
			guides.box(at + Vector3.UP * 0.8, Vector3(0.8, 1.6, 0.8), Color.WHITE, Color("#39434a"))
			guides.box(at + Vector3.UP * 1.74, Vector3(0.9, 0.28, 0.9), Color.WHITE, VectorArt.AMBER)
	add_child(VectorArt.solid(guides.vertices, guides.indices, Color.WHITE, guides.face_colors))
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
		supply.hide()
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
	var story := campaign.first_rescue()
	var contract := ""
	if story and patrol.next_job == 1 and patrol.current < 0:
		if sector != "vespera":
			if not is_instance_valid(rescue):
				rescue = RescueRun.new()
				add_child(rescue)
				rescue.cue.connect(boarding_cue.emit)
				rescue.knock.connect(hull_knock.emit)
			var outcome := rescue.advance(delta, previous, pilot, campaign, flight, route)
			if is_instance_valid(rescue.battery) and not rescue.battery.missile_requested.is_connected(battery_missile.emit):
				rescue.battery.missile_requested.connect(battery_missile.emit)
			if not outcome.is_empty():
				campaign.rescue_method = outcome
				patrol.next_job += 1
				rescue = null
		elif flight.distance >= Boarding.ENTRY - 510 and flight.hull > 0:
			if boarding == null:
				boarding = Boarding.new()
				add_child(boarding)
				boarding.cue.connect(boarding_cue.emit)
			var result := boarding.advance(flight.distance, previous, pilot, route, flight.shots)
			if not result.is_empty():
				campaign.vespera_boarding = result
				campaign.rescue_method = result
				patrol.next_job += 1
				contract = "THREE GROUPS ABOARD / " + ("COVERED RAMP" if result == "covered" else "QUIET LANE")
				if result == "quiet":
					campaign.combat_score += SurfacePatrol.REWARDS[SurfacePatrol.Job.CEASEFIRE] * 10
	else:
		if story and sector == "vespera" and patrol.job_order.is_empty():
			# The middle patrol slot is the story crossing regardless of sortie order.
			var jobs := [SurfacePatrol.Job.SLALOM, SurfacePatrol.Job.CEASEFIRE, SurfacePatrol.Job.COURIER]
			for i in 3: patrol.job_order.append(jobs[posmod(i - campaign.sortie_id + 1, 3)])
		contract = patrol.advance(delta, previous, pilot, campaign, flight, route)
	if not contract.is_empty():
		messages.append(contract)
	if not announced and flight.distance >= GroundRoute.FORK - GroundRoute.WARNING_DISTANCE:
		announced = true
		messages.append("FORK AHEAD / LEFT: PAD COURIER / RIGHT: RELAY WALKER" if sector == "kharon" and story else "FORK AHEAD / FLY LEFT FOR SAFE / RIGHT FOR HAZARD")
	for supply in supplies:
		var message: String = supply.advance(delta, previous, pilot, route.selected, campaign, flight)
		if not message.is_empty():
			messages.append(message)
	if route.finish_hazard(flight.distance, flight.hull > 0):
		messages.append("HAZARD TRENCH COMPLETE / REJOINING MAIN ROUTE")
	return messages

func objective(distance: float) -> String:
	if is_instance_valid(rescue) and not rescue.prompt.is_empty(): return rescue.prompt
	if sector == "kharon" and not route.locked and distance >= GroundRoute.FORK - GroundRoute.WARNING_DISTANCE:
		return "FORK / LEFT: COVER PAD COURIER     RIGHT: DISABLE WALKER AT RELAY"
	if boarding != null and not boarding.prompt.is_empty(): return boarding.prompt
	if not route.locked and distance >= GroundRoute.FORK - GroundRoute.WARNING_DISTANCE:
		return "FORK IN %ds / LEFT OR CENTER: SAFE     RIGHT: HAZARD" % ceili(maxf(0, GroundRoute.FORK - distance) / FlightState.SPEED)
	if not patrol.prompt.is_empty():
		return patrol.prompt
	if distance >= GroundRoute.REJOIN:
		return "MAIN ROUTE / BOSS APPROACH"
	if route.selected:
		return "HAZARD TRENCH / COLLECT SUPPLIES"
	if route.locked:
		return "SAFE ROUTE / MAIN CANYON"
	return "FORK: FLY LEFT FOR SAFE / RIGHT FOR HAZARD"
