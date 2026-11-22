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
	for encounter in [["ignis", false], ["ignis", true], ["thalassa", false], ["xylo", false], ["cryo", false], ["vespera", false], ["kharon", false]]:
		var orbital: bool = encounter[1]
		var boss := BossEncounter.new()
		boss.sector = encounter[0]
		game.campaign.sector = boss.sector
		boss.orbital = orbital
		game.world.add_child(boss)
		boss.missile_requested.connect(game._launch_missile)
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
		for part in [boss.turrets[0], boss.parts[0], boss.radars[0]]:
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
		await game._capture(label + "-boss-sections-removed.png")
		boss.queue_free()
		game.boss = null
		game.targets.clear()
		await process_frame
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("BOSS_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
