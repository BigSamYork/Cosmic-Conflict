extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.campaign.phase = "launch"
	var path: String = "user://launch-test-%d.json" % OS.get_process_id()
	game.store = CampaignStore.new(path)
	check(game.store.save_game(game.campaign) == OK, "An unfinished station departure is a valid checkpoint")
	await game._load_phase()
	check(game.mode == game.Mode.TRANSITION and game.sequence == "station_departure" and game.station.to_local(game.camera.global_position).is_equal_approx(Vector3(0, 0, -12)), "Launch starts inside the station, not in the ground canyon")
	check((-game.camera.global_basis.z).dot(game.station.global_basis.z) > 0.999 and not game.sequence_log.has("launch_turn"), "The ship already faces the exit when departure begins, without an initial turn")
	await verify_route(game, 30)
	var saved := CampaignStore.new(path)
	check(saved.load_game() == OK and saved.state.phase == "ground", "Ground checkpoint is written only after atmospheric arrival")
	game.campaign = game._snapshot()
	game.campaign.dock(false)
	game._show_market()
	game.station.global_transform = Transform3D(Basis.from_euler(Vector3(0.08, 0.7, 0)), Vector3(2500, 950, -7200))
	game.camera.global_transform = game.station.global_transform * Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, -12))
	var station: Node3D = game.station
	var camera_before: Transform3D = game.camera.global_transform
	var station_before: Transform3D = station.global_transform
	game._depart_market(game.campaign.sector)
	check(game.station == station and game.station.global_transform.is_equal_approx(station_before) and game.camera.global_transform.is_equal_approx(camera_before), "Market departure preserves the existing station and camera exactly")
	await verify_route(game, 45)
	var launches: Array[int] = [0]
	var turret: GroundTurret = game.turrets[0]
	turret.reset()
	turret.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: launches[0] += 1)
	var pilot: Vector3 = game.director.ground_course * FlightState.rail_point(turret.travel - 100)
	turret.advance(1.0, pilot, -game.director.ground_course.basis.z * FlightState.SPEED)
	check(launches[0] == 1, "Ground turret tracking works on a translated and rotated destination course")
	game.campaign.phase = "launch"
	await game._load_phase()
	game.show_title()
	check(game.launch_approach == null and not game.launch_prepared and game.camera.far == VectorArt.VIEW_DISTANCE, "Returning to title removes hyperspace/planet effects and restores normal view distance")
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("LAUNCH_TEST_FAILURES=", failures)
	quit(failures)

func verify_route(game: Node3D, fps: int) -> void:
	var prepared: Node3D = game.world
	var target: RangeTarget = game.targets[0]
	var target_position: Vector3 = target.global_position
	var surface: Dictionary = game.launch_approach.ground_sources[0]
	var original_mesh: Mesh = surface["mesh"]
	check(surface["node"].mesh != original_mesh, "Arrival uses a subdivided foundation without modifying the cached gameplay mesh")
	var smoke: MultiMeshInstance3D = game.heat_vents[0].volcano.smoke
	var smoke_source: Material
	for source in game.launch_approach.ground_sources:
		if source["node"] == smoke:
			smoke_source = source["material"]
	check(smoke_source != null and smoke.material_override != smoke_source and smoke.material_override.get_shader_parameter("effect_opacity") == 0, "Instanced volcanic smoke fades with the prepared ground during descent")
	check(surface["node"].material_override != surface["material"] and surface["node"].material_override.get_shader_parameter("effect_opacity") == 0, "Prepared curved ground starts hidden without changing cached source materials")
	var paused: Dictionary = {}
	var previous: Transform3D = game.camera.global_transform
	var maximum_step: float = 0.0
	var maximum_warp_step: float = 0.0
	var maximum_turn: float = 0.0
	var turn_sequence: String = ""
	var phase_times: Dictionary = {}
	var warp_peak: float = 0.0
	var saw_warp: bool = false
	var early_planet: bool = false
	var saw_planet: bool = false
	var saw_departure_climb: bool = false
	var early_terrain: bool = false
	var curved_reveal: bool = false
	var countdown_correct := true
	var ticks := 0
	for _i in range(fps * 50):
		if game.mode == game.Mode.FLIGHT:
			break
		game.hud._process(0)
		countdown_correct = countdown_correct and game.hud.instrument_canvas.transit_seconds == 22 - ticks / fps
		ticks += 1
		if not paused.has(game.sequence):
			paused[game.sequence] = true
			var age: float = game.launch_approach.age
			game.pause_flight()
			game._physics_process(2.0)
			check(game.camera.global_transform.is_equal_approx(previous) and game.launch_approach.age == age, "Pause freezes %s at %d Hz" % [game.sequence, fps])
			game.resume_flight()
		var active_sequence: String = game.sequence
		phase_times[active_sequence] = phase_times.get(active_sequence, 0.0) + 1.0 / fps
		game._physics_process(1.0 / fps)
		var current: Transform3D = game.camera.global_transform
		if game.sequence == "warp_alignment":
			saw_departure_climb = saw_departure_climb or (current.origin.y > game.station.global_position.y + 400 and -current.basis.z.y > 0.3)
		if active_sequence == "hyperspace":
			maximum_warp_step = maxf(maximum_warp_step, previous.origin.distance_to(current.origin))
		else:
			maximum_step = maxf(maximum_step, previous.origin.distance_to(current.origin))
		var turn: float = previous.basis.get_rotation_quaternion().angle_to(current.basis.get_rotation_quaternion())
		if turn > maximum_turn:
			maximum_turn = turn
			turn_sequence = active_sequence + "@" + str(game.sequence_time)
		if game.launch_approach != null:
			warp_peak = maxf(warp_peak, game.launch_approach.streak_material.get_shader_parameter("effect_opacity"))
			saw_warp = saw_warp or game.launch_approach.streaks.visible
			early_planet = early_planet or (game.sequence != "planet_descent" and game.launch_approach.planet.visible)
			saw_planet = saw_planet or (game.sequence == "planet_descent" and game.launch_approach.planet.visible)
			early_planet = early_planet or game.sky_planet_visibility > 0
			var reveal: float = surface["node"].material_override.get_shader_parameter("effect_opacity") if surface["node"].material_override is ShaderMaterial else 1.0
			var height: float = (game.director.ground_course.affine_inverse() * current.origin).y
			early_terrain = early_terrain or (height >= LaunchApproach.TERRAIN_REVEAL_HEIGHT and reveal > 0.0)
			curved_reveal = curved_reveal or (reveal > 0.1 and game.launch_approach.curvature > 0.99)
		previous = current
	check(game.mode == game.Mode.FLIGHT and game.campaign.phase == "ground" and game.flight.elapsed == 0 and game.flight.duration == 90, "The complete launch leaves all ninety ground-combat seconds at %d Hz" % fps)
	check(saw_warp and paused.has("hyperspace") and paused.has("planet_descent"), "Launch includes visible hyperspace and atmospheric descent")
	check(absf(phase_times["hyperspace"] - 3.0) <= 1.0 / fps + 0.00001 and warp_peak > 0.99, "Hyperspace lasts three seconds (75 percent shorter) and reaches its full streak effect at %d Hz" % fps)
	check(countdown_correct and ticks == 22 * fps and not game.hud.autopilot, "Combiner counts down the entire 22-second launch across pauses and leg changes at %d Hz" % fps)
	check(saw_departure_climb, "The ship smoothly pulls up after clearing the station and before hyperspace")
	check(not early_planet and saw_planet, "The destination planet is absent before/during hyperspace and appears only after emergence")
	check(not early_terrain and curved_reveal, "Terrain waits until below 280m and first appears wrapped to the planet, not as a distant flat sheet")
	check(maximum_step < 1200.0 / fps and maximum_warp_step < 4800.0 / fps and maximum_turn < 2.0 / fps, "Station-to-ground camera stays continuous with faster hyperspace at %d Hz (ordinary %.2fm / warp %.2fm / %.3frad at %s)" % [fps, maximum_step, maximum_warp_step, maximum_turn, turn_sequence])
	check(game.world == prepared and target.global_position.is_equal_approx(target_position), "Arrival activates the already-visible terrain and targets without rebuilding")
	check(surface["node"].material_override == surface["material"] and surface["material"].albedo_color.a == 1, "Arrival restores the original opaque ground materials before combat")
	check(smoke.material_override == smoke_source, "Arrival restores the volcanic smoke shader without leaving a faded clone")
	check(surface["node"].mesh == original_mesh and surface["node"].extra_cull_margin == surface["margin"], "Active ground restores original mesh and culling bounds along with its exact collision layout")
	check(game.camera.global_transform.is_equal_approx(game.director.ground_course * FlightState.rail_frame(0)) and game.camera.far == VectorArt.VIEW_DISTANCE, "Ground flight begins at the exact descent endpoint and normal render distance")
	check(game.flight.impacts == 0 and game.campaign.stats["shots"] == 0, "Autopilot departure/descent neither takes combat hits nor fabricates weapon statistics")
	await physics_frame
	await physics_frame
	var probe := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = game.flight.collision_radius
	probe.shape = sphere
	probe.collision_mask = 1
	var clear: bool = true
	for vent in game.heat_vents:
		var travel: float = -vent.position.z
		probe.transform = Transform3D(Basis.IDENTITY, game.director.ground_course * FlightState.rail_point(travel - 8))
		probe.motion = game.director.ground_course * FlightState.rail_point(travel + 8) - probe.transform.origin
		clear = clear and game.get_world_3d().direct_space_state.cast_motion(probe)[0] == 1
	check(clear, "Every volcanic cone leaves the real nominal flight corridor clear on the destination course")
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
