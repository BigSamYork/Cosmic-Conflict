extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := CampaignState.new()
	state.phase = "market"
	state.reward(3000)
	check(state.purchase("emp").is_empty() and state.emp_launcher and state.selected_secondary == "emp" and state.ammo == 3, "EMP can be the first installed secondary and supplies three shared units")
	var before: Dictionary = state.to_dict()
	check(not state.purchase("emp").is_empty() and state.to_dict() == before, "Duplicate station purchases cannot spend credits or refill ordnance")
	check(not state.select_secondary("swarm").is_empty() and state.selected_secondary == "emp", "Unowned stations cannot be selected")
	state.purchase("swarm")
	state.purchase("secondary")
	check(state.ammo == 6 and state.secondary and state.swarm_launcher and state.emp_launcher, "All launchers share the original six-unit Rook bay without overwriting existing ammo")
	check(state.select_secondary("swarm").is_empty(), "An installed station can be selected")
	state.purchase("hawk")
	state.purchase("ammo")
	check(state.ammo == 8 and state.selected_secondary == "swarm" and state.copy().swarm_launcher and state.copy().emp_launcher, "Hull changes transfer both stations and selection while respecting the new shared bay")
	var invalid: Dictionary = state.to_dict()
	invalid["selected_secondary"] = "unknown"
	check(not CampaignState.new().restore(invalid).is_empty(), "Unknown saved station selection is rejected")
	invalid = state.to_dict()
	invalid["swarm_launcher"] = false
	check(not CampaignState.new().restore(invalid).is_empty(), "Saved selection must refer to an owned station")
	var lost: CampaignState = state.copy()
	lost.phase = "ground"
	lost.eject()
	check(not lost.secondary and not lost.swarm_launcher and not lost.emp_launcher and lost.ammo == 0 and lost.selected_secondary == "concussion", "Ejection loses all secondary stations and the shared ordnance pool")
	var legacy := CampaignState.new()
	legacy.secondary = true
	legacy.ammo = 4
	legacy.reward(425)
	var old_data: Dictionary = legacy.to_dict()
	old_data["schema"] = 5
	for key in ["swarm_launcher", "emp_launcher", "selected_secondary"]:
		old_data.erase(key)
	var path: String = "user://secondary-stations-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_data))
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and store.state.secondary and store.state.ammo == 4 and store.state.selected_secondary == "concussion" and not store.state.swarm_launcher and not store.state.emp_launcher, "Schema-five saves retain their concussion launcher and ammo without granting new stations")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v5-") and FileAccess.get_file_as_string(store.migration_backup_path) == JSON.stringify(old_data), "Schema-five migration preserves an exact labeled backup")
	DirAccess.remove_absolute(store.migration_backup_path)
	store.save_game(state)
	state.select_secondary("emp")
	check(store.load_game() == OK and store.state.selected_secondary == "swarm", "Uncheckpointed weapon switching rolls back with the rest of the phase")
	await _test_gameplay(path)
	DirAccess.remove_absolute(path)
	await process_frame
	print("SECONDARY_SYSTEMS_FAILURES=", failures)
	quit(failures)

func _test_gameplay(path: String) -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game.camera.global_transform = Transform3D.IDENTITY
	game.campaign = CampaignState.new()
	game.campaign.ship = "hawk"
	game.campaign.hull = game.campaign.hull_capacity()
	game.campaign.shields = game.campaign.shield_capacity()
	game.campaign.secondary = true
	game.campaign.swarm_launcher = true
	game.campaign.emp_launcher = true
	game.campaign.ammo = 8
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.mode = game.Mode.FLIGHT
	game._select_secondary("swarm")
	check(game.campaign.selected_secondary == "concussion", "Live flight cannot switch stations outside the tactical pause")
	game.mode = game.Mode.PAUSE
	game._select_secondary("swarm")
	check(game.campaign.selected_secondary == "swarm" and game.flight.ammo == 8 and game.mode == game.Mode.PAUSE, "Paused switching changes the station without firing, spending ammo, or resuming flight")
	game.mode = game.Mode.FLIGHT
	for i in range(3):
		var fighter := EnemyFighter.new()
		fighter.new_design = true
		game.world.add_child(fighter)
		fighter.global_position = Vector3((i - 1) * 12, 8 if i == 1 else 0, -80 - i * 5)
		game.targets.append(fighter)
	await physics_frame
	await physics_frame
	game.fire_secondary()
	var locks: Dictionary = {}
	for rocket in game.torpedoes:
		locks[rocket.homing_target.get_instance_id()] = true
	check(game.flight.ammo == 6 and game.torpedoes.size() == 3 and locks.size() == 3 and game.flight.shots == 3, "Swarm spends two units for three separately locked, accuracy-counted rockets")
	game.targets[0].position.x += 6
	for _i in range(100):
		game._advance_torpedoes(1.0 / 60.0)
		await physics_frame
		if game.torpedoes.is_empty():
			break
	check(game.flight.hits == 3 and game.flight.destroyed == 3, "Homing rockets hit distinct enemies, including a target that moved after launch")
	var ammo: int = game.flight.ammo
	game.flight.secondary_cooldown = 0
	game.fire_secondary()
	check(game.flight.ammo == ammo and game.torpedoes.is_empty(), "No swarm locks produces an explicit refusal without spending ordnance")
	game._clear_stage()
	await process_frame
	game.world = Node3D.new()
	game.add_child(game.world)
	var gunship := EnemyFighter.new()
	gunship.heavy = true
	gunship.dogfight = true
	gunship.spawn_frame = Transform3D.IDENTITY
	gunship.velocity = Vector3.FORWARD
	game.world.add_child(gunship)
	gunship.position = Vector3(15, 0, -60)
	game.targets.append(gunship)
	var boss := BossEncounter.new()
	boss.orbital = true
	boss.position = Vector3(0, 0, -170)
	game.world.add_child(boss)
	game.boss = boss
	game.targets.append_array(boss.parts)
	game._launch_missile(Vector3(0, 0, -30), Vector3.BACK)
	game._launch_missile(Vector3(0, 0, 30), Vector3.FORWARD)
	game._launch_missile(Vector3(0, 0, -260), Vector3.BACK)
	game._start_thermal_sweep(boss.thermal_emitter)
	game.campaign.select_secondary("emp")
	game.flight.secondary_cooldown = 0
	var hits: int = game.flight.hits
	var kills: int = game.campaign.combo_kills
	var score: int = game.campaign.combat_score
	await physics_frame
	await physics_frame
	game.fire_secondary()
	check(game.flight.ammo == ammo - 3 and not game.missiles[0].active and game.missiles[1].active and game.missiles[2].active, "EMP spends three units and clears only visible, in-range hostile projectiles")
	check(boss.stun_remaining == EnemyFighter.STUN_DURATION and gunship.stun_remaining == EnemyFighter.STUN_DURATION and not gunship.shield_active() and game.thermal_sweeps.is_empty(), "EMP disables capital weapons, cancels thermal sweeps, and drops gunship shields")
	check(not boss.core.unlocked and not boss.defeated() and game.campaign.combo_kills == kills and game.campaign.combat_score == score and game.flight.hits == hits + 1, "EMP preserves boss shield rules and counts one successful activation without awarding kills")
	var boss_position: Vector3 = boss.position
	boss.advance(1.0, game.camera.global_position, Vector3.ZERO)
	check(boss.position != boss_position and boss.stun_remaining > 0, "Stunned capital ships keep safe pursuit motion while weapon systems are disabled")
	game.mode = game.Mode.PAUSE
	var pulse_age: float = game.emp_pulses[0].age
	game._physics_process(3.0)
	check(game.emp_pulses[0].age == pulse_age and boss.stun_remaining > 0, "Pause freezes EMP effects and disabled-system timers")
	game.mode = game.Mode.FLIGHT
	var cover := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30, 30, 2)
	collider.shape = shape
	cover.add_child(collider)
	cover.position = Vector3(0, 0, -20)
	game.world.add_child(cover)
	game._launch_missile(Vector3(0, 0, -40), Vector3.BACK)
	var covered: EnemyMissile = game.missiles[-1]
	game.flight.secondary_cooldown = 0
	hits = game.flight.hits
	await physics_frame
	await physics_frame
	game.fire_secondary()
	check(covered.active and game.flight.hits == hits and game.flight.ammo == 0, "EMP cannot clear threats through solid cover; an empty pulse is not counted as a hit")
	var shots: int = game.flight.shots
	game.flight.secondary_cooldown = 0
	game.fire_secondary()
	check(game.flight.shots == shots and game.flight.ammo == 0, "Insufficient shared ordnance cannot fire or increment shot statistics")
	var departing := PlayerTorpedo.new()
	departing.position = Vector3(0, 0, -5)
	game.add_child(departing)
	game.torpedoes.append(departing)
	game._advance_torpedoes(0.3, false)
	check(departing.position.z < -50 and departing.active and game.flight.hits == hits, "Outstanding ordnance keeps moving during transit without post-checkpoint combat rewards")
	game._clear_stage()
	check(game.torpedoes.is_empty() and game.emp_pulses.is_empty(), "Stage cleanup removes guided rockets and EMP visuals")
	game.campaign = game._snapshot()
	game.campaign.dock(false)
	game.mode = game.Mode.MARKET
	game.store = CampaignStore.new(path)
	game._select_secondary("swarm")
	var saved := CampaignStore.new(path)
	check(saved.load_game() == OK and saved.state.selected_secondary == "swarm" and saved.state.emp_launcher, "Docked station selection is saved immediately with all unlocks")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
