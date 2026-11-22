extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Cockpit compositing must be checked with native rendering.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.mode = game.Mode.PAUSE
	game.hud.show_menu("flight", game.settings)
	var background := CanvasLayer.new()
	background.layer = 0
	game.add_child(background)
	var world_color := ColorRect.new()
	world_color.color = Color("#16405f")
	world_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(world_color)
	world_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var placement: Transform2D = CockpitInstruments.artwork_transform(root.get_visible_rect().size)
	var indicator := ColorRect.new()
	indicator.position = placement * Vector2(690, 680) - Vector2(8, 8)
	indicator.size = Vector2(16, 16)
	indicator.color = Color("#ef374a")
	indicator.z_index = 100
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(indicator)
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var pixel_scale: Vector2 = Vector2(image.get_size()) / root.get_visible_rect().size
	var window: Color = image.get_pixelv(Vector2i((placement * Vector2(688, 350)) * pixel_scale))
	var metal: Color = image.get_pixelv(Vector2i((placement * Vector2(690, 608)) * pixel_scale))
	var hud_pixel: Color = image.get_pixelv(Vector2i((placement * Vector2(690, 680)) * pixel_scale))
	check(similar(window, world_color.color), "World renders through the transparent windshield")
	check(not similar(metal, world_color.color), "Cockpit frame renders above the world")
	check(similar(hud_pixel, indicator.color), "Live HUD renders above the cockpit artwork")
	var base: Texture2D = game.cockpit_artwork.texture
	game._set_cockpit("hawk", 1)
	check(game.cockpit_skin == "hawk" and game.gun_level_displayed == 1 and game.cockpit_artwork.texture != base, "Native rendering selects the hull and first gun upgrade")
	var first_upgrade: Texture2D = game.cockpit_artwork.texture
	await RenderingServer.frame_post_draw
	var idle: Image = root.get_texture().get_image()
	for _i in range(12):
		game._advance_rotors(1.0 / 60, true)
	await RenderingServer.frame_post_draw
	var spinning: Image = root.get_texture().get_image()
	var crop := Rect2i(Vector2i((placement * Vector2(403, 426)) * pixel_scale), Vector2i(Vector2(74, 55) * placement.get_scale() * pixel_scale))
	check(idle.get_region(crop).get_data() != spinning.get_region(crop).get_data(), "Firing Quad Plasma visibly rotates the barrels through the canopy")
	game._advance_rotors(0.05, false)
	check(game.rotor_speed > 0.0, "Rotor coasts rather than snapping to rest on release")
	for _i in range(60):
		game._advance_rotors(1.0 / 60, false)
	check(game.rotor_speed == 0.0, "Rotor comes to rest with the trigger released")
	game._set_cockpit("hawk", 2)
	check(game.gun_level_displayed == 2 and game.cockpit_artwork.texture != first_upgrade, "Second primary tier selects its distinct gun artwork")
	for ship: String in CampaignState.SHIPS:
		game._set_cockpit(ship)
		var frame: Texture2D = game.cockpit_artwork.texture
		var deck: Texture2D = game.cockpit_foredeck.texture
		check(frame.resource_path == "res://assets/cockpits/%s.png" % ship and deck.resource_path == "res://assets/cockpits/foredecks/%s.png" % ship, "Frame and forward hull match " + ship)
		check(game.hull_plate.text == String(CampaignState.SHIPS[ship].name).to_upper(), "Instrument panel identifies " + ship)
		await RenderingServer.frame_post_draw
		var view: Image = root.get_texture().get_image()
		check(similar(view.get_pixelv(Vector2i((placement * Vector2(688, 350)) * pixel_scale)), world_color.color), "Clear central sightline for " + ship)
		game.cockpit_foredeck.hide()
		await RenderingServer.frame_post_draw
		var without_deck: Image = root.get_texture().get_image()
		var hull_samples := 0
		for y in range(430, 572, 8):
			for x in range(8, 1370, 8):
				var pixel := Vector2i((placement * Vector2(x, y)) * pixel_scale)
				if similar(without_deck.get_pixelv(pixel), world_color.color) and not similar(view.get_pixelv(pixel), world_color.color):
					hull_samples += 1
		check(hull_samples >= 12, "Forward hull is visible through the glazing on " + ship)
		game.cockpit_foredeck.show()
	game._set_cockpit("", 2)
	check(game.cockpit_foredeck.texture == null and game.hull_plate.text.is_empty() and game.cockpit_artwork.material == null and game.gun_level_displayed == 0, "Recovery clears the previous hull and its upgrades")
	game.queue_free()
	await process_frame
	print("COCKPIT_COMPOSITE_FAILURES=", failures)
	quit(failures)

func similar(a: Color, b: Color) -> bool:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) < 0.04

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
