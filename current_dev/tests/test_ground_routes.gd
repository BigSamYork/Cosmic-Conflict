extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await verify()
	await process_frame
	print("GROUND_ROUTES_FAILURES=", failures)
	quit(failures)

func verify() -> void:
	verify_geometry()
	verify_supplies()
	await verify_game()

func verify_geometry() -> void:
	for fps in [30, 45]:
		for hazard in [false, true]:
			var director := FlightDirector.new()
			director.ground_course = Transform3D(Basis(Vector3.UP, 0.8), Vector3(1700, 900, -2300))
			director.ground_route = GroundRoute.new()
			director.ground_route.advance(GroundRoute.FORK, 1 if hazard else -1)
			director.begin_phase("ground", Transform3D.IDENTITY)
			var previous: Transform3D = director.frame
			var max_step: float = 0
			var max_turn: float = 0
			var wrong_path: bool = false
			for i in range(1, fps * 90 + 1):
				var elapsed: float = float(i) / fps
				var distance: float = elapsed * FlightState.SPEED
				director.advance("ground", 1.0 / fps, distance, elapsed, [])
				max_step = maxf(max_step, director.frame.origin.distance_to(previous.origin))
				max_turn = maxf(max_turn, director.frame.basis.get_rotation_quaternion().angle_to(previous.basis.get_rotation_quaternion()))
				if not hazard or distance >= GroundRoute.REJOIN:
					wrong_path = wrong_path or not director.frame.is_equal_approx(director.ground_course * FlightState.rail_frame(distance))
				previous = director.frame
			check(max_step < 50.0 / fps and max_turn < 0.025 and not wrong_path, "%s route is continuous through fork/rejoin and translated course at %d Hz (%.3fm / %.4frad)" % ["Hazard" if hazard else "Safe", fps, max_step, max_turn])
			check(director.frame.is_equal_approx(director.ground_course * FlightState.rail_frame(3780)), "Both routes reach the same boss entry after exactly ninety active seconds")
	var closed := GroundRoute.new()
	check(not closed.advance(GroundRoute.FORK - 0.01, 8), "Steering on approach does not commit early")
	closed.advance(GroundRoute.FORK, 0)
	check(not closed.advance(GroundRoute.FORK + 1, 8) and not closed.selected, "Center defaults to safe and crossing sides after commitment cannot reroute")
	check(closed.claim_bonus(GroundRoute.REJOIN + 100, true) == 0, "The default safe route never grants the hazard bonus")
	var selected := GroundRoute.new()
	selected.advance(GroundRoute.FORK, 1)
	check(selected.claim_bonus(GroundRoute.REJOIN - 0.1, true) == 0 and selected.claim_bonus(GroundRoute.REJOIN, false) == 0, "Hazard reward requires reaching the rejoin alive")
	check(selected.claim_bonus(GroundRoute.REJOIN, true) == 100 and selected.claim_bonus(GroundRoute.REJOIN + 100, true) == 0, "Hazard completion pays exactly once")

func verify_supplies() -> void:
	var campaign := CampaignState.new()
	campaign.ship = "emergency"
	campaign.secondary = true
	campaign.countermeasures = true
	var flight := FlightState.new()
	flight.configure_campaign(campaign)
	flight.shields = 10
	flight.ammo = 2
	campaign.flares = 2
	for kind in ["shield", "ordnance", "flare"]:
		var supply := SupplyPickup.new()
		supply.kind = kind
		root.add_child(supply)
		var message: String = supply.advance(1.0, Vector3(0, 0, 20), Vector3(0, 0, -20), true, campaign, flight)
		check(not message.is_empty() and not supply.active, "Swept crossing collects the %s supply, even across a large frame" % kind)
		var snapshot := Vector3(flight.shields, flight.ammo, campaign.flares)
		check(supply.advance(1.0, Vector3.BACK, Vector3.FORWARD, true, campaign, flight).is_empty() and snapshot == Vector3(flight.shields, flight.ammo, campaign.flares), "The %s supply cannot be collected twice" % kind)
		supply.queue_free()
	check(flight.shields == 35 and flight.ammo == 3 and campaign.flares == 3 and campaign.credits == 0, "Shield, ordnance and flare pickups use separate capped inventories without bonus credits")
	for kind in ["ordnance", "flare", "shield"]:
		var supply := SupplyPickup.new()
		supply.kind = kind
		root.add_child(supply)
		flight.shields = flight.max_shields
		var message: String = supply.advance(0.1, Vector3.BACK, Vector3.FORWARD, true, campaign, flight)
		check(message.contains("FULL") and flight.ammo == 3 and campaign.flares == 3 and flight.shields == flight.max_shields, "Full %s inventory is explicitly reported, never overfilled" % kind)
		supply.queue_free()
	campaign.secondary = false
	campaign.countermeasures = false
	campaign.flares = 0
	flight.ammo = 0
	for kind in ["ordnance", "flare"]:
		var supply := SupplyPickup.new()
		supply.kind = kind
		root.add_child(supply)
		check(supply.advance(0.1, Vector3.BACK, Vector3.FORWARD, true, campaign, flight).contains("NO ") and flight.ammo == 0 and campaign.flares == 0, "Missing %s equipment is reported without granting an unlock or ammunition" % kind)
		supply.queue_free()
	var untouched := SupplyPickup.new()
	root.add_child(untouched)
	check(untouched.advance(0.1, Vector3.BACK, Vector3.FORWARD, false, campaign, flight).is_empty() and untouched.active, "The safe route cannot collect hazard supplies")
	flight.hull = 0
	check(untouched.advance(0.1, Vector3.BACK, Vector3.FORWARD, true, campaign, flight).is_empty() and untouched.active, "An ejected pilot cannot collect a supply in the same frame")
	untouched.queue_free()

func verify_game() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	check(game.ground_branch == null and game.director.ground_route == null, "Training retains its original unbranched course")
	game.set_process(false)
	game.set_physics_process(false)
	game.campaign = CampaignState.new()
	game.campaign.secondary = true
	game.campaign.countermeasures = true
	game.campaign.ammo = 1
	game.campaign.flares = 0
	var path: String = "user://ground-route-test-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	check(game.store.save_game(game.campaign) == OK, "Ground entry checkpoint is saved before choosing a branch")
	var entry: Dictionary = game.campaign.to_dict()
	await game._load_phase()
	game.mode = game.Mode.FLIGHT
	await physics_frame
	await physics_frame
	verify_terrain(game)
	for sector in ["ignis", "cryo"]:
		game.campaign.sector = sector
		for hazard in [false, true]:
			game.ground_branch.route.selected = hazard
			for distance in [1543.5, 2021.5, 2791.5]:
				game.director.advance("ground", 0, distance, 0, game.targets)
				for side in [-1, 1]:
					game.flight.offset = Vector2(side * 60, -25)
					check(game._limit_canyon_travel(), "%s rejects a below-ground steering request" % sector)
					game._update_camera()
					var local: Vector3 = game.director.ground_course.affine_inverse() * game.camera.transform.origin
					check(local.y > -1 and VectorArt.canyon_clearance(local, true, sector == "cryo", game.flight.collision_radius) >= -0.001,
						"%s pilot stays above the selected canyon floor" % sector)
			game.flight.offset = Vector2.ZERO
			check(not game._limit_canyon_travel(), "Clear lane centre is not constrained")
	game.campaign.sector = "ignis"
	game.ground_branch.route.selected = false
	game.flight.distance = GroundRoute.FORK - 1
	game.flight.elapsed = game.flight.distance / FlightState.SPEED
	game.flight.offset = Vector2(5, 0)
	game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game.cursor = game.get_viewport().get_visible_rect().size * Vector2(0.45, 0.5)
	Input.action_release("primary")
	game._physics_process(1.0 / 30)
	check(game.ground_branch.route.selected and game.flight.shots == 0, "Being right at the fork selects hazard without firing, even with the reticle left")
	var branch: GroundBranch = game.ground_branch
	check(branch.engages(branch.turrets[0], 1800) and not branch.engages(game.turrets[7], 1800), "Selected hazard weapons engage while the alternate central-route sector is inactive")
	branch.route.selected = false
	check(not branch.engages(branch.turrets[0], 1800) and branch.engages(game.turrets[7], 1800), "The safe route stays free of hazard-turret fire")
	branch.route.selected = true
	game.pause_flight()
	var before: Transform3D = game.camera.global_transform
	var elapsed: float = game.flight.elapsed
	var age: float = branch.supplies[0].age
	game._physics_process(2.0)
	check(game.camera.global_transform == before and game.flight.elapsed == elapsed and branch.supplies[0].age == age, "Pause freezes branch travel, choice timing and supply animation")
	game.resume_flight()
	var nominal_hits: int = 0
	game.player_probe_shape.radius = game.flight.collision_radius
	for distance in range(int(GroundRoute.FORK), int(GroundRoute.REJOIN) + 1, 2):
		game.player_probe.transform = game.director.ground_course * GroundRoute.frame(distance)
		game.player_probe.motion = Vector3.ZERO
		if not game.get_world_3d().direct_space_state.intersect_shape(game.player_probe, 1).is_empty():
			nominal_hits += 1
	check(nominal_hits == 0, "The nominal hazard lane clears real tower/turret collision volumes")
	game.flight.shields = 20
	for supply in branch.supplies:
		supply.advance(0.1, supply.global_position + Vector3.BACK * 10, supply.global_position + Vector3.FORWARD * 10, true, game.campaign, game.flight)
	game.flight.distance = GroundRoute.REJOIN
	branch.advance(0.1, game.camera.global_position, game.camera.global_position, game.campaign, game.flight)
	branch.advance(0.1, game.camera.global_position, game.camera.global_position, game.campaign, game.flight)
	check(game.campaign.credits == 100 and game.campaign.earned == 100 and game.campaign.combo_kills == 0, "Integrated rejoin bonus is paid once, without combat multiplier or fictitious kills")
	game.flight.distance = 3780
	game.flight.elapsed = 90
	game.director.advance("ground", 0, 3780, 90, game.targets)
	game._update_camera()
	game._finish_phase()
	var saved := CampaignStore.new(path)
	check(saved.load_game() == OK and saved.state.phase == "ground_boss" and saved.state.credits == 100 and saved.state.ammo == 3 and saved.state.flares == 1, "The normal boss checkpoint persists branch credits and both separate ammunition inventories together")
	game.campaign = CampaignState.new()
	check(game.campaign.restore(entry).is_empty(), "The saved ground-entry state remains valid without a schema change")
	await game._load_phase()
	check(not game.ground_branch.route.selected and not game.ground_branch.route.rewarded and game.campaign.credits == 0 and game.flight.ammo == 1 and game.campaign.flares == 0, "Retrying a ground-entry snapshot rolls back route choice, rewards and supplies together")
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func verify_terrain(game: Node3D) -> void:
	var course: Transform3D = game.director.ground_course
	for side in [-1, 1]:
		game.flight.aim = Vector2(side, 0)
		game.flight.advance(1, false)
		check(side * game.flight.offset.x > 50 and game.flight.offset.y == 0, "Full ground steering reaches the %s ridge" % ("left" if side < 0 else "right"))
	var ridge: Vector3 = VectorArt.ground_point(45, 160)
	var shields: float = game.flight.shields
	game._check_obstacles(course * (ridge + Vector3.UP * 4), course * (ridge - Vector3.UP * 4))
	check(game.flight.shields < shields, "Sweeping through the visible canyon slope damages the pilot")
	for lateral in [0, 45]:
		var a: Vector3 = FlightState.rail_point(120) + Vector3(lateral, 0, 0)
		var b: Vector3 = FlightState.rail_point(200) + Vector3(lateral, 0, 0)
		a.y = 14
		b.y = a.y
		var missile := EnemyMissile.new()
		game.add_child(missile)
		missile.position = course * a
		var pilot: Vector3 = course * b
		missile.direction = missile.position.direction_to(pilot)
		missile.age = EnemyMissile.HOMING_TIME
		var hits := [0]
		missile.hit_pilot.connect(func(): hits[0] += 1)
		missile.advance(1.1, pilot, pilot)
		check(not missile.active and hits[0] == (1 if lateral == 0 else 0), "An exposed pilot is hit" if lateral == 0 else "The intervening ridge stops a missile before it can hit the pilot")
		missile.free()
