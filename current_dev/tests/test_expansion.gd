extends SceneTree

var failures: int = 0
var game: Node3D
var path: String
var captures: String = ""

func _initialize() -> void:
	path = "user://expansion-test-%d.json" % OS.get_process_id()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	call_deferred("run")

func run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.unfocusable = true
	root.mouse_passthrough = true
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	verify_saves()
	await verify_hazards()
	game = load("res://main.tscn").instantiate()
	game.automation = "--unit-fixture"
	game.normal_save_path = path
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	await verify_worlds()
	await verify_boss_radars()
	await verify_transitions()
	game.queue_free()
	await process_frame
	for file in [path, path + ".records"]:
		if FileAccess.file_exists(file):
			check(DirAccess.remove_absolute(file) == OK, "Isolated expansion save removed")
	print("EXPANSION_FAILURES=", failures)
	quit(failures)

func verify_saves() -> void:
	var old := CampaignState.new()
	old.phase = "market"
	old.required_sectors = SectorCatalog.LEGACY.duplicate()
	old.reward(3000)
	old.purchase("hawk")
	old.purchase("primary")
	for sector in SectorCatalog.LEGACY:
		old.depart(sector)
		old.stats["bosses"] += 2
		old.dock(true)
	var source: Dictionary = old.to_dict()
	source["schema"] = 11
	source.erase("required_sectors")
	source["tour_result"].erase("sectors")
	var original_record: Dictionary = source["tour_result"].duplicate(true)
	var broken: Dictionary = source.duplicate(true)
	broken["tour_result"] = {}
	check(not CampaignState.new().restore(broken).is_empty(), "A missing frozen legacy result cannot be silently reclassified as an unfinished tour")
	var bytes: String = JSON.stringify(source, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(bytes)
	file.close()
	var store := CampaignStore.new(path)
	check(store.load_game() == OK, "Schema-eleven completed campaign loads: " + store.message)
	if store.state == null:
		return
	check(store.state.tour_result == CampaignHonors.normalized_record(original_record) and store.state.required_sectors == SectorCatalog.LEGACY and store.state.ship == old.ship and store.state.credits == old.credits, "Frozen four-world results, hull and wallet are unchanged")
	check(store.save_game(store.state) == OK and FileAccess.get_file_as_string(store.migration_backup_path) == bytes, "Schema-twelve migration preserves the exact original save bytes")
	DirAccess.remove_absolute(store.migration_backup_path)
	var hall := HallOfFameStore.new(path + ".records")
	check(hall.record_tour(original_record) == OK, "Legacy four-world record remains accepted without fabricated sectors")
	var record_bytes: String = FileAccess.get_file_as_string(hall.path)
	check(hall.record_tour(store.state.tour_result) == OK and FileAccess.get_file_as_string(hall.path) == record_bytes, "Re-recording a migrated completed tour does not rewrite or duplicate the original record")
	check(store.state.continue_tour().is_empty() and store.state.required_sectors == SectorCatalog.AVAILABLE and store.state.replays_unlocked, "Continue after a legacy completion begins six worlds and retains replay access")
	source["tour_result"] = {}
	source["phase"] = "orbit"
	source["cleared_sectors"] = ["ignis", "cryo"]
	var ongoing := CampaignState.new()
	check(ongoing.restore(source).is_empty() and ongoing.required_sectors.size() == 6 and ongoing.cleared_sectors == ["ignis", "cryo"] and ongoing.phase == "orbit" and ongoing.replays_unlocked, "Unfinished tours gain two worlds without losing checkpoint, clears or earned replay rights")
	var invalid: Dictionary = source.duplicate(true)
	invalid["sector"] = "thalassa"
	check(not CampaignState.new().restore(invalid).is_empty(), "A pre-expansion save cannot claim a not-yet-available planet")
	invalid = ongoing.to_dict()
	invalid["required_sectors"] = ["ignis", "ignis"]
	check(not CampaignState.new().restore(invalid).is_empty(), "Duplicate or incomplete tour requirement lists are rejected")
	var six := CampaignState.new()
	six.phase = "market"
	for sector in SectorCatalog.LEGACY:
		six.depart(sector)
		six.dock(true)
	check(six.tour_result.is_empty() and not six.replays_unlocked, "Four original planets do not prematurely finish a new six-world tour")
	for sector in ["thalassa", "kharon"]:
		six.depart(sector)
		six.dock(true)
	check(six.copy().tour_result == six.tour_result and CampaignHonors.record_sectors(six.tour_result).size() == 6 and six.replays_unlocked, "Six worlds seal a persistent six-world result and unlock replays")
	check(hall.record_tour(six.tour_result) == OK and hall.records.size() == 2 and CampaignHonors.record_sectors(hall.records[0]).size() == 4 and CampaignHonors.record_sectors(hall.records[1]).size() == 6, "Four- and six-world records coexist with their original scopes")

func verify_hazards() -> void:
	for fps in [30, 45, 120]:
		var lightning := StormLightning.new()
		root.add_child(lightning)
		lightning.advance(0.05, Vector3.ZERO, Vector3.ZERO)
		var on_channel: Vector3 = lightning.paths[0][18]
		var hits: int = 0
		for i in range(fps * 4):
			hits += int(lightning.advance(1.0 / fps, on_channel, on_channel))
		check(hits == 1, "Storm strike damages once per warned cycle at %dHz" % fps)
		var age: float = lightning.age
		lightning.advance(0, Vector3.ZERO, Vector3.ZERO)
		check(lightning.age == age, "A paused storm strike does not consume its cycle")
		check(on_channel.y > 30 and lightning.paths[0][-1].distance_to(on_channel) <= lightning.pilot_radius, "The visible channel terminates at the ship that intercepted it")
		lightning.queue_free()
	var ruin := RuinFall.new()
	ruin.travel = 560
	ruin.lane.x = 8
	root.add_child(ruin)
	check(ruin.armor == 2 and not ruin.receive_hit(1) and ruin.receive_hit(1), "A collapsing ruin chunk is removable with two baseline shots")
	ruin.queue_free()
	await process_frame

func phase(sector: String, stage: String, ship: String = "rook") -> void:
	game.campaign = CampaignState.new()
	game.campaign.sector = sector
	game.campaign.phase = stage
	game.campaign.ship = ship
	game.campaign.hull = game.campaign.hull_capacity()
	game.campaign.shields = game.campaign.shield_capacity()
	game.campaign.assisted = true
	game.store = CampaignStore.new(path)
	game.is_campaign = true
	await game._load_phase()

func verify_worlds() -> void:
	for ship in ["titan", "bastion"]:
		game.campaign = CampaignState.new()
		game.campaign.phase = "market"
		game.campaign.reward(12000)
		game.campaign.purchase("primary")
		game.campaign.purchase("secondary")
		game.store = CampaignStore.new(path)
		game._show_market()
		var credits: int = game.campaign.credits
		game._market_purchase(ship)
		check(game.campaign.ship == ship and game.cockpit_skin == ship and game.campaign.credits == credits - CampaignState.SHIPS[ship]["cost"] and game.campaign.primary_level == 1 and game.campaign.secondary, "Astra really purchases the player battleship " + ship + " and transfers upgrades")
		var saved := CampaignStore.new(path)
		check(saved.load_game() == OK and saved.state.to_dict() == game.campaign.to_dict(), "Heavy player hull, equipment and wallet survive the on-disk checkpoint")
		var configured := FlightState.new()
		configured.configure_campaign(game.campaign)
		check(configured.max_hull == CampaignState.SHIPS[ship]["hull"] and configured.max_shields == CampaignState.SHIPS[ship]["shield"] and configured.collision_radius == CampaignState.SHIPS[ship]["radius"], "Actual flight config uses the heavy hull's protection and hitbox")
		await shot("market-" + ship)
		game.campaign.eject()
		check(game.campaign.ship.is_empty() and game.campaign.primary_level == 0 and not game.campaign.secondary, "Ejection loses the heavy ship and its equipment, not its retained credit wallet")
	for sector in ["thalassa", "kharon"]:
		await phase(sector, "ground", "titan" if sector == "thalassa" else "bastion")
		game.flight.distance = 500
		game.flight.elapsed = 500 / FlightState.SPEED
		game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
		game._update_camera()
		game._stream_ground(game.flight.distance)
		check(game.heat_vents.is_empty() and game.frost_fields.is_empty() and game.flight.duration == 90, "The new world has its own environment rather than inherited volcanic/frost hazards: " + sector)
		if sector == "thalassa":
			check(game.lightning_fields.size() == 10 and game.ocean_material != null, "Thalassa has animated water, offshore geometry and ten warned storm strikes")
			verify_ocean_tiles()
			var age: float = game.ocean_age
			game.pause_flight()
			game._physics_process(3)
			check(game.ocean_age == age, "Pause freezes ocean wave and storm simulation")
			game.resume_flight()
			game._advance_ocean(1)
			check(game.ocean_material.get_shader_parameter("wave_time") == age + 1, "Actual ocean surface receives simulation-driven wave time")
			for lightning in game.lightning_fields:
				lightning.advance(2, game.camera.global_position, game.camera.global_position)
		else:
			check(game.falling_ice.size() == 8 and game.falling_ice[0] is RuinFall, "Kharon contains eight distinct warned collapsing ruin blocks")
		game._update_contacts()
		await shot("ground-" + sector)
		if sector == "thalassa" and DisplayServer.get_name() != "headless":
			var first: Image = root.get_texture().get_image()
			game._advance_ocean(1)
			await shot("ocean-waves-moving")
			var second: Image = root.get_texture().get_image()
			var changes: int = 0
			for y in range(500, 720, 2):
				for x in range(140, 1780, 2):
					var a: Color = first.get_pixel(x, y)
					var b: Color = second.get_pixel(x, y)
					if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.02:
						changes += 1
			check(changes > 500, "Visible ocean waves actually move in the forward canopy (%d changed samples)" % changes)
		if sector == "thalassa":
			await verify_storm_destruction()
		game._open_sector_map(false)
		await shot("six-world-map")
		check(root.get_visible_rect().encloses(game.hud.menu.get_global_rect()), "All six world-selection cards fit the viewport")

func verify_storm_destruction() -> void:
	var platforms := get_nodes_in_group(&"offshore_platforms")
	check(platforms.size() >= 2, "Offshore rigs stream as independently destructible structures")
	var rig: OffshorePlatform = platforms[0]
	var fighter := EnemyFighter.new()
	fighter.sector = "thalassa"
	game.world.add_child(fighter)
	fighter.global_position = rig.global_position + Vector3(0, 45, 0)
	await physics_frame
	await physics_frame
	var bolt := StormLightning.new()
	game.world.add_child(bolt)
	bolt.global_position = rig.global_position
	bolt.contact.connect(game._storm_contact)
	var credited: int = game.flight.destroyed
	var wallet: int = game.campaign.credits
	var count: int = game.explosions.size()
	var aside := rig.global_position + Vector3(50, 20, 0)
	var straight := PackedVector3Array([Vector3.UP * 90, Vector3.UP * 65, Vector3.DOWN * 4])
	bolt.cycle_id = 0
	bolt.paths.assign([straight.duplicate()])
	bolt.advance(1.51, aside, aside)
	check(fighter.destroyed and rig.collision_layer != 0 and bolt.paths[0][-1].y > 42, "A ship intercepts the bolt and explodes, shielding the platform underneath")
	bolt.advance(0.59, aside, aside)
	check(game.explosions.size() == count + 1, "Return strokes stop at the first contact without duplicating the explosion")
	await physics_frame
	bolt.age = StormLightning.CYCLE
	bolt.cycle_id = 1
	bolt.next_stroke = 0
	bolt.paths.assign([straight])
	bolt.advance(1.51, aside, aside)
	check(not rig.visible and rig.collision_layer == 0 and platforms[1].visible and game.explosions.size() == count + 2, "A subsequent direct hit blows up only that rig and removes its cover")
	var tower: DestructibleTower = game.towers[0]
	game._storm_contact(tower, tower.to_global(Vector3.UP * 3), Vector3.DOWN)
	check(tower.destroyed and tower.break_band == 2, "A lightning hit at the crown starts the tower's upper-section collapse")
	var patrol: SurfacePatrol = game.ground_branch.patrol
	patrol.job_order = [SurfacePatrol.Job.REPAIR, SurfacePatrol.Job.REPAIR, SurfacePatrol.Job.REPAIR]
	patrol.advance(0.01, aside, aside, game.campaign, game.flight, game.ground_branch.route)
	check(patrol.storm_hull != null, "The repair tender participates in storm collisions")
	if patrol.storm_hull != null:
		game._storm_contact(patrol.storm_hull, patrol.carrier.global_position, Vector3.DOWN)
		check(patrol.current < 0 and patrol.storm_hull == null, "A destroyed support ship closes its contract without paying the pilot")
	check(game.flight.destroyed == credited and game.campaign.credits == wallet, "Storm kills do not count as pilot weapons or pay a bounty")
	var hull: float = game.flight.hull
	var shields: float = game.flight.shields
	var saved_camera: Transform3D = game.camera.global_transform
	game.camera.global_position = rig.global_position + Vector3.UP * 58
	game.lightning_fields.append(bolt)
	bolt.age = 0.0
	bolt.cycle_id = 0
	bolt.next_stroke = 0
	bolt.paths.assign([PackedVector3Array([Vector3.UP * 90, Vector3.UP * 38])])
	game.flight.roll_remaining = 0.2
	game._advance_storm(1.51, game.camera.global_position)
	check(game.flight.hull == hull, "A barrel roll evades a direct lightning discharge")
	game.flight.roll_remaining = 0.0
	game._advance_storm(0.25, game.camera.global_position)
	check(game.flight.hull == 0 and game.flight.shields == 0, "An unprotected pilot ship caught by the return stroke is destroyed")
	game.lightning_fields.erase(bolt)
	game.camera.global_transform = saved_camera
	game.flight.hull = hull
	game.flight.shields = shields
	bolt.free()
	fighter.free()

func verify_ocean_tiles() -> void:
	var previous := PackedVector2Array()
	var joined := true
	var oily := 0
	var clean := 0
	var width := FrontierArt.SEA_COLUMNS + 1
	for chunk in game.ground_chunks:
		var surface: MeshInstance3D = chunk.get_child(0)
		var masks: PackedVector2Array = surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		if not previous.is_empty():
			for x in range(width):
				joined = joined and previous[x].distance_to(masks[x]) < 0.002
		previous = masks.slice(masks.size() - width)
		for mask in masks:
			oily += int(mask.x > 0.6)
			clean += int(mask.x < 0.01)
	check(joined and oily > 0 and clean > oily, "Oil plumes cross streamed boundaries continuously and leave most water clear")
	game.settings["reduced_effects"] = true
	game._apply_settings()
	check(game.ocean_material.shader == FrontierArt.WATER, "Reduced effects keeps waves with a single-pass ocean")
	game.settings["reduced_effects"] = false
	game._apply_settings()
	check(game.ocean_material.shader == FrontierArt.WATER_REFLECTION, "Full effects restores reflections on already streamed water")

func verify_boss_radars() -> void:
	for sector in SectorCatalog.AVAILABLE:
		for stage in ["ground_boss", "orbit_boss"]:
			await phase(sector, stage)
			var boss: BossEncounter = game.boss
			boss.advance(60, game.camera.global_position, Vector3.ZERO)
			game.flight.elapsed = 60
			game.flight.distance += 60 * FlightState.SPEED
			game.director.advance(stage, 0, game.flight.distance, 60, game.targets)
			game._update_camera()
			check(boss.pursuit_range < (114 if stage == "orbit_boss" else 84), "%s %s closer framing reaches the approved range" % [sector, stage])
			var all_visible: bool = true
			for part in [boss.parts[0], boss.parts[1], boss.core]:
				all_visible = all_visible and game.camera.is_position_in_frustum(part.aim_point())
			check(all_visible, "Closer framing retains every required weak point in view")
			var radar: BossRadar = boss.radars[0]
			check(radar.position.is_equal_approx(boss.radar_mount(-1)) and radar.get_parent() == boss and radar.scanner != null, "The rotating radar has a solid support rooted on the actual boss hull")
			var scanner_pose: Basis = radar.scanner.basis
			boss.advance_visuals(0.5)
			check(not scanner_pose.is_equal_approx(radar.scanner.basis), "Marine-style scanner physically rotates independently of the hull")
			var credits: int = game.campaign.credits
			var enemies: int = game.campaign.stats["enemies"]
			var streak: int = game.campaign.combo_kills
			await shot("%s-%s-radars" % [sector, stage])
			await physics_frame
			await physics_frame
			for other in boss.radars:
				var ray := PhysicsRayQueryParameters3D.create(game.camera.global_position, other.aim_point(), 3)
				var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
				check(not hit.is_empty() and hit["collider"] == other, "%s %s exposes each actual scanner collision for manual aiming" % [sector, stage])
			var query := PhysicsRayQueryParameters3D.create(game.camera.global_position, radar.aim_point(), 3)
			var contact: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
			check(not contact.is_empty() and contact["collider"] == radar, "The mounted radar's actual shootable collision is exposed beyond hull cover")
			if contact.is_empty() or contact["collider"] != radar:
				continue
			for _i in range(6):
				game._strike(contact, 1)
			check(radar.destroyed and radar.collision_layer == 0 and not radar.visible, "Six actual baseline hits destroy the radar, hide it and remove collision")
			check(game.campaign.credits == credits + 30 and game.campaign.stats["enemies"] == enemies and game.campaign.combo_kills == streak and not boss.core.unlocked, "One radar gives a single reward and leaves the core sealed")
			check(not game._strike({"collider": radar, "position": radar.aim_point()}, 10) and game.campaign.credits == credits + 30, "Destroyed radar cannot be rewarded again")
			boss.advance(0.01, game.camera.global_position, Vector3.ZERO)
			check(boss.turrets[0].interval_multiplier == 1.25, "One radar loss slows turret cadence by the agreed interval multiplier")
			boss.radars[1].receive_hit(boss.radars[1].armor)
			boss.advance(0.01, game.camera.global_position, Vector3.ZERO)
			check(boss.core.unlocked == (sector == "vespera"), "Both shield radars expose the Vespera core, with other sector objectives still active")
			check(boss.turrets[0].interval_multiplier == 1.5 and not game.explosions.is_empty() and not game.debris.is_empty(), "Both radars stack additively and real destruction includes explosion and hull-colored breakup")
			var camera_before: Basis = game.camera.basis
			var hull_before: Vector3 = boss.global_position
			boss.advance(0.1, game.camera.global_position, Vector3.ZERO)
			check(camera_before.is_equal_approx(game.camera.basis) and boss.global_position.distance_to(hull_before) < 6, "Gentle boss drift does not impose a camera oscillation or aiming lock")

func verify_transitions() -> void:
	await phase("ignis", "launch")
	var expected: Dictionary = {"station_departure": 4.0, "warp_alignment": 4.0, "hyperspace": 3.0, "planet_descent": 11.0}
	var measured: Dictionary = {}
	for _i in range(1800):
		if game.mode == game.Mode.FLIGHT:
			break
		measured[game.sequence] = measured.get(game.sequence, 0.0) + 1.0 / 60
		game._physics_process(1.0 / 60)
	for id in expected:
		check(absf(measured[id] - expected[id]) <= 1.0 / 60 + 0.00001, "Actual " + id + " duration matches the 22-second launch schedule")
	for id in ["ground_victory", "ascent", "orbital_victory", "belt_transfer", "belt_climb", "station_approach", "docking"]:
		await phase("ignis", "orbit_boss" if id == "orbital_victory" else "docking" if id in ["belt_climb", "station_approach", "docking"] else "ground_boss")
		if id == "belt_transfer":
			game.belt_entry = game.director.frame * Transform3D(Basis.IDENTITY, Vector3(0, 500, -1200))
		game._begin_sequence(id)
		var durations: Dictionary = {"ground_victory": 1, "ascent": 6, "orbital_victory": 1, "belt_transfer": 14, "belt_climb": 10, "station_approach": 4, "docking": 4}
		check(game.director.transition_duration == durations[id], "Actual autopilot director uses the exact requested duration for " + id)
		var elapsed: float = 0
		while game.sequence == id and elapsed <= durations[id] + 1:
			game._physics_process(1.0 / 60)
			elapsed += 1.0 / 60
		check(absf(elapsed - durations[id]) <= 1.0 / 60 + 0.00001, "Measured simulation duration matches the handoff schedule for " + id)
	await phase("ignis", "orbit")
	game._begin_sequence("blockade_exit")
	check(game.director.transition_duration == 1, "Boss intercept still has a one-second animated handoff")
	await phase("cryo", "asteroids")
	game.flight.distance = 60 * FlightDirector.ASTEROID_SPEED
	game.flight.elapsed = 60
	game.director.advance("asteroids", 0, game.flight.distance, 60, game.targets)
	game._update_camera()
	game._begin_sequence("belt_exit")
	var time: float = 0
	while game.sequence == "belt_exit" and time < 5:
		game._physics_process(1.0 / 60)
		time += 1.0 / 60
	check(absf(time - 3) < 0.018, "Belt coast actually lasts three rather than five seconds")
	var nearest: float = INF
	for rock in game.mission_world.backdrop.rocks:
		var local: Vector3 = game.director.frame.affine_inverse() * rock["position"]
		nearest = minf(nearest, local.z - rock["radius"] * 1.3)
	check(nearest >= 24, "Finite backdrop still clears behind the ship before the shortened pull-up")

func shot(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless" or captures.is_empty():
		return
	game._update_contacts()
	if game.boss != null:
		game.hud.objective = game.boss.objective()
	game.hud.next_instrument_update = 0
	game.hud._process(0)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == Vector2i(1920, 1080) and image.save_png(captures.path_join(name + ".png")) == OK, "Native screenshot saved: " + name)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
