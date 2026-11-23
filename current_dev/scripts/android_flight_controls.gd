extends Control

signal aimed(point: Vector2)
signal commanded(action: StringName)

const BUTTONS := {
	&"primary": "FIRE", &"secondary": "ORD", &"countermeasures": "FLARE",
	&"barrel_roll": "ROLL", &"evade": "DASH", &"pause": "PAUSE"
}
const INK := Color("#acece5")
const AMBER := Color("#ffd39a")
var fingers: Dictionary[int, StringName] = {}
var aim_finger := -1
var stick_finger := -1
var stick := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_visibility_changed)
	hide()

func _visibility_changed() -> void:
	fingers.clear()
	aim_finger = -1
	stick_finger = -1
	stick = Vector2.ZERO
	queue_redraw()

func safe_rect() -> Rect2:
	var area := Rect2(Vector2.ZERO, size)
	if OS.has_feature("android"):
		var safe := get_viewport().get_screen_transform().affine_inverse() * Rect2(DisplayServer.get_display_safe_area())
		if area.intersects(safe):
			return area.intersection(safe)
	return area

func unit(area: Rect2) -> float:
	return minf(area.size.x / 16.0, area.size.y / 9.0)

func center(action: StringName, area: Rect2) -> Vector2:
	var u := unit(area)
	var left := Vector2(area.position.x, area.end.y)
	match action:
		&"stick": return left + Vector2(1.55, -1.52) * u
		&"barrel_roll": return left + Vector2(3.42, -0.88) * u
		&"evade": return left + Vector2(3.42, -2.17) * u
		&"primary": return area.end - Vector2(1.17, 1.52) * u
		&"secondary": return area.end - Vector2(2.76, 0.88) * u
		&"countermeasures": return area.end - Vector2(2.76, 2.17) * u
		_: return Vector2(area.end.x - 3.5 * u, area.position.y + 0.68 * u)

func radius(action: StringName) -> float:
	match action:
		&"stick": return 1.08
		&"primary": return 0.78
		_: return 0.59

func _draw() -> void:
	var area := safe_rect()
	var u := unit(area)
	var base := center(&"stick", area)
	var fill := Color(0.025, 0.065, 0.08, 0.76)
	draw_circle(base, radius(&"stick") * u, fill)
	draw_arc(base, radius(&"stick") * u, 0, TAU, 72, INK, 2, true)
	draw_circle(base + stick * u * 0.72, u * 0.34, Color(INK, 0.50))
	for action: StringName in BUTTONS:
		var p := center(action, area)
		var r := radius(action) * u
		var color := AMBER if action == &"primary" else INK
		draw_circle(p, r, Color(color, 0.42) if fingers.values().has(action) else fill)
		draw_arc(p, r, 0, TAU, 64, color, 2, true)
		var font_size := maxi(12, roundi(u * 0.23))
		draw_string(ThemeDB.fallback_font, p + Vector2(-r, font_size * 0.35), BUTTONS[action], HORIZONTAL_ALIGNMENT_CENTER, 2*r, font_size, color)

func firing() -> bool:
	return fingers.values().has(&"primary")

func handle(event: InputEvent) -> bool:
	if not visible:
		return false
	var area := safe_rect()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			for action: StringName in BUTTONS:
				if event.position.distance_to(center(action, area)) <= radius(action) * unit(area):
					fingers[event.index] = action
					queue_redraw()
					if action != &"primary":
						commanded.emit(action)
					return true
			if event.position.distance_to(center(&"stick", area)) <= radius(&"stick") * unit(area):
				if stick_finger == -1:
					stick_finger = event.index
					fingers[event.index] = &"stick"
					_move_stick(event.position, area)
			elif aim_finger == -1:
				aim_finger = event.index
				fingers[event.index] = &"aim"
				aimed.emit(event.position.clamp(Vector2.ZERO, size))
		else:
			fingers.erase(event.index)
			if event.index == stick_finger:
				stick_finger = -1
				stick = Vector2.ZERO
				if aim_finger == -1:
					aimed.emit(size * 0.5)
			elif event.index == aim_finger:
				aim_finger = -1
				aimed.emit((Vector2.ONE + stick) * size * 0.5)
			queue_redraw()
		return true
	if event is InputEventScreenDrag:
		if event.index == aim_finger:
			aimed.emit(event.position.clamp(Vector2.ZERO, size))
		elif event.index == stick_finger:
			_move_stick(event.position, area)
		return true
	return false

func _move_stick(point: Vector2, area: Rect2) -> void:
	stick = ((point - center(&"stick", area)) / (unit(area) * 0.85)).limit_length()
	if aim_finger == -1:
		aimed.emit((Vector2.ONE + stick) * size * 0.5)
	queue_redraw()
