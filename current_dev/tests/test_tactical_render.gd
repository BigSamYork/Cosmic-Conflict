extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Tactical appearance must be checked with a native renderer.")
		quit(1)
		return
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	game.pause_flight()
	game.world.hide()
	game.campaign = CampaignState.new()
	game.campaign.phase = "orbit"
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.hud.campaign = game.campaign
	game.hud.show_menu("flight", game.settings)
	game.hud.phase_title = "GUNSHIP TACTICAL TRIAL"
	game.hud.objective = "FLANK, WAIT FOR THE BANK, OR STUN WITH A MISSILE"
	game.director.frame = Transform3D.IDENTITY
	game.camera.global_transform = Transform3D.IDENTITY
	game.hud.cursor = root.get_visible_rect().size * 0.5
	game.cursor = game.hud.cursor
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			game.screenshot_directory = argument.trim_prefix("--capture-dir=")
	var gunship := EnemyFighter.new()
	gunship.heavy = true
	gunship.dogfight = true
	gunship.velocity = Vector3.BACK * 10
	gunship.spawn_frame = Transform3D.IDENTITY
	game.add_child(gunship)
	gunship.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 1.5, -40))
	var hit: Dictionary = {"collider": gunship, "position": gunship.to_global(Vector3(0, 0, -8))}
	game._strike(hit, 1)
	check(gunship.shield_visual.visible and gunship.armor == 10 and game.blocked_primary_hits == 1, "Visible frontal shield blocks primary fire")
	await process_frame
	await game._capture("gunship-shield.png")
	game.campaign.secondary = true
	game.flight.ammo = 2
	await physics_frame
	await physics_frame
	game.fire_secondary()
	for _i in range(30):
		game._advance_torpedoes(1.0 / 60.0)
		if game.torpedoes.is_empty():
			break
	check(not gunship.shield_visual.visible and gunship.armor == 2 and game.stunned_gunships == 1 and game.flight.ammo == 1, "A fired secondary projectile penetrates the shield, spends ammo, and stuns the gunship")
	await process_frame
	await game._capture("gunship-stunned.png")
	game.flight.request_evasion()
	game.flight.advance(FlightState.EVADE_DURATION * 0.5, false)
	game.settings["shake"] = true
	game._update_camera()
	var banked: Basis = game.camera.basis
	game.settings["shake"] = false
	game._update_camera()
	var visual_bank: float = banked.get_rotation_quaternion().angle_to(game.camera.basis.get_rotation_quaternion())
	check(absf(visual_bank - deg_to_rad(14.0)) < 0.001, "Evasion uses the requested gentle bank and honors the camera-motion toggle")
	game.settings["shake"] = true
	game._update_camera()
	await process_frame
	await game._capture("evasion-bank.png")
	for _i in range(10):
		game.campaign.record_combat_kill(20)
	game.flight.advance(0.4, false)
	game._update_camera()
	game.hud.show_menu("pause", game.settings)
	await process_frame
	await game._capture("tactical-pause.png")
	game.sound.stop_all()
	game.queue_free()
	await process_frame
	print("TACTICAL_RENDER_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
