extends SceneTree

var failures := 0
var captures := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.unfocusable = true
	root.mouse_passthrough = true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			captures = argument.trim_prefix("--capture-dir=")
	var game: Node3D = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.settings["reduced_effects"] = false
	for sector in ["ignis", "cryo", "vespera", "xylo", "thalassa", "kharon"]:
		game.campaign.sector = sector
		game.campaign.phase = "ground"
		await game._load_phase()
		game.flight.distance = 690.0
		game.flight.elapsed = game.flight.distance / FlightState.SPEED
		game.director.advance("ground", 0, game.flight.distance, game.flight.elapsed, game.targets)
		game._stream_ground(game.flight.distance)
		game._update_camera()
		game._update_contacts()
		game.surface_weather.advance(3.2)
		check(game.surface_weather.visible and game.surface_weather.climate == sector, sector + " has its own cockpit weather")
		verify_population(game, sector)
		if sector in ["ignis", "cryo", "kharon"]:
			verify_smooth_ground(game, sector)
		await snapshot("surface-" + sector + ".png")
	game.settings["reduced_effects"] = true
	game._apply_settings()
	check(not game.surface_weather.visible, "Reduced effects removes close particles")
	await snapshot("surface-kharon-reduced.png")
	game.sound.stop_all()
	game.free()
	await process_frame
	# Isolate the pass to prove actual GPU visibility and steady motion.
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.make_current()
	var weather := SurfaceWeather.new()
	camera.add_child(weather)
	weather.configure("cryo", true, true)
	var bare := await snapshot("")
	weather.configure("cryo", true, false)
	var snow := await snapshot("")
	weather.advance(1.7)
	var moved := await snapshot("")
	check(different(bare, snow) > 20 and different(snow, moved) > 25, "Sector particles illuminate real pixels and travel between frames")
	weather.configure("cryo", false, false)
	var space := await snapshot("")
	check(different(bare, space) == 0, "Particles clear immediately on the transition to space")
	await verify_ground_motion(scene, camera)
	await verify_water_reflection(scene, camera)
	scene.free()
	print("SURFACE_WEATHER_RENDER_FAILURES=", failures)
	quit(failures)

func verify_population(game: Node3D, sector: String) -> void:
	var buildings := {}
	var plants := {}
	for id: String in GroundArt.BUILDINGS[sector]:
		buildings[FleetArt.mesh_for(sector + "_" + id, "ground")] = false
	for id: String in GroundArt.PLANTS[sector]:
		plants[FleetArt.mesh_for(sector + "_" + id, "ground")] = false
	for chunk in game.ground_chunks:
		for node in chunk.get_children():
			if node is MultiMeshInstance3D:
				var mesh: Mesh = node.multimesh.mesh
				if plants.has(mesh) and node.material_override == GroundArt.foliage_material and node.multimesh.instance_count > 0:
					plants[mesh] = true
				if sector != "thalassa" and buildings.has(mesh):
					buildings[mesh] = true
			elif node is OffshorePlatform:
				var deck: Mesh = node.get_child(0).mesh
				if buildings.has(deck) and node.collision_layer == 1:
					buildings[deck] = true
	check(not buildings.values().has(false) and not plants.values().has(false), sector + " streams all three new buildings and all three plants")

func verify_smooth_ground(game: Node3D, sector: String) -> void:
	var seam: float = -float(game.ground_chunks[1].get_meta("start"))
	var first: Dictionary[int, Vector3] = {}
	var matches := 0
	for i in 2:
		for surface in game.ground_chunks[i].get_children():
			if not surface is MeshInstance3D or surface.material_override != GroundArt.materials[sector]:
				continue
			var arrays: Array = surface.mesh.surface_get_arrays(0)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for j in positions.size():
				if is_equal_approx(positions[j].z, seam):
					var x := roundi(positions[j].x * 100)
					if i == 0:
						first[x] = normals[j]
					elif first.has(x) and first[x].dot(normals[j]) > 0.999:
						matches += 1
						first.erase(x)
	check(matches > 20 and first.is_empty(), sector + " lighting joins across streamed terrain chunks")

func verify_ground_motion(scene: Node3D, camera: Camera3D) -> void:
	# Isolate the actual flight materials from camera travel, sky and airborne weather.
	camera.position = Vector3(0, 9, 0)
	camera.look_at(Vector3(3, 0, -19))
	var floor_tile := VectorArt.solid(PackedVector3Array([
		Vector3(-70, 0, 15), Vector3(70, 0, 15), Vector3(70, 0, -90), Vector3(-70, 0, -90)
	]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE, PackedColorArray(),
		PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]))
	scene.add_child(floor_tile)
	for sector: String in ["ignis", "cryo", "vespera", "xylo", "kharon"]:
		floor_tile.material_override = GroundArt.materials[sector]
		for reduced in [false, true]:
			RenderingServer.global_shader_parameter_set("ground_motion", 0.0 if reduced else 1.0)
			RenderingServer.global_shader_parameter_set("ground_time", 3.25)
			var first := await snapshot("")
			RenderingServer.global_shader_parameter_set("ground_time", 5.75)
			var second := await snapshot("")
			var changed := different(first, second)
			check(changed == 0 if reduced else changed > 100,
				"%s terrain motion with reduced effects %s (%d changed channel samples)" % [sector, reduced, changed])
		if sector in ["ignis", "vespera"]:
			# Molten seams and reflected city lamps have their own light at midnight.
			RenderingServer.global_shader_parameter_set("sector_ambient", Vector3.ZERO)
			var dark := await snapshot("")
			var unlit := StandardMaterial3D.new()
			unlit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			unlit.cull_mode = BaseMaterial3D.CULL_DISABLED
			unlit.albedo_color = Color.BLACK
			floor_tile.material_override = unlit
			check(different(await snapshot(""), dark) > 100, sector + " has visible light sources in darkness")
			RenderingServer.global_shader_parameter_set("sector_ambient", Vector3.ONE)
	floor_tile.free()
	# A return visit uses the cached MultiMesh. Check the blades themselves
	# against a fixed background so peat ripples cannot satisfy this assertion.
	var chunk := XyloArt.terrain_chunk(0.0)
	var sedge_motion := 0
	for child in chunk.get_children():
		if child is MultiMeshInstance3D and child.multimesh.has_meta("decorative_ground_cover"):
			chunk.remove_child(child)
			scene.add_child(child)
			var tuft: Vector3 = child.multimesh.get_instance_transform(0).origin + Vector3.UP
			camera.position = tuft + Vector3(1, 1, 5)
			camera.look_at(tuft)
			RenderingServer.global_shader_parameter_set("ground_motion", 1.0)
			RenderingServer.global_shader_parameter_set("ground_time", 0.5)
			var still := await snapshot("")
			RenderingServer.global_shader_parameter_set("ground_time", 2.0)
			sedge_motion = different(still, await snapshot(""))
			child.free()
			break
	chunk.free()
	check(sedge_motion > 100, "Cached Xylo sedges bend in the wind")
	RenderingServer.global_shader_parameter_set("ground_motion", 1.0)
	RenderingServer.global_shader_parameter_set("ground_time", 0.0)

func verify_water_reflection(scene: Node3D, camera: Camera3D) -> void:
	camera.position = Vector3(0, 4, 0)
	camera.look_at(Vector3(0, 0, -30))
	var surface := FrontierArt._sea_surface(0, [])
	scene.add_child(surface)
	var test_rig := MeshInstance3D.new()
	var hull := BoxMesh.new()
	hull.size = Vector3(12, 8, 10)
	test_rig.mesh = hull
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(0.9, 0.09, 0.05)
	test_rig.material_override = red
	test_rig.position = Vector3(0, 2.1, -27)
	scene.add_child(test_rig)
	var bare := await snapshot("")
	surface.material_override.shader = FrontierArt.WATER_REFLECTION
	var reflected := await snapshot("")
	var pixels := 0
	for y in range(roundi(bare.get_height() * 0.55), bare.get_height(), 2):
		for x in range(bare.get_width() / 3, 2 * bare.get_width() / 3, 2):
			var delta := reflected.get_pixel(x, y) - bare.get_pixel(x, y)
			pixels += int(delta.r > 0.055 and delta.r > delta.g * 2.0)
	check(pixels > 30, "Actual rig color appears on nearby waves when reflections are enabled (%d samples)" % pixels)

func snapshot(filename: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if not filename.is_empty() and not captures.is_empty():
		check(image.save_png(captures.path_join(filename)) == OK, "Save " + filename)
	return image

func different(first: Image, second: Image) -> int:
	var a := first.get_data()
	var b := second.get_data()
	var count := 0
	for i in a.size():
		if absi(a[i] - b[i]) > 3:
			count += 1
	return count

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
