extends SceneTree

var failures: int = 0

func _initialize() -> void:
	for fps in [30, 60, 120]:
		var state := FlightState.new()
		state.aim = Vector2(2.0, -2.0)
		for _i in range(fps * 10):
			state.advance(1.0 / float(fps), true)
		check(is_equal_approx(state.distance, 420.0), "Travel at %d FPS" % fps)
		check(state.offset.distance_to(FlightState.CORRIDOR) < 0.001, "Bounded steering at %d FPS" % fps)
		check(state.shots == 80, "Eight shots per second at %d FPS (got %d)" % [fps, state.shots])
	var campaign := CampaignState.new()
	for phase: String in ["asteroids", "ground_boss", "orbit_boss", "orbit"]:
		campaign.phase = phase
		var pilot := FlightState.new()
		pilot.configure_campaign(campaign)
		for side: float in [-1.0, 1.0]:
			pilot.aim = Vector2(side, -1.0)
			pilot.advance(2.0, false)
			var reach := 12.0 if phase == "orbit" else 60.0
			check(pilot.offset.distance_to(Vector2(side * reach, 7.2)) < 0.001, "%s reaches its steering boundary on side %.0f" % [phase, side])
	var paused := FlightState.new()
	var steering := FlightState.new()
	steering.aim = Vector2(1.0, -1.0)
	steering.advance(1.0, false)
	var original_response: Vector2 = Vector2(6.0, 3.6) * (1.0 - exp(-4.5))
	check(steering.offset.x >= original_response.x * 2.0 and steering.offset.y >= original_response.y * 2.0, "Mouse movement produces at least twice the original steering in both axes")
	paused.advance(0.5, true)
	paused.impact()
	var snapshot: Array = [paused.elapsed, paused.offset, paused.shots, paused.shields, paused.impact_cooldown, paused.fire_cooldown]
	paused.advance(5.0, true, false)
	check(snapshot == [paused.elapsed, paused.offset, paused.shots, paused.shields, paused.impact_cooldown, paused.fire_cooldown], "Pause freezes all simulation state")
	check(not paused.impact(), "One contact cannot drain shields every physics tick")
	paused.advance(2.1, false)
	check(paused.impact(), "A later distinct impact is counted")
	var trainee := FlightState.new()
	trainee.impact("SHIP COLLISION", 18, true)
	check(trainee.hull == 82 and trainee.shields == 100, "Training contact demonstrates hull damage through charged shields")
	trainee.impact("SHIP COLLISION", 100, true)
	trainee.impact("MISSILE", 18)
	check(trainee.hull == 1 and trainee.shields == 82, "Training crashes remain nonlethal while weapon impacts still exhaust shields first")
	var completed := FlightState.new()
	completed.advance(FlightState.DURATION - 0.005, false)
	completed.advance(1.0 / 60.0, false)
	check(completed.elapsed == FlightState.DURATION, "Course ends exactly at active duration")
	var distance: float = completed.distance
	completed.advance(5.0, true)
	check(completed.distance == distance and completed.shots == 0, "Completed course cannot keep firing or moving")
	for travel in [0.0, 300.0, 1000.0]:
		var frame := FlightState.rail_frame(travel)
		check(frame.basis.is_conformal() and is_equal_approx(frame.basis.determinant(), 1.0), "Rail frame preserves corridor scale at %.0fm" % travel)
	var reference_shots: int = -1
	var reference_heat: float = 0.0
	for fps in [30, 60, 120]:
		var thermal := FlightState.new()
		thermal.training = false
		for _i in range(fps * 10):
			thermal.advance(1.0 / fps, true)
		if reference_shots < 0:
			reference_shots = thermal.shots
			reference_heat = thermal.heat
		check(thermal.shots == reference_shots and absf(thermal.heat - reference_heat) < 0.001 and thermal.overheat_events > 0, "Live heat and shot cadence agree at %d FPS" % fps)
	var vent := FlightState.new()
	vent.training = false
	vent.heat = 100
	vent.overheat_remaining = 2
	check(vent.advance_primary(1.999, true) == 0 and vent.advance_primary(0.001, true) == 0 and vent.advance_primary(0.001, true) == 1, "Overheat blocks firing for exactly two seconds, then permits a shot")
	vent.heat = 75
	vent.overheat_remaining = 1.5
	vent.advance(5, true, false)
	check(vent.heat == 75 and vent.overheat_remaining == 1.5, "Pause freezes heat and the overheat countdown")
	vent.zero_heat = true
	check(vent.advance_primary(0.2, true) > 0 and vent.heat == 0 and vent.overheat_remaining == 0, "Zero-heat testing bypass clears thermal lockout")
	var balanced := FlightState.new()
	var weapons := FlightState.new()
	var cooled := FlightState.new()
	for item in [balanced, weapons, cooled]:
		item.training = false
	weapons.power_mode = "weapons"
	cooled.heat_sink_level = 2
	balanced.advance(1, true)
	weapons.advance(1, true)
	cooled.advance(1, true)
	check(weapons.shots > balanced.shots and weapons.heat < balanced.heat, "Weapons power increases fire rate while reducing heat buildup")
	check(cooled.shots == balanced.shots and cooled.heat < balanced.heat, "Cooling vents reduce heat without reducing weapon output")
	var sustained := FlightState.new()
	var bursts := FlightState.new()
	sustained.training = false
	bursts.training = false
	var resting: bool = false
	for _i in range(1200):
		sustained.advance(1.0 / 60.0, true)
		if bursts.heat > 70:
			resting = true
		elif bursts.heat < 20:
			resting = false
		bursts.advance(1.0 / 60.0, not resting)
	check(bursts.overheat_events == 0 and bursts.shots > sustained.shots, "Controlled bursts outperform overheating during sustained combat")
	var shields := FlightState.new()
	shields.shields = 0
	shields.power_mode = "shields"
	shields.advance(1, false)
	var normal_shields := FlightState.new()
	normal_shields.shields = 0
	normal_shields.advance(1, false)
	check(shields.shields > normal_shields.shields, "Shield routing improves regeneration between hits")
	var engines := FlightState.new()
	engines.power_mode = "engines"
	engines.aim = Vector2.ONE
	engines.advance(0.1, false)
	var normal_engines := FlightState.new()
	normal_engines.aim = Vector2.ONE
	normal_engines.advance(0.1, false)
	check(engines.offset.length() > normal_engines.offset.length(), "Engine routing improves horizontal and vertical dodge response")
	for fps in [30, 60, 120]:
		var dash := FlightState.new()
		dash.offset.x = 8.0
		dash.aim = Vector2.ONE
		check(dash.request_evasion().is_empty(), "Evasive maneuver starts at %d FPS" % fps)
		var time: float = 0.0
		while time < FlightState.EVADE_DURATION - 0.000001:
			var step: float = minf(1.0 / fps, FlightState.EVADE_DURATION - time)
			dash.advance(step, false)
			time += step
		check(is_equal_approx(dash.offset.x, -FlightState.EVADE_EDGE) and dash.evade_remaining == 0.0 and absf(dash.evade_bank) < 0.00001, "Dash reaches the opposite side and levels out at %d FPS" % fps)
		check(not dash.deflect_projectile() and not dash.request_evasion().is_empty(), "Deflection ends with the maneuver; capacitor prevents spamming at %d FPS" % fps)
	var dash := FlightState.new()
	dash.request_evasion()
	dash.advance(0.2, false)
	var dash_snapshot: Array = [dash.evade_remaining, dash.evade_cooldown, dash.offset, dash.evade_bank]
	dash.advance(3.0, false, false)
	check(dash_snapshot == [dash.evade_remaining, dash.evade_cooldown, dash.offset, dash.evade_bank], "Pause freezes maneuver motion and capacitor recharge")
	var inherited := FlightState.new()
	inherited.offset = dash.offset
	inherited.inherit_evasion(dash)
	check(inherited.evade_remaining == dash.evade_remaining and inherited.evade_cooldown == dash.evade_cooldown and inherited.evade_bank == dash.evade_bank, "Phase handoff preserves an active maneuver and its bank")
	dash.advance(5.8, false)
	check(dash.request_evasion().is_empty(), "Capacitor permits another maneuver after six active seconds")
	print("FLIGHT_TEST_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
