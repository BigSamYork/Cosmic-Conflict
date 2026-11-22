extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var radar := RadarDish.new()
	root.add_child(radar)
	radar.animate(0)
	radar.animate(4)
	check(absf(radar.dish.rotation.y - 3.0) < 0.001, "Ground radar rotates continuously beyond the old oscillating range")
	radar.receive_hit(5)
	var stopped: Basis = radar.dish.basis
	radar.animate(8)
	check(radar.dish.basis.is_equal_approx(stopped), "Destroyed ground radars stop rotating")
	radar.queue_free()
	for orbital in [false, true]:
		var boss := BossEncounter.new()
		boss.orbital = orbital
		root.add_child(boss)
		var before: Basis = boss.radars[0].scanner.basis
		boss.advance(1.0, Vector3(0, 0, 120), Vector3.ZERO)
		check(boss.radars.size() == 2 and not before.is_equal_approx(boss.radars[0].scanner.basis) and boss.radars[0].is_visible_in_tree(), "Capital ships carry two visibly rotating marine radar scanners")
		boss.queue_free()
	var station := StationHangar.new()
	root.add_child(station)
	var designs: Dictionary = {}
	var clear_lane: bool = true
	for ship in station.parked_ships:
		designs[ship.get_meta("design")] = true
		clear_lane = clear_lane and absf(ship.position.x) >= 22
	check(station.parked_ships.size() == 8 and designs.size() == 4, "Expanded hangar contains eight parked ships in four distinct designs")
	check(clear_lane, "Parked ships leave the central docking corridor clear")
	var hull: MeshInstance3D = station.get_child(0).get_child(0)
	var bounds: AABB = hull.mesh.get_aabb()
	check(bounds.size.x > 180 and bounds.size.z > 230, "Station shell and docking apron are substantially larger than the original bay")
	check(bounds.size.x >= 256 and bounds.size.y >= 256, "The detailed station outer ring is more than twice the previous diameter")
	var dome_before: Basis = station.radar_domes[0].basis
	var marine_before: Basis = station.marine_radars[0].basis
	var gun_before: Basis = station.gun_heads[0].basis
	var station_before: Transform3D = station.transform
	station.advance(1.0)
	check(station.radar_domes.size() == 6 and station.marine_radars.size() == 8 and station.gun_heads.size() == 8 and not station.radar_domes[0].basis.is_equal_approx(dome_before) and not station.marine_radars[0].basis.is_equal_approx(marine_before) and not station.gun_heads[0].basis.is_equal_approx(gun_before), "Radar domes, marine scanners, and gun heads all move independently")
	check(station.transform.is_equal_approx(station_before), "Animated station equipment never moves the docking reference frame")
	station.queue_free()
	await process_frame
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game.targets.clear()
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.hud.campaign = game.campaign
	game.flight.configure_campaign(game.campaign)
	var rock := Asteroid.new()
	rock.radius = 6.0
	rock.routed = true
	rock.course_position = Vector3(0, 0, -50)
	rock.mineral = true
	game.add_child(rock)
	game.targets.append(rock)
	game._strike({"collider": rock, "position": rock.global_position}, 6)
	var chunks_valid: bool = true
	for chunk in game.rock_fragments:
		chunks_valid = chunks_valid and chunk.fragment and chunk.radius < rock.radius and chunk.collision_layer == 3 and not chunk.mineral and not chunk.volatile and not chunk.indestructible
	check(game.rock_fragments.size() == 3 and chunks_valid, "Shattering an asteroid creates three smaller shootable and collidable rocks")
	check(game.debris.is_empty() and not game.rock_debris.is_empty() and game.rock_debris[0].chunks.size() == 7, "Asteroids use rocky volumetric debris rather than ship hull triangles")
	var paid: int = game.campaign.credits
	var first: Asteroid = game.rock_fragments[0]
	var at: Vector3 = first.global_position
	game._strike({"collider": first, "position": at}, first.armor)
	game._advance_rock_fragments(0.1, Vector3(0, 100, 0), Vector3(0, 100, 0))
	check(game.rock_fragments.size() == 2 and game.campaign.credits == paid and game.campaign.stats["asteroids"] == 1 and game.mineral_pickups.size() == 1, "Destroying child rocks neither splits recursively nor duplicates credits, minerals, or original-rock statistics")
	var moving: Asteroid = game.rock_fragments[0]
	moving.global_position = Vector3(-10, 0, 0)
	moving.fragment_velocity = Vector3(100, 0, 0)
	game.mode = game.Mode.FLIGHT
	var shield: float = game.flight.shields
	var hull_before_impact: float = game.flight.hull
	var offset_before_impact: Vector2 = game.flight.offset
	game._advance_rock_fragments(0.2, Vector3.ZERO, Vector3.ZERO)
	check(game.flight.hull < hull_before_impact and game.flight.shields == shield and game.flight.offset != offset_before_impact and not game.rock_fragments.has(moving), "A fast-moving fragment deflects the pilot and dents the hull through shields")
	game.pause_flight()
	var frozen: Vector3 = game.rock_fragments[0].global_position
	game._physics_process(3.0)
	check(game.rock_fragments[0].global_position == frozen, "Pause freezes physical rock fragments")
	for fragment in game.rock_fragments:
		fragment.fragment_age = Asteroid.FRAGMENT_LIFETIME - 0.1
	game._advance_rock_fragments(0.2, Vector3(0, 100, 0), Vector3(0, 100, 0))
	check(game.rock_fragments.is_empty() and game.campaign.credits == paid, "Old fragments expire without another payout")
	for _i in range(18):
		game._spawn_rock_fragments(rock)
	check(game.rock_fragments.size() == game.MAX_ROCK_FRAGMENTS, "Physical fragment population remains bounded during heavy shattering")
	game._clear_stage()
	check(game.rock_fragments.is_empty() and game.rock_debris.is_empty(), "Phase cleanup removes all physical and visual rock fragments")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("RADAR_ROCK_HANGAR_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
