extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var expected := PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
	for name: String in CockpitInstruments.PANELS:
		var corners := PackedVector2Array(CockpitInstruments.PANELS[name]["corners"])
		var inverse: Basis = CockpitInstruments.inverse_projection(corners)
		var matches: bool = true
		for i in range(4):
			var projected: Vector3 = inverse * Vector3(corners[i].x, corners[i].y, 1)
			var uv := Vector2(projected.x, projected.y) / projected.z
			matches = matches and uv.distance_to(expected[i]) < 0.0001
		check(matches, "Perspective UV mapping matches supplied corners: " + name)
	var frames := PackedStringArray(["res://assets/cockpit_overlay.png"])
	for ship: String in CampaignState.SHIPS:
		frames.append("res://assets/cockpits/%s.png" % ship)
	for filename in frames:
		var image := Image.new()
		var decoded: Error = image.load_png_from_buffer(FileAccess.get_file_as_bytes(filename))
		check(decoded == OK and image.get_size() == Vector2i(1376, 768), "Cockpit shares the calibrated image dimensions: " + filename.get_file())
		check(image.get_pixel(688, 350).a == 0.0 and image.get_pixel(690, 608).a > 0.9, "Transparent windows and opaque structure preserved: " + filename.get_file())
	print("COCKPIT_LAYOUT_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
