extends SceneTree

const Hazard := preload("res://scripts/frontier_hazard.gd")
var failures := 0
var capture_dir := ""

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	root.size = Vector2i(960, 540)
	root.unfocusable = true
	var camera := Camera3D.new()
	root.add_child(camera)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#28364b")
	root.add_child(world)
	var floor_mesh := MeshInstance3D.new()
	var ground := PlaneMesh.new()
	ground.size = Vector2(400, 400)
	floor_mesh.mesh = ground
	var matte := StandardMaterial3D.new()
	matte.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	matte.albedo_color = Color("#57616d")
	floor_mesh.material_override = matte
	root.add_child(floor_mesh)
	for code: String in ["cryo", "vespera", "cryo_creature"]:
		var event = Hazard.new()
		event.sector = "cryo" if code == "cryo_creature" else code
		event.creature_encounter = code == "cryo_creature"
		var started := Time.get_ticks_usec()
		root.add_child(event)
		print("EVENT_BUILD_MS ", code, " ", (Time.get_ticks_usec() - started) / 1000.0)
		for age: float in [0.8, 1.95, 2.5, 2.78, 3.38, 4.9]:
			event.advance_event(age, false)
			check(event.visible, "Event visible while active")
			if code == "cryo_creature":
				var beast = event.creature
				var left: Vector3 = beast.wrists[0].global_position
				if age == 1.95:
					check(left.y > 16, "Mauler raises its paws above the flight lane before impact")
				elif age == 2.5:
					var right: Vector3 = beast.wrists[1].global_position
					var strike := left.lerp(right, 0.5)
					check(Vector2(strike.x, strike.z).length() < 0.1 and strike.y < 1.1 and left.distance_to(right) > 4, "Both giant paws bracket the marked strike on the ice")
				elif age == 4.9:
					check(beast.position.length() > 27, "Mauler visibly retreats")
				camera.position = Vector3(11, 7, 21)
				camera.look_at(Vector3(0, 5, -5))
			elif code == "cryo":
				check(event.scar.scale.x < 0.75 if age < 1.0 else event.scar.scale.x > 0.90, "Fault opens during buildup")
				# The dummy renderer does not retain MultiMesh transforms for readback.
				if age == 1.95 and DisplayServer.get_name() != "headless":
					check(event.ice.multimesh.get_instance_transform(0).basis.y.length() < 2.5, "Sheet flexes before contact")
				elif age == 2.78 and DisplayServer.get_name() != "headless":
					check(event.ice.multimesh.get_instance_transform(0).basis.y.length() > 9, "Broken sheet rises into flight lane")
				camera.position = Vector3(16, 10, 31)
				camera.look_at(Vector3(0, 5, 0))
			else:
				var nose: Vector3 = event.carriage.transform * event.NOSE
				if age == 1.95:
					check(nose.y > 16.0 and absf(nose.x) > 7.0, "Railcar approaches from above and aside")
				elif age == 2.5:
					check(nose.length() < 0.4, "Railcar hits the gameplay contact point on time")
				elif age == 3.38:
					check(nose.y < 2.0 and Vector2(nose.x, nose.z).length() > 9.0, "Wreck skids beyond impact")
				camera.position = Vector3(20, 8, 38)
				camera.look_at(Vector3(0, 7, 0) if age >= 2.5 else Vector3(-5, 16, -5))
			if not capture_dir.is_empty():
				await RenderingServer.frame_post_draw
				var file := capture_dir.path_join("%s-%03d.png" % [code, roundi(age * 100)])
				check(root.get_texture().get_image().save_png(file) == OK, "Capture written")
		event.advance_event(2.9, true)
		check(not event.light.visible and event.cloud.multimesh.visible_instance_count < event.CLOUDS, "Reduced mode limits light and particles")
		event.advance_event(5.5, false)
		check(not event.visible, "Event ends cleanly")
		event.free()
	print("FRONTIER_EVENT_FAILURES=", failures)
	quit(failures)
