extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var reference_exposure: float = -1.0
	for fps in [30, 45, 60]:
		var vent := HeatVent.new()
		root.add_child(vent)
		var exposure: float = 0.0
		for _i in range(fps):
			exposure += vent.advance(1.0 / fps, Vector3(0, 10, 0), Vector3(0, 10, 0))
		check(exposure == 0 and not vent.plume.visible, "Ground vent warns without applying heat at %d FPS" % fps)
		for _i in range(fps * 3):
			exposure += vent.advance(1.0 / fps, Vector3(0, 10, 0), Vector3(0, 10, 0))
		if reference_exposure < 0:
			reference_exposure = exposure
		check(absf(exposure - HeatVent.ERUPTION * HeatVent.HEAT_PER_SECOND) < 1 and absf(exposure - reference_exposure) < 1, "Vent heat follows active exposure rather than update count at %d FPS" % fps)
		vent.age = 2.0
		check(vent.advance(0.1, Vector3(6, 10, 0), Vector3(6, 10, 0)) == 0 and vent.advance(0.1, Vector3(0, 21, 0), Vector3(0, 21, 0)) == 0, "Flying around or above the plume avoids external heat")
		vent.age = 2.0
		var swept: float = vent.advance(0.5, Vector3(0, 10, 10), Vector3(0, 10, -10))
		check(swept > 15 and swept < 30, "Fast plume crossings integrate only the time inside the hazard")
		vent.queue_free()
	var volcano := HeatVent.new()
	root.add_child(volcano)
	volcano.age = 0.2
	volcano.advance(0, Vector3.ZERO, Vector3.ZERO)
	var early_flow: float = volcano.volcano.lava_material.get_shader_parameter("flow_amount")
	volcano.age = 3.0
	volcano.advance(0, Vector3.ZERO, Vector3.ZERO)
	check(volcano.volcano.lava_material.get_shader_parameter("flow_amount") > early_flow and volcano.plume.visible, "Lava advances down the slopes as the active eruption develops")
	volcano.age = 5.99
	volcano.advance(0, Vector3.ZERO, Vector3.ZERO)
	check(not volcano.plume.visible and volcano.volcano.lava_material.get_shader_parameter("activity") < 0.01, "The hot jet ends on schedule and lava cools before the next cycle")
	await physics_frame
	await physics_frame
	var cone_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 2, 8), Vector3(0, 2, -8), 1)
	var contact: Dictionary = volcano.get_world_3d().direct_space_state.intersect_ray(cone_ray)
	check(contact.get("collider") == volcano.cone_body, "The visible volcanic cone is real solid cover, even between eruptions")
	volcano.queue_free()
	var flight := FlightState.new()
	flight.training = false
	flight.heat = 95
	check(flight.add_external_heat(10) and flight.heat == 100 and flight.overheat_remaining == 2.0, "External heat triggers the normal exact two-second weapon lock")
	flight.advance_primary(1.0, false)
	check(not flight.add_external_heat(100) and flight.overheat_remaining == 1.0, "A continuing heat hazard cannot reset an active vent lock forever")
	flight.advance_primary(1.0, false)
	check(flight.advance_primary(0.001, true) == 1, "Primary firing resumes when environmental overheat clears")
	flight.zero_heat = true
	flight.heat = 0
	check(not flight.add_external_heat(50) and flight.heat == 0, "Zero-heat testing also bypasses environmental heat")
	flight.training = true
	flight.zero_heat = false
	check(not flight.add_external_heat(50) and flight.heat == 0, "Training retains unlimited heat-free practice")
	for fps in [30, 45, 60]:
		var emitter := ThermalEmitter.new()
		root.add_child(emitter)
		var sweep := ThermalSweep.new()
		sweep.emitter = emitter
		sweep.aim = Basis.IDENTITY
		root.add_child(sweep)
		var hits: int = 0
		for _i in range(fps):
			if sweep.advance(1.0 / fps, Vector3(0, 0, -100), Vector3(0, 0, -100), 0.6):
				hits += 1
		check(hits == 0 and not sweep.beam.visible, "Thermal projector warns before damaging the pilot at %d FPS" % fps)
		for _i in range(fps * 4):
			if sweep.advance(1.0 / fps, Vector3(0, 0, -100), Vector3(0, 0, -100), 0.6):
				hits += 1
		check(hits == 1 and sweep.complete(), "A full thermal sweep hits at most once and expires at %d FPS" % fps)
		sweep.queue_free()
		var dodged := ThermalSweep.new()
		dodged.emitter = emitter
		dodged.aim = Basis.IDENTITY
		root.add_child(dodged)
		check(not dodged.advance(5.0, Vector3(0, 4, -100), Vector3(0, 4, -100), 0.6), "A vertical dodge clears the complete sweeping beam")
		dodged.queue_free()
		var interrupted := ThermalSweep.new()
		interrupted.emitter = emitter
		interrupted.aim = Basis.IDENTITY
		root.add_child(interrupted)
		emitter.receive_hit(emitter.armor)
		check(not interrupted.advance(5.0, Vector3(0, 0, -100), Vector3(0, 0, -100), 0.6) and interrupted.complete() and not interrupted.visible, "Destroying the projector immediately cancels its thermal sweep")
		interrupted.queue_free()
		emitter.queue_free()
	var boss := BossEncounter.new()
	boss.orbital = true
	root.add_child(boss)
	var launches: Array[int] = [0]
	boss.sweep_requested.connect(func(_emitter: ThermalEmitter) -> void: launches[0] += 1)
	boss.advance(4.1, Vector3(0, 0, 120), Vector3.ZERO)
	check(launches[0] == 1 and not boss.core.unlocked, "Orbital boss uses its projector independently of shield-generator progression")
	boss.thermal_emitter.receive_hit(boss.thermal_emitter.armor)
	boss.advance(12.0, Vector3(0, 0, 120), Vector3.ZERO)
	check(launches[0] == 1 and not boss.defeated() and boss.core.unlocked, "Disabling the thermal weapon stops future sweeps and exposes the reactor")
	boss.queue_free()
	await process_frame
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.hud.campaign = game.campaign
	game.flight.configure_campaign(game.campaign)
	var emitter := ThermalEmitter.new()
	game.add_child(emitter)
	game.camera.global_position = Vector3(0, 0, -100)
	game.mode = game.Mode.FLIGHT
	game._start_thermal_sweep(emitter)
	game.pause_flight()
	game._physics_process(3.0)
	check(game.thermal_sweeps[0].age == 0 and game.flight.shields == 100, "Pause freezes beam warnings and thermal damage")
	game.thermal_sweeps[0].aim = Basis.IDENTITY
	game._advance_thermal_hazards(4.7, game.camera.global_position, game.camera.global_position)
	check(game.flight.shields == 100 - ThermalSweep.DAMAGE and game.flight.heat == ThermalSweep.HEAT, "An actual thermal collision applies shield damage and weapon heat")
	game._clear_stage()
	check(game.thermal_sweeps.is_empty() and game.heat_vents.is_empty(), "Phase cleanup removes all thermal hazards")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("THERMAL_HAZARDS_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

