extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Planet opacity requires a native renderer.")
		quit(1)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	root.unfocusable = true
	root.mouse_passthrough = true
	AudioServer.set_bus_mute(0, true)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	await verify_opacity()
	await verify_solar_disc()
	await verify_arrival()
	await process_frame
	print("PLANET_ARRIVAL_RENDER_FAILURES=", failures)
	quit(failures)

func verify_opacity() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 50
	camera.position.z = 3.3
	scene.add_child(camera)
	camera.make_current()
	for destination in SectorCatalog.AVAILABLE:
		var planet: Node3D = LaunchApproach._planet_model(destination)
		scene.add_child(planet)
		var surface := planet.get_child(0) as MeshInstance3D
		var material: ShaderMaterial = surface.material_override.duplicate()
		surface.material_override = material
		for reveal in [0.12, 1.0]:
			material.set_shader_parameter("reveal", reveal)
			environment.environment.background_color = Color("#b52020")
			var red: Image = await image("")
			environment.environment.background_color = Color("#2033b5")
			var blue: Image = await image("")
			var differences: int = changed_pixels(red, blue, Rect2i(800, 390, 320, 300))
			check(differences == 0, "%s planet blocks the background even during reveal %.2f (%d leaking pixels)" % [destination, reveal, differences])
		environment.environment.background_color = Color("#02040b")
		await image("planet-detail-" + destination + ".png")
		check(surface.mesh.surface_get_array_len(0) > 8000, "The %s globe has substantially finer geometric relief than the original globe" % destination)
		planet.queue_free()
		await process_frame
	scene.queue_free()
	await process_frame

func verify_solar_disc() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/sky.gdshader")
	sky.sky_material = material
	environment.environment.sky = sky
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 24
	scene.add_child(camera)
	camera.look_at(Vector3(-0.44, 0.25, -1))
	camera.make_current()
	var plain: Image = await image("")
	material.set_shader_parameter("icy_mix", 1.0)
	var ice: Image = await image("")
	check(plain.get_pixel(960, 540).r > 0.75 and changed_pixels(plain, ice, Rect2i(885, 465, 150, 150)) == 0,
		"Sun has a bright solid interior independent of the sector sky behind it")
	material.set_shader_parameter("icy_mix", 0.0)
	material.set_shader_parameter("desert_mix", 1.0)
	var ringed: Image = await image("kharon-ringed-sun.png")
	check(changed_pixels(plain, ringed, Rect2i(975, 630, 45, 25)) > 300 and changed_pixels(plain, ringed, Rect2i(900, 435, 40, 25)) == 0,
		"Kharon's near ring crosses the disc while its far ring stays behind the sun")
	camera.look_at(Vector3(0.62, 0.3, -1))
	material.set_shader_parameter("desert_mix", 0.0)
	material.set_shader_parameter("ocean_mix", 1.0)
	for reveal in [0.15, 1.0]:
		material.set_shader_parameter("planet_visibility", reveal)
		material.set_shader_parameter("atmosphere_mix", 0.0)
		var clear: Image = await image("")
		material.set_shader_parameter("atmosphere_mix", 1.0)
		var overcast: Image = await image("")
		check(changed_pixels(clear, overcast, Rect2i(1400, 400, 90, 90)) > 1000 and changed_pixels(clear, overcast, Rect2i(835, 420, 250, 240)) == 0,
			"Moon blocks the changing sky at reveal %.2f" % reveal)
	material.set_shader_parameter("ocean_mix", 0.0)
	material.set_shader_parameter("icy_mix", 1.0)
	var frost_ring: Image = await image("cryo-ringed-moon.png")
	material.set_shader_parameter("planet_visibility", 0.0)
	var hidden: Image = await image("")
	check(frost_ring.get_pixel(1316, 669).b > 0.35 and hidden.get_pixel(1316, 669).b < 0.25,
		"Cryo-Vex's ice ring extends beyond the lunar limb and hides with the moon")
	scene.queue_free()
	await process_frame

func verify_arrival() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game: Node3D = packed.instantiate()
	var path: String = "user://planet-arrival-native-%d.json" % OS.get_process_id()
	game.normal_save_path = path
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.automation = "--native-fixture"
	game.set_process(false)
	game.set_physics_process(false)
	game.screenshot_directory = capture_dir
	for destination in SectorCatalog.AVAILABLE:
		await verify_sector_arrival(game, destination)
	game.campaign.phase = "docking"
	await game._load_phase()
	for _i in range(20 * 30):
		if game.mode == game.Mode.MARKET:
			break
		game._physics_process(1.0 / 30)
	check(game.mode == game.Mode.MARKET and (-game.camera.global_basis.z).dot(game.station.global_basis.z) > 0.999, "Automatic docking finishes already aligned for the next departure")
	DirAccess.remove_absolute(path)
	game.sound.stop_all()
	game.queue_free()
	await process_frame

func verify_sector_arrival(game: Node3D, destination: String) -> void:
	game._new_campaign(destination)
	await process_frame
	await process_frame
	check((-game.camera.global_basis.z).dot(game.station.global_basis.z) > 0.999, "The native departure camera faces directly through the station exit")
	check(not game.launch_approach.planet.visible and game.sky_planet_visibility == 0, "Neither the destination globe nor sky planet is exposed at departure")
	await game._capture(destination + "-departure-facing-exit.png")
	reach(game, "warp_alignment", FlightDirector.ALIGN_DURATION * 0.7)
	check(not game.launch_approach.planet.visible and -game.camera.global_basis.z.y > 0.3, "The visible station-clearance climb occurs before any planet reveal")
	await game._capture(destination + "-departure-pullup.png")
	reach(game, "hyperspace", LaunchApproach.HYPERSPACE_DURATION * 0.5)
	check(not game.launch_approach.planet.visible and game.launch_approach.streaks.visible, "Hyperspace has streaks, not an already-visible destination")
	await game._capture(destination + "-departure-hyperspace.png")
	reach(game, "planet_descent", 0.5)
	await game._capture(destination + "-planet-reveal-start.png")
	reach(game, "planet_descent", 2.5)
	check(game.launch_approach.planet.visible and game.launch_approach.planet_material.get_shader_parameter("reveal") == 1, "The detailed globe fades to full appearance only after hyperspace")
	await game._capture(destination + "-planet-revealed.png")
	var alignment_checked: bool = false
	for fraction in [0.25, 0.44, 0.56, 0.69, 0.75, 0.81, 0.875, 0.97]:
		var moment: float = FlightDirector.DESCENT_DURATION * fraction
		reach(game, "planet_descent", moment)
		var height: float = (game.director.ground_course.affine_inverse() * game.camera.global_position).y
		var reveal: float = game.launch_approach.terrain_reveal(game.camera.global_transform)
		print("ARRIVAL_GEOMETRY sector=%s seconds=%.2f height=%.2f terrain=%.3f curvature=%.3f" % [destination, game.sequence_time, height, reveal, game.launch_approach.curvature])
		await game._capture("%s-descent-%04d.png" % [destination, roundi(moment * 10)])
		if reveal > 0.7 and game.launch_approach.curvature > 0.99 and not alignment_checked:
			await verify_curved_silhouette(game, destination)
			alignment_checked = true
	check(alignment_checked, "The %s approach includes a visibly curved terrain reveal before leveling into the canyon" % destination)
	var before: Image = await image(destination + "-planet-ground-handoff.png")
	game.launch_approach.planet.hide()
	var after: Image = await image("")
	var differences: int = changed_pixels(before, after, Rect2i(220, 320, 1480, 380))
	check(differences == 0, "%s prepared terrain already occludes the globe before removal (%d changed canopy pixels)" % [destination, differences])
	game.launch_approach.planet.show()
	while game.mode != game.Mode.FLIGHT:
		game._physics_process(1.0 / 30)
	await game._capture(destination + "-planet-ground-active.png")

func verify_curved_silhouette(game: Node3D, destination: String) -> void:
	var environment: Environment
	var layers: Array[CanvasLayer] = []
	for child in game.get_children():
		if child is WorldEnvironment:
			environment = child.environment
		elif child is CanvasLayer and child.visible:
			layers.append(child)
			child.hide()
	var background: int = environment.background_mode
	var background_color: Color = environment.background_color
	var fog: bool = environment.fog_enabled
	var glow: bool = environment.glow_enabled
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.fog_enabled = false
	environment.glow_enabled = false
	var planet: Node3D = game.launch_approach.planet
	var transform: Transform3D = planet.transform
	var solid: MeshInstance3D = planet.get_child(0)
	var material: Material = solid.material_override
	var foundation: MeshInstance3D = game.ground_horizon.get_child(0)
	var foundation_mesh: Mesh = foundation.mesh
	var vertices: PackedVector3Array = foundation_mesh.get_meta("fragment_vertices")
	var indices: PackedInt32Array = foundation_mesh.get_meta("fragment_indices")
	var filtered := PackedInt32Array()
	for i in range(0, indices.size(), 3):
		if maxf(vertices[indices[i]].y, maxf(vertices[indices[i + 1]].y, vertices[indices[i + 2]].y)) <= 0:
			filtered.append_array(PackedInt32Array([indices[i], indices[i + 1], indices[i + 2]]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = filtered
	arrays[Mesh.ARRAY_COLOR] = foundation_mesh.get_meta("fragment_colors")
	var floor_mesh := ArrayMesh.new()
	floor_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	foundation.mesh = floor_mesh
	var visibility: Dictionary = {}
	for child in game.world.get_children() + game.ground_horizon.get_children():
		if child is Node3D and child != game.ground_horizon and child != foundation:
			visibility[child] = child.visible
			child.hide()
	var mask := ShaderMaterial.new()
	mask.shader = Shader.new()
	mask.shader.code = "shader_type spatial; render_mode unshaded, fog_disabled, cull_disabled; void fragment() { ALBEDO = vec3(1.0); }"
	solid.material_override = mask
	planet.scale *= 1.025
	planet.get_child(1).hide()
	game.world.hide()
	var envelope: Image = await image(destination + "-planet-envelope-mask.png")
	planet.hide()
	game.world.show()
	var terrain: Image = await image(destination + "-curved-foundation-mask.png")
	var coverage: Vector2i = terrain_coverage(terrain, envelope)
	check(coverage.x > 5000 and coverage.y == 0, "%s curved foundation follows the globe within 2.5 percent radial clearance (%d visible, %d detached pixels)" % [destination, coverage.x, coverage.y])
	for shader: ShaderMaterial in game.launch_approach.ground_shaders:
		shader.set_shader_parameter("arrival_curvature", 0.0)
	var flat: Image = await image(destination + "-flat-negative-control.png")
	var flat_coverage: Vector2i = terrain_coverage(flat, envelope)
	check(flat_coverage.y > 5000, "%s negative control detects the original off-planet flat sheet (%d detached pixels)" % [destination, flat_coverage.y])
	for shader: ShaderMaterial in game.launch_approach.ground_shaders:
		shader.set_shader_parameter("arrival_curvature", game.launch_approach.curvature)
	foundation.mesh = foundation_mesh
	for child: Node3D in visibility:
		child.visible = visibility[child]
	solid.material_override = material
	planet.transform = transform
	planet.show()
	planet.get_child(1).show()
	environment.background_mode = background
	environment.background_color = background_color
	environment.fog_enabled = fog
	environment.glow_enabled = glow
	for layer in layers:
		layer.show()

func terrain_coverage(terrain: Image, envelope: Image) -> Vector2i:
	var result := Vector2i.ZERO
	for y in range(1080):
		for x in range(1920):
			var color: Color = terrain.get_pixel(x, y)
			if maxf(color.r, maxf(color.g, color.b)) > 0.04:
				result.x += 1
				if envelope.get_pixel(x, y).r < 0.5:
					result.y += 1
	return result

func reach(game: Node3D, sequence: String, time: float) -> void:
	for _i in range(1400):
		if game.sequence == sequence and game.sequence_time >= time:
			return
		game._physics_process(0.05)
	check(false, "Arrival fixture failed to reach " + sequence)

func image(filename: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Image = root.get_texture().get_image()
	check(result.get_size() == Vector2i(1920, 1080), "Planet validation renders at actual 1920x1080")
	if not filename.is_empty() and not capture_dir.is_empty():
		check(result.save_png(capture_dir.path_join(filename)) == OK, "Planet validation capture saved")
	return result

func changed_pixels(a: Image, b: Image, region: Rect2i) -> int:
	var changes: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var first: Color = a.get_pixel(x, y)
			var second: Color = b.get_pixel(x, y)
			if absf(first.r - second.r) + absf(first.g - second.g) + absf(first.b - second.b) > 0.01:
				changes += 1
	return changes

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
