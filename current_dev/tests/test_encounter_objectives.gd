extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for fps in [30, 45, 60]:
		var web := LaserWeb.new()
		root.add_child(web)
		var damaged: bool = false
		for i in range(fps):
			var z: float = 6.0 - i * 12.0 / fps
			damaged = web.advance(1.0 / fps, Vector3(0, 0, z), Vector3(0, 0, z - 12.0 / fps), 0.6) or damaged
		check(not damaged and not web.beam.visible, "Telegraphed tripwire cannot damage before arming at %d FPS" % fps)
		web.advance(0.3, Vector3(0, 0, 10), Vector3(0, 0, 10), 0.6)
		check(web.beam.visible, "Tripwire visibly arms after its warning at %d FPS" % fps)
		check(not web.advance(0.1, Vector3(0, 3, 5), Vector3(0, 3, -5), 0.6), "Pilot can fly above an armed tripwire at %d FPS" % fps)
		check(web.advance(0.1, Vector3(0, 0, 5), Vector3(0, 0, -5), 0.6), "Swept tripwire collision catches a fast crossing at %d FPS" % fps)
		check(not web.advance(0.1, Vector3(0, 0, 5), Vector3(0, 0, -5), 0.6), "Discharged web cannot hit the pilot twice at %d FPS" % fps)
		web.queue_free()
	for side in [0, 1]:
		var web := LaserWeb.new()
		root.add_child(web)
		web.nodes[side].receive_hit(2)
		check(web.disabled and web.nodes[1 - side].collision_layer == 0 and not web.beam.visible, "Destroying either node disables the entire web")
		check(not web.nodes[1 - side].receive_hit(2), "The other node cannot produce a duplicate destruction reward")
		web.queue_free()
	var boundary := LaserWeb.new()
	root.add_child(boundary)
	boundary.age = 1.0
	check(not boundary.advance(0.4, Vector3(0, 0, 1), Vector3(0, 0, -5), 0.1), "Crossing before arming is safe even if the same frame ends after arming")
	boundary.age = LaserWeb.LIFETIME - 0.1
	check(not boundary.advance(0.4, Vector3(0, 0, 5), Vector3(0, 0, -1), 0.1) and boundary.complete(), "A crossing after expiry does not receive retroactive web damage")
	boundary.queue_free()
	var world := MissionWorld.new()
	root.add_child(world)
	world.build("orbit")
	world.advance(8.0, Transform3D.IDENTITY)
	var layers: int = 0
	for target in world.targets:
		if target is EnemyFighter and target.web_layer:
			layers += 1
	check(layers == 1, "The second orbital wave introduces one web-layer drone")
	for _i in range(6):
		world._request_web()
	world.advance(0.01, Transform3D.IDENTITY)
	check(world.webs.size() == 3, "Simultaneous tripwires are bounded")
	var node: WebNode = world.webs[0].nodes[0]
	node.receive_hit(2)
	world.advance_webs(0.01, Vector3.ZERO, Vector3.ZERO, 0.6)
	check(world.webs.size() == 2 and not world.targets.has(node), "Disabled webs remove their node targets and free their slot")
	world.queue_free()
	var belt := MissionWorld.new()
	root.add_child(belt)
	belt.build("asteroids")
	belt.advance(10.0, FlightDirector.asteroid_frame(480))
	check(belt.pirates.size() == 1, "The belt introduces a finite optional pirate encounter")
	var pirate: PirateSkirmisher = belt.pirates[0]
	var pirate_launches: Array[int] = [0]
	pirate.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: pirate_launches[0] += 1)
	var clearance: float = INF
	for _i in range(120):
		pirate.advance(0.1, pirate.global_position + Vector3.BACK * 65, Vector3.FORWARD * 48)
		for target in belt.targets:
			if target is Asteroid:
				clearance = minf(clearance, pirate.global_position.distance_to(target.global_position) - target.collision_radius() - PirateSkirmisher.CLEARANCE_RADIUS)
	check(clearance > 0.0, "Pirate weaving stays clear of actual asteroid collision volumes (%.2fm)" % clearance)
	check(pirate_launches[0] == 0, "Ignoring an optional pirate never provokes missile fire")
	pirate.receive_hit(1)
	pirate.advance(1.1, pirate.global_position + Vector3.BACK * 65, Vector3.FORWARD * 48)
	check(pirate_launches[0] == 1 and pirate.engaged, "An engaged pirate returns fire after its reaction delay")
	pirate.advance(2.0, Vector3.ZERO, Vector3.ZERO)
	check(pirate.expired and pirate.collision_layer == 0 and not pirate.visible, "Escaping pirates retire without a bounty or lingering collider")
	belt.queue_free()
	await process_frame
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game._build_world(false)
	game.flight.configure_campaign(game.campaign)
	var radar: RadarDish
	for target in game.targets:
		if target is RadarDish:
			radar = target
			break
	var upstream: GroundTurret = game.turrets[0]
	var downstream: GroundTurret = game.turrets[2]
	var distant: GroundTurret = game.turrets[-1]
	downstream.cooldown = 0.0
	game._strike({"collider": radar, "position": radar.aim_point()}, radar.armor)
	check(downstream.tracking_jammed == RadarDish.JAM_DURATION and upstream.tracking_jammed == 0 and distant.tracking_jammed == 0, "Destroying a radar jams only its downstream turret sector")
	var credits: int = game.campaign.credits
	game._strike({"collider": radar, "position": radar.aim_point()}, 5)
	check(game.campaign.credits == credits and credits == 0 and game.campaign.combo_kills == 0, "Radar objectives grant no credits or combat streak")
	var bounty := PirateSkirmisher.new()
	game.world.add_child(bounty)
	game._strike({"collider": bounty, "position": bounty.global_position}, 5)
	var bounty_credits: int = game.campaign.credits
	game._strike({"collider": bounty, "position": bounty.global_position}, 5)
	check(bounty_credits == credits and game.campaign.credits == bounty_credits and game.campaign.stats["pirates"] == 1, "Defeating a pirate records one kill without funding the wallet")
	var launches: Array[int] = [0]
	downstream.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: launches[0] += 1)
	var pilot: Vector3 = downstream.position + Vector3(0, 10, 100)
	downstream.advance(11.9, pilot)
	check(launches[0] == 0, "Jammed turret cannot track or launch missiles")
	downstream.advance(0.2, pilot)
	check(launches[0] == 0 and downstream.beacon.visible, "Recovered tracking gives another visible warning before firing")
	downstream.advance(2.0, pilot)
	check(launches[0] == 1, "Turret tracking and fire recover when jamming expires")
	var mission := MissionWorld.new()
	game.world.add_child(mission)
	game.mission_world = mission
	mission.build("orbit")
	mission._deploy_web()
	var before: float = mission.webs[0].age
	game._physics_process(3.0)
	check(mission.webs[0].age == before, "Pause freezes laser tripwires along with combat")
	game._clear_stage()
	check(game.mission_world == null and game.targets.is_empty(), "Phase cleanup removes objective and web targets")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("ENCOUNTER_OBJECTIVES_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
