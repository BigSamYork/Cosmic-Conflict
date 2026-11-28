extends SceneTree

var failures := 0
var route := GroundRoute.new()
var campaign: CampaignState
var flight: FlightState
var patrol: SurfacePatrol
var pilot: Camera3D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	pilot = Camera3D.new()
	root.add_child(pilot)
	pilot.make_current()
	for job in SurfacePatrol.Job.values():
		verify_job(job)
	for missing_hull in [0.0, 20.0]:
		begin(SurfacePatrol.Job.REPAIR)
		flight.hull = flight.max_hull - missing_hull
		var message := fly_formation()
		check(flight.hull == flight.max_hull - maxf(0, missing_hull - 12), "Tender restores up to twelve hull per visit")
		check(message.contains("ALREADY SOUND") if missing_hull == 0 else message.contains("12 HULL RESTORED"), "Tender reports its actual repair")
		patrol.free()
	verify_failure_paths()
	for outcome in ["quiet", "miss", "fire"]:
		verify_boarding(outcome)
	for id in ["ignis", "cryo", "xylo", "thalassa", "kharon"]:
		verify_rescue(id, false, false)
		verify_rescue(id, true, true)
	verify_rescue("kharon", true, false)
	var rovers := XyloRovers.new()
	root.add_child(rovers)
	var drivetrain: AnimationPlayer = rovers.drivetrains[0]
	var skeleton := rovers.vehicles[0].find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var wheel := skeleton.find_bone("Wheel_1_0")
	var old := skeleton.get_bone_pose_rotation(wheel)
	rovers.advance(0.38)
	check(drivetrain.is_playing() and skeleton.get_bone_count() == 8 and not old.is_equal_approx(skeleton.get_bone_pose_rotation(wheel)), "Blender wheel bones advance on the gameplay clock")
	rovers.free()
	var terminal := StationHangar.new()
	root.add_child(terminal)
	var dock_rig := terminal.lifts[0].get_parent().find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var carriage := dock_rig.find_bone("Carriage")
	var before := dock_rig.get_bone_pose_position(carriage)
	terminal.advance(0.9)
	check(terminal.lifts.size() == 2 and dock_rig.get_bone_count() == 4 and not before.is_equal_approx(dock_rig.get_bone_pose_position(carriage)), "The station hoists move their suspended freight on skinned carriages")
	terminal.free()
	pilot.free()
	await process_frame
	print("SURFACE_PATROL_FAILURES=", failures)
	quit(failures)

func begin(job: int) -> void:
	campaign = CampaignState.new()
	flight = FlightState.new()
	flight.configure_campaign(campaign)
	patrol = SurfacePatrol.new()
	root.add_child(patrol)
	patrol.job_order = [job, job, job]
	flight.distance = SurfacePatrol.MARKS[0] - 140.0
	patrol.advance(0.016, Vector3.ZERO, Vector3.ZERO, campaign, flight, route)

func verify_rescue(id: String, right_lane: bool, miss: bool) -> void:
	var run := preload("res://scripts/rescue_run.gd").new()
	root.add_child(run)
	var state := CampaignState.new()
	state.sector = id
	var ship := FlightState.new()
	ship.configure_campaign(state)
	var branch := GroundRoute.new()
	branch.advance(GroundRoute.FORK, 7 if right_lane else -7)
	var previous := Vector3.ZERO
	var outcome := ""
	var knocks := [0]
	var sounds: Array[String] = []
	run.sound_requested.connect(func(sound_id: String) -> void: sounds.append(sound_id))
	run.knock.connect(func() -> void: knocks[0] += 1)
	for i in 550:
		ship.distance = 1150 + i * 2.1
		var frame := GroundRoute.frame(ship.distance) if right_lane else FlightState.rail_frame(ship.distance)
		var at := frame * Vector3(80 if miss else 6 if id == "xylo" else 1, 2, 0)
		outcome = run.advance(0.05, previous, at, state, ship, branch)
		if not outcome.is_empty(): break
		if not miss and is_instance_valid(run.battery):
			run.battery.receive_hit(run.battery.armor)
		if not miss and is_instance_valid(run.walker_effect):
			run.walker_effect.walker.receive_hit(36)
		previous = at
	var expected: String = {"ignis":"mold", "cryo":"converter", "thalassa":"cradle", "xylo":"pallet", "kharon":"relay" if right_lane else "courier"}[id]
	check(outcome == ("backup" if miss else expected), "%s rescue resolves the player's actual route: %s" % [id, outcome])
	var success_cues := {"ignis":"rescue_mold", "cryo":"rescue_converter", "thalassa":"rescue_tow", "xylo":"rescue_reeds", "kharon":"rescue_relay" if right_lane else "patrol_freight"}
	check(sounds == ["patrol_failed" if miss else success_cues[id]], "%s plays the sound for its actual rescue outcome once" % id)
	if id == "thalassa": check(knocks[0] == 3, "The maintenance compartment answers with three knocks")
	state.rescue_method = outcome
	var retry := state.copy()
	retry.eject()
	check(retry.home_manifest.is_empty() and retry.rescue_method.is_empty(), "An ejection does not credit the rescue")
	state.dock(true)
	check(state.copy().home_manifest.get(id) == outcome, "Astra retains the actual rescue method on disk")

func verify_boarding(scenario: String) -> void:
	var scene := preload("res://scripts/vespera_boarding.gd").new()
	root.add_child(scene)
	var heard: Array[String] = []
	scene.cue.connect(func(id: String) -> void: heard.append(id))
	var cursor := scene.ENTRY - 515
	var result := ""
	var groups: Array[int] = []
	while cursor < scene.EXIT + 100:
		var offset := Vector3.RIGHT * 12 if scenario == "miss" else Vector3.ZERO
		var previous := FlightState.rail_frame(cursor).origin + offset
		cursor += 5
		var pilot_pos := FlightState.rail_frame(cursor).origin + offset
		var done := scene.advance(cursor, previous, pilot_pos, route, int(scenario == "fire" and cursor > scene.ENTRY + 22))
		if scene.beat > 0:
			var lit := scene.flares.filter(func(f: Label3D) -> bool: return f.visible).size()
			if groups.is_empty() or groups[-1] != lit: groups.append(lit)
		if not done.is_empty(): result = done
	check(groups == [3, 2, 1, 0], scenario + ": three flares go dark one at a time")
	check(heard.slice(0, 3) == ["clearance", "refusal", "handoff"], scenario + ": attendants receive the channel before boarding")
	check(result == ("quiet" if scenario == "quiet" else "covered") and heard.count("divert") == int(scenario != "quiet"), scenario + ": quiet lane or covered ramp resolves exactly once")
	var save := CampaignState.new()
	save.vespera_boarding = result
	check(save.copy().vespera_boarding == result, "Boarding outcome survives phase-boundary save/load")
	save.eject()
	check(save.vespera_boarding.is_empty(), "Ejection does not count as a rescue")
	scene.free()

func cross_gate(distance: float, side: float) -> String:
	flight.distance = distance
	var at := patrol._pose(distance, side, route)
	return patrol.advance(0.016, at * Vector3(0, 0, 4), at * Vector3(0, 0, -4), campaign, flight, route)

func fly_formation() -> String:
	flight.offset = Vector2(patrol.lane_sign * 8.2, 2.6)
	flight.precision_hold = true
	var message := ""
	while flight.distance < patrol.station_distance + 250 and patrol.current >= 0:
		var previous := pilot.position
		flight.advance(1.0 / 60, false)
		pilot.position = FlightState.rail_frame(flight.distance) * Vector3(flight.offset.x, flight.offset.y, 0)
		message = patrol.advance(1.0 / 60, previous, pilot.position, campaign, flight, route)
	return message

func verify_job(job: int) -> void:
	begin(job)
	var d := patrol.station_distance
	var side := patrol.lane_sign
	var before := campaign.credits
	match job:
		SurfacePatrol.Job.SLALOM:
			cross_gate(d, side)
			cross_gate(d + 74.0, -side)
			var final_gate := patrol._pose(d + 148.0, side, route)
			flight.distance = d + 168.0
			var message := patrol.advance(0.6, final_gate * Vector3.BACK, final_gate * (Vector3.FORWARD * 20), campaign, flight, route)
			check(message.contains("+380 SCORE"), "Crossing the final gate on a long tick reports the earned score")
		SurfacePatrol.Job.ESCORT, SurfacePatrol.Job.REPAIR:
			flight.hull = flight.max_hull - 4.0
			var message := fly_formation()
			check(message.contains("HULL RESTORED") if job == SurfacePatrol.Job.REPAIR else message.contains("ESCORT COMPLETE"), "Holding formation at normal flight speed completes " + SurfacePatrol.LABELS[job])
			if job == SurfacePatrol.Job.REPAIR:
				check(is_equal_approx(flight.hull, flight.max_hull), "A repair transfer respects the hull maximum")
		SurfacePatrol.Job.COURIER, SurfacePatrol.Job.CEASEFIRE, SurfacePatrol.Job.INTERCEPT:
			cross_gate(d, side)
			if job == SurfacePatrol.Job.INTERCEPT:
				flight.interceptions += 1
			cross_gate(d + 185.0, -side if job == SurfacePatrol.Job.COURIER else side)
		SurfacePatrol.Job.SURVEY:
			pilot.transform = FlightState.rail_frame(d - 110.0)
			pilot.look_at(patrol.main_model.global_position)
			for _i in range(15):
				patrol.advance(0.1, pilot.position, pilot.position, campaign, flight, route)
		_:
			flight.heat = 88.0
			flight.overheat_remaining = 0.3
			var shields := flight.shields
			cross_gate(d, side)
			if job == SurfacePatrol.Job.RESTART:
				check(is_equal_approx(flight.shields, shields - 12), "Restart transfers twelve shield units")
			elif job == SurfacePatrol.Job.COOLANT:
				check(flight.heat == 0 and flight.overheat_remaining == 0, "Coolant brings overheated guns back online")
	check(patrol.current < 0 and campaign.credits == before and campaign.combat_score == SurfacePatrol.REWARDS[job] * 10, "Contract score and wallet settle correctly for " + SurfacePatrol.LABELS[job])
	patrol.free()

func verify_failure_paths() -> void:
	for job in [SurfacePatrol.Job.CEASEFIRE, SurfacePatrol.Job.COURIER, SurfacePatrol.Job.RESTART]:
		begin(job)
		var d := patrol.station_distance
		var side := patrol.lane_sign
		if job == SurfacePatrol.Job.RESTART:
			flight.shields = 8
			cross_gate(d, side)
			check(flight.shields == 8, "Low reserve cannot start a stalled ship")
		else:
			cross_gate(d, side)
			flight.shots += 1
			campaign.hull_damage += 1
			cross_gate(d + 185.0, -side if job == SurfacePatrol.Job.COURIER else side)
		check(campaign.credits == 0 and patrol.current == -1, "Failed condition closes the contract without payment")
		patrol.free()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
