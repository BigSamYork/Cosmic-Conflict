extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	verify_migration()
	await verify_gates()
	await verify_flight()
	await process_frame
	print("VESPERA_TEST_FAILURES=", failures)
	quit(failures)

func verify_migration() -> void:
	var old := CampaignState.new()
	old.sector = "cryo"
	old.phase = "orbit"
	old.credits = 450
	old.earned = 450
	old.cleared_sectors.assign(["ignis", "cryo"])
	old.stats["sorties"] = 2
	var legacy: Dictionary = old.to_dict()
	legacy["schema"] = 8
	legacy.erase("replays_unlocked")
	var path: String = "user://vespera-migration-%d.json" % OS.get_process_id()
	var text: String = JSON.stringify(legacy, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and store.state.replays_unlocked and store.state.can_visit("ignis") and store.state.can_visit("cryo") and store.state.can_visit("vespera"), "Existing two-sector pilots retain replays while gaining Vespera access")
	check(store.state.phase == "orbit" and store.state.sector == "cryo" and store.state.credits == 450, "Schema-eight migration preserves the active checkpoint and wallet")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v8-") and FileAccess.get_file_as_string(store.migration_backup_path) == text, "Schema-eight migration preserves an exact original-format backup")
	var reload := CampaignStore.new(path)
	reload.load_game()
	reload.state.eject()
	check(reload.state.replays_unlocked and reload.state.can_visit("cryo"), "Grandfathered replay access survives reload and ejection")
	var invalid: Dictionary = legacy.duplicate(true)
	invalid["sector"] = "vespera"
	check(not CampaignState.new().restore(invalid).is_empty(), "A legacy save cannot claim a sector that did not exist in its schema")
	invalid = CampaignState.new().to_dict()
	invalid["replays_unlocked"] = true
	check(not CampaignState.new().restore(invalid).is_empty(), "Replay entitlement without the required clears is rejected")
	DirAccess.remove_absolute(store.migration_backup_path)
	DirAccess.remove_absolute(path)

func verify_gates() -> void:
	var course := Transform3D(Basis(Vector3.UP, 0.7), Vector3(1300, 900, -2400))
	for fps in [30, 45, 120]:
		var gate := CityLaserGate.new()
		root.add_child(gate)
		gate.global_transform = course
		var hits: int = 0
		for i in range(fps * 10):
			var z: float = 20 - float(i) / fps * 5
			hits += int(gate.advance(1.0 / fps, course * Vector3(0, 0, z), course * Vector3(0, 0, z - 5.0 / fps), 0.6))
		check(hits == 0, "The central lane stays clear through every laser-gate state at %d Hz on a transformed course" % fps)
		gate.age = 2.5
		gate.struck = false
		check(gate.advance(0.1, course * Vector3(-9, 0, 4), course * Vector3(-9, 0, -4), 0.6), "Swept side-lane crossings hit a real active beam at %d Hz" % fps)
		check(not gate.advance(0.1, course * Vector3(-9, 0, 4), course * Vector3(-9, 0, -4), 0.6), "A gate crossing cannot inflict repeated frame-based hits")
		gate.struck = false
		gate.emitters[0].jam()
		check(not gate.advance(0.1, course * Vector3(-9, 0, 4), course * Vector3(-9, 0, -4), 0.6), "EMP-jammed gate emitters do not deal damage")
		gate.emitters[0].receive_hit(4)
		gate.age = 2.5
		gate.emitters[0].jam_remaining = 0
		check(not gate.advance(0.1, course * Vector3(-9, 0, 4), course * Vector3(-9, 0, -4), 0.6) and not gate.beams[0].visible, "Destroying a post permanently disables its visible beams and damage")
		gate.queue_free()
	await process_frame

func verify_flight() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.automation = "--unit-fixture"
	var path: String = "user://vespera-flight-%d.json" % OS.get_process_id()
	game.normal_save_path = path
	game._new_campaign("vespera")
	await process_frame
	await process_frame
	check(game.launch_approach.sector == "vespera" and game.city_traffic != null and game.laser_gates.size() == 9 and game.heat_vents.is_empty() and game.frost_fields.is_empty(), "Vespera launch prepares its city traffic and side gates instead of reusing volcanic or frost hazards")
	for _i in range(50 * 30):
		if game.mode == game.Mode.FLIGHT:
			break
		game._physics_process(1.0 / 30)
	check(game.mode == game.Mode.FLIGHT and game.flight.elapsed == 0 and game.sky_city_mix == 1 and game.sky_icy_mix == 0, "Vespera arrival preserves the full combat timer and reaches its own sky")
	var traffic: CityTraffic = game.city_traffic
	var pose: Transform3D = traffic.poses[0]
	traffic.advance(0.1, 0)
	check(traffic.poses[0] != pose and traffic.poses[0].origin.y > 14 + FlightState.CORRIDOR.y + 3 and game.targets.all(func(target: RangeTarget) -> bool: return target.get_parent() != traffic), "City traffic moves well above the flight corridor and is not a combat target")
	var traffic_clear: bool = true
	for traffic_pose in traffic.poses:
		var travel: float = -traffic_pose.origin.z
		var side_distance: float = absf(traffic_pose.origin.x - FlightState.rail_point(travel).x)
		traffic_clear = traffic_clear and side_distance + 2 < 30 and traffic_pose.origin.y + 1.5 < 52
	check(traffic_clear, "Decorative traffic stays inside the building faces and below the overhead bridges")
	game.pause_flight()
	var gate_age: float = game.laser_gates[0].age
	var traffic_age: float = traffic.age
	game._physics_process(5)
	check(game.laser_gates[0].age == gate_age and traffic.age == traffic_age, "Pause freezes laser gates and decorative traffic")
	game.resume_flight()
	var post: GateEmitter = game.laser_gates[0].emitters[0]
	var credits: int = game.campaign.credits
	var kills: int = game.campaign.stats["enemies"]
	game.flight.shots += 1
	game.campaign.stats["shots"] += 1
	game._strike({"collider": post, "position": post.aim_point()}, 4)
	check(post.destroyed and game.campaign.credits == credits and game.campaign.stats["enemies"] == kills, "Disabling infrastructure does not create enemy kills, combo rewards or credits")
	game.campaign.phase = "orbit"
	await game._load_phase()
	for target in game.targets:
		target.collision_layer = 0
	game.targets.clear()
	var fighter := EnemyFighter.new()
	fighter.sector = "vespera"
	fighter.dogfight = true
	fighter.spawn_frame = game.camera.global_transform
	fighter.spawn_position = game.camera.to_global(Vector3(0, 0, -55))
	fighter.velocity = -game.camera.global_basis.z * 20
	game.world.add_child(fighter)
	fighter.global_position = fighter.spawn_position
	game.targets.append(fighter)
	fighter.cloak.age = 3
	fighter.advance(0, game.camera.global_position + Vector3.UP * 1000, Vector3.ZERO)
	await physics_frame
	await physics_frame
	check(not fighter.guided_lockable and game._swarm_targets().is_empty() and fighter.collision_layer != 0, "Cloaked fighters remain physical targets but cannot acquire guided locks")
	game.cursor = game.camera.unproject_position(fighter.aim_point())
	game.fire_armed = true
	Input.action_press("primary")
	game._physics_process(0.125)
	Input.action_release("primary")
	check(fighter.armor == 1 and not fighter.destroyed and game.flight.hits > 0, "A real manual primary shot damages a visibly cloaked fighter")
	game.campaign.emp_launcher = true
	game.campaign.selected_secondary = "emp"
	game.flight.ammo = 3
	game.fire_secondary()
	check(fighter.guided_lockable and fighter.cloak.revealed_remaining > 2 and fighter.stun_remaining > 0 and game._swarm_targets().has(fighter), "Actual EMP reveals and stuns a cloaked ship and immediately restores guided acquisition")
	var rocket := PlayerTorpedo.new()
	rocket.homing = true
	rocket.homing_target = fighter
	rocket.direction = -game.camera.global_basis.z
	rocket.position = game.camera.global_position
	game.add_child(rocket)
	fighter.global_position += game.camera.global_basis.x * 12
	fighter.guided_lockable = false
	var direction: Vector3 = rocket.direction
	rocket.advance(0.1, false)
	check(rocket.direction.is_equal_approx(direction), "An existing guided rocket stops steering toward a target while its cloak blocks the lock")
	fighter.stun()
	rocket.advance(0.1, false)
	check(not rocket.direction.is_equal_approx(direction), "A revealed target can be reacquired by an existing guided rocket")
	rocket.queue_free()
	fighter.cloak.revealed_remaining = 0
	fighter.cloak.age = 3
	fighter.cloak.refresh()
	fighter.receive_hit(fighter.armor)
	check(fighter.cloak.meshes[0].material_override == fighter.cloak.originals[0], "Destroying a cloaked fighter restores its original hull material before polygon breakup")
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	game.boss.cloak.age = 3
	game.boss.cloak.refresh()
	game.boss._update_guidance()
	check(game.boss.thermal_emitter == null and game.boss.drone_bay == null and not game.boss.parts[0].guided_lockable, "Nyx has its own cloaking system rather than copied thermal or drone mechanics")
	var hp: int = game.boss.core.armor
	check(not game._strike({"collider": game.boss.core, "position": game.boss.core.aim_point()}, 3) and game.boss.core.armor == hp, "Cloaking never bypasses the mandatory generator/core protection")
	game.boss.stun()
	check(game.boss.parts[0].guided_lockable and not game.boss.cloak.active(), "EMP reveals every Nyx weak point for guided targeting")
	game.boss.cloak.revealed_remaining = 0
	game.boss.cloak.age = 3
	game.boss.cloak.refresh()
	game.boss.begin_destruction()
	check(game.boss.cloak.meshes[0].material_override == game.boss.cloak.originals[0], "Nyx destruction restores original-colored hull materials instead of fragmenting the cloak effect")
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
