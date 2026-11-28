extends Node3D

## Render-only civilians: they are never offered to weapon locks or combat AI.
var boat: Node3D
var section: Node3D
var label := Label3D.new()
var outside := 0.0
var sector := ""

func configure(destination: String) -> void:
	sector = destination
	boat = FleetArt.model("traffic")
	add_child(boat)
	if sector == "thalassa":
		section = FleetArt.model("traffic")
		section.scale *= 1.5
		section.position = Vector3(0, -1.5, 23)
		add_child(section)
		add_child(VectorArt.lines(PackedVector3Array([Vector3.BACK * 4, Vector3.BACK * 18]), VectorArt.AMBER))
	label.font_size = 34
	label.pixel_size = 0.036
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#99f8ce")
	label.position.y = 5
	label.text = {"xylo":"CLINIC BOAT", "thalassa":"AEGIS-4 / MAINTENANCE TOW", "ignis":"FOUNDRY TUG", "cryo":"WARD TRANSPORT"}[sector]
	add_child(label)

func advance(delta: float, pilot: Transform3D, detour: bool) -> void:
	outside = move_toward(outside, 1 if detour else 0, delta * 0.35)
	global_transform = pilot.translated_local(Vector3(-20 - 26 * outside, 4 + 8 * outside, -69))
	if detour: label.text = "CLINIC BOAT / OUTSIDE PASSAGE"
