extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.camera.transform = Transform3D.IDENTITY
	game.cursor = root.get_visible_rect().size * 0.5
	for drone in game.targets:
		drone.collision_layer = 0
	var target: RangeTarget = game.targets[0]
	target.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -20))
	target.collision_layer = 2
	await physics_frame
	await physics_frame
	game.fire_primary()
	check(target.armor == 1 and game.flight.hits == 1, "Reticle ray damages a visible drone")
	check(not game.debris.is_empty() and game.debris[-1].pieces.size() == 1, "A nonlethal hit sheds a hull fragment")
	var initial_transform: Transform3D = game.debris[-1].pieces[0]["transform"]
	game.debris[-1].advance(0.1)
	var moved: Transform3D = game.debris[-1].pieces[0]["transform"]
	check(moved.origin != initial_transform.origin and moved.basis != initial_transform.basis, "Broken hull fragments drift and tumble")
	var polygon_scale: Vector3 = game.debris[-1].pieces[0]["transform"].basis.get_scale()
	game.debris[-1].advance(0.35)
	check(game.debris[-1].pieces[0]["opacity"] > 0 and game.debris[-1].pieces[0]["opacity"] < 0.8 and game.debris[-1].pieces[0]["transform"].basis.get_scale().is_equal_approx(polygon_scale), "Original polygons fade without shrinking away")
	moved = game.debris[-1].pieces[0]["transform"]
	if DisplayServer.get_name() != "headless":
		var rendered: Transform3D = game.debris[-1].solid_instances.multimesh.get_instance_transform(0)
		check(rendered.is_equal_approx(moved), "Native debris instances receive the simulated fragment transforms")
	game.fire_primary()
	check(target.destroyed and game.flight.destroyed == 1, "Second pulse disables the drone exactly once")
	check(game.debris[-1].pieces.size() > 1, "A destroyed training ship breaks into multiple pieces")
	await physics_frame
	game.fire_primary()
	check(game.flight.destroyed == 1, "Disabled drone does not award duplicate hits")
	target.destroyed = false
	target.armor = 2
	target.collision_layer = 2
	target.show()
	var cover := StaticBody3D.new()
	cover.position = Vector3(0, 0, -10)
	cover.collision_layer = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10, 10, 2)
	collider.shape = shape
	cover.add_child(collider)
	root.add_child(cover)
	await physics_frame
	await physics_frame
	game.fire_primary()
	check(target.armor == 2, "Solid cover blocks fire before the target")
	var intercept := EnemyMissile.new()
	intercept.position = Vector3(0, 0, -6)
	game.add_child(intercept)
	await physics_frame
	await physics_frame
	game.fire_primary()
	check(not intercept.active and game.flight.interceptions == 1, "Primary fire intercepts incoming missiles")
	game.fire_primary()
	check(game.flight.interceptions == 1, "Intercepted missile is not counted twice")
	intercept.queue_free()
	var fast_missile := EnemyMissile.new()
	fast_missile.position = Vector3(-8, 0, 0)
	fast_missile.direction = Vector3.RIGHT
	fast_missile.age = 1.0
	var hits: Array[int] = [0]
	fast_missile.hit_pilot.connect(func() -> void: hits[0] += 1)
	game.add_child(fast_missile)
	fast_missile.advance(0.2, Vector3.ZERO, Vector3.ZERO)
	check(not fast_missile.active and hits[0] == 1, "Swept missile hit detects crossing the pilot between frames")
	fast_missile.advance(0.2, Vector3.ZERO, Vector3.ZERO)
	check(hits[0] == 1, "A missile only damages the pilot once")
	fast_missile.queue_free()
	var moving_pilot := Vector3(0, 12, 0)
	var velocity := Vector3(0, 0, -FlightState.SPEED)
	var led_missile := EnemyMissile.new()
	led_missile.position = Vector3(18, 5, -200)
	led_missile.direction = EnemyMissile.aim_direction(led_missile.position, moving_pilot, velocity)
	led_missile.hit_pilot.connect(game._missile_impact)
	game.add_child(led_missile)
	for _i in range(60):
		var previous_pilot: Vector3 = moving_pilot
		moving_pilot += velocity * 0.05
		led_missile.advance(0.05, previous_pilot, moving_pilot)
		if not led_missile.active:
			break
	check(game.flight.missile_hits == 1 and game.flight.shields < 100.0, "Missile leads the moving rail pilot and damages its shield")
	led_missile.queue_free()
	var turret: GroundTurret = game.turrets[0]
	turret.position = Vector3(18, 0, -150)
	turret.reset()
	var launches: Array[int] = [0]
	turret.missile_requested.connect(func(_origin: Vector3, _direction: Vector3) -> void: launches[0] += 1)
	turret.advance(GroundTurret.WARNING_TIME - 0.1, Vector3.ZERO)
	check(launches[0] == 0 and turret.beacon.visible, "Ground turret signals its attack before firing")
	turret.advance(0.2, Vector3.ZERO)
	check(launches[0] == 1, "Ground turret launches a missile at the pilot")
	for _i in range(4):
		turret.receive_hit()
	turret.advance(5.0, Vector3.ZERO)
	check(turret.destroyed and launches[0] == 1, "Destroyed turrets stop firing")
	game.resume_flight()
	for _i in range(game.MAX_MISSILES + 3):
		game._launch_missile(Vector3(0, 5, -35), Vector3.BACK)
	check(game.missiles.size() == game.MAX_MISSILES, "Missile population has a fixed performance bound")
	game.pause_flight()
	var missile_position: Vector3 = game.missiles[0].position
	await physics_frame
	await physics_frame
	check(game.missiles[0].position == missile_position, "Pause freezes incoming missiles")
	game.start_flight()
	check(game.missiles.is_empty() and game.debris.is_empty() and not game.turrets[0].destroyed and game.turrets[0].armor == 4, "Restart clears missiles/debris and restores turrets")
	game.resume_flight()
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == game.Mode.PAUSE, "Focus loss pauses active gameplay")
	var debug_path: String = "user://debug-tools-test-%d.json" % OS.get_process_id()
	game.campaign = CampaignState.new()
	game.store = CampaignStore.new(debug_path)
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.flight.elapsed = 12.0
	game.flight.hull = 73.0
	game._toggle_debug()
	game._debug_action("credits")
	check(game.campaign.credits == 1000 and game.flight.hull == 73.0, "Credit cheats do not silently repair the ship")
	check(game.flight.elapsed == 12.0 and game.mode == game.Mode.DEBUG, "Non-warp debug actions preserve the running phase")
	game._debug_action("close")
	check(game.mode == game.Mode.PAUSE, "Closing debug restores an existing pause instead of resuming combat")
	game.mode = game.Mode.FLIGHT
	var power_key := InputEventKey.new()
	power_key.physical_keycode = KEY_3
	power_key.pressed = true
	game._unhandled_input(power_key)
	check(game.flight.power_mode == "engines" and game.campaign.power_mode == "engines", "Key 3 routes power and updates the next checkpoint state")
	game.pause_flight()
	power_key.physical_keycode = KEY_1
	game._unhandled_input(power_key)
	check(game.flight.power_mode == "engines", "Paused gameplay does not accept live reactor commands")
	game._toggle_debug()
	game._debug_action("zero_heat")
	check(game.zero_heat and game.flight.zero_heat and game.campaign.assisted, "Zero-heat debug control is applied and marks the operation assisted")
	game.mode = game.Mode.FLIGHT
	game.flight.evade_cooldown = 0.0
	var shift := InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	shift.pressed = true
	game._unhandled_input(shift)
	check(game.flight.evade_remaining > 0.0 and game.flight.evasions == 1, "Shift activates the evasive maneuver")
	for _i in range(5):
		game.campaign.record_combat_kill(20)
	var shield_before: float = game.flight.shields
	game._missile_impact()
	check(game.flight.shields == shield_before and game.flight.deflections == 1 and game.campaign.combo_kills == 5, "Active maneuver deflects missiles without shield damage or combo loss")
	game.flight.impact_cooldown = 0
	game.flight.shields = 0
	game.flight.hull = 100
	game._apply_pilot_damage("PROXIMITY IMPACT")
	check(game.flight.hull == 82 and game.campaign.combo_kills == 0, "Physical collisions still hurt during evasion and reset a hull-damage streak")
	game.campaign.record_combat_kill(20)
	game.flight.impact_cooldown = 0
	game.flight.shields = 100
	game._apply_pilot_damage("PROXIMITY IMPACT")
	check(game.campaign.combo_kills == 1, "Damage absorbed entirely by shields preserves the kill streak")
	game.pause_flight()
	var maneuver_before: float = game.flight.evade_remaining
	game._physics_process(0.5)
	check(game.flight.evade_remaining == maneuver_before, "Paused game cannot advance the evasive maneuver")
	game.mode = game.Mode.FLIGHT
	var gunship := EnemyFighter.new()
	gunship.heavy = true
	gunship.dogfight = true
	gunship.velocity = Vector3.FORWARD * 10
	gunship.spawn_frame = Transform3D.IDENTITY
	game.add_child(gunship)
	gunship.global_transform = Transform3D.IDENTITY
	game.camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -20))
	var initial_armor: int = gunship.armor
	var initial_hits: int = game.flight.hits
	game._strike({"collider": gunship, "position": Vector3(0, 0, -8)}, 1)
	check(gunship.armor == initial_armor and game.flight.hits == initial_hits and gunship.shield_flash > 0, "Frontal gunship shield blocks primary fire without awarding a hit")
	game.camera.position = Vector3(0, 0, 20)
	game._strike({"collider": gunship, "position": Vector3(0, 0, 8)}, 1)
	check(gunship.armor == initial_armor - 1, "Primary fire damages the gunship from behind")
	gunship.age = EnemyFighter.SHIELD_OPEN_START + 0.2
	game.camera.position = Vector3(0, 0, -20)
	game._strike({"collider": gunship, "position": Vector3(0, 0, -8)}, 1)
	check(gunship.armor == initial_armor - 2, "Banking opens the shield to frontal primary fire")
	gunship.reset()
	game._strike({"collider": gunship, "position": Vector3(0, 0, -8)}, 8, true)
	check(not gunship.destroyed and gunship.stun_remaining == EnemyFighter.STUN_DURATION and not gunship.shield_active(), "Concussion hit stuns a surviving gunship and drops its shield")
	gunship.cooldown = 0
	var gunship_launches: Array[int] = [0]
	gunship.missile_requested.connect(func(_at: Vector3, _direction: Vector3) -> void: gunship_launches[0] += 1)
	gunship.advance(0.5, game.camera.position, Vector3.ZERO)
	check(gunship_launches[0] == 0 and gunship.motion_age == 0, "Stunned gunships stop moving and firing")
	gunship.age = 0
	gunship.phase = 0
	gunship.advance(1.5, Vector3(0, 0, -300), Vector3.ZERO)
	check(gunship.stun_remaining == 0 and gunship.shield_active(), "Directional shield recovers after the two-second stun")
	gunship.age = EnemyFighter.SHIELD_OPEN_START + 0.2
	game._strike({"collider": gunship, "position": gunship.position}, 2)
	var paid: int = game.campaign.credits
	var streak: int = game.campaign.combo_kills
	game._strike({"collider": gunship, "position": gunship.position}, 8)
	check(gunship.destroyed and game.campaign.credits == paid and game.campaign.combo_kills == streak, "Destroyed gunship cannot pay a reward or combo kill twice")
	gunship.queue_free()
	var colored_batch := GeometryBatch.new()
	colored_batch.box(Vector3.LEFT * 2, Vector3.ONE, Color.YELLOW, Color("#6a2520"))
	colored_batch.box(Vector3.RIGHT * 2, Vector3.ONE, Color.CYAN, Color("#20386a"))
	var colored: Node3D = colored_batch.build()
	game.add_child(colored)
	var original_colors := BreakupEffect.new()
	game.add_child(original_colors)
	original_colors.build(colored, true, Color.GREEN)
	var fills: Dictionary = {}
	var edges: Dictionary = {}
	for piece in original_colors.pieces:
		fills[piece["color"].to_html()] = true
		edges[piece["edge_color"].to_html()] = true
	check(fills.has(Color("#6a2520").to_html()) and fills.has(Color("#20386a").to_html()) and not fills.has(Color.GREEN.to_html()), "Exploded polygons retain each original hull color instead of an explosion tint")
	check(edges.has(Color.YELLOW.to_html()) and edges.has(Color.CYAN.to_html()), "Authored polygon edges retain their original trim colors")
	var color_before: Color = original_colors.pieces[0]["color"]
	original_colors.advance(2.0)
	check(original_colors.pieces[0]["color"] == color_before and original_colors.pieces[0]["opacity"] < 1, "Fading changes alpha without repainting a polygon's original RGB")
	colored.queue_free()
	original_colors.queue_free()
	game.pause_flight()
	for orbital in [false, true]:
		var capital := BossEncounter.new()
		capital.orbital = orbital
		game.add_child(capital)
		game.boss = capital
		var launches_from: Array[Vector3] = []
		capital.missile_requested.connect(func(at: Vector3, _direction: Vector3) -> void: launches_from.append(at))
		var weapon: BossTurret = capital.turrets[0]
		weapon.cooldown = GroundTurret.WARNING_TIME
		var pilot := Vector3(0, 5, 120)
		capital.advance(0.1, pilot, Vector3.ZERO)
		check(weapon.beacon.visible and launches_from.is_empty(), "Boss turret visibly warns before firing")
		capital.advance(0.95, pilot, Vector3.ZERO)
		check(launches_from.size() == 1 and launches_from[0].distance_to(weapon.head.global_position) < 6.0, "Boss missile launches from a visible turret muzzle")
		var shots_before: int = weapon.launches
		game._strike({"collider": weapon, "position": weapon.aim_point()}, weapon.armor)
		capital.advance(weapon.interval + 1.0, pilot, Vector3.ZERO)
		check(weapon.destroyed and not weapon.visible and weapon.collision_layer == 0 and weapon.launches == shots_before, "Destroying a boss turret removes its model, targeting collision, and weapon fire")
		for other in capital.turrets:
			other.receive_hit(other.armor)
		var before_silenced: int = launches_from.size()
		capital.advance(20.0, pilot, Vector3.ZERO)
		check(launches_from.size() == before_silenced and not capital.defeated(), "Destroying all optional turrets silences the boss without bypassing its reactor")
		var generator: BossPart = capital.parts[0]
		var nacelle: Node3D = generator.get_child(0)
		var collector := BreakupEffect.new()
		var intact_surfaces: Array[Dictionary] = []
		collector._collect(capital, intact_surfaces)
		check(nacelle.is_visible_in_tree() and capital.model.visible, "Shield generator belongs to a visible engine nacelle")
		game._strike({"collider": generator, "position": generator.aim_point()}, generator.armor)
		var credits_after: int = game.campaign.credits
		game._strike({"collider": generator, "position": generator.aim_point()}, 10)
		check(not nacelle.is_visible_in_tree() and capital.model.visible and not capital.core.unlocked and game.campaign.credits == credits_after, "Destroying a generator removes the whole nacelle once, leaving the hull and remaining shield intact")
		check(game.debris[-1].pieces.size() > 12 and not game.explosions.is_empty(), "Destroyed boss sections release many original polygons and an animated explosion")
		var remaining_surfaces: Array[Dictionary] = []
		collector._collect(capital, remaining_surfaces)
		check(remaining_surfaces.size() < intact_surfaces.size(), "Final capital breakup excludes ship sections that already broke away")
		collector.free()
		game.boss = null
		capital.queue_free()
	game.mode = game.Mode.PAUSE
	game.campaign.secondary = true
	game.flight.ammo = 0
	game.campaign.reward(500)
	var earned_before: int = game.campaign.earned
	game._toggle_debug()
	game._debug_action("reset_credits")
	check(game.campaign.credits == 0 and game.campaign.earned == earned_before and game.campaign.assisted, "Reset-wallet testing preserves historical earnings and marks the run assisted")
	game._debug_action("infinite_ammo")
	game.flight.secondary_cooldown = 0
	game.fire_secondary()
	check(game.infinite_ammo and game.flight.ammo == 0 and not game.torpedoes.is_empty(), "Infinite ordnance permits a fitted secondary without consuming or inventing ammo")
	game._debug_action("one_hit")
	var tough := RangeTarget.new()
	game.add_child(tough)
	tough.armor = 20
	game._strike({"collider": tough, "position": tough.global_position}, 1)
	check(tough.destroyed and game.one_hit_kill, "One-hit testing destroys an exposed target with normal weapon input")
	tough.queue_free()
	var debug_boss := BossEncounter.new()
	game.add_child(debug_boss)
	game.boss = debug_boss
	var core_health: int = debug_boss.core.armor
	game._strike({"collider": debug_boss.core, "position": debug_boss.core.aim_point()}, 1)
	check(debug_boss.core.armor == core_health, "One-hit testing does not silently bypass the normal boss shield lock")
	var credits_before: int = game.campaign.credits
	var hits_before: int = game.flight.hits
	var score_before: int = game.campaign.combat_score
	game._debug_action("kill_boss")
	check(debug_boss.defeated() and debug_boss.death_time == 0 and game.flight.hits == hits_before and game.campaign.credits == credits_before and game.campaign.combat_score == score_before, "Explicit developer boss defeat starts destruction without fake shots or combat rewards")
	debug_boss.queue_free()
	game.boss = null
	game.start_flight()
	check(not game.infinite_ammo and not game.one_hit_kill, "Returning to ordinary training clears the new testing toggles")
	game.set_process(false)
	game.set_physics_process(false)
	game.automation = "--native-fixture"
	game.normal_save_path = debug_path
	game.flight.ammo = 5
	game._toggle_debug()
	game._debug_action("credits")
	await process_frame
	await process_frame
	check(game.campaign.credits == 1000 and game.campaign.ammo == 0 and not game.campaign.secondary and game.campaign.assisted, "A fresh debug operation cannot inherit stale ammunition from another flight")
	DirAccess.remove_absolute(debug_path)
	if FileAccess.file_exists(debug_path + ".tmp"):
		DirAccess.remove_absolute(debug_path + ".tmp")
	print("COMBAT_TEST_FAILURES=", failures)
	game.sound.stop_all()
	await create_timer(0.1).timeout
	cover.queue_free()
	game.queue_free()
	await process_frame
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
