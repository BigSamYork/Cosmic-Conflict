class_name CampaignMedal
extends Control

var rank: int = 0

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 82)
	var gold := Color("#ffa65c").lerp(Color("#e5f2f2"), rank / 10.0)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 8, -30), center + Vector2(side * 42, -74),
			center + Vector2(side * 60, -74), center + Vector2(side * 27, -12)
		]), Color("#327985"))
	draw_circle(center, 48, Color("#152e39"))
	draw_arc(center, 48, 0, TAU, 64, gold, 3, true)
	draw_arc(center, 39, 0, TAU, 64, Color("#70e2e7"), 1.5, true)
	var star := PackedVector2Array()
	var points: int = 4 + rank / 2
	for i in range(points * 2):
		star.append(center + Vector2.from_angle(-PI / 2 + TAU * i / (points * 2)) * (32 if i % 2 == 0 else 14))
	draw_colored_polygon(star, gold)
	draw_circle(center, 8, Color("#152e39"))
	draw_line(center + Vector2(-5, 3), center + Vector2(0, -5), Color("#70e2e7"), 2, true)
	draw_line(center + Vector2(0, -5), center + Vector2(5, 3), Color("#70e2e7"), 2, true)
	for i in range(rank + 1):
		draw_circle(Vector2(size.x * 0.5 + (i - rank * 0.5) * 13, 144), 3, gold)
