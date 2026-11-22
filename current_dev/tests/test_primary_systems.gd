extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	verify_cadence()
	await verify_gameplay()
	await process_frame
	print("PRIMARY_SYSTEMS_FAILURES=", failures)
	quit(failures)

func verify_cadence() -> void:
	for level in range(3):
		var reference: Array = []
		for fps in [30, 45, 120]:
			var campaign := CampaignState.new()
			campaign.primary_level = level
			var flight := FlightState.new()
			flight.configure_campaign(campaign)
			for _i in range(fps * 10):
				flight.advance(1.0 / fps, true)
			if reference.is_empty():
				reference = [flight.shots, flight.heat, flight.overheat_events]
			check(flight.shots == reference[0] and absf(flight.heat - reference[1]) < 0.001 and flight.overheat_events == reference[2] and flight.overheat_events > 0, "Primary tier %d cadence and heat agree at %d Hz" % [level, fps])
		var state := FlightState.new()
		state.primary_level = level
		state.zero_heat = true
		var volleys: int = state.advance_primary(1.0, true)
		check(volleys == (4 if level == 1 else 8) and state.shots == (16 if level == 1 else 8), "Primary tier %d counts actual bolts or fixed ticks, not visual barrels" % level)
		state.training = false
		state.zero_heat = false
		state.heat = 100
		state.overheat_remaining = 2
		state.fire_cooldown = 0
		check(state.advance_primary(1.999, true) == 0 and state.advance_primary(0.001, true) == 0 and state.advance_primary(0.001, true) == 1, "Primary tier %d retains the exact two-second overheat lock" % level)
		var copy := CampaignState.new()
		copy.primary_level = level
		check(copy.restore(copy.to_dict()).is_empty() and copy.primary_level == level, "Existing saved primary tier %d remains valid without a schema migration" % level)

func prepare(game: Node3D, level: int) -> void:
	game._clear_stage()
	game.world = MissionWorld.new()
	game.add_child(game.world)
	game.mission_world = game.world
	game.campaign = CampaignState.new()
	game.campaign.phase = "orbit"
	game.campaign.primary_level = level
	game.campaign.secondary = true
	game.campaign.ammo = 3
	game.campaign.countermeasures = true
	game.campaign.flares = 2
	game.flight = FlightState.new()
	game.flight.configure_campaign(game.campaign)
	game.flight.duration = 90
	game.is_campaign = true
	game.director = FlightDirector.new()
	game.director.frame = Transform3D.IDENTITY
	game.camera.global_transform = Transform3D.IDENTITY
	game._set_cockpit("rook", level)
	game.hud.flight = game.flight
	game.hud.campaign = game.campaign
	game.mode = game.Mode.FLIGHT
	game.resume_mode = game.Mode.FLIGHT
	game.cursor = game.get_viewport().get_visible_rect().size * 0.5
	game.fire_armed = true
	Input.action_release("primary")
	await physics_frame
	await physics_frame

func fighter(game: Node3D, at: Vector3, armor: int = 12) -> EnemyFighter:
	var target := EnemyFighter.new()
	game.world.add_child(target)
	target.global_position = at
	target.armor = armor
	return target

func fire_tick(game: Node3D) -> void:
	game.fire_armed = true
	Input.action_press("primary")
	game._physics_process(1.0 / 60.0)
	Input.action_release("primary")

func wall(game: Node3D, at: Vector3) -> StaticBody3D:
	var cover := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 20, 0.04)
	collider.shape = shape
	cover.add_child(collider)
	game.world.add_child(cover)
	cover.global_position = at
	return cover

func verify_gameplay() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	var path: String = "user://primary-systems-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	await prepare(game, 1)
	var target: EnemyFighter = fighter(game, Vector3(0, 0, -80), 20)
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(game.plasma_bolts.size() == 4 and game.flight.shots == 4 and game.campaign.stats["shots"] == 4 and target.armor == 20, "Quad fire launches four real travelling bolts, not instant damage or four cosmetic lines")
	game.pause_flight()
	var before: Vector3 = game.plasma_bolts[0].global_position
	var heat: float = game.flight.heat
	game._physics_process(1.0)
	check(game.plasma_bolts[0].global_position == before and game.flight.heat == heat, "Pause freezes travelling plasma and weapon heat")
	game.resume_flight()
	for _i in range(12):
		game._physics_process(1.0 / 60.0)
		await physics_frame
	check(target.armor == 16 and game.flight.hits == 4 and game.campaign.stats["hits"] == 4 and game.plasma_bolts.is_empty(), "Each plasma bolt resolves its own actual impact and accuracy sample")
	check(game.flight.ammo == 3 and game.campaign.flares == 2, "Advanced primaries consume neither shared ordnance nor flare charges")
	await prepare(game, 1)
	target = fighter(game, Vector3(0, 0, -80), 20)
	wall(game, Vector3(0, 0, -20))
	await physics_frame
	await physics_frame
	fire_tick(game)
	for _i in range(12):
		game._physics_process(1.0 / 60.0)
		await physics_frame
	check(target.armor == 20 and game.flight.hits == 0 and game.plasma_bolts.is_empty(), "Fast plasma cannot tunnel through thin solid cover")

	await prepare(game, 2)
	var ships: Array[EnemyFighter] = []
	for i in range(3):
		ships.append(fighter(game, Vector3(0, 0, -40 - i * 30)))
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(ships[0].armor == 9 and ships[1].armor == 9 and ships[2].armor == 9, "A tachyon tick pierces three small ships in depth order")
	check(game.flight.shots == 1 and game.flight.hits == 1 and game.campaign.stats["shots"] == 1 and game.campaign.stats["hits"] == 1, "A multi-target beam tick counts at most one hit and cannot exceed one hundred percent accuracy")
	check(game.tachyon_beam != null and game.tachyon_beam.visible, "The tachyon beam is visible between damage ticks")
	var beam_transform: Transform3D = game.tachyon_beam.segments[0].global_transform
	game.pause_flight()
	game._physics_process(1.0)
	check(ships[0].armor == 9 and game.tachyon_beam.segments[0].global_transform == beam_transform, "Paused continuous beams neither damage nor move")
	game.resume_flight()
	game._physics_process(1.0 / 60.0)
	check(not game.tachyon_beam.visible and game.flight.shots == 1, "Releasing fire extinguishes the beam without inventing another shot")
	game.fire_armed = true
	game.flight.overheat_remaining = 2
	Input.action_press("primary")
	game._physics_process(1.0 / 60.0)
	Input.action_release("primary")
	check(not game.tachyon_beam.visible and game.flight.shots == 1, "An overheated tachyon cannot display an active damaging beam")

	for blocker_kind in ["wall", "core", "iron", "gunship", "tower"]:
		await prepare(game, 2)
		var rear: EnemyFighter = fighter(game, Vector3(0, 0, -90))
		var blocker: Node3D
		match blocker_kind:
			"wall":
				blocker = wall(game, Vector3(0, 0, -30))
			"core":
				var core := BossPart.new()
				core.core = true
				core.unlocked = false
				game.world.add_child(core)
				blocker = core
			"iron":
				var rock := Asteroid.new()
				rock.indestructible = true
				game.world.add_child(rock)
				blocker = rock
			"gunship":
				var gunship := EnemyFighter.new()
				gunship.heavy = true
				gunship.dogfight = true
				game.world.add_child(gunship)
				gunship.rotation.y = PI
				blocker = gunship
			"tower":
				blocker = DestructibleTower.new()
				game.world.add_child(blocker)
		blocker.global_position = Vector3(0, 0, -30)
		await physics_frame
		await physics_frame
		fire_tick(game)
		check(rear.armor == 12 and game._trace_tachyon(false).z > -40, "Tachyon stops at %s and shields the ship behind it" % blocker_kind)
		if blocker is DestructibleTower:
			check(blocker.armor == 3 and game.flight.hits == 1, "A tachyon shot damages the tower shaft at its actual contact")
		else:
			check(game.flight.hits == 0, "Protected %s rejects beam damage" % blocker_kind)
	await prepare(game, 2)
	var rear: EnemyFighter = fighter(game, Vector3(0, 0, -90))
	var partial_cover: StaticBody3D = wall(game, Vector3(0.45, 0, -30))
	partial_cover.get_child(0).shape.size.x = 0.2
	await physics_frame
	await physics_frame
	var center_ray := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3(0, 0, -490), 7)
	var center_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(center_ray)
	fire_tick(game)
	check(center_hit.get("collider") == rear and rear.armor == 12 and game.flight.hits == 0, "Aperture-edge cover stops the whole beam even when its center ray is clear")
	await prepare(game, 2)
	var front: EnemyFighter = fighter(game, Vector3(0, 0, -25))
	rear = fighter(game, Vector3(0, 0, -90))
	wall(game, Vector3(0, 0, -55))
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(front.armor == 9 and rear.armor == 12 and game.flight.hits == 1, "Piercing a small ship cannot bypass the next solid obstruction")
	await prepare(game, 2)
	target = fighter(game, Vector3(3.5, 0, -50))
	await physics_frame
	await physics_frame
	var precise := PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3(0, 0, -490), 7)
	check(game.get_world_3d().direct_space_state.intersect_ray(precise).is_empty(), "Edge fixture lies outside precise pulse-ray aim")
	fire_tick(game)
	check(target.armor == 9 and game.flight.hits == 1, "The physical 0.9-meter-wide tachyon catches a genuine edge hit")
	await prepare(game, 2)
	target = fighter(game, Vector3(3.8, 0, -50))
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(target.armor == 12 and game.flight.hits == 0, "Tachyon width is bounded, not screen-wide targeting")
	await prepare(game, 2)
	var course := Transform3D(Basis(Vector3.UP, 0.61), Vector3(-1400, -800, -9000))
	game.world.global_transform = course
	game.camera.global_transform = course
	game.director.frame = course
	target = fighter(game, course * Vector3(3.5, 0, -80))
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(target.armor == 9 and game.flight.hits == 1, "Wider edge contacts remain valid on distant translated and rotated courses")
	await prepare(game, 2)
	target = fighter(game, Vector3.ZERO)
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(target.armor == 9 and game.flight.hits == 1, "An initial overlapping ship is hit once rather than ignored or repeatedly pierced")
	await prepare(game, 2)
	var missile := EnemyMissile.new()
	game.world.add_child(missile)
	missile.global_position = Vector3(0, 0, -15)
	await physics_frame
	await physics_frame
	fire_tick(game)
	check(not missile.active and game.flight.interceptions == 1 and game.flight.hits == 1, "The wider beam intercepts actual Area3D missile colliders")
	await prepare(game, 1)
	target = fighter(game, Vector3(0, 0, -90))
	await physics_frame
	await physics_frame
	fire_tick(game)
	game._finish_phase()
	game._advance_sequence(0.2)
	check(target.armor == 12 and game.flight.hits == 0 and game.plasma_bolts[0].travelled > 100 and not game.plasma_bolts[0].dangerous, "A real phase checkpoint lets plasma drift onward without post-checkpoint damage or rewards")
	await prepare(game, 2)
	fire_tick(game)
	game._finish_phase()
	check(not game.tachyon_beam.visible, "A real phase checkpoint extinguishes the continuous beam")
	game._clear_stage()
	check(game.plasma_bolts.is_empty() and game.tachyon_beam == null, "Stage cleanup releases advanced-primary effects")
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
