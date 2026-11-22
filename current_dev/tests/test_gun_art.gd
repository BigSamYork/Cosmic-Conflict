extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var panels: Array[Vector2i] = [Vector2i(690, 140), Vector2i(325, 660), Vector2i(1050, 660), Vector2i(685, 690), Vector2i(515, 650), Vector2i(860, 650)]
	for hull in ["rook", "hawk"]:
		var frame: Image = read_png("res://assets/cockpits/%s.png" % hull)
		for filename in ["upgrade_1_plasma_shroud.png", "upgrade_2_outboard_autocannons.png"]:
			var guns: Image = read_png("res://assets/guns/" + filename)
			var result: Image = GunAppearance.composite(frame, guns)
			var preserved: bool = true
			for point in panels:
				preserved = preserved and result.get_pixelv(point).is_equal_approx(frame.get_pixelv(point))
			check(preserved, "Gun artwork preserves all cockpit displays: " + hull + "/" + filename)
			check(result.get_pixel(688, 350).a == 0.0, "Gun artwork keeps the windshield transparent")
			var visible_guns: int = 0
			for y in range(400, 610, 8):
				for x in range(100, 1270, 8):
					if frame.get_pixel(x, y).a == 0.0 and guns.get_pixel(x, y).a > 0.5 and result.get_pixel(x, y).a > 0.5:
						visible_guns += 1
			check(visible_guns > 20, "Upgraded barrels appear through the cockpit openings")
	print("GUN_ART_FAILURES=", failures)
	quit(failures)

func read_png(path: String) -> Image:
	var image := Image.new()
	var error: Error = image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	assert(error == OK, "Cannot decode gun test asset: " + path)
	return image

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
