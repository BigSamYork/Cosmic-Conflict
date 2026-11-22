extends SceneTree

var failures: int = 0

class FailingStore extends CampaignStore:
	var blocked: bool = true
	func _init(save_path: String) -> void:
		super(save_path)
	func save_game(candidate: CampaignState) -> Error:
		if blocked:
			blocked = false
			message = "Simulated unavailable checkpoint storage."
			return ERR_CANT_CREATE
		return super.save_game(candidate)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	verify_state()
	verify_frost()
	await verify_worlds()
	await verify_selection()
	await process_frame
	print("SECTOR_TEST_FAILURES=", failures)
	quit(failures)

func verify_state() -> void:
	var state := CampaignState.new()
	state.phase = "market"
	check(state.depart("cryo").is_empty() and state.sector == "cryo" and state.phase == "launch", "Either available sector can be the first mission")
	state.dock(true)
	var paid: int = state.credits
	state.dock(true)
	check(state.cleared_sectors == ["cryo"] and state.credits == paid and not state.can_visit("cryo") and state.can_visit("ignis"), "Sector completion and rewards are idempotent; unfinished available sectors come next")
	var before: Dictionary = state.to_dict()
	check(not state.depart("cryo").is_empty() and state.to_dict() == before and not state.depart("unknown").is_empty(), "Premature replays and unavailable sectors explicitly reject departure")
	state.depart("ignis")
	state.dock(true)
	check(not state.can_visit("ignis") and state.can_visit("vespera"), "A new three-sector campaign still has its unfinished destination")
	state.depart("vespera")
	state.dock(true)
	check(not state.can_visit("ignis") and state.can_visit("xylo"), "New campaigns retain their unfinished fourth-sector objective")
	state.depart("xylo")
	state.dock(true)
	for sector in ["thalassa", "kharon"]:
		state.depart(sector)
		state.dock(true)
	check(state.can_visit("ignis") and state.can_visit("cryo") and state.can_visit("vespera") and state.can_visit("xylo") and state.replays_unlocked and not state.tour_result.is_empty(), "Clearing available sectors retains replay entitlement and presents the completed tour")
	state.continue_tour()
	state.depart("cryo")
	state.dock(true)
	state.depart("ignis")
	state.eject()
	check(state.sector == "ignis" and state.cleared_sectors == ["cryo"] and state.credits > 0 and state.ship.is_empty(), "Ejection preserves current-tour sector progress and earnings while losing the ship")
	var old := CampaignState.new()
	old.stats["sorties"] = 2
	old.credits = 450
	old.earned = 450
	old.primary_level = 1
	var legacy: Dictionary = old.to_dict()
	legacy["schema"] = 7
	legacy.erase("sector")
	legacy.erase("cleared_sectors")
	var path: String = "user://sector-migration-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK and store.state.sector == "ignis" and store.state.cleared_sectors == ["ignis"] and store.state.phase == "ground" and store.state.credits == 450 and store.state.primary_level == 1, "Schema-seven migration preserves an active Ignis replay, wallet and equipment")
	check(store.save_game(store.state) == OK and store.migration_backup_path.contains(".v7-") and FileAccess.get_file_as_string(store.migration_backup_path) == JSON.stringify(legacy), "Migration preserves the exact original schema-seven file")
	DirAccess.remove_absolute(store.migration_backup_path)
	DirAccess.remove_absolute(path)
	var invalid: Dictionary = old.to_dict()
	invalid["sector"] = "unknown"
	check(not CampaignState.new().restore(invalid).is_empty(), "Unavailable saved destinations are rejected")
	invalid = old.to_dict()
	invalid["cleared_sectors"] = ["cryo", "cryo"]
	check(not CampaignState.new().restore(invalid).is_empty(), "Duplicate completion flags are rejected")

func verify_frost() -> void:
	for fps in [30, 45, 120]:
		var cold := FlightState.new()
		var normal := FlightState.new()
		cold.training = false
		normal.training = false
		cold.aim = Vector2(0.7, -0.5)
		normal.aim = cold.aim
		cold.apply_frost()
		var elapsed: float = 0
		while elapsed < 0.1 - 0.000001:
			var step: float = minf(1.0 / fps, 0.1 - elapsed)
			cold.advance(step, true)
			normal.advance(step, true)
			elapsed += step
		check(cold.offset.length() < normal.offset.length() and cold.shots == normal.shots and is_equal_approx(cold.frost_remaining, 1.9), "Frost slows steering, not weapons, at %d Hz" % fps)
		check(not cold.apply_frost() and is_equal_approx(cold.frost_remaining, 1.9), "Repeated frost does not extend an active slowdown")
		cold.request_evasion()
		cold.advance(0.65, false)
		check(is_equal_approx(absf(cold.offset.x), FlightState.EVADE_EDGE) and cold.evade_remaining == 0, "Shift retains its full defensive dash while frosted")
		cold.advance(1.25, false)
		check(cold.frost_remaining == 0, "Frost expires on its original two-second schedule")
	var damage_only := FlightState.new()
	var unaffected := FlightState.new()
	damage_only.training = false
	damage_only.frost_slowdown = false
	damage_only.apply_frost()
	damage_only.aim = Vector2.ONE
	unaffected.aim = Vector2.ONE
	damage_only.advance(0.1, false)
	unaffected.advance(0.1, false)
	check(damage_only.offset.is_equal_approx(unaffected.offset), "The damage-only comparison mode leaves steering unchanged")
	var paused: float = damage_only.frost_remaining
	damage_only.advance(5.0, false, false)
	check(damage_only.frost_remaining == paused, "Pause freezes frost status instead of consuming its duration")

func verify_worlds() -> void:
	for fps in [30, 45]:
		var field := FrostField.new()
		root.add_child(field)
		var hits: int = 0
		for _i in range(fps):
			hits += int(field.advance(1.0 / fps, Vector3(0, 10, 0), Vector3(0, 10, 0)))
		check(hits == 0, "Frost fissure warning is non-damaging at %d Hz" % fps)
		for _i in range(fps * 3):
			hits += int(field.advance(1.0 / fps, Vector3(0, 10, 0), Vector3(0, 10, 0)))
		check(hits == 1, "A frost eruption hits at most once at %d Hz" % fps)
		field.queue_free()
	var world := MissionWorld.new()
	root.add_child(world)
	world.build("orbit_boss", Transform3D.IDENTITY, "cryo")
	world.boss.pursuing = false
	world.boss.advance(0.1, Vector3(0, 0, 150), Vector3.ZERO)
	world.boss.stun()
	world.advance(1.0, Transform3D.IDENTITY)
	check(world.carrier_drones.is_empty() and world.drone_clock == 3, "EMP disables carrier reinforcement deployment without spending its launch timer")
	world.boss.advance(2.0, Vector3(0, 0, 150), Vector3.ZERO)
	world.advance(3.1, Transform3D.IDENTITY)
	check(world.boss.drone_bay != null and world.boss.thermal_emitter == null and world.carrier_drones.size() == 2, "Hydra has a real drone bay and launches a distinct reinforcement wave")
	world.advance(10.0, Transform3D.IDENTITY)
	world.advance(10.0, Transform3D.IDENTITY)
	check(world.carrier_drones.size() == 4, "Carrier reinforcement population is bounded")
	var launches: int = world.drone_launches
	world.boss.drone_bay.receive_hit(world.boss.drone_bay.armor)
	world.advance(30, Transform3D.IDENTITY)
	check(world.drone_launches == launches and not world.boss.defeated() and not world.boss.core.unlocked, "Destroying the optional drone bay stops launches without bypassing the required boss weak points")
	world.queue_free()
	var belt := MissionWorld.new()
	root.add_child(belt)
	belt.build("asteroids", Transform3D.IDENTITY, "cryo")
	var giants: int = 0
	var variants: Dictionary = {}
	var speeds: Dictionary = {}
	var minimum_clearance: float = INF
	var correct_scale: bool = true
	for rock in belt.backdrop.rocks:
		if not rock.get("giant", false):
			continue
		giants += 1
		variants[rock["variant"]] = true
		speeds[snappedf(rock["spin"], 0.005)] = true
		correct_scale = correct_scale and is_equal_approx(rock["radius"], rock["normal_radius"] * 5)
		for distance in range(0, 2881, 48):
			minimum_clearance = minf(minimum_clearance, rock["position"].distance_to(FlightDirector.asteroid_point(distance)) - rock["radius"] * 1.3 - Vector2(FlightState.WIDE_HALF_WIDTH, FlightState.CORRIDOR.y).length() - 0.6)
	check(giants > 0 and correct_scale and variants.size() == 2 and speeds.size() > 12, "Cryo giants use five-times scale, two distinct forms and varied tumble speeds")
	check(minimum_clearance > 0, "Five-times-scale giants remain outside the full reachable corridor at every sampled travel position (%.2fm)" % minimum_clearance)
	check(AsteroidArt.point(Vector3.UP, 3).length() > AsteroidArt.point(Vector3.UP, 4).length() * 1.15, "The second oblong form has a visibly different pinched cross-section")
	belt.queue_free()
	await process_frame

func verify_selection() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	var path: String = "user://sector-selection-%d.json" % OS.get_process_id()
	game.normal_save_path = path
	game._open_sector_map(true)
	game.hud.sector_cancelled.emit()
	check(game.mode == game.Mode.TITLE and not FileAccess.file_exists(path), "Cancelling initial sector selection does not create or replace a campaign")
	game._open_sector_map(true)
	game._choose_sector("cryo")
	await process_frame
	await process_frame
	check(game.campaign.sector == "cryo" and game.sequence == "station_departure" and game.heat_vents.is_empty() and game.frost_fields.size() == 8 and game.ground_branch.sector == "cryo", "Selecting Cryo builds its own prepared icy ground and frost hazards")
	check(game.launch_approach.sector == "cryo" and game.campaign.phase == "launch", "Cryo departure begins at the station with the correct destination planet")
	var saved := CampaignStore.new(path)
	check(saved.load_game() == OK and saved.state.sector == "cryo", "The launch checkpoint preserves the selected sector")
	game.campaign.phase = "market"
	game.campaign.dock(false)
	game._show_market()
	game.store.save_game(game.campaign)
	var checkpoint: String = FileAccess.get_file_as_string(path)
	game._open_sector_map(false)
	game.hud.sector_cancelled.emit()
	check(game.mode == game.Mode.MARKET and FileAccess.get_file_as_string(path) == checkpoint, "Cancelling the market sector map leaves the saved checkpoint unchanged")
	game._open_sector_map(false)
	var station: Node3D = game.station
	var before: Transform3D = game.camera.global_transform
	var sky: float = game.sky_icy_mix
	game.store = FailingStore.new(path)
	var errors_enabled: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	game._choose_sector("ignis")
	Engine.print_error_messages = errors_enabled
	check(game.mode == game.Mode.SAVE_ERROR and game.campaign.sector == "cryo" and FileAccess.get_file_as_string(path) == checkpoint and game.station == station, "A failed departure save reports an error without changing the destination, checkpoint or station")
	var retry: Button
	for button: Button in game.hud.menu.find_children("*", "Button", true, false):
		if button.text == "RETRY SAVE":
			retry = button
	check(retry != null, "A failed sector departure offers an explicit retry")
	if retry != null:
		retry.pressed.emit()
	check(game.station == station and game.camera.global_transform == before and game.sky_icy_mix == sky and game.campaign.sector == "ignis", "Cross-sector departure preserves the existing station, camera and departure sky")
	for _i in range(50 * 30):
		game._physics_process(1.0 / 30)
		if game.mode == game.Mode.FLIGHT:
			break
	check(game.campaign.phase == "ground" and game.flight.elapsed == 0 and game.sky_icy_mix == 0 and game.heat_vents.size() == 8 and game.frost_fields.is_empty(), "Cross-sector arrival smoothly reaches Ignis with the full ground timer and correct hazards")
	game.flight.apply_frost()
	game.campaign.phase = "ground_boss"
	game._enter_phase(true)
	check(game.flight.frost_remaining == FlightState.FROST_DURATION, "An immediate phase handoff preserves an active frost effect")
	game.campaign.sector = "cryo"
	game.campaign.phase = "orbit_boss"
	await game._load_phase()
	for part in [game.boss.parts[0], game.boss.parts[1], game.boss.core]:
		part.unlocked = true
		part.receive_hit(part.armor)
	game._process(0)
	check(game.hud.boss_fraction == 0 and not game.boss.drone_bay.destroyed, "The optional drone bay does not inflate the required boss health bar")
	game._finish_phase()
	var preview: MissionWorld = game.approaching_belt
	var preview_clearance := backdrop_clearance(game.camera.global_position, preview.backdrop)
	check(preview_clearance > VectorArt.VIEW_DISTANCE, "The giant belt is prepared beyond draw range rather than popping into view (%.2fm)" % preview_clearance)
	var nearest: float = INF
	for _i in range(25 * 30):
		if game.mode == game.Mode.FLIGHT:
			break
		game._physics_process(1.0 / 30)
		nearest = minf(nearest, backdrop_clearance(game.camera.global_position, preview.backdrop))
	check(nearest > 1, "The actual orbital approach clears every cold backdrop rock throughout the rise (%.2fm)" % nearest)
	game.flight.distance = FlightDirector.ASTEROID_SPEED * FlightDirector.ASTEROID_DURATION
	game.flight.elapsed = FlightDirector.ASTEROID_DURATION
	game.director.advance("asteroids", 0, game.flight.distance, game.flight.elapsed, game.targets)
	game._update_camera()
	game._finish_phase()
	nearest = INF
	var passed_before_climb: bool = false
	for _i in range(36 * 30):
		if game.mode == game.Mode.MARKET:
			break
		game._physics_process(1.0 / 30)
		nearest = minf(nearest, backdrop_clearance(game.camera.global_position, preview.backdrop))
		if game.sequence == "belt_climb" and game.sequence_time == 0:
			var inverse: Transform3D = game.director.origin.affine_inverse()
			var pilot_travel: float = -(inverse * game.camera.global_position).z
			passed_before_climb = true
			for rock in preview.backdrop.rocks:
				var farthest: float = -(inverse * Vector3(rock["position"])).z + rock["radius"] * 1.3
				passed_before_climb = passed_before_climb and pilot_travel - farthest >= 23.9
	check(passed_before_climb, "Every outer rock's full rotating envelope has passed at least 24m behind the route position before the pull-up starts")
	check(game.mode == game.Mode.MARKET and nearest > 1, "The real coast, pull-up and docking path never fly through a giant or ordinary backdrop rock (%.2fm)" % nearest)
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func backdrop_clearance(pilot: Vector3, backdrop: BeltBackdrop) -> float:
	var nearest: float = INF
	for rock in backdrop.rocks:
		nearest = minf(nearest, pilot.distance_to(rock["position"]) - rock["radius"] * 1.3)
	return nearest

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
