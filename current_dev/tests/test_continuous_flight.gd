extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for orbital in [false, true]:
		var boss := BossEncounter.new()
		boss.orbital = orbital
		root.add_child(boss)
		boss.configure_pursuit(FlightState.rail_frame(800), 800)
		var before: Vector3 = boss.global_position
		var starting_range: float = boss.pursuit_range
		for i in range(600):
			var pilot: Vector3 = FlightState.rail_point(800 + (i + 1) * FlightState.SPEED / 60.0)
			boss.advance(1.0 / 60.0, pilot, Vector3.FORWARD * FlightState.SPEED)
		check(boss.global_position.distance_to(before) > 80.0, "Boss physically moves away rather than remaining stationary")
		check(boss.pursuit_range < starting_range - 200.0 and boss.pursuit_range > 100.0, "Boss is approached gradually and maintains a safe pursuit distance")
		boss.queue_free()
	var scene := MissionWorld.new()
	root.add_child(scene)
	scene.build("orbit", Transform3D.IDENTITY)
	var behind: int = 0
	var close: bool = true
	for target in scene.targets:
		if target.global_position.z > 0:
			behind += 1
		close = close and target.global_position.length() < 140
	check(behind >= 2 and close, "Dogfight fighters appear nearby from multiple bearings, including behind")
	var director := FlightDirector.new()
	director.begin_phase("orbit", Transform3D.IDENTITY)
	var before_basis: Basis = director.frame.basis
	director.advance("orbit", 1.0 / 60.0, 0, 0, scene.targets)
	var turned: float = before_basis.get_rotation_quaternion().angle_to(director.frame.basis.get_rotation_quaternion())
	check(turned <= FlightDirector.TURN_RATE / 60.0 + 0.0001, "Flight computer turns smoothly instead of snapping to targets")
	var first: EnemyFighter = director.tracked
	if first != null:
		first.destroyed = true
		director.advance("orbit", 1.0 / 60.0, 0, 0, scene.targets)
		check(director.tracked != first and is_instance_valid(director.tracked), "Flight computer acquires another live fighter after a kill")
	else:
		check(false, "Flight computer acquires an initial live fighter")
	check(FlightDirector.radar_position(Transform3D.IDENTITY, Vector3(-20, 0, -50)).x < 0 and FlightDirector.radar_position(Transform3D.IDENTITY, Vector3(0, 0, 50)).y > 0, "Radar includes correct left and rear bearings")
	scene.queue_free()
	var belt := MissionWorld.new()
	root.add_child(belt)
	belt.build("asteroids", Transform3D.IDENTITY)
	var minimum_clearance: float = INF
	var iron_count: int = 0
	var iron_intact: bool = true
	var slowest_spin: float = INF
	var fastest_spin: float = 0.0
	var fixed_colliders: bool = true
	for item in belt.targets:
		var rock := item as Asteroid
		var body: Transform3D = rock.global_transform
		rock.animate(0.0)
		var initial_rotation: Quaternion = rock.appearance.basis.orthonormalized().get_rotation_quaternion()
		rock.animate(1.0)
		var spin: float = initial_rotation.angle_to(rock.appearance.basis.orthonormalized().get_rotation_quaternion())
		slowest_spin = minf(slowest_spin, spin)
		fastest_spin = maxf(fastest_spin, spin)
		fixed_colliders = fixed_colliders and rock.global_transform.is_equal_approx(body) and rock.appearance.basis.get_scale().is_equal_approx(Vector3.ONE * rock.radius)
		for step in range(-15, 16):
			var path_point: Vector3 = FlightDirector.asteroid_point(rock.travel + step)
			minimum_clearance = minf(minimum_clearance, path_point.distance_to(rock.course_position) - rock.collision_radius() - 0.6)
		if rock.indestructible:
			iron_count += 1
			rock.receive_hit(9999)
			iron_intact = iron_intact and not rock.destroyed and rock.collision_layer == 3
	check(minimum_clearance > 1.8 and minimum_clearance < 3.5, "Nominal autopilot route clears every rock while producing close passes (%.2fm)" % minimum_clearance)
	check(iron_count > 0, "Asteroid field includes indestructible obstacles")
	check(iron_intact, "All iron-core rocks survive weapons and remain collidable")
	check(slowest_spin < 0.1 and fastest_spin > 0.5 and fastest_spin > slowest_spin * 4, "Physical asteroids include clearly slow and fast tumblers")
	check(fixed_colliders, "Varied tumbling leaves collision centers and model sizes unchanged")
	var rock := belt.targets[0] as Asteroid
	var section: Transform3D = FlightDirector.asteroid_frame(rock.travel)
	var relative: Vector3 = section.affine_inverse() * rock.course_position
	check(absf(relative.x) < FlightState.CORRIDOR.x and absf(relative.y) < FlightState.CORRIDOR.y, "Manual mouse offset can still steer into a near-passing rock")
	belt.queue_free()
	var flight := FlightState.new()
	flight.duration = INF
	flight.distance = 1000
	flight.advance(1.0, false)
	check(is_equal_approx(flight.distance, 1042), "Phase clock changes do not reset accumulated canyon travel")
	for fps in [30, 60, 120]:
		var path := FlightDirector.new()
		var start := Transform3D(Basis.IDENTITY, Vector3(20, 12, -800))
		path.frame = start
		var end := Transform3D(Basis.IDENTITY, start.origin + Vector3(0, 560, -620))
		path.begin_transition(end, 10, 42, 24)
		var previous: Vector3 = path.frame.origin
		var largest: float = 0.0
		for _i in range(fps * 10 + 1):
			path.advance_transition(1.0 / fps)
			largest = maxf(largest, previous.distance_to(path.frame.origin))
			previous = path.frame.origin
		check(path.frame.origin.is_equal_approx(end.origin) and largest < 140.0 / fps, "Ascent is continuous and reaches the orbital endpoint at %d FPS" % fps)
	await _test_game_sequences()
	await process_frame
	print("CONTINUOUS_FLIGHT_FAILURES=", failures)
	quit(failures)

func _test_game_sequences() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.start_flight()
	var tower: DestructibleTower = game.towers[0]
	var base: Vector3 = tower.to_global(Vector3(0, -4.5, 1.5))
	var armor: int = tower.armor
	game._strike({"collider": tower, "position": tower.to_global(Vector3(0, 4, 2))}, 1)
	check(tower.armor == armor - 1, "A crown strike damages the whole tower")
	for _i in range(6):
		game._strike({"collider": tower, "position": base}, 1)
	check(tower.destroyed and tower.collision_layer == 0 and flight_count(game) == 1, "Several foundation hits start one tower collapse and remove its collision")
	tower.advance(0.8)
	check(tower.pivot.basis.get_rotation_quaternion().get_angle() > 0.1 and tower.pivot.visible, "Tower visibly topples along the shot direction before fragmenting")
	game.pause_flight()
	var frozen: float = tower.collapse_time
	game._physics_process(0.5)
	check(tower.collapse_time == frozen, "Pause freezes tower collapse")
	tower.advance(0.6)
	check(tower.has_fractured and not tower.pivot.visible and not game.debris.is_empty(), "Tower collapse releases animated structural fragments")
	var save_path: String = "user://continuous-test-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(save_path)
	game.campaign = CampaignState.new()
	game.campaign.phase = "docking"
	game.is_campaign = true
	await game._load_phase()
	check(game.mode == game.Mode.TRANSITION and not game.docked, "Docking checkpoint starts an approach, not the market")
	check(game.hud.transit_seconds == 8, "Docking checkpoint counts only approach and docking")
	for _i in range(120):
		game._physics_process(1.0 / 60.0)
	game.pause_flight()
	var camera_before: Transform3D = game.camera.global_transform
	var station_clock: float = game.station.age
	game._physics_process(1.0)
	check(game.camera.global_transform.is_equal_approx(camera_before), "Pause freezes automatic approach motion")
	check(game.station.age == station_clock and game.hud.transit_seconds == 6, "Pause freezes docking countdown and station equipment")
	game.resume_flight()
	for _i in range(1100):
		if game.mode == game.Mode.MARKET:
			break
		game._physics_process(1.0 / 60.0)
	check(game.mode == game.Mode.MARKET and game.docked and game.station.to_local(game.camera.global_position).z < 0, "Market opens only after the flight computer enters the hangar")
	station_clock = game.station.age
	game._process(0.5)
	check(game.station.age > station_clock, "Station equipment keeps moving while the market is open")
	check(game.sequence_log.has("station_approach") and game.sequence_log.has("docking"), "Station alignment precedes final docking")
	game.campaign.phase = "asteroids"
	await game._load_phase()
	game.pause_flight()
	var belt_clock: float = game.mission_world.elapsed
	var rock_before: Basis = game.targets[0].appearance.basis
	game._physics_process(1.0)
	check(game.mission_world.elapsed == belt_clock and game.targets[0].appearance.basis.is_equal_approx(rock_before), "Pause freezes both foreground and backdrop tumbling clocks")
	game.resume_flight()
	game.flight.elapsed = 60.0
	game.flight.distance = FlightDirector.ASTEROID_SPEED * 60.0
	game.director.advance("asteroids", 0.0, game.flight.distance, 60.0, game.targets)
	game._update_camera()
	var retained_belt: Node3D = game.world
	var last_rock: Asteroid = game.targets[-1]
	var rock_position: Vector3 = last_rock.global_position
	var exit_position: Vector3 = game.camera.global_position
	game._finish_phase()
	check(game.hud.transit_seconds == 21, "Belt exit counts all four legs to market")
	check(game.world == retained_belt and game.station != null and is_instance_valid(last_rock), "Station appears in the existing belt scene without removing the last asteroids")
	var station_frame: Transform3D = game.station.global_transform
	var previous_frame: Transform3D = game.camera.global_transform
	var maximum_step: float = 0.0
	var maximum_turn: float = 0.0
	var upward_pitch: float = 0.0
	for _i in range(1100):
		if game.mode == game.Mode.MARKET:
			break
		game._physics_process(1.0 / 30.0)
		var current: Transform3D = game.camera.global_transform
		maximum_step = maxf(maximum_step, previous_frame.origin.distance_to(current.origin))
		maximum_turn = maxf(maximum_turn, previous_frame.basis.get_rotation_quaternion().angle_to(current.basis.get_rotation_quaternion()))
		upward_pitch = maxf(upward_pitch, -current.basis.z.y)
		previous_frame = current
	check(game.mode == game.Mode.MARKET and game.sequence_log.has("belt_climb") and upward_pitch > 0.3 and game.camera.global_position.y > exit_position.y + 400, "The ship pulls up out of the belt before automatically docking (rise %.1fm / pitch %.2f)" % [game.camera.global_position.y - exit_position.y, upward_pitch])
	check(maximum_step < 4.0 and maximum_turn < 0.08, "Belt exit, climb, approach, and docking have no camera jump or snap at 30 FPS (%.2fm / %.3frad)" % [maximum_step, maximum_turn])
	check(game.world == retained_belt and last_rock.global_position.is_equal_approx(rock_position) and game.station.global_transform.is_equal_approx(station_frame), "Asteroids and station remain in one persistent scene throughout docking")
	game.campaign = CampaignState.new()
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	for part in [game.boss.parts[0], game.boss.parts[1], game.boss.core]:
		part.unlocked = true
		game._strike({"collider": part, "position": part.aim_point()}, part.armor)
	var orbital_start: Vector3 = game.camera.global_position
	var old_world: Node3D = game.world
	game._finish_phase()
	check(game.hud.transit_seconds == 15, "Orbital victory includes the whole belt transfer")
	var preview: MissionWorld = game.approaching_belt
	var first_rock: Asteroid = preview.targets[0]
	var prepared_position: Vector3 = first_rock.global_position
	var nearest: float = INF
	for target in preview.targets:
		nearest = minf(nearest, orbital_start.distance_to(target.global_position) - target.collision_radius())
	for background in preview.backdrop.rocks:
		nearest = minf(nearest, orbital_start.distance_to(background["position"]) - background["radius"] * 1.25)
	check(nearest > VectorArt.VIEW_DISTANCE, "The approaching belt is prepared beyond draw range instead of appearing beside the pilot")
	game.pause_flight()
	var preview_clock: float = preview.visual_time
	game._physics_process(3.0)
	check(preview.visual_time == preview_clock and game.camera.global_position.is_equal_approx(orbital_start), "Pause freezes the orbital pull-up and preview asteroid tumbling")
	game.resume_flight()
	previous_frame = game.camera.global_transform
	maximum_step = 0.0
	maximum_turn = 0.0
	upward_pitch = 0.0
	var visible_before_entry: int = 0
	for _i in range(750):
		if game.mode == game.Mode.FLIGHT:
			break
		game._physics_process(1.0 / 30.0)
		var current: Transform3D = game.camera.global_transform
		maximum_step = maxf(maximum_step, previous_frame.origin.distance_to(current.origin))
		maximum_turn = maxf(maximum_turn, previous_frame.basis.get_rotation_quaternion().angle_to(current.basis.get_rotation_quaternion()))
		upward_pitch = maxf(upward_pitch, -current.basis.z.y)
		previous_frame = current
		if game.sequence == "belt_transfer" and game.sequence_time >= FlightDirector.BELT_TRANSFER_DURATION - 2:
			visible_before_entry = maxi(visible_before_entry, visible_belt_rocks(game.camera, preview))
	check(game.mode == game.Mode.FLIGHT and game.campaign.phase == "asteroids" and game.camera.global_position.y > orbital_start.y + 500 and upward_pitch > 0.3, "Orbital victory leads through a real rising approach into the asteroid field")
	check(maximum_step < 5 and maximum_turn < 0.08, "Orbital pull-up has no camera jump or heading snap at 30 FPS (%.2fm / %.3frad)" % [maximum_step, maximum_turn])
	check(game.world == preview and game.mission_world == preview and first_rock.global_position.is_equal_approx(prepared_position) and game.retired_world == old_world, "Belt activation reuses the already-visible scene and rock positions")
	check(visible_before_entry >= 20, "Asteroids already occupy the forward canopy before handoff (%d visible centers)" % visible_before_entry)
	check(game.flight.elapsed == 0 and preview.elapsed == 0 and preview.pirates.is_empty() and is_equal_approx(preview.visual_time, 15), "The full sixty-second mining phase starts only after the 15-second climb; tumbling never resets")
	var rotation_before: Quaternion = first_rock.appearance.basis.orthonormalized().get_rotation_quaternion()
	game.cursor = game.get_viewport().get_visible_rect().size * 0.5
	game._physics_process(1.0 / 30.0)
	var rotation_after: Quaternion = first_rock.appearance.basis.orthonormalized().get_rotation_quaternion()
	check(rotation_before.angle_to(rotation_after) < 0.03 and game.flight.impacts == 0, "First active belt frame preserves asteroid orientation and safe entry")
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	game._finish_phase()
	check(game.hud.transit_seconds == 7, "Ground victory includes clearance and ascent")
	for tick in range(100):
		game._physics_process(0.07)
	check(game.mode == game.Mode.FLIGHT and game.campaign.phase == "orbit" and game.flight.elapsed == 0, "Seven-second ground victory hands off to fresh orbital gameplay")
	DirAccess.remove_absolute(save_path)
	game.queue_free()
	await process_frame

func flight_count(game: Node3D) -> int:
	return game.flight.towers_destroyed

func visible_belt_rocks(camera: Camera3D, belt: MissionWorld) -> int:
	var viewport: Vector2 = root.get_visible_rect().size
	var canopy := Rect2(viewport * Vector2(0.1, 0.25), viewport * Vector2(0.8, 0.35))
	var count: int = 0
	for rock in belt.backdrop.rocks:
		var at: Vector3 = rock["position"]
		if not camera.is_position_behind(at) and camera.global_position.distance_to(at) < camera.far and canopy.has_point(camera.unproject_position(at)):
			count += 1
	return count

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
