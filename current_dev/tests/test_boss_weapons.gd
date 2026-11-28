extends SceneTree

const Attack := preload("res://scripts/boss_attack.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var rig := Node3D.new()
	rig.transform = Transform3D(Basis.from_euler(Vector3(0.2, -0.9, 0.16)), Vector3(55, 7, 215))
	root.add_child(rig)
	var weapon := BossTurret.new()
	rig.add_child(weapon)
	var hull := StaticBody3D.new()
	rig.add_child(hull)
	var pilot := rig.to_global(Vector3(0, 2, -93))
	# Each trajectory is fired down a transformed lane at two different tick
	# rates. A consistent dodge and stationary pilot must give opposite results.
	var tested := {}
	for sector: String in Attack.ARSENAL:
		for orbital in [false, true]:
			for stage in range(3):
				var pattern: int = Attack.ARSENAL[sector][int(orbital)][stage][1]
				if tested.has(pattern):
					continue
				tested[pattern] = true
				for fps in [20, 120]:
					for dodge in [false, true]:
						var attack := Attack.new()
						rig.add_child(attack)
						attack.configure(sector, orbital, stage, 0, weapon, hull, pilot)
						check(not attack.warning().is_empty() and attack.guides[0].visible and not attack.shots[0].visible, "Charge advertises the firing lane before the weapon is active")
						var hits := 0
						while not attack.complete():
							var at := pilot + (rig.global_basis.y * 7 if dodge else Vector3.ZERO)
							if attack.advance(1.0 / fps, at, 0.6):
								hits += 1
								check(attack.age >= attack.windup, "A charge cannot deal damage")
						check(hits == (0 if dodge else 1), "%s at %d Hz / dodge %s / hits %d" % [attack.attack_name, fps, dodge, hits])
						attack.free()
	check(tested.size() == Attack.Pattern.size(), "Every attack trajectory is exercised")
	var cover := StaticBody3D.new()
	rig.add_child(cover)
	cover.position.z = -42
	var collider := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = Vector3(30, 30, 5)
	collider.shape = block
	cover.add_child(collider)
	await physics_frame
	await physics_frame
	var lance := Attack.new()
	rig.add_child(lance)
	lance.configure("vespera", false, 0, 0, weapon, hull, pilot)
	check(not lance.advance(3.0, pilot, 0.6) and not lance.struck, "Solid cover blocks the charged lance even across a long frame")
	check(lance.shots[0].basis.z.length() < 42, "The visible lance ends on the near face of the obstruction")
	var torpedoes := Attack.new()
	rig.add_child(torpedoes)
	torpedoes.configure("cryo", true, 0, 0, weapon, hull, pilot)
	check(not torpedoes.advance(4.0, pilot, 0.6) and not torpedoes.spent.has(false), "Cover intercepts every projectile in a staggered torpedo salvo")
	rig.free()
	for sector in SectorCatalog.AVAILABLE:
		for orbital in [false, true]:
			check_escalation(sector, orbital)
	await check_radar_tracking()
	check_disabled_banks()
	check_blind_barrage()
	await process_frame
	print("BOSS_WEAPON_FAILURES=", failures)
	quit(failures)

func check_radar_tracking() -> void:
	var misses: Array[float] = []
	for lost in range(3):
		misses.append(await fly_past_missile(lost))
	print("BOSS_RADAR_MISS_DISTANCES=", misses)
	check(misses[1] > misses[0] + 0.35 and misses[2] > misses[1] + 0.35,
			"Identical evasive inputs take progressively less guided fire after one and two dish kills: %s" % [misses])

func fly_past_missile(dishes_lost: int) -> float:
	# Launch the same round first, then shoot its radar support out from under it.
	# The campaign relay, cockpit steering, missile steering and shield damage all run live.
	var game: Node3D = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.campaign.sector = "ignis"
	game.campaign.phase = "orbit_boss"
	game._enter_phase(false)
	var boss: BossEncounter = game.boss
	var pilot: FlightState = game.flight
	boss.age = 40 # Settled pursuit distance.
	pilot.elapsed = boss.age
	pilot.distance = boss.age * pilot.speed
	game.director.advance("orbit_boss", 0.0, pilot.distance, pilot.elapsed, game.targets)
	game._update_camera(false)
	for turret in boss.turrets:
		turret.cooldown = 20.0
	var tick := 1.0 / 60.0
	game.cursor = root.get_visible_rect().size * 0.5
	game._physics_process(tick)
	await physics_frame
	await physics_frame
	boss.turrets[0].cooldown = 0.0
	game._physics_process(tick)
	check(game.missiles.size() == 1, "A real turret round reaches the campaign missile list")
	if game.missiles.is_empty():
		game.free()
		return INF
	var round: EnemyMissile = game.missiles[0]
	for i in range(dishes_lost):
		var dish := boss.radars[i]
		game._strike({"collider": dish, "position": dish.aim_point()}, dish.armor)
	game.cursor.x += 0.04 * root.get_visible_rect().size.x
	var closest := INF
	for frame in range(100):
		var before: Vector3 = round.position - game.camera.position
		game._physics_process(tick)
		var after: Vector3 = round.position - game.camera.position
		var crossing := Geometry3D.get_closest_point_to_segment(Vector3.ZERO, before, after)
		closest = minf(closest, crossing.length())
		if not round.active or after.dot(game.director.frame.basis.z) > EnemyMissile.HIT_RADIUS + pilot.collision_radius:
			break
	check((pilot.missile_hits == 1) == (dishes_lost == 0), "Only a fully tracked round catches this lateral jink after %d dish kills (clearance %.2f)" % [dishes_lost, closest])
	game.sound.stop_all()
	game.free()
	return closest

func check_disabled_banks() -> void:
	var boss := BossEncounter.new()
	root.add_child(boss)
	var pilot := Vector3(0, 4, 110)
	var damage: Array[float] = []
	boss.special_hit.connect(func(_name: String, amount: float) -> void: damage.append(amount))
	boss.advance(1.3, pilot, Vector3.ZERO)
	var full_damage: float = boss.special.damage
	for gun in boss.turrets:
		gun.cooldown = 0.22
	var port := boss.turrets[0]
	var starboard := boss.turrets[2]
	var left_before := port.launches
	var right_before := starboard.launches
	boss.parts[0].receive_hit(boss.parts[0].armor)
	for frame in range(60):
		boss.advance(1.0 / 60, pilot, Vector3.ZERO)
	check(port.launches == left_before and starboard.launches == right_before + 1,
			"Severing the port feed aborts only the loaded launchers on that side")
	for frame in range(270):
		boss.advance(1.0 / 60, pilot, Vector3.ZERO)
	check(port.launches == left_before + 1 and starboard.launches >= right_before + 2,
			"The damaged bank fires once while the opposing bank completes two volleys")
	check(not damage.is_empty() and is_equal_approx(damage[0], full_damage * 0.8),
			"The pilot takes less damage from the already charging special when its power feed is severed")
	boss.free()

func check_blind_barrage() -> void:
	var boss := BossEncounter.new()
	root.add_child(boss)
	var pilot := Vector3(22, 4, 110)
	boss.advance(1.3, pilot, Vector3.ZERO)
	var opening_windup := boss.special.windup
	boss.radars[0].receive_hit(boss.radars[0].armor)
	check(boss.special == null, "Losing a dish interrupts an acquired firing solution")
	boss.advance(3.0, pilot, Vector3.ZERO)
	check(boss.special != null and boss.special.windup > opening_windup + 0.3,
			"The remaining dish gives the pilot a longer visible charge to react to")
	boss.radars[1].receive_hit(boss.radars[1].armor)
	boss.advance(3.0, pilot, Vector3.ZERO)
	var blind := boss.special
	check(blind != null and blind.attack_name == "BLIND BARRAGE", "The blinded capital ship switches to unguided fire")
	if blind != null:
		var hits := 0
		while not blind.complete():
			hits += int(blind.advance(1.0 / 60, pilot, 0.6))
		check(hits == 0, "An off-center pilot can hold course outside the blind barrage")
	boss.free()

func check_escalation(sector: String, orbital: bool) -> void:
	var boss := BossEncounter.new()
	boss.sector = sector
	boss.orbital = orbital
	root.add_child(boss)
	var pilot := Vector3(0, 7, 130)
	boss.advance(1.3, pilot, Vector3.ZERO)
	var arsenal: Array = Attack.ARSENAL[sector][int(orbital)]
	check(boss.rage_stage == 0 and boss.attack_warning().begins_with(arsenal[0][0]), "The undamaged %s opens with %s" % [sector, arsenal[0][0]])
	if boss.thermal_emitter != null:
		check(boss.special.emitter == boss.thermal_emitter, "The Solar Cruiser fires its lance from the thermal projector")
	boss.turrets[0].receive_hit(ceili(boss.turrets[0].maximum_armor * 0.8))
	boss.advance(0.02, pilot, Vector3.ZERO)
	check(boss.rage_stage == 1, "Serious damage to a live subsystem provokes a new tactic")
	boss.stun()
	boss.advance(0.5, pilot, Vector3.ZERO)
	check(boss.special == null, "EMP clears the telegraph and holds the launch")
	boss.advance(2.9, pilot, Vector3.ZERO)
	check(boss.attack_warning().begins_with(arsenal[1][0]), "A damaged %s changes weapons" % sector)
	if sector == "xylo" and not orbital:
		check(boss.special.emitter in [boss.parts[0], boss.parts[1]], "The Goliath's spore bloom vents from a living sac")
	if sector == "thalassa" and orbital:
		check(boss.special.emitter == boss.core, "The Storm Ark focuses its lightning through the turbine")
	if boss.special.emitter.unlocked:
		boss.special.emitter.receive_hit(boss.special.emitter.maximum_armor)
		boss.advance(0.02, pilot, Vector3.ZERO)
		check(boss.special == null, "Destroying a charging subsystem interrupts its weapon")
	else:
		boss.stun()
	for i in [0, 1, 2]:
		boss.turrets[i].receive_hit(boss.turrets[i].maximum_armor)
	boss.advance(4.1, pilot, Vector3.ZERO)
	check(boss.rage_stage == 2 and boss.turrets.back().rage_stage == 2 and boss.attack_warning().begins_with(arsenal[2][0]), "The enraged %s fires its final tactic and powers up surviving launchers" % sector)
	if (sector == "ignis" and not orbital) or (sector == "kharon" and orbital):
		for gun in boss.turrets:
			gun.receive_hit(gun.maximum_armor)
		boss.advance(0.02, pilot, Vector3.ZERO)
		boss.advance(1.3, pilot, Vector3.ZERO)
		if sector == "kharon":
			check(boss.defeated() and boss.special == null, "The last Sovereign magazine prevents a post-victory reactor discharge")
		else:
			check(not boss.defeated() and boss.special.emitter == boss.core and boss.attack_warning().begins_with("EMERGENCY DISCHARGE"), "A disarmed siege runner vents from its surviving core")
	boss.begin_destruction()
	boss.advance(0.2, pilot, Vector3.ZERO)
	check(boss.special == null and boss.attack_warning().is_empty(), "Destruction retires the weapon and prevents a final hit")
	boss.free()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
