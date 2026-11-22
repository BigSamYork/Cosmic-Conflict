extends SceneTree

var failures: int = 0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Debris fading must be verified with a native renderer.")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	stage.add_child(environment)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.make_current()
	var ship: Node3D = EncounterArt.strike_fighter()
	ship.position = Vector3(0, 0, -22)
	stage.add_child(ship)
	var breakup := BreakupEffect.new()
	stage.add_child(breakup)
	breakup.build(ship, true, VectorArt.CYAN, 256, 2.6, 8)
	ship.hide()
	var early: Image = await image()
	breakup.age = breakup.lifetime * 0.96
	breakup.advance(0)
	var late: Image = await image()
	var early_light: float = brightness(early)
	var late_light: float = brightness(late)
	print("POLYGON_FADE early=%.3f late=%.3f" % [early_light, late_light])
	check(early_light > 10 and late_light > 0 and late_light < early_light * 0.4, "Rendered solid polygons and their glowing edges visibly fade at full size")
	check(breakup.solid_instances.multimesh.get_instance_color(0).a < 0.2 and breakup.line_instances.multimesh.get_instance_color(0).a < 0.2, "Native solid and line instance buffers receive the fade alpha")
	breakup.advance(0.4)
	var gone: Image = await image()
	check(brightness(gone) < early_light * 0.01, "Expired polygon debris becomes transparent before removal")
	if not capture_dir.is_empty():
		check(early.save_png(capture_dir.path_join("polygons-early.png")) == OK and late.save_png(capture_dir.path_join("polygons-fading.png")) == OK, "Saved polygon fade comparison")
	breakup.queue_free()
	ship.queue_free()
	await process_frame
	var colors := GeometryBatch.new()
	for side in [-1.0, 1.0]:
		var center := Vector3(side * 3, 0, -20)
		colors.surface(PackedVector3Array([center + Vector3(-2, -1, 0), center + Vector3(2, -1, 0), center + Vector3(2, 1, 0), center + Vector3(-2, 1, 0)]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#8f3542") if side < 0 else Color("#35758f"))
	var painted: Node3D = colors.build()
	stage.add_child(painted)
	var before: Image = await image()
	var colored_fragments := BreakupEffect.new()
	stage.add_child(colored_fragments)
	colored_fragments.build(painted, true, Color.GREEN)
	painted.hide()
	var after: Image = await image()
	var unchanged_colors: bool = true
	for at in [Vector3(-3.3, 0.5, -20), Vector3(3.4, -0.5, -20)]:
		var pixel := Vector2i(camera.unproject_position(at))
		var original: Color = before.get_pixelv(pixel)
		var fragment: Color = after.get_pixelv(pixel)
		unchanged_colors = unchanged_colors and Vector3(original.r, original.g, original.b).distance_to(Vector3(fragment.r, fragment.g, fragment.b)) < 0.03
	check(unchanged_colors, "Rendered detached polygons preserve their original source colors")
	colored_fragments.queue_free()
	painted.queue_free()
	await process_frame
	var rock := Asteroid.new()
	rock.radius = 4
	rock.routed = true
	rock.course_position = Vector3(0, 0, -22)
	stage.add_child(rock)
	var rocky := RockBreakup.new()
	stage.add_child(rocky)
	rocky.build(rock, true)
	rock.hide()
	var rock_early: Image = await image()
	rocky.age = rocky.lifetime * 0.9
	rocky.polygons.age = rocky.age
	rocky.advance(0)
	var rock_late: Image = await image()
	check(brightness(rock_early) > 10 and brightness(rock_late) > 0 and brightness(rock_late) < brightness(rock_early) * 0.4, "Volumetric rock chunks and asteroid surface polygons also fade")
	if not capture_dir.is_empty():
		check(rock_early.save_png(capture_dir.path_join("rock-debris-early.png")) == OK and rock_late.save_png(capture_dir.path_join("rock-debris-fading.png")) == OK, "Saved rocky fade comparison")
	stage.queue_free()
	await process_frame
	print("DEBRIS_FADE_FAILURES=", failures)
	quit(failures)

func image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func brightness(picture: Image) -> float:
	var total: float = 0
	for y in range(0, picture.get_height(), 3):
		for x in range(0, picture.get_width(), 3):
			var color: Color = picture.get_pixel(x, y)
			total += color.r + color.g + color.b
	return total

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
