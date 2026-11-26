extends SceneTree

var failures: int = 0
var path: String

func _initialize() -> void:
	path = "user://campaign-test-%d.json" % OS.get_process_id()
	call_deferred("run")

func run() -> void:
	await verify_named_games()
	var state := CampaignState.new()
	var combo := CampaignState.new()
	for _i in range(4):
		combo.record_combat_kill(20)
	check(combo.combo_multiplier() == 1 and combo.credits == 0 and combo.combat_score == 800, "First four kills award base score only")
	combo.record_combat_kill(20)
	check(combo.combo_multiplier() == 2 and combo.credits == 0 and combo.combat_score == 1200, "Fifth consecutive kill doubles the score award")
	for _i in range(5):
		combo.record_combat_kill(20)
	check(combo.combo_multiplier() == 4 and combo.credits == 0 and combo.combat_score == 3600 and combo.combo_bonus_credits == 0, "Tenth kill starts 4x with exact score and bonus accounting")
	var copy: CampaignState = combo.copy()
	check(copy.combo_kills == 10 and copy.best_streak == 10 and copy.combat_score == combo.combat_score, "Live streak and score survive checkpoint serialization")
	combo.reward(1000)
	check(combo.credits == 1000 and combo.combo_kills == 10 and combo.combat_score == 3600, "Hoop credits are not multiplied or scored")
	combo.break_combo()
	check(combo.combo_multiplier() == 1 and combo.best_streak == 10 and combo.combat_score == 3600, "Breaking a streak preserves earned score and best streak")
	combo.record_combat_kill(20)
	combo.dock(true)
	var settlement: Dictionary = combo.to_dict()
	combo.dock(true)
	check(combo.combo_kills == 0 and combo.to_dict() == settlement, "Docking clears the streak and never pays its reward twice")
	state.reward(1500)
	state.phase = "market"
	check(state.purchase("primary").is_empty() and state.purchase("secondary").is_empty(), "Market purchases equip primary and secondary upgrades")
	var credits: int = state.credits
	var spent: int = state.spent
	state.phase = "ground"
	state.eject()
	check(state.ship.is_empty() and state.primary_level == 0 and not state.secondary and state.ammo == 0, "Ejection loses ship, fitted upgrades and ammo")
	check(state.copy().purchase_counts == {"primary": 1, "secondary": 1}, "Receipts survive ejection and save/load without restoring lost equipment")
	var pre_receipts := state.to_dict()
	pre_receipts.erase("purchase_counts")
	var migrated_wallet := CampaignState.new()
	check(migrated_wallet.restore(pre_receipts).is_empty() and migrated_wallet.purchase_counts.is_empty(), "Existing saves do not acquire fabricated purchase receipts")
	check(state.credits == credits and state.spent == spent and state.stats["ejections"] == 1, "Ejection retains earned credits without a completion bonus")
	state.eject()
	check(state.stats["ejections"] == 1 and state.credits == credits, "Repeated ejection cannot duplicate settlement")
	check(not state.purchase("emergency").is_empty(), "Emergency ship is unavailable when a normal replacement is affordable")
	state.credits = 10
	check(state.purchase("emergency").is_empty() and state.ship == "emergency" and state.credits == 10, "Stranded pilot gets a free ship without debt")
	check(state.depart("ignis").is_empty() and state.phase == "launch", "Recovery departs from the station before returning to ground assault")
	state.phase = "asteroids"
	state.hull = 12
	state.shields = 1
	state.dock(true)
	var paid: Dictionary = state.to_dict()
	check(state.hull == state.hull_capacity() and state.shields == state.shield_capacity(), "Docking repairs hull and shields for free")
	state.dock(true)
	check(state.to_dict() == paid, "Reopening the market does not pay completion rewards twice")
	var plated := CampaignState.new()
	plated.phase = "market"
	plated.reward(2000)
	check(plated.purchase("armor").is_empty() and plated.hull_capacity() == 125 and plated.hull == 125, "Hull plating increases usable hull and repairs it at the market")
	check(plated.purchase("armor").is_empty() and plated.hull_capacity() == 150 and not plated.purchase("armor").is_empty(), "Hull plating has two purchasable tiers")
	plated.purchase("hawk")
	var after_purchase := plated.credits
	check(not plated.purchase("rook").is_empty() and plated.switch_hull("rook").is_empty(), "Parked Rook cannot be bought again but can be selected")
	check(plated.credits == after_purchase and plated.copy().parked_ships == ["hawk"] and plated.switch_hull("hawk").is_empty(), "Switching costs nothing and the hangar survives a checkpoint")
	check(plated.hull_armor_level == 2 and plated.hull_capacity() == 130 and plated.copy().hull == 130, "Hull swaps and save validation preserve fitted armor")
	plated.phase = "ground"
	plated.eject()
	check(plated.copy().parked_ships == ["rook"] and not plated.switch_hull("hawk").is_empty(), "Ejection loses only the active Hawk; the parked Rook survives")
	check(plated.hull_armor_level == 0 and plated.hull_capacity() == 0, "Ejection loses hull plating with the destroyed ship")
	var accurate := CampaignState.new()
	accurate.stats["shots"] = 40
	accurate.stats["hits"] = 30
	accurate.hull = 63
	accurate.dock(true)
	check(accurate.credits == 0 and accurate.debrief["hits"] == 30 and accurate.debrief["shots"] == 40 and accurate.debrief["completion"] == 0, "Docking records marksmanship without paying for combat")
	check(accurate.combat_score == 0 and accurate.copy().debrief == accurate.debrief, "Debrief bonuses persist without inflating combat score")
	var settled_credits: int = accurate.credits
	accurate.dock(true)
	check(accurate.credits == settled_credits and accurate.accuracy_bonus_credits == 0, "Reopening the market cannot pay the accuracy bonus twice")
	accurate.depart("cryo")
	accurate.stats["shots"] += 20
	accurate.stats["hits"] += 5
	accurate.dock(true)
	check(accurate.debrief["shots"] == 20 and accurate.debrief["hits"] == 5 and accurate.debrief["accuracy"] == 0, "A new sortie calculates accuracy from its own shots, not lifetime totals")
	for shot_count in [0, 19, 20]:
		var small := CampaignState.new()
		small.stats["shots"] = shot_count
		small.stats["hits"] = shot_count
		small.dock(true)
		check(small.debrief["accuracy"] == 0 and small.debrief["hits"] == shot_count, "Even perfect accuracy pays no credits (%d shots)" % shot_count)
	var failed := CampaignState.new()
	failed.stats["shots"] = 40
	failed.stats["hits"] = 40
	failed.eject()
	check(failed.debrief["accuracy"] == 0 and failed.debrief["hull"] == 0 and failed.debrief["completion"] == 0 and failed.credits == 0, "Failed sorties receive no completion, hull, or accuracy bonuses")
	state.reward(2000)
	state.purchase("primary")
	state.purchase("secondary")
	state.purchase("cooling")
	state.reward(400)
	check(state.purchase("tractor").is_empty() and state.tractor, "Market installs the tractor beam")
	var tractor_balance: int = state.credits
	check(not state.purchase("tractor").is_empty() and state.credits == tractor_balance, "An owned tractor cannot be charged twice")
	check(state.purchase("hawk").is_empty() and state.primary_level == 1 and state.secondary and state.ammo == 3 and state.heat_sink_level == 1, "A voluntary hull change transfers fitted equipment and cooling vents")
	check(state.tractor, "Voluntary hull changes retain the tractor module")
	var score_before: int = state.combat_score
	state.collect_mineral()
	check(state.stats["minerals"] == 1 and state.mineral_credits == 0 and state.combat_score == score_before, "Mineral collection records salvage without cash or combat score")
	var before: Dictionary = state.to_dict()
	check(not state.purchase("invalid_item").is_empty() and state.to_dict() == before, "Invalid purchases do not mutate inventory or wallet")
	state.credits = 0
	before = state.to_dict()
	check(not state.purchase("shield").is_empty() and state.to_dict() == before, "Unaffordable purchases do not mutate state")
	var flight := FlightState.new()
	flight.configure_campaign(state)
	flight.shields = 2
	flight.hull = 30
	flight.impact("TEST", 18)
	check(flight.shields == 0 and flight.hull == 14, "Shields absorb damage before the hull")
	flight.impact_cooldown = 0
	flight.impact("TEST", 50)
	check(flight.hull == 0, "Campaign hull damage is lethal rather than training-clamped")
	var store := CampaignStore.new(path)
	check(store.save_game(state) == OK, "Write an atomic campaign checkpoint")
	state.reward(75)
	check(store.save_game(state) == OK, "Atomically replace an existing Windows checkpoint")
	var loaded: Error = store.load_game()
	check(loaded == OK and store.state.to_dict() == state.to_dict(), "Checkpoint round trip preserves loadout, economy, and progress: " + store.message)
	if loaded != OK:
		DirAccess.remove_absolute(path)
		quit(failures)
		return
	state.reward(100)
	store.load_game()
	check(store.state.credits == state.credits - 100, "Unfinished phase rewards roll back to the saved checkpoint")
	var legacy: Dictionary = state.to_dict()
	legacy["schema"] = 1
	legacy.erase("heat_sink_level")
	legacy.erase("power_mode")
	var old_save := FileAccess.open(path, FileAccess.WRITE)
	old_save.store_string(JSON.stringify(legacy))
	old_save.close()
	check(store.load_game() == OK and store.migrated and store.state.heat_sink_level == 0 and store.state.power_mode == "balanced", "Version-one saves migrate to balanced power and no cooling upgrades")
	check(store.save_game(store.state) == OK and FileAccess.file_exists(store.migration_backup_path), "Save migration preserves the original version-one checkpoint")
	var backup: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.migration_backup_path))
	check(backup is Dictionary and backup["schema"] == 1, "Pre-migration backup retains the original format")
	DirAccess.remove_absolute(store.migration_backup_path)
	var mining_legacy: Dictionary = state.to_dict()
	mining_legacy["schema"] = 3
	mining_legacy.erase("tractor")
	mining_legacy.erase("mineral_credits")
	mining_legacy["stats"].erase("minerals")
	mining_legacy["stats"].erase("chain_rocks")
	old_save = FileAccess.open(path, FileAccess.WRITE)
	old_save.store_string(JSON.stringify(mining_legacy))
	old_save.close()
	check(store.load_game() == OK and not store.state.tractor and store.state.stats["minerals"] == 0 and store.state.credits == state.credits, "Version-three saves retain progress and initialize mining fields")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v3-"), "Mining migration preserves a version-three backup")
	check(FileAccess.get_file_as_string(store.migration_backup_path) == JSON.stringify(mining_legacy), "Version-three backup retains the complete pre-mining checkpoint")
	DirAccess.remove_absolute(store.migration_backup_path)
	var previous_mining: Dictionary = accurate.to_dict()
	previous_mining["schema"] = 4
	for key in ["hull_armor_level", "sortie_start_shots", "sortie_start_hits", "accuracy_bonus_credits", "debrief"]:
		previous_mining.erase(key)
	for key in ["radars", "webs", "pirates"]:
		previous_mining["stats"].erase(key)
	old_save = FileAccess.open(path, FileAccess.WRITE)
	old_save.store_string(JSON.stringify(previous_mining))
	old_save.close()
	check(store.load_game() == OK and store.state.credits == accurate.credits and store.state.sortie_start_shots == accurate.stats["shots"] and store.state.hull_armor_level == 0, "Schema-four mining saves retain progress and start new accuracy tracking at the upgrade checkpoint")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v4-") and FileAccess.get_file_as_string(store.migration_backup_path) == JSON.stringify(previous_mining), "Schema-four migration preserves the exact original backup")
	DirAccess.remove_absolute(store.migration_backup_path)
	var previous_save: Dictionary = state.to_dict()
	previous_save["schema"] = 2
	for key in ["combo_kills", "best_streak", "combat_score", "combo_bonus_credits"]:
		previous_save.erase(key)
	old_save = FileAccess.open(path, FileAccess.WRITE)
	old_save.store_string(JSON.stringify(previous_save))
	old_save.close()
	check(store.load_game() == OK and store.state.heat_sink_level == state.heat_sink_level and store.state.combo_kills == 0 and store.state.combat_score == 0, "Version-two saves preserve equipment and start new scoring at zero")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v2-"), "Version-two migration keeps a correctly labeled backup")
	backup = JSON.parse_string(FileAccess.get_file_as_string(store.migration_backup_path))
	check(backup is Dictionary and backup["schema"] == 2, "Version-two backup retains the original schema")
	DirAccess.remove_absolute(store.migration_backup_path)
	var invalid: Dictionary = state.to_dict()
	invalid["credits"] = -1
	var candidate := CampaignState.new()
	check(not candidate.restore(invalid).is_empty(), "Negative save balances are rejected")
	invalid = state.to_dict()
	invalid["schema"] = 999
	check(not candidate.restore(invalid).is_empty(), "Unsupported save versions are rejected")
	invalid = state.to_dict()
	invalid["power_mode"] = "invalid"
	check(not candidate.restore(invalid).is_empty(), "Unknown saved power routing is rejected explicitly")
	invalid = state.to_dict()
	invalid["combo_kills"] = 10
	check(not candidate.restore(invalid).is_empty(), "Inconsistent streak and best-streak data is rejected")
	invalid = state.to_dict()
	invalid["tractor"] = "true"
	check(not candidate.restore(invalid).is_empty(), "Malformed tractor ownership is rejected")
	invalid = state.to_dict()
	invalid["mineral_credits"] = invalid["earned"] + 1
	check(not candidate.restore(invalid).is_empty(), "Mineral credit totals cannot exceed earned credits")
	invalid = state.to_dict()
	invalid["stats"]["chain_rocks"] = invalid["stats"]["asteroids"] + 1
	check(not candidate.restore(invalid).is_empty(), "Chain statistics cannot exceed shattered rocks")
	invalid = state.to_dict()
	invalid["hull_armor_level"] = 3
	check(not candidate.restore(invalid).is_empty(), "Out-of-range hull plating is rejected")
	invalid = state.to_dict()
	invalid["sortie_start_shots"] = invalid["stats"]["shots"] + 1
	check(not candidate.restore(invalid).is_empty(), "A sortie baseline cannot exceed lifetime shots")
	invalid = state.to_dict()
	invalid["debrief"]["accuracy"] = 201
	check(not candidate.restore(invalid).is_empty(), "Malformed debrief bonuses are rejected")
	var lost: CampaignState = state.copy()
	lost.phase = "ground"
	lost.power_mode = "weapons"
	lost.eject()
	check(lost.heat_sink_level == 0 and lost.power_mode == "balanced", "Ejection loses cooling upgrades and resets reactor routing")
	check(not lost.tractor and lost.stats["minerals"] == state.stats["minerals"], "Ejection loses the tractor but retains mined totals")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{malformed")
	file.close()
	check(store.load_game() == ERR_PARSE_ERROR and not store.message.is_empty(), "Malformed saves surface an explicit load failure")
	var unavailable := CampaignStore.new(path + "/missing/save.json")
	check(unavailable.save_game(state) != OK and not unavailable.message.is_empty(), "A failed write is reported, not treated as success")
	for orbital in [false, true]:
		var boss := BossEncounter.new()
		boss.orbital = orbital
		root.add_child(boss)
		var core_armor: int = boss.core.armor
		boss.core.receive_hit(1000)
		check(boss.core.armor == core_armor and boss.core.shield_cover.visible, "Boss core starts covered and shielded")
		var defenses := [boss.thermal_emitter] if orbital else [boss.parts[0], boss.parts[1]]
		for defense: BossPart in defenses:
			for _hit in range(defense.maximum_armor):
				defense.receive_hit(1)
		boss.advance(0.01, Vector3(0, 12, 200), Vector3.ZERO)
		check(boss.core.unlocked and not boss.core.shield_cover.visible, "Disabling the appropriate reactor interlock exposes the core")
		for _hit in range(boss.core.maximum_armor):
			boss.core.receive_hit(1)
		check(boss.defeated(), "Boss is beatable with basic primary damage and no secondary ammunition")
		boss.queue_free()
	DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path + ".tmp"):
		DirAccess.remove_absolute(path + ".tmp")
	await process_frame
	print("CAMPAIGN_TEST_FAILURES=", failures)
	quit(failures)

func verify_named_games() -> void:
	var game: Node3D = preload("res://main.tscn").instantiate()
	game.normal_save_path = path
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var market := CampaignState.new()
	market.phase = "market"
	market.reward(2000)
	market.purchase("hawk")
	game.store.save_game(market)
	game.campaign = market
	game._show_market()
	game.hud.named_games_requested.emit()
	game._process(0)
	check(game.music.requested == "station" and not game.music.paused, "Market save browser keeps the station soundtrack")
	game._save_named_game("After shopping")
	var ground := market.copy()
	ground.phase = "ground"
	game.store.save_game(ground)
	game.campaign = ground
	game._load_phase()
	await process_frame
	game.pause_flight()
	game.campaign.reward(100)
	game.hud.named_games_requested.emit()
	game._process(0)
	check(game.music.paused, "Opening named games from pause does not resume music")
	game._save_named_game("Canyon 1")
	game._save_named_game("After shopping")
	var slots: CampaignStore = game.store
	var shop := slots.named_slot("After shopping")
	check(game.hud.mode == "notice" and shop.load_game() == OK and shop.state.to_dict() == market.to_dict(), "Saving over an existing name asks before replacing its market state")
	check(slots.slot_names() == PackedStringArray(["After shopping", "Canyon 1"]) and slots.named_slot("../escape") == null, "Separate named saves are selectable and cannot escape the save location")
	game._load_named_game("After shopping")
	check(game.hud.mode == "market" and game.campaign.to_dict() == market.to_dict(), "A paused pilot can restore purchases and credits from a named market save")
	game.hud.named_games_requested.emit()
	game._load_named_game("Canyon 1")
	await process_frame
	check(game.hud.mode == "flight" and game.flight.elapsed == 0 and game.campaign.credits == market.credits and slots.load_game() == OK and slots.state.phase == "ground", "Loading from market restarts the saved phase without its uncheckpointed rewards and restores Continue")
	for label in slots.slot_names():
		DirAccess.remove_absolute(slots.named_slot(label).path)
	game.queue_free()
	await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
