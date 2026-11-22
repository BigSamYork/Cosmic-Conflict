extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	verify_migration()
	await verify_hazards()
	await verify_guardian()
	await verify_world()
	await process_frame
	print("XYLO_TEST_FAILURES=", failures)
	quit(failures)

func verify_migration() -> void:
	var old := CampaignState.new()
	old.phase = "orbit"
	old.sector = "vespera"
	old.cleared_sectors.assign(["ignis", "cryo", "vespera"])
	old.replays_unlocked = true
	old.stats["sorties"] = 3
	old.credits = 450
	old.earned = 450
	var legacy: Dictionary = old.to_dict()
	legacy["schema"] = 9
	legacy["stats"].erase("eggs")
	legacy["stats"].erase("guardians")
	var path: String = "user://xylo-migration-%d.json" % OS.get_process_id()
	var text: String = JSON.stringify(legacy, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and store.state.replays_unlocked and store.state.can_visit("ignis") and store.state.can_visit("xylo"), "Three-sector veterans retain replays while gaining the fourth destination")
	check(store.state.phase == "orbit" and store.state.sector == "vespera" and store.state.credits == 450 and store.state.stats["eggs"] == 0, "Schema-nine migration retains the active checkpoint without inventing hive rewards")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v9-") and FileAccess.get_file_as_string(store.migration_backup_path) == text, "Schema-nine migration preserves the exact original file")
	var invalid: Dictionary = legacy.duplicate(true)
	invalid["sector"] = "xylo"
	check(not CampaignState.new().restore(invalid).is_empty(), "An older save cannot claim a not-yet-available Xylo checkpoint")
	DirAccess.remove_absolute(store.migration_backup_path)
	DirAccess.remove_absolute(path)

func verify_hazards() -> void:
	for fps in [30, 45, 120]:
		var acid := XyloField.new()
		root.add_child(acid)
		var flight := FlightState.new()
		flight.training = false
		var hits: int = 0
		for _i in range(fps * 4):
			flight.advance(1.0 / fps, false)
			if acid.advance(1.0 / fps, Vector3(0, 10, 0), Vector3(0, 10, 0)):
				hits += 1
				flight.impact("CORROSIVE GEYSER", XyloField.ACID_DAMAGE)
		check(hits == 1 and flight.hull == 100 and flight.impacts == 1, "Acid damages shields once per eruption contact, not every frame, at %d Hz" % fps)
		var direct := FlightState.new()
		direct.training = false
		direct.impact("CORROSIVE GEYSER", XyloField.ACID_DAMAGE)
		check(direct.shields == 82 and direct.hull == 100, "Acid applies the approved eighteen shield-first damage")
		direct.advance(1, false)
		check(direct.shields == 82 and direct.hull == 100, "Acid adds no lingering damage after the contact")
		acid.queue_free()
	var affected := FlightState.new()
	var normal := FlightState.new()
	affected.training = false
	normal.training = false
	affected.aim = Vector2(0.7, -0.5)
	normal.aim = affected.aim
	check(affected.apply_spores(), "A spore exposure starts brief radar interference")
	affected.advance(0.3, true)
	normal.advance(0.3, true)
	check(affected.offset.is_equal_approx(normal.offset) and affected.distance == normal.distance and affected.shots == normal.shots and affected.aim == normal.aim, "Spores do not alter aiming, steering, travel or primary fire")
	var remaining: float = affected.radar_static_remaining
	affected.advance(3, false, false)
	check(affected.radar_static_remaining == remaining and not affected.apply_spores(), "Pause freezes radar static and repeated contacts cannot extend an active effect")
	affected.request_evasion()
	normal.request_evasion()
	affected.advance(0.65, false)
	normal.advance(0.65, false)
	check(affected.offset.is_equal_approx(normal.offset), "Shift keeps its full maneuver during spore interference")
	affected.advance(1.05, false)
	check(affected.radar_static_remaining == 0, "Radar interference expires after its original two seconds")
	await process_frame

func verify_guardian() -> void:
	var guardian := PirateSkirmisher.new()
	guardian.biological = true
	root.add_child(guardian)
	var shots: Array[int] = [0]
	guardian.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: shots[0] += 1)
	guardian.advance(3, Vector3(0, 0, 50), Vector3.ZERO)
	check(shots[0] == 0 and not guardian.engaged, "An untouched hive guardian does not attack")
	guardian.receive_hit(1)
	guardian.advance(1.1, Vector3.ZERO, Vector3.ZERO)
	check(shots[0] > 0 and guardian.engaged, "Attacking a guardian enables its real retaliatory projectile fire")
	guardian.retire()
	guardian.advance(2, Vector3.ZERO, Vector3.ZERO)
	check(guardian.expired and guardian.collision_layer == 0, "Guardians still leave the route instead of becoming mandatory bosses")
	guardian.queue_free()
	await process_frame

func verify_world() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.automation = "--unit-fixture"
	game.campaign = CampaignState.new()
	game.campaign.sector = "xylo"
	game.is_campaign = true
	var path: String = "user://xylo-world-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	await game._load_phase()
	check(game.xylo_fields.size() == 14 and game.xylo_rovers != null and game.heat_vents.is_empty() and game.frost_fields.is_empty(), "Xylo has its own corrosive/spore fields and survey vehicles")
	check(game.xylo_rovers.find_children("*", "CollisionObject3D", true, false).is_empty(), "Survey rovers are non-hostile scenery, not targets or collision traps")
	game.pause_flight()
	var age: float = game.xylo_fields[0].age
	game._physics_process(3)
	check(game.xylo_fields[0].age == age, "Pause freezes biological hazard cycles")
	game.resume_flight()
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	check(game.boss.bio_legs.size() == 2 and game.boss.parts[0].biological, "Goliath has articulated limbs and organic weak-point organs")
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	for part in [game.boss.parts[0], game.boss.parts[1], game.boss.core]:
		part.unlocked = true
		part.receive_hit(part.armor)
	game._finish_phase()
	var preview: MissionWorld = game.approaching_belt
	var first: EggShip = preview.targets[0]
	var prepared_position: Vector3 = first.global_position
	check(preview.backdrop is HiveBackdrop and preview.targets.all(func(target: RangeTarget) -> bool: return target is EggShip) and preview.boss == null, "The hive field contains egg ships and mothers, not renamed asteroids or an extra boss")
	var nearest: float = INF
	for _i in range(25 * 30):
		if game.mode == game.Mode.FLIGHT:
			break
		game._physics_process(1.0 / 30)
		nearest = minf(nearest, backdrop_clearance(game.camera.global_position, preview.backdrop))
	check(nearest > 1 and game.world == preview and first.global_position.is_equal_approx(prepared_position), "Hive entry clears background bodies and reuses the already-visible fleet")
	await physics_frame
	await physics_frame
	var probe := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = game.flight.collision_radius
	probe.shape = sphere
	probe.collision_mask = 1
	var clear: bool = true
	for travel in range(0, 3120, 5):
		probe.transform = preview.asteroid_course * FlightDirector.asteroid_frame(travel)
		probe.motion = preview.asteroid_course * FlightDirector.asteroid_point(travel + 5) - probe.transform.origin
		clear = clear and game.get_world_3d().direct_space_state.cast_motion(probe)[0] == 1
	check(clear, "Real egg-ship collision volumes leave the nominal course and coast clear")
	var cargo: EggShip
	for target in game.targets:
		if target is EggShip and target.cargo:
			cargo = target
			break
	game.flight.shots += 1
	game.campaign.stats["shots"] += 1
	game._strike({"collider": cargo, "position": cargo.global_position}, cargo.armor)
	game._strike({"collider": cargo, "position": cargo.global_position}, 10)
	check(game.campaign.stats["eggs"] == 1 and game.campaign.credits == 8 and game.campaign.stats["asteroids"] == 0 and game.rock_fragments.is_empty() and game.mineral_pickups.size() == 1 and game.mineral_pickups[0].biological, "Egg cargo pays once and releases a biological pickup without stone fragments")
	var brood: EggShip
	for target in game.targets:
		if target is EggShip and target.infested:
			brood = target
			break
	check(brood != null and not brood.cargo and brood.appearance.get_child(0).name == &"brood_egg", "A distinct brood shell occurs among the shootable swarm eggs")
	var contact := {"collider": brood, "position": brood.global_position}
	game._strike(contact, 1)
	check(game.parasites.is_empty(), "Wounding the shell does not hatch the parasite")
	game._strike(contact, brood.armor)
	game._strike(contact, 1)
	check(game.parasites.size() == 1 and game.parasites[0].global_position.is_equal_approx(brood.global_position), "Destroying the egg releases one creature from the explosion")
	var parasite: CanopyParasite = game.parasites[0]
	var hull_before: float = game.flight.hull
	var shields_before: float = game.flight.shields
	var damage_before: float = game.campaign.hull_damage
	game._advance_parasites(CanopyParasite.LEAP + 2.9)
	check(parasite.gripping() and parasite.get_parent() == game.camera and parasite.position.z < 0, "The creature reaches the canopy belly-first")
	var frozen := parasite.age
	game.pause_flight()
	game._physics_process(1.0)
	check(parasite.age == frozen and game.flight.hull == hull_before, "Pause freezes the latch and its bite timer")
	game.resume_flight()
	game.flight.impact_cooldown = 0.7
	game._advance_parasites(0.11)
	check(game.flight.hull < hull_before and game.flight.shields == shields_before, "An attached bite reaches the hull through charged shields")
	game._advance_parasites(12.0)
	var loss: float = game.flight.max_hull * 0.10
	check(is_equal_approx(hull_before - game.flight.hull, loss) and is_equal_approx(game.campaign.hull_damage - damage_before, loss), "A full fifteen-second latch removes ten percent of maximum hull exactly once")
	var at_release := parasite.position.y
	game._advance_parasites(0.4)
	check(parasite.position.y < at_release, "The parasite slides down the glass after fifteen seconds")
	game._advance_parasites(0.5)
	check(game.parasites.is_empty() and not game.sound.parasite_voice.playing, "The latch clears its view and sound after release")
	game.flight.distance = FlightDirector.ASTEROID_SPEED * FlightDirector.ASTEROID_DURATION
	var final_hull: float = game.flight.hull
	for egg in game.targets:
		if egg is EggShip and egg.infested and not egg.destroyed:
			game._strike({"collider": egg, "position": egg.global_position}, egg.armor)
			break
	game.flight.elapsed = FlightDirector.ASTEROID_DURATION
	game.director.advance("asteroids", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._finish_phase()
	var passed: bool = false
	nearest = INF
	for _i in range(36 * 30):
		if game.mode == game.Mode.MARKET:
			break
		game._physics_process(1.0 / 30)
		nearest = minf(nearest, backdrop_clearance(game.camera.global_position, preview.backdrop))
		if game.sequence == "belt_climb" and game.sequence_time == 0:
			passed = true
			var inverse: Transform3D = game.director.origin.affine_inverse()
			var pilot_travel: float = -(inverse * game.camera.global_position).z
			for body in preview.backdrop.rocks:
				passed = passed and pilot_travel + (inverse * Vector3(body["position"])).z - body["radius"] * 1.3 >= 23.9
	check(passed and nearest > 1 and game.mode == game.Mode.MARKET and game.world == preview, "The living fleet passes behind before the pull-up and remains in one scene through docking")
	check(game.parasites.is_empty() and is_equal_approx(final_hull - game.flight.hull, loss), "A last-second hatch stays on the glass during the coast and releases before docking")
	check((-game.camera.global_basis.z).dot(game.station.global_basis.z) > 0.999, "Xylo docking finishes aligned with the next station exit")
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func backdrop_clearance(pilot: Vector3, backdrop: BeltBackdrop) -> float:
	var nearest: float = INF
	for body in backdrop.rocks:
		nearest = minf(nearest, pilot.distance_to(body["position"]) - body["radius"] * 1.3)
	return nearest

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
