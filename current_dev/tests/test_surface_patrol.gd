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
	verify_failure_paths()
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

func cross_gate(distance: float, side: float) -> String:
	flight.distance = distance
	var at := patrol._pose(distance, side, route)
	return patrol.advance(0.016, at * Vector3(0, 0, 4), at * Vector3(0, 0, -4), campaign, flight, route)

func verify_job(job: int) -> void:
	begin(job)
	var d := patrol.station_distance
	var side := patrol.lane_sign
	var before := campaign.credits
	match job:
		SurfacePatrol.Job.SLALOM:
			cross_gate(d, side)
			cross_gate(d + 74.0, -side)
			cross_gate(d + 148.0, side)
		SurfacePatrol.Job.ESCORT, SurfacePatrol.Job.REPAIR:
			flight.hull = flight.max_hull - 4.0
			flight.distance = d + 190.0
			var point := patrol._pose(d + 201.6, side, route).origin
			for _i in range(22):
				patrol.advance(0.1, point, point, campaign, flight, route)
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
	check(patrol.current < 0 and campaign.credits == before + SurfacePatrol.REWARDS[job], "Contract settles once: " + SurfacePatrol.LABELS[job])
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
