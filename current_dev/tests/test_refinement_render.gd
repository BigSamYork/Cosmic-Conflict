extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Radar, rocky debris, and hangar checks require native rendering.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	await check_ship_silhouettes(game)
	game.start_flight()
	game.pause_flight()
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game.is_campaign = true
	game.campaign = CampaignState.new()
	game.hud.campaign = game.campaign
	game.flight.configure_campaign(game.campaign)
	game.hud.show_menu("flight", game.settings)
	game._set_ground_environment(false)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	game.camera.global_transform = Transform3D.IDENTITY
	game.hud.phase_title = "ASTEROID FRACTURE / SOLID ROCK CHUNKS"
	var rock := Asteroid.new()
	rock.radius = 6.0
	rock.routed = true
	rock.course_position = Vector3(0, 0, -40)
	game.world.add_child(rock)
	game.targets.append(rock)
	game.cursor = game.camera.unproject_position(rock.global_position)
	await physics_frame
	await physics_frame
	for _i in range(6):
		game.fire_primary()
	check(rock.destroyed and game.rock_fragments.size() == 3 and game.debris.is_empty(), "Native primary fire shatters an asteroid into smaller rocks, not ship panels")
	game._advance_rock_fragments(0.5, Vector3.ZERO, Vector3.ZERO)
	game._advance_debris(0.5)
	for chunk in game.rock_fragments:
		chunk.animate(0.5)
	game._update_contacts()
	await game._capture("asteroid-rock-fragments.png")
	var fragment: Asteroid = game.rock_fragments[0]
	game.cursor = game.camera.unproject_position(fragment.global_position)
	await physics_frame
	await physics_frame
	for _i in range(fragment.armor):
		game.fire_primary()
	check(fragment.destroyed and game.campaign.credits == 0 and game.campaign.stats["asteroids"] == 1, "Native shots destroy child rocks without awarding combat credits")
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	for orbital in [false, true]:
		var boss := BossEncounter.new()
		boss.orbital = orbital
		game.world.add_child(boss)
		game.camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 10, 125 if orbital else 105))
		boss.advance(1.0, game.camera.global_position, Vector3.ZERO)
		game.hud.phase_title = "CAPITAL RADAR / CONTINUOUS ROTATION"
		await game._capture("radar-%s-boss.png" % ("orbital" if orbital else "ground"))
		boss.queue_free()
		await process_frame
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game.station = MissionWorld.station()
	game.world.add_child(game.station)
	game.camera.global_transform = game.station.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 4, 420))
	game.hud.phase_title = "ASTRA / OUTER RING DEFENSE AND RADAR"
	game.station.advance(0.7)
	await game._capture("station-outer-ring.png")
	game.station.advance(2.0)
	await game._capture("station-outer-ring-scanning.png")
	game.camera.global_position = Vector3(95, 55, 205)
	game.camera.look_at(Vector3(112, 40, 84))
	await game._capture("station-radar-turret-detail.png")
	game.camera.global_transform = game.station.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, 110))
	game.hud.phase_title = "ASTRA / EXPANDED SHIP BAY"
	await game._capture("expanded-hangar-approach.png")
	game.camera.global_transform = game.station.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0, -12))
	var visible_right: int = 0
	for ship in game.station.parked_ships:
		var at: Vector2 = game.camera.unproject_position(ship.global_position)
		if not game.camera.is_position_behind(ship.global_position) and at.x > 1250 and at.x < 1850 and at.y > 250 and at.y < 800:
			visible_right += 1
	check(visible_right >= 3, "At least three parked craft remain in the visible area beside the market menu")
	await game._capture("expanded-hangar-interior.png")
	game.campaign.dock(true)
	game._show_market()
	await game._capture("expanded-market-ships.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("REFINEMENT_RENDER_FAILURES=", failures)
	quit(failures)

func check_ship_silhouettes(game: Node3D) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(96, 96)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	root.add_child(viewport)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position.y = 20
	camera.rotation.x = -PI / 2
	var masks := {}
	for id: String in CampaignState.SHIPS:
		game._set_cockpit(id)
		var preview: Node3D = game.display_ship.duplicate()
		masks[id] = await ship_mask(viewport, preview)
	for id: String in masks:
		for other: String in masks:
			if id < other:
				check(distinct_masks(masks[id], masks[other]), "%s and %s read differently in silhouette" % [id, other])
	var fighter := EnemyFighter.new()
	for sector in ["cryo", "vespera"]:
		fighter.sector = sector
		masks[sector] = await ship_mask(viewport, fighter.create_model())
	check(distinct_masks(masks.cryo, masks.vespera), "Ice runners and cloak vanes remain distinct without faction colors")
	fighter.free()
	viewport.free()

func ship_mask(viewport: SubViewport, model: Node3D) -> PackedByteArray:
	viewport.add_child(model)
	model.transform = Transform3D.IDENTITY
	model.show()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var mask := PackedByteArray()
	for y in image.get_height():
		for x in image.get_width():
			mask.append(int(image.get_pixel(x, y).a > 0.5))
	model.free()
	return mask

func distinct_masks(a: PackedByteArray, b: PackedByteArray) -> bool:
	var shared := 0
	var combined := 0
	for i in a.size():
		shared += a[i] & b[i]
		combined += a[i] | b[i]
	return a.count(1) > 100 and b.count(1) > 100 and shared < combined * 0.85

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
