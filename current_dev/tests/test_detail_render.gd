extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Detail visibility requires native rendering, not --headless.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 78.0
	camera.far = VectorArt.VIEW_DISTANCE
	stage.add_child(camera)
	camera.make_current()
	var tower: Node3D = VectorArt.tower()
	stage.add_child(tower)
	for reduced in [false, true]:
		VectorArt.set_reduced_effects(reduced)
		for distance in [750.0, 1000.0]:
			tower.position = Vector3(0, 0, -distance)
			await process_frame
			await RenderingServer.frame_post_draw
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var measured: Dictionary = measure_pixels(image)
			var lit_pixels: int = measured["count"]
			if lit_pixels >= 8:
				print("PASS: Tower strokes visible at %.0fm, reduced=%s, pixels=%d" % [distance, reduced, lit_pixels])
			else:
				var clip: Vector4 = camera.get_camera_projection() * Vector4(0, 0, -distance, 1)
				push_error("Distant tower detail not visible at %.0fm (reduced=%s, pixels=%d, brightest=%s, ndc_z=%.8f)" % [distance, reduced, lit_pixels, measured["brightest"], clip.z / clip.w])
				failures += 1
	var cover: MeshInstance3D = VectorArt.solid(PackedVector3Array([Vector3(-20, -20, -700), Vector3(20, -20, -700), Vector3(20, 20, -700), Vector3(-20, 20, -700)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.BLACK)
	stage.add_child(cover)
	tower.position.z = -750
	VectorArt.set_reduced_effects(false)
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var covered: Dictionary = measure_pixels(root.get_texture().get_image())
	if covered["count"] == 0:
		print("PASS: Distant strokes remain hidden behind opaque scenery")
	else:
		push_error("Stroke depth bias draws through opaque scenery.")
		failures += 1
	var palette_color := Color("#254769")
	var colors := PackedColorArray([palette_color, palette_color, palette_color, palette_color])
	var palette: MeshInstance3D = VectorArt.solid(PackedVector3Array([Vector3(-5, -5, -20), Vector3(5, -5, -20), Vector3(5, 5, -20), Vector3(-5, 5, -20)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE, colors)
	stage.add_child(palette)
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	var center_color: Color = rendered.get_pixelv(Vector2i(rendered.get_size() / 2))
	var difference: float = maxf(absf(center_color.r - palette_color.r), maxf(absf(center_color.g - palette_color.g), absf(center_color.b - palette_color.b)))
	if difference < 0.04:
		print("PASS: Renderer preserves the authored terrain palette")
	else:
		push_error("Renderer changes the authored palette: " + str(center_color))
		failures += 1
	stage.queue_free()
	await process_frame
	print("DETAIL_RENDER_FAILURES=", failures)
	quit(failures)

func measure_pixels(image: Image) -> Dictionary:
	var count: int = 0
	var brightest := Color.BLACK
	var center := Vector2i(image.get_size() / 2)
	for y in range(center.y - 24, center.y + 24):
		for x in range(center.x - 24, center.x + 24):
			var color: Color = image.get_pixel(x, y)
			if color.r > brightest.r:
				brightest = color
			if color.r > 0.28 and color.g > 0.12:
				count += 1
	return {"count": count, "brightest": brightest}
