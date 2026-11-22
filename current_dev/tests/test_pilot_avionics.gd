extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check_maneuvers()
	check_reactor()
	check_steering()
	await check_sensor_picture()
	print("PILOT_AVIONICS_FAILURES=", failures)
	quit(failures)

func check_maneuvers() -> void:
	var pilot := FlightState.new()
	pilot.configure_campaign(CampaignState.new())
	pilot.aim.x = -0.8
	check(pilot.request_barrel_roll().is_empty(), "A ready pilot starts a roll toward the pointer")
	check(pilot.deflect_projectile() and not pilot.impact("LASER GATE"), "A roll deflects fire and evades an external hit")
	check(pilot.impact("ATTACHED PARASITE", 2, true), "Internal hull damage still applies")
	pilot.advance(FlightState.ROLL_DURATION * 0.5, false)
	check(is_equal_approx(pilot.roll_bank(false), -PI) and absf(pilot.roll_bank(true)) < 0.2, "Roll reaches inverted attitude and respects reduced motion")
	var frozen := pilot.roll_remaining
	pilot.advance(10.0, false, false)
	check(pilot.roll_remaining == frozen, "Pause freezes the roll")
	var successor := FlightState.new()
	successor.inherit_evasion(pilot)
	check(successor.roll_remaining == pilot.roll_remaining and successor.roll_side == pilot.roll_side, "Roll carries through a continuous handoff")
	pilot.advance(FlightState.ROLL_DURATION * 0.5, false)
	check(pilot.roll_bank(false) == 0.0 and not pilot.deflect_projectile() and not pilot.request_evasion().is_empty(), "Full rotation ends immunity and shares the dash capacitor")
	pilot.advance(FlightState.EVADE_COOLDOWN, false)
	check(pilot.request_evasion().is_empty(), "Dash recharges normally after a roll")

func check_reactor() -> void:
	var state := FlightState.new()
	state.configure_campaign(CampaignState.new())
	state.shields = 30.0
	state.request_shield_surge()
	check(is_equal_approx(state.shields, 53.0) and state.heat == FlightState.SURGE_HEAT and state.surge_remaining > 0.0, "Shield surge trades reactor heat for shields")
	state.request_shield_surge()
	check(is_equal_approx(state.shields, 53.0), "Surge bank cannot discharge twice")
	for fps in [30, 120]:
		var gun := FlightState.new()
		gun.configure_campaign(CampaignState.new())
		gun.heat_governor = true
		for i in range(fps * 15):
			gun.advance(1.0 / fps, true)
		check(gun.shots > 50 and gun.overheat_events == 0, "Thermal governor cycles live bursts at %d Hz" % fps)

func check_steering() -> void:
	var state := FlightState.new()
	state.configure_campaign(CampaignState.new())
	state.aim = Vector2(0, 0.7)
	state.strafe = Vector2.RIGHT
	state.advance(0.5, false)
	check(state.offset.x > 45.0 and state.offset.y < -4, "Independent thrusters preserve aim on the other axis")
	state.strafe = Vector2.ZERO
	state.precision_hold = true
	var held := state.offset
	state.aim = Vector2(-1.0, -1.0)
	state.advance(1.0, false)
	check(state.offset.is_equal_approx(held), "Precision clutch holds the flight line while the guns traverse")
	var director := FlightDirector.new()
	director.begin_phase("orbit", Transform3D.IDENTITY)
	for i in range(60):
		director.advance("orbit", 1.0 / 60, 0.0, i / 60.0, [], Vector2.RIGHT)
	check(director.frame.origin.x > 9.0 and -director.frame.basis.z.x > 0.8, "A manual turn changes orbital heading and trajectory")

func check_sensor_picture() -> void:
	var pilot := Camera3D.new()
	root.add_child(pilot)
	var state := FlightState.new()
	var sensors := FlightDeckSensors.new()
	var missile := EnemyMissile.new()
	missile.position = Vector3(0, 0, -100)
	missile.direction = Vector3.BACK
	root.add_child(missile)
	var pickup := MineralPickup.new()
	pickup.position = Vector3(10, 18, 28)
	root.add_child(pickup)
	var rock := Asteroid.new()
	root.add_child(rock)
	rock.global_position = Vector3(0, 0, -24)
	var targets: Array[RangeTarget] = [rock]
	var missiles: Array[EnemyMissile] = [missile]
	var pickups: Array[MineralPickup] = [pickup]
	sensors.scan(pilot, state, targets, missiles, pickups, [], null, Vector2.ZERO)
	check(sensors.returns.size() == 3 and sensors.returns[0].kind == &"missile", "The scanner distinguishes ordnance, salvage and belt hazards")
	check(sensors.intercept_seconds < 1.0 and sensors.collision_seconds < 1.0, "Collision prediction distinguishes two independent imminent threats")
	check(sensors.returns.any(func(e: Dictionary) -> bool: return e.kind == &"salvage" and e.point.y > 0.0), "A pickup behind the cockpit appears aft on the tactical scope")
	missile.diverted = true
	sensors.cycle_range()
	sensors.scan(pilot, state, targets, missiles, pickups, [], null, Vector2.ZERO)
	check(sensors.range_m == 720 and is_inf(sensors.intercept_seconds), "Range switch refreshes the scan and diverted ordnance drops out")
	var motion := Vector3(32, 4, 0)
	var rel := Vector3(0, 0, -300)
	var t := FlightDeckSensors.plasma_intercept(rel, motion)
	check(t > 0 and is_equal_approx((rel + t * motion).length(), PlasmaBolt.SPEED * t), "Gunsight lead matches the actual plasma velocity")
	for node in [rock, pickup, missile, pilot]:
		node.queue_free()
	await process_frame

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)
