extends SceneTree

var failures: int = 0
var capture_dir: String = ""
var camera: Camera3D
var window_mask: Image
var inverse_art: Transform2D

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Belt visibility requires a native renderer.")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	root.size = Vector2i(1920, 1080)
	root.unfocusable = true
	root.mouse_passthrough = true
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080)
	window_mask = Image.new()
	var decoded: Error = window_mask.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/cockpits/rook.png"))
	if decoded != OK:
		push_error("Cannot decode the cockpit visibility mask.")
		quit(1)
		return
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	stage.add_child(environment)
	camera = Camera3D.new()
	camera.fov = 78
	camera.far = VectorArt.VIEW_DISTANCE
	stage.add_child(camera)
	camera.make_current()
	var belt := MissionWorld.new()
	stage.add_child(belt)
	belt.build("asteroids", Transform3D.IDENTITY)
	await process_frame
	inverse_art = CockpitInstruments.artwork_transform(root.get_visible_rect().size).affine_inverse()
	var baseline_total: int = 0
	var dense_total: int = 0
	var baseline_edges := Vector3i.ZERO
	var dense_edges := Vector3i.ZERO
	var old_pixels: int = 0
	var new_pixels: int = 0
	await check_backdrop_tumbling(belt.backdrop)
	for travel in [160.0, 800.0, 1500.0, 2250.0, 2800.0]:
		camera.transform = FlightDirector.asteroid_frame(travel)
		for asteroid in belt.targets:
			asteroid.animate(travel / FlightDirector.ASTEROID_SPEED)
		belt.backdrop.animate(travel / FlightDirector.ASTEROID_SPEED, camera.global_position)
		var baseline: int = 0
		var dense: int = 0
		var old_edges := Vector3i.ZERO
		var new_edges := Vector3i.ZERO
		for asteroid in belt.targets:
			if in_view(asteroid.global_position, asteroid.radius):
				baseline += 1
				dense += 1
				old_edges += edge_region(camera.unproject_position(asteroid.global_position))
				new_edges += edge_region(camera.unproject_position(asteroid.global_position))
		for rock in belt.backdrop.rocks:
			if in_view(rock["position"], rock["radius"]):
				dense += 1
				var region: Vector3i = edge_region(camera.unproject_position(rock["position"]))
				new_edges += region
				if not rock["peripheral"]:
					baseline += 1
					old_edges += region
		var previous_periphery: int = old_edges.x + old_edges.y + old_edges.z
		var new_periphery: int = new_edges.x + new_edges.y + new_edges.z
		check(new_periphery >= previous_periphery * 2 and new_periphery >= 20, "More peripheral rocks at %.0fm: v0.6.0=%d new=%d" % [travel, previous_periphery, new_periphery])
		baseline_total += baseline
		dense_total += dense
		baseline_edges += old_edges
		dense_edges += new_edges
		for node in belt.backdrop.get_children():
			node.multimesh.visible_instance_count = BeltBackdrop.BASE_ROCKS_PER_BATCH
		var old_image: Image = await frame_image()
		old_pixels += occupied_samples(old_image)
		for node in belt.backdrop.get_children():
			node.multimesh.visible_instance_count = -1
		var new_image: Image = await frame_image()
		new_pixels += occupied_samples(new_image)
		if not capture_dir.is_empty() and travel == 800.0:
			check(old_image.save_png(capture_dir.path_join("belt-v060-comparison.png")) == OK, "Saved v0.6.0 density comparison")
			check(new_image.save_png(capture_dir.path_join("belt-peripheral-comparison.png")) == OK, "Saved peripheral-field comparison")
	check(dense_edges.x >= baseline_edges.x * 2 and dense_edges.y >= baseline_edges.y * 2 and dense_edges.z >= baseline_edges.z * 2, "Left, right, and upper/lower canopy periphery each have at least twice as many visible rocks")
	check(new_pixels > old_pixels * 1.5, "Rendered peripheral canopy coverage rises by at least 50 percent")
	print("BELT_DENSITY old_count=%d new_count=%d old_edges=%s new_edges=%s old_edge_coverage=%d new_edge_coverage=%d" % [baseline_total, dense_total, baseline_edges, dense_edges, old_pixels, new_pixels])
	belt.hide()
	camera.transform = Transform3D(Basis.IDENTITY, Vector3(0, 0, 20))
	for variant in range(AsteroidArt.VARIANTS):
		var model: Node3D = AsteroidArt.create(variant, Color("#b7afbc"))
		model.scale = Vector3.ONE * 7
		model.rotation = Vector3(0.15, 0.35, -0.35 if variant != 0 else 0)
		stage.add_child(model)
		var image: Image = await frame_image()
		if not capture_dir.is_empty():
			check(image.save_png(capture_dir.path_join("asteroid-variant-%d.png" % variant)) == OK, "Saved cratered model preview")
		model.queue_free()
		await process_frame
	stage.queue_free()
	await process_frame
	print("BELT_VISUAL_FAILURES=", failures)
	quit(failures)

func in_view(at: Vector3, radius: float) -> bool:
	if camera.is_position_behind(at) or camera.global_position.distance_to(at) > 1100:
		return false
	var screen: Vector2 = camera.unproject_position(at)
	if not root.get_visible_rect().has_point(screen):
		return false
	var pixel_radius: float = screen.distance_to(camera.unproject_position(at + camera.basis.x * radius))
	return pixel_radius >= 3.0 and through_window(screen)

func through_window(screen: Vector2) -> bool:
	var source: Vector2 = inverse_art * screen
	if not Rect2(Vector2.ZERO, Vector2(window_mask.get_size())).has_point(source):
		return false
	return window_mask.get_pixelv(Vector2i(source)).a < 0.35

func edge_region(screen: Vector2) -> Vector3i:
	var normalized: Vector2 = screen / root.get_visible_rect().size * 2.0 - Vector2.ONE
	if normalized.x <= -0.55:
		return Vector3i(1, 0, 0)
	if normalized.x >= 0.55:
		return Vector3i(0, 1, 0)
	return Vector3i(0, 0, 1) if absf(normalized.y) >= 0.55 else Vector3i.ZERO

func occupied_samples(image: Image) -> int:
	var samples: int = 0
	var pixel_scale: Vector2 = Vector2(image.get_size()) / root.get_visible_rect().size
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var screen: Vector2 = Vector2(x, y) / pixel_scale
			if edge_region(screen) != Vector3i.ZERO and through_window(screen):
				var color: Color = image.get_pixel(x, y)
				if maxf(color.r, maxf(color.g, color.b)) > 0.055:
					samples += 1
	return samples

func check_backdrop_tumbling(backdrop: BeltBackdrop) -> void:
	backdrop.animate(1.0, Vector3.ZERO)
	await frame_image()
	var slowest: float = INF
	var fastest: float = 0.0
	var aligned: bool = true
	var fixed_centers: bool = true
	for batch in backdrop.batches:
		if Vector3(batch["center"]).length() > VectorArt.VIEW_DISTANCE:
			continue
		var meshes: Array[MultiMesh] = batch["meshes"]
		var transforms: Array[Transform3D] = batch["transforms"]
		for i in range(transforms.size()):
			var spun: Transform3D = meshes[0].get_instance_transform(i)
			var angle: float = transforms[i].basis.orthonormalized().get_rotation_quaternion().angle_to(spun.basis.orthonormalized().get_rotation_quaternion())
			slowest = minf(slowest, angle)
			fastest = maxf(fastest, angle)
			aligned = aligned and spun.is_equal_approx(meshes[1].get_instance_transform(i))
			fixed_centers = fixed_centers and spun.origin.is_equal_approx(transforms[i].origin) and spun.basis.get_scale().is_equal_approx(transforms[i].basis.get_scale())
	check(slowest > 0.02 and fastest > slowest * 4, "Uploaded backdrop rocks visibly rotate at different rates")
	check(aligned and fixed_centers, "Instanced crater strokes follow tumbling solids without changing centers or sizes")

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
