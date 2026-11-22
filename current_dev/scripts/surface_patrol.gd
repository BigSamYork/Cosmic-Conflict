class_name SurfacePatrol
extends Node3D

# Each contract occupies one short stretch of the existing course. Its pickup
# and finish are swept against the pilot segment so frame rate cannot skip them.
enum Job { SLALOM, RESCUE, SURVEY, COURIER, ESCORT, REPAIR, COOLANT, CEASEFIRE, RESTART, INTERCEPT }

const SCHEDULE := {
	"ignis": [Job.COOLANT, Job.INTERCEPT, Job.ESCORT],
	"cryo": [Job.RESCUE, Job.SURVEY, Job.REPAIR],
	"vespera": [Job.CEASEFIRE, Job.SLALOM, Job.COURIER],
	"xylo": [Job.SURVEY, Job.RESTART, Job.RESCUE],
	"thalassa": [Job.REPAIR, Job.ESCORT, Job.CEASEFIRE],
	"kharon": [Job.COURIER, Job.RESTART, Job.SLALOM]
}
const BRIEFS := [
	"SLALOM / THREAD THREE GREEN GATES",
	"DISTRESS BEACON / SCOOP THE ESCAPE POD",
	"SURVEY BUOY / HOLD RETICLE ON SENSOR",
	"FRAGILE FREIGHT / SCOOP POD AND DELIVER INTACT",
	"ESCORT / HOLD THE GREEN FORMATION LIGHT",
	"REPAIR TENDER / HOLD THE SERVICE LIGHT",
	"COOLANT SIPHON / SKIM THE GREEN VENT",
	"CIVILIAN CORRIDOR / ENTER GREEN GATE AND HOLD FIRE",
	"STRANDED SKIFF / DONATE 12 SHIELD AT THE BEACON",
	"INTERCEPT BOUNTY / ENTER GATE AND SHOOT A MISSILE"
]
const MARKS := [580.0, 1940.0, 3290.0]
const LABELS := ["GATE", "SOS", "SURVEY", "FREIGHT", "FORMATION", "SERVICE", "COOLANT", "CEASEFIRE", "TRANSFER", "BOUNTY"]
const REWARDS := [38, 36, 32, 54, 42, 0, 0, 38, 48, 50]
var next_job := 0
var current := -1
var station_distance := 0.0
var lane_sign := 1.0
var main_model: Node3D
var gate: Node3D
var carrier: Node3D
var storm_hull: StaticBody3D
const STORM_LAYER := 8
var lamp: Label3D
var stage := 0
var progress := 0.0
var checkpoint_hull := 0.0
var checkpoint_count := 0
var prompt := ""
var job_order: Array = []

func _begin(sector: String, flight_number: int) -> void:
	current = job_order[(next_job + posmod(flight_number - 1, 3)) % 3]
	station_distance = MARKS[next_job]
	lane_sign = -1.0 if (next_job + sector.length() + flight_number) % 2 else 1.0
	next_job += 1
	stage = 0
	progress = 0.0
	main_model = Node3D.new()
	add_child(main_model)
	gate = FleetArt.model("patrol_gate", "ground")
	main_model.add_child(gate)
	if current in [Job.RESCUE, Job.COURIER, Job.SURVEY]:
		carrier = FleetArt.model("survival_pod", "ground")
		main_model.add_child(carrier)
		gate.scale *= 0.70
	elif current in [Job.ESCORT, Job.REPAIR, Job.RESTART]:
		carrier = FleetArt.model("traffic")
		carrier.scale *= 0.57
		main_model.add_child(carrier)
		carrier.position = Vector3(5.8 * lane_sign, 0, -1.0)
		if sector == "thalassa":
			var mesh := FleetArt.mesh_for("traffic")
			if not mesh.has_meta("storm_shape"):
				var shape := mesh.create_trimesh_shape()
				shape.backface_collision = true
				mesh.set_meta("storm_shape", shape)
			storm_hull = StaticBody3D.new()
			storm_hull.collision_layer = STORM_LAYER
			storm_hull.collision_mask = 0
			var collider := CollisionShape3D.new()
			collider.shape = mesh.get_meta("storm_shape")
			storm_hull.add_child(collider)
			carrier.add_child(storm_hull)
	else:
		carrier = null
	lamp = Label3D.new()
	lamp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lamp.pixel_size = 0.026
	lamp.font_size = 43
	lamp.outline_size = 8
	lamp.modulate = Color("#a4f5d0")
	lamp.position.y = 4.8
	lamp.text = LABELS[current]
	main_model.add_child(lamp)
	prompt = BRIEFS[current]

func _finish(message: String, campaign: CampaignState, paid: bool = false) -> String:
	if storm_hull != null:
		storm_hull.collision_layer = 0
		storm_hull = null
	var reward: int = REWARDS[current] if paid else 0
	if reward:
		campaign.reward(reward)
	main_model.hide()
	main_model.queue_free()
	current = -1
	prompt = ""
	return message + (" / +%d CR" % reward if reward else "")

func lose_carrier(campaign: CampaignState) -> String:
	return _finish("SUPPORT SHIP LOST TO LIGHTNING / CONTRACT CLOSED", campaign)

func _pose(distance: float, side: float, route: GroundRoute) -> Transform3D:
	var frame := GroundRoute.frame(distance) if route.selected else FlightState.rail_frame(distance)
	return frame.translated_local(Vector3(side * 8.2, 2.6, 0))

func _crossed(previous: Vector3, pilot: Vector3) -> bool:
	var contact := Geometry3D.get_closest_point_to_segment(main_model.global_position, previous, pilot)
	return contact.distance_squared_to(main_model.global_position) <= 3.35 * 3.35

func advance(delta: float, previous: Vector3, pilot: Vector3, campaign: CampaignState, flight: FlightState, route: GroundRoute) -> String:
	if flight.training or flight.hull <= 0 or delta <= 0:
		return ""
	if job_order.is_empty():
		job_order = SCHEDULE.get(campaign.sector, SCHEDULE["ignis"])
	if current < 0:
		if next_job >= MARKS.size() or flight.distance < MARKS[next_job] - 230.0:
			return ""
		_begin(campaign.sector, campaign.sortie_id)
	var mark := station_distance
	var side := lane_sign
	if current == Job.SLALOM:
		mark += stage * 74.0
		side *= -1 if stage == 1 else 1
	elif stage > 0 and current in [Job.COURIER, Job.CEASEFIRE, Job.INTERCEPT]:
		mark += 185.0
		if current == Job.COURIER:
			side = -side
	var formation := current in [Job.ESCORT, Job.REPAIR]
	if formation:
		# A slow tender overtakes into view then holds ahead for the transfer.
		mark += clampf((flight.distance - station_distance + 50.0) * 0.84, 0, 230.0)
	main_model.transform = _pose(mark, side, route)
	var range_m := pilot.distance_to(main_model.global_position)
	if current == Job.SURVEY:
		return _scan(delta, range_m, campaign, flight)
	if formation:
		return _formation(delta, pilot, range_m, campaign, flight)
	if flight.distance > mark + 14.0:
		return _finish("CONTRACT EXPIRED" if stage else "", campaign)
	if not _crossed(previous, pilot):
		return ""
	match current:
		Job.SLALOM:
			stage += 1
			if stage == 3:
				return _finish("SLALOM COMPLETE", campaign, true)
			lamp.text = "GATE %d / 3" % (stage + 1)
			return "GATE %d / 3" % stage
		Job.RESCUE:
			return _finish("SURVIVOR ABOARD", campaign, true)
		Job.COOLANT:
			flight.heat = 0.0
			flight.overheat_remaining = 0.0
			return _finish("HEAT EXCHANGER PURGED / GUNS COLD", campaign)
		Job.RESTART:
			if flight.shields < 12.0:
				return _finish("TRANSFER DECLINED / SHIELD RESERVE LOW", campaign)
			flight.shields -= 12
			flight.recharge_delay = maxf(flight.recharge_delay, FlightState.SHIELD_RECOVERY_DELAY)
			return _finish("SKIFF RESTARTED / 12 SHIELD TRANSFERRED", campaign, true)
		Job.COURIER, Job.CEASEFIRE, Job.INTERCEPT:
			if stage == 0:
				checkpoint_hull = campaign.hull_damage
				checkpoint_count = flight.shots if current == Job.CEASEFIRE else flight.interceptions
				stage = 1
				if carrier != null:
					carrier.hide()
				lamp.text = "DELIVER" if current == Job.COURIER else "EXIT"
				return "FREIGHT ABOARD / CROSS DELIVERY GATE" if current == Job.COURIER else "CIVILIANS IN TRANSIT / HOLD FIRE" if current == Job.CEASEFIRE else "BOUNTY LIVE / INTERCEPT BEFORE EXIT"
			if current == Job.COURIER:
				var intact := is_equal_approx(campaign.hull_damage, checkpoint_hull)
				return _finish("FREIGHT DELIVERED" if intact else "FREIGHT DAMAGED", campaign, intact)
			if current == Job.CEASEFIRE:
				var clear := flight.shots == checkpoint_count
				return _finish("CIVILIAN CONVOY CLEAR" if clear else "CEASEFIRE BROKEN", campaign, clear)
			var intercepted := flight.interceptions > checkpoint_count
			return _finish("INTERCEPTION VERIFIED" if intercepted else "NO INTERCEPTION LOGGED", campaign, intercepted)
	return ""

func _scan(delta: float, range_m: float, campaign: CampaignState, flight: FlightState) -> String:
	if flight.distance > station_distance + 5:
		return _finish("", campaign)
	var pilot := get_viewport().get_camera_3d()
	if pilot == null or range_m > 175 or pilot.is_position_behind(main_model.global_position):
		return ""
	var screen := get_viewport().get_visible_rect()
	var cursor := screen.position + (flight.aim + Vector2.ONE) * screen.size * 0.5
	var target := pilot.unproject_position(main_model.global_position)
	if cursor.distance_to(target) < screen.size.y * 0.085:
		progress += delta
	else:
		progress = maxf(0.0, progress - delta * 0.7)
	lamp.text = "SCAN %d%%" % mini(100, roundi(progress / 1.35 * 100.0))
	if progress >= 1.35:
		return _finish("SURVEY TELEMETRY RECORDED", campaign, true)
	return ""

func _formation(delta: float, pilot: Vector3, range_m: float, campaign: CampaignState, flight: FlightState) -> String:
	if flight.distance > station_distance + 244.0:
		return _finish("", campaign)
	# The ring denotes the wing position beside the service craft.
	var relative := main_model.to_local(pilot)
	if range_m < 12.6 and Vector2(relative.x, relative.y).length_squared() < 3.8 * 3.8:
		progress += delta
		lamp.text = "%s %d%%" % [LABELS[current], mini(100, roundi(progress * 50))]
	else:
		progress = maxf(0.0, progress - delta * 0.5)
	if progress < 2.0:
		return ""
	if current == Job.ESCORT:
		return _finish("FORMATION ESCORT COMPLETE", campaign, true)
	var amount := minf(12.0, flight.max_hull - flight.hull)
	flight.hull += amount
	return _finish("TENDER RELEASE / %d HULL RESTORED" % roundi(amount) if amount > 0.0 else "TENDER RELEASE / HULL ALREADY SOUND", campaign)
