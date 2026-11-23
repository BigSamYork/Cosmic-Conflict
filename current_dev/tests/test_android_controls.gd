extends SceneTree

const Controls := preload("res://scripts/android_flight_controls.gd")
var controls := Controls.new()
var aim := Vector2.ZERO
var commands: Array[StringName] = []
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func touch(id: int, point: Vector2, pressed: bool, canceled := false) -> bool:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	event.canceled = canceled
	return controls.handle(event)

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr(label)

func run() -> void:
	root.add_child(controls)
	controls.aimed.connect(func(point: Vector2) -> void: aim = point)
	controls.commanded.connect(func(action: StringName) -> void: commands.append(action))
	check(not touch(0, Vector2.ZERO, true), "Menus must receive touches")
	controls.show()
	var area := controls.safe_rect()
	var center := controls.center(&"stick", area)
	touch(1, center, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = center + Vector2(controls.unit(area), 0)
	controls.handle(drag)
	check(controls.stick.is_equal_approx(Vector2.RIGHT) and is_equal_approx(aim.x, area.size.x), "Stick steers and aims")
	touch(2, controls.center(&"primary", area), true)
	touch(3, area.get_center(), true)
	touch(4, controls.center(&"secondary", area), true)
	check(controls.firing() and aim.is_equal_approx(area.get_center()) and controls.stick.x == 1.0, "Canopy aim, thrust and fire work simultaneously")
	check(commands == [&"secondary"], "Ordnance fires once on press")
	touch(3, Vector2.ZERO, false)
	check(is_equal_approx(aim.x, area.size.x), "Releasing canopy aim restores stick aim")
	touch(2, Vector2.ZERO, false, true)
	check(not controls.firing() and controls.stick.x == 1.0, "Canceled fire leaves thrust held")
	controls.hide()
	check(controls.fingers.is_empty() and controls.stick.is_zero_approx(), "Leaving flight releases every finger")
	controls.queue_free()
	print("ANDROID_CONTROL_FAILURES=%d" % failures)
	quit(1 if failures else 0)
