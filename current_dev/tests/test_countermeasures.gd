extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := CampaignState.new()
	state.phase = "market"
	state.secondary = true
	state.ammo = 4
	state.reward(2000)
	check(not state.purchase("flare_reload").is_empty(), "Flare reload requires its own installed pod")
	check(state.purchase("countermeasures").is_empty() and state.countermeasures and state.flares == 3 and state.ammo == 4, "Countermeasure purchase supplies separate charges without changing weapon ordnance")
	var balance: int = state.credits
	check(not state.purchase("countermeasures").is_empty() and not state.purchase("flare_reload").is_empty() and state.credits == balance, "Duplicate pods and full reloads cannot spend credits")
	state.flares = 1
	check(state.purchase("flare_reload").is_empty() and state.flares == 3 and state.ammo == 4 and state.credits == balance - 60, "Dedicated reload refills only the flare inventory")
	state.purchase("hawk")
	check(state.countermeasures and state.flares == 3 and state.copy().flares == 3, "Voluntary hull purchases retain the flare pod and its charges")
	var invalid: Dictionary = state.to_dict()
	invalid["flares"] = 4
	check(not CampaignState.new().restore(invalid).is_empty(), "Over-capacity flare inventories are rejected")
	invalid = state.to_dict()
	invalid["countermeasures"] = false
	check(not CampaignState.new().restore(invalid).is_empty(), "Saved flare charges require an installed pod")
	var old_data: Dictionary = state.to_dict()
	old_data["schema"] = 6
	old_data.erase("countermeasures")
	old_data.erase("flares")
	var path: String = "user://countermeasures-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_data))
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and not store.state.countermeasures and store.state.flares == 0 and store.state.ammo == 4 and store.state.secondary, "Schema-six migration retains secondary ordnance and starts with no free flare pod")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v6-") and FileAccess.get_file_as_string(store.migration_backup_path) == JSON.stringify(old_data), "Schema-six migration preserves the exact original backup")
	DirAccess.remove_absolute(store.migration_backup_path)
	state.phase = "launch"
	state.flares = 2
	check(store.save_game(state) == OK and store.load_game() == OK and store.state.phase == "launch" and store.state.flares == 2, "Launch checkpoints retain equipped countermeasures and charges")
	state.eject()
	check(not state.countermeasures and state.flares == 0 and state.ammo == 0, "Ejection loses the pod and both separate ammunition inventories")
	await gameplay()
	DirAccess.remove_absolute(path)
	await process_frame
	print("COUNTERMEASURE_FAILURES=", failures)
	quit(failures)

func gameplay() -> void:
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
	game.campaign.countermeasures = true
	game.campaign.flares = 3
	game.campaign.secondary = true
	game.campaign.ammo = 6
	game.hud.campaign = game.campaign
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.mode = game.Mode.FLIGHT
	for i in range(6):
		game._launch_missile(Vector3(0, 0, -20 - i * 12), Vector3.BACK)
	game._launch_missile(Vector3(0, 0, -140), Vector3.BACK)
	game._launch_missile(Vector3(0, 0, 20), Vector3.BACK)
	await physics_frame
	await physics_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = true
	game._unhandled_input(key)
	var diverted: Array[EnemyMissile] = []
	for missile in game.missiles:
		if missile.diverted:
			diverted.append(missile)
	check(diverted.size() == 4 and game.campaign.flares == 2 and game.flight.ammo == 6 and game.flare_clouds.size() == 1, "C spends one separate charge to divert at most four nearby incoming missiles")
	check(not game.missiles[4].diverted and not game.missiles[6].diverted and not game.missiles[7].diverted, "Extra, distant and outgoing missiles are not magically neutralized")
	check(game.flight.shots == 0 and game.flight.hits == 0 and game.campaign.credits == 0 and game.campaign.combo_kills == 0, "Defensive deployment does not inflate accuracy, kills or credits")
	game.deploy_countermeasures()
	check(game.campaign.flares == 2 and game.flight.countermeasure_cooldown == 8.0, "Cooldown prevents rapid flare-charge consumption")
	game.pause_flight()
	game._physics_process(3.0)
	check(game.flare_clouds[0].age == 0 and game.flight.countermeasure_cooldown == 8.0 and diverted[0].age == 0, "Pause freezes flare visuals, missiles and the countermeasure cooldown")
	game.resume_flight()
	var hits: Array[int] = [0]
	for missile in diverted:
		missile.hit_pilot.connect(func() -> void: hits[0] += 1)
	var pilot := Vector3.ZERO
	for _i in range(126):
		var before: Vector3 = pilot
		pilot += Vector3.FORWARD * 42.0 / 60.0
		for missile in diverted:
			missile.advance(1.0 / 60.0, before, pilot)
	check(hits[0] == 0 and not diverted[0].active and game.flight.shields == 100, "Diverted missiles veer away, stop reacquiring and expire without hitting a normally advancing pilot")
	game._update_contacts()
	check(game.hud.incoming.size() == 4, "The threat display drops broken missile locks but retains other threats")
	game.flight.advance(8.0, false)
	game._advance_flare_clouds(8.0)
	game.deploy_countermeasures()
	check(game.campaign.flares == 1 and game.flight.countermeasure_cooldown == 8.0, "A later deployment becomes available after the full cooldown")
	game._clear_missiles()
	game.flight.countermeasure_cooldown = 0
	game.deploy_countermeasures()
	check(game.campaign.flares == 1, "No nearby incoming locks leaves the remaining charge unspent")
	game._launch_missile(Vector3(0, 0, -4), Vector3.BACK)
	var shield: float = game.flight.shields
	game._advance_missiles(0.2, Vector3.ZERO, Vector3.ZERO, false)
	check(game.flight.shields == shield, "Projectiles finishing automatic transit cannot cause post-checkpoint combat damage")
	game._clear_stage()
	check(game.flare_clouds.is_empty() and game.missiles.is_empty(), "Stage cleanup removes flare visuals and diverted missiles")
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
