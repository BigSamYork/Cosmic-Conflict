extends SceneTree

var failures: int = 0
var path: String
var captures: String = ""

class FailingStore extends CampaignStore:
	var blocked: bool = true
	func save_game(candidate: CampaignState) -> Error:
		if blocked:
			blocked = false
			message = "Simulated checkpoint failure after recording the completed tour."
			return ERR_CANT_CREATE
		return super.save_game(candidate)

func _initialize() -> void:
	path = "user://campaign-completion-test-%d.json" % OS.get_process_id()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	call_deferred("run")

func run() -> void:
	verify_tours()
	verify_ranks()
	verify_records()
	verify_migration()
	await verify_gameplay_and_ui()
	await verify_difficulty()
	for suffix in ["", ".hall-of-fame.json"]:
		if FileAccess.file_exists(path + suffix):
			check(DirAccess.remove_absolute(path + suffix) == OK, "Isolated completion fixture removed")
	print("CAMPAIGN_COMPLETION_FAILURES=", failures)
	quit(failures)

func completed(assisted: bool = false) -> CampaignState:
	var state := CampaignState.new()
	state.phase = "market"
	state.assisted = assisted
	state.stats["shots"] = 200
	state.stats["hits"] = 150
	state.hull_damage = 40
	state.reward(4000)
	state.purchase("primary")
	state.purchase("secondary")
	for _i in range(25):
		state.record_combat_kill(20)
	for sector in SectorCatalog.AVAILABLE:
		state.depart(sector)
		state.stats["bosses"] += 2
		state.dock(true)
	return state

func verify_tours() -> void:
	var state := CampaignState.new()
	state.phase = "market"
	for sector in ["xylo", "vespera", "cryo"]:
		state.depart(sector)
		state.dock(true)
	check(state.tour_result.is_empty(), "Three planets do not prematurely complete a tour")
	state.depart("ignis")
	state.dock(true)
	check(state.tour_result.is_empty(), "Four planets no longer prematurely seal a new six-world tour")
	for sector in ["thalassa", "kharon"]:
		state.depart(sector)
		state.dock(true)
	var frozen: Dictionary = state.to_dict()
	state.dock(true)
	state.eject()
	check(state.to_dict() == frozen and not state.tour_result.is_empty(), "Sixth-planet docking seals a result exactly once; repeated settlement cannot alter it")
	check(not state.depart("ignis").is_empty() and not state.purchase("primary").is_empty() and state.to_dict() == frozen, "A finished tour cannot launch or change its recorded loadout before Continue")
	state = completed(true)
	var before: Dictionary = state.to_dict()
	var lifetime: Dictionary = state.totals()
	check(state.continue_tour().is_empty(), "Continue accepts a completed tour")
	check(state.tour == 2 and state.health_multiplier() == 1.25 and state.cleared_sectors.is_empty() and state.replays_unlocked and state.tour_result.is_empty(), "Continue resets only tour completion while retaining permanent replay access")
	for key in CampaignHonors.LOADOUT_COUNTERS + CampaignHonors.LOADOUT_FLAGS + ["ship", "selected_secondary", "power_mode", "assisted"]:
		check(state.get(key) == before[key], "Continue retains " + key)
	check(state.totals() == lifetime and state.tour_totals()["combat_score"] == 0 and state.tour_totals()["hull_damage"] == 0 and state.tour_totals()["best_streak"] == 0, "Tour counters reset without losing lifetime totals or confusing best streaks")
	check(state.copy().to_dict() == state.to_dict(), "Later-tour checkpoint round-trips all retained and reset fields")
	var next_before: Dictionary = state.to_dict()
	check(not state.continue_tour().is_empty() and state.to_dict() == next_before, "Repeated Continue cannot skip an unfinished tour")
	state.depart("xylo")
	state.hull_damage += 12.5
	state.stats["shots"] += 20
	state.stats["hits"] += 10
	state.record_combat_kill(20)
	state.dock(true)
	check(state.tour_totals()["sorties"] == 1 and state.tour_totals()["hull_damage"] == 12.5 and state.tour_totals()["best_streak"] == 1 and state.best_streak == 25, "Later-tour damage, accuracy and streaks count only new activity")
	state.depart("cryo")
	state.eject()
	check(state.cleared_sectors == ["xylo"] and state.tour_totals()["ejections"] == 1 and state.assisted, "Ejection keeps tour clears and lifetime assistance identity")
	var restored := CampaignState.new()
	var invalid: Dictionary = state.to_dict()
	invalid["tour_start"]["shots"] = state.stats["shots"] + 1
	check(not restored.restore(invalid).is_empty(), "A baseline larger than lifetime totals is rejected")
	invalid = completed().to_dict()
	invalid["tour_result"]["rating"] += 1
	check(not restored.restore(invalid).is_empty(), "Tampered final rating is rejected")
	invalid = completed().to_dict()
	invalid["tour_result"] = {}
	check(not restored.restore(invalid).is_empty(), "A completed market save cannot silently lose its final debrief")
	invalid = completed().to_dict()
	invalid["credits"] += 1
	check(not restored.restore(invalid).is_empty(), "A completed checkpoint cannot disagree with its frozen wallet and loadout")

func verify_ranks() -> void:
	var state := CampaignState.new()
	var metrics: Dictionary = state.totals()
	metrics["shots"] = 200
	metrics["hits"] = 200
	metrics["combat_score"] = 100000
	metrics["best_streak"] = 25
	check(CampaignHonors.rating(metrics, true) == 1000, "Perfect measured tour reaches 1000 rating points")
	metrics["ejections"] = 1
	metrics["hull_damage"] = 100
	check(CampaignHonors.rating(metrics, true) == 900, "One ejection and 100 actual hull damage cost exactly 100 survival points")
	metrics["spent"] = 100000
	check(CampaignHonors.rating(metrics, true) == 900, "Buying upgrades never penalizes rank")
	metrics["shots"] = 19
	metrics["hits"] = 19
	check(CampaignHonors.score_parts(metrics, true)["accuracy"] == 0, "Nineteen shots cannot claim the accuracy rating")
	metrics["shots"] = 20
	metrics["hits"] = 10
	check(CampaignHonors.score_parts(metrics, true)["accuracy"] == 150, "Twenty-shot 50-percent accuracy gives exactly 150 points")
	check(CampaignHonors.score_parts(metrics, false)["survival"] == 0, "Unknown legacy damage never fabricates a pristine-survival score")
	metrics["ejections"] = 100
	metrics["hull_damage"] = 100000
	metrics["combat_score"] = 999999
	metrics["best_streak"] = 1000
	check(CampaignHonors.score_parts(metrics, true) == {"accuracy": 150, "combat": 300, "survival": 0, "streak": 150}, "Repeated kills cannot exceed component caps and losses cannot produce negative ratings")
	for i in range(1, CampaignHonors.THRESHOLDS.size()):
		var threshold: int = CampaignHonors.THRESHOLDS[i]
		check(CampaignHonors.rank_for(threshold - 1) == i - 1 and CampaignHonors.rank_for(threshold) == i, "Rank threshold %d awards the intended rank only when reached" % threshold)

func verify_records() -> void:
	var state: CampaignState = completed()
	var hall := HallOfFameStore.new(path + ".hall-of-fame.json")
	check(hall.record_tour(state.tour_result) == OK and hall.record_tour(state.tour_result) == OK and hall.records.size() == 1, "Retiring or retrying the same frozen result writes one record")
	var assisted: CampaignState = completed(true)
	check(hall.record_tour(assisted.tour_result) == OK and hall.ranked(true).size() == 1 and hall.ranked(false).size() == 1, "Assisted and unassisted records occupy separate rankings")
	state.continue_tour()
	for sector in SectorCatalog.AVAILABLE:
		state.depart(sector)
		state.dock(true)
	check(hall.record_tour(state.tour_result) == OK and hall.ranked(false).size() == 2, "A later tour has a distinct record without duplicating its predecessor")
	var record_bytes: String = FileAccess.get_file_as_string(hall.path)
	var conflict: Dictionary = state.tour_result.duplicate(true)
	conflict["loadout"]["credits"] += 1
	check(hall.record_tour(conflict) == ERR_INVALID_DATA and FileAccess.get_file_as_string(hall.path) == record_bytes, "Conflicting retries preserve the original Hall of Fame bytes")
	var file := FileAccess.open(hall.path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(hall.record_tour(completed().tour_result) == ERR_PARSE_ERROR and not hall.message.is_empty() and FileAccess.get_file_as_string(hall.path) == "{broken", "Malformed records surface an error and are never overwritten as an empty Hall of Fame")
	DirAccess.remove_absolute(hall.path)
	var blocked := HallOfFameStore.new(path + ".missing-parent\\records.json")
	check(blocked.record_tour(state.tour_result) != OK and not blocked.message.is_empty(), "Unwritable record storage returns an explicit failure")

func verify_migration() -> void:
	var legacy_state := CampaignState.new()
	legacy_state.required_sectors = SectorCatalog.LEGACY.duplicate()
	legacy_state.phase = "market"
	for sector in SectorCatalog.LEGACY:
		legacy_state.depart(sector)
		legacy_state.dock(true)
	var original: Dictionary = legacy_state.to_dict()
	original["schema"] = 10
	for key in ["operation_id", "tour", "tour_start", "tour_best_streak", "hull_damage", "damage_history_complete", "tour_damage_complete", "tour_result"]:
		original.erase(key)
	var bytes: String = JSON.stringify(original)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(bytes)
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and store.state.credits == original["credits"] and store.state.cleared_sectors.size() == 4, "Schema-ten completed operations retain credits, equipment and all four clears")
	check(not store.state.tour_result.is_empty() and not store.state.tour_damage_complete and store.state.hull_damage == 0, "Migrated completion gets a debrief with honestly incomplete damage history")
	var identity: String = store.state.operation_id
	check(store.load_game() == OK and store.state.operation_id == identity, "Legacy identity is stable before the upgraded checkpoint is first written")
	check(store.save_game(store.state) == OK and FileAccess.get_file_as_string(store.migration_backup_path) == bytes, "Schema-eleven migration retains the exact original schema-ten backup")
	DirAccess.remove_absolute(store.migration_backup_path)
	check(store.load_game() == OK and not store.migrated and store.state.tour_result["operation_id"] == identity, "Reloading the migrated result keeps its record identity")
	store.state.continue_tour()
	check(store.state.tour_damage_complete and not store.state.damage_history_complete, "Next tour gets full damage tracking while legacy lifetime incompleteness stays visible")

func verify_gameplay_and_ui() -> void:
	AudioServer.set_bus_mute(0, true)
	var game: Node3D = load("res://main.tscn").instantiate()
	game.normal_save_path = path
	game.automation = "--unit-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.flight = FlightState.new()
	game.flight.configure_campaign(game.campaign)
	game.flight.shields = 2
	game.flight.hull = 30
	game._apply_pilot_damage("TEST", 18)
	check(game.campaign.hull_damage == 16, "Gameplay damage records only sixteen actual hull points after two shield points")
	game._apply_pilot_damage("COOLDOWN", 18)
	check(game.campaign.hull_damage == 16, "Rejected cooldown hits do not add phantom damage")
	game.flight.impact_cooldown = 0
	game._apply_pilot_damage("OVERKILL", 100)
	check(game.campaign.hull_damage == 30, "Overkill records only the fourteen remaining hull points")
	var checkpoint := CampaignStore.new(path)
	game.campaign.hull = 30
	check(checkpoint.save_game(game.campaign) == OK, "Damage tracking enters the same atomic checkpoint as rewards")
	game.campaign.hull_damage += 10
	check(checkpoint.load_game() == OK and checkpoint.state.hull_damage == 30, "Restoring an unfinished phase rolls damage back with other statistics")
	game.campaign = completed(true)
	game.store = CampaignStore.new(path)
	check(game.store.save_game(game.campaign) == OK, "Integration fixture saves an actual completed campaign")
	game._show_market()
	if game.campaign.homecoming_pending:
		check(game.hud.menu.find_child("CampaignMedal", true, false) == null, "Arrival roll precedes the medal")
		game._advance_homecoming(9)
		game._advance_homecoming(1)
		check(game.homecoming_knocks == 2, "Two knocks answer the final manifest")
		game._advance_homecoming(3)
	await layout_check(game, "campaign-debrief")
	check(game.mode == game.Mode.CAMPAIGN_COMPLETE and game.hud.mode == "campaign_result", "Fourth-planet completion routes to the final debrief instead of ordinary shopping")
	var statistics: ScrollContainer = game.hud.menu.find_child("CampaignStatistics", true, false)
	statistics.scroll_vertical = 10000
	await layout_check(game, "campaign-debrief-statistics")
	press(game, "HOW RANKS ARE CALCULATED")
	await layout_check(game, "campaign-rank-rules")
	press(game, "BACK TO CAMPAIGN DEBRIEF")
	press(game, "CONTINUE / BEGIN TOUR 2")
	await layout_check(game, "campaign-continue-confirmation")
	press(game, "CANCEL")
	var before: Dictionary = game.campaign.to_dict()
	press(game, "RETIRE / RECORD AND RETURN TO TITLE")
	check(game.mode == game.Mode.TITLE and game.hud.can_resume, "Retire returns to title while leaving the completed campaign resumable")
	await layout_check(game, "campaign-retired-title")
	game._continue_campaign()
	check(game.campaign.to_dict() == before and game.mode == game.Mode.CAMPAIGN_COMPLETE, "Resume after retirement restores the same frozen debrief and wallet")
	game._retire_campaign()
	game._continue_campaign()
	var hall: HallOfFameStore = game._hall_store()
	check(hall.load_records() == OK and hall.records.size() == 1, "Repeated retirement and resume cannot duplicate a Hall of Fame entry")
	game._show_hall_of_fame(true)
	await layout_check(game, "campaign-hall-assisted")
	for node in game.hud.menu.find_children("*", "Button", true, false):
		if node.text.begins_with("%04d /" % before["tour_result"]["rating"]):
			node.pressed.emit()
			break
	check(game.hud.mode == "campaign_result" and game.hud.menu.find_child("CampaignMedal", true, false).rank == before["tour_result"]["rank"], "Selecting a recorded tour displays its own medal and details")
	await layout_check(game, "campaign-record-detail")
	game._show_campaign_result()
	game.store = FailingStore.new()
	game.store.path = path
	var print_errors: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	game._begin_next_tour()
	Engine.print_error_messages = print_errors
	check(game.mode == game.Mode.SAVE_ERROR and game.campaign.to_dict() == before, "A failed next-tour checkpoint keeps the completed campaign in memory")
	var retained := CampaignStore.new(path)
	check(retained.load_game() == OK and retained.state.to_dict() == before, "A failed next-tour checkpoint keeps the completed campaign on disk")
	await layout_check(game, "campaign-save-retry")
	game._begin_next_tour()
	check(game.campaign.tour == 2 and game.mode == game.Mode.MARKET and game.campaign.credits == before["credits"], "Continue records the completed tour and opens the next tour's market with the same wallet")
	check(hall.load_records() == OK and hall.records.size() == 1, "Continuing an already retired tour does not write another entry")
	game._continue_campaign()
	check(game.campaign.tour == 2 and game.campaign.cleared_sectors.is_empty() and game.campaign.tour_result.is_empty(), "A fresh process can resume the next tour without returning to the old debrief")
	game.campaign = completed()
	game.campaign.tour_damage_complete = false
	game.campaign.damage_history_complete = false
	game.campaign._seal_tour()
	game._show_campaign_result()
	await layout_check(game, "campaign-legacy-damage")
	game.queue_free()
	await process_frame

func press(game: Node3D, text: String) -> void:
	for node in game.hud.menu.find_children("*", "Button", true, false):
		if node.text == text:
			node.pressed.emit()
			return
	check(false, "Expected actionable button: " + text)

func layout_check(game: Node3D, name: String) -> void:
	await process_frame
	await process_frame
	var viewport: Rect2 = game.get_viewport().get_visible_rect()
	check(viewport.encloses(game.hud.menu.get_global_rect()), "All menu bounds fit the actual viewport: " + name)
	if not captures.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(game.get_viewport().get_texture().get_image().save_png(captures.path_join(name + ".png")) == OK, "Native campaign screen captured: " + name)

func verify_difficulty() -> void:
	for tour in [1, 2, 5, 12]:
		var state := CampaignState.new()
		state.tour = tour
		var factor: float = state.health_multiplier()
		var world := MissionWorld.new()
		world.health_scale = factor
		root.add_child(world)
		world.build("orbit", Transform3D.IDENTITY, "vespera")
		var fighter: EnemyFighter = world.targets[0]
		var heavy: EnemyFighter = world.targets[2]
		check(fighter.armor == ceili(6 * factor) and heavy.armor == ceili(18 * factor), "Actual orbital light/heavy health follows bounded scaling in tour %d" % tour)
		check(fighter.lifetime == 23 and fighter.velocity.length() < 17 and world.wave_index == 1, "Tour %d does not scale wave counts, lifetime or flight speed" % tour)
		world.queue_free()
		var branch := GroundBranch.new()
		branch.health_scale = factor
		root.add_child(branch)
		check(branch.turrets[0].armor == ceili(6 * factor) and branch.turrets[0].fire_interval == 1.9, "Hazard-branch turrets scale health, not firing cadence, in tour %d" % tour)
		branch.queue_free()
		for sector in SectorCatalog.AVAILABLE:
			var encounter := BossEncounter.new()
			encounter.sector = sector
			encounter.orbital = true
			encounter.health_scale = factor
			root.add_child(encounter)
			check(encounter.core.maximum_armor == ceili(64 * factor) and encounter.core.armor == encounter.core.maximum_armor and not encounter.core.unlocked, "Tour %d %s boss doubles at most, preserving core protection" % [tour, sector])
			encounter.queue_free()
		await process_frame

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
