extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Boss visibility requires a native renderer.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game._clear_stage()
	game.world = Node3D.new()
	game.add_child(game.world)
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.mode = game.Mode.FLIGHT
	game.hud.show_menu("flight", game.settings)
	game._set_ground_environment(false)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	var encounters := []
	for sector in SectorCatalog.AVAILABLE:
		encounters.append([sector, false])
		encounters.append([sector, true])
	for encounter in encounters:
		var orbital: bool = encounter[1]
		var boss := BossEncounter.new()
		boss.sector = encounter[0]
		game.campaign.sector = boss.sector
		boss.orbital = orbital
		game.world.add_child(boss)
		boss.missile_requested.connect(game._launch_missile.bind(boss))
		game.boss = boss
		game.targets.assign(boss.parts)
		game.camera.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 7, 140 if orbital else 105))
		game.hud.phase_title = SectorCatalog.ORBITAL_BOSSES[boss.sector] if orbital else SectorCatalog.GROUND_BOSSES[boss.sector]
		boss.advance(0.3, game.camera.global_position, Vector3.ZERO)
		await physics_frame
		await physics_frame
		var reachable: bool = true
		for turret in boss.turrets:
			var armor: int = turret.armor
			game.cursor = game.camera.unproject_position(turret.aim_point())
			game.fire_primary()
			reachable = reachable and turret.armor == armor - game.flight.weapon_damage
		check(reachable, "Every visible boss turret can be hit by an actual reticle ray")
		boss.advance(0.8, game.camera.global_position, Vector3.ZERO)
		check(not game.missiles.is_empty(), "Visible boss weaponry launches real incoming missiles")
		game._update_contacts()
		var label: String = "orbital" if orbital else "ground"
		if boss.sector != "ignis":
			label = boss.sector + "-" + label
		await game._capture(label + "-boss-intact.png")
		game._clear_missiles()
		var sections: Array = [boss.turrets[0], boss.parts[0], boss.radars[0]]
		if boss.sector == "thalassa" and orbital:
			sections = boss.parts.filter(func(part: BossPart) -> bool: return part != boss.core)
		elif boss.sector == "xylo":
			sections = [boss.turrets[0], boss.turrets[2], boss.turrets[4]] if orbital else [boss.parts[0], boss.parts[1]]
		for part in sections:
			game.cursor = game.camera.unproject_position(part.aim_point())
			for _shot in range(part.maximum_armor):
				if part.destroyed:
					break
				game.fire_primary()
			check(part.destroyed and not part.visible and part.collision_layer == 0, "Actual primary fire removes a boss section")
		game._advance_explosions(0.8)
		game._advance_debris(0.3)
		game._update_contacts()
		await game._capture(label + "-boss-section-explosion.png")
		game._advance_explosions(4.0)
		game._advance_debris(3.0)
		game._update_beams(1.0)
		boss.advance_visuals(3.0)
		if boss.sector == "thalassa" and orbital:
			game.camera.position = Vector3(0, 1.5, 112.5)
			boss.advance(0.01, game.camera.global_position, Vector3.ZERO)
			game.hud.objective = boss.objective()
			game._update_contacts()
			check(boss.breaches.size() == sections.size(), "The Storm Ark retains all ten breaches on the stripped ship")
		await game._capture(label + "-boss-sections-removed.png")
		if boss.sector == "xylo":
			boss.advance(0.02, game.camera.global_position, Vector3.ZERO)
			game.cursor = game.camera.unproject_position(boss.core.aim_point())
			var before := boss.core.armor
			game.fire_primary()
			check(boss.core.unlocked and boss.core.armor < before, "Primary fire reaches the beating heart after breaking the interlock")
			game._update_contacts()
			game.hud.objective = boss.objective()
			await game._capture(label + "-heart-exposed.png")
		boss.queue_free()
		game.boss = null
		game.targets.clear()
		await process_frame
	for orbital in [false, true]:
		await verify_chest_occlusion(orbital)
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("BOSS_RENDER_FAILURES=", failures)
	quit(failures)

# Count actual heart pixels under the chest geometry, then isolate the same
# mesh and camera to measure the full silhouette at that angle.
func verify_chest_occlusion(orbital: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 240)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var boss := BossEncounter.new()
	boss.sector = "xylo"
	boss.orbital = orbital
	viewport.add_child(boss)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.fov = 27
	var marker := StandardMaterial3D.new()
	marker.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.albedo_color = Color.MAGENTA
	boss.core.face_mesh.material_override = marker
	var heart_layer := 1 << 8
	boss.core.face_mesh.layers = heart_layer
	for lateral: float in [-5.0, 0.0, 5.0]:
		camera.position = boss.core.position + Vector3(lateral, -3, 32)
		camera.look_at(boss.core.position)
		camera.cull_mask = 1 | heart_layer
		boss.core.unlocked = false
		var sealed := await count_heart_pixels(viewport)
		boss.core.unlocked = true
		var exposed := await count_heart_pixels(viewport)
		camera.cull_mask = heart_layer
		var total := await count_heart_pixels(viewport)
		var fraction := float(exposed) / maxi(1, total)
		print("CHEST_VISIBILITY orbital=", orbital, " lateral=", lateral, " sealed=", sealed, " exposed_fraction=", fraction)
		check(sealed == 0, "Intact chest completely conceals the heart")
		check(total > 200 and fraction > 0.05 and fraction < 0.50, "An open wound reveals a shootable portion of the buried heart")
	viewport.free()

func count_heart_pixels(viewport: SubViewport) -> int:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := viewport.get_texture().get_image()
	var pixels := 0
	for y in range(frame.get_height()):
		for x in range(frame.get_width()):
			var color := frame.get_pixel(x, y)
			if color.r > 0.8 and color.b > 0.8 and color.g < 0.15:
				pixels += 1
	return pixels

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
