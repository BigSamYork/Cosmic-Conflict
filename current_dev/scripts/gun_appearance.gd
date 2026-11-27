class_name GunAppearance
extends RefCounted

const OVERLAYS: Array[Texture2D] = [
	preload("res://assets/guns/upgrade_1_plasma_shroud.png"),
	preload("res://assets/guns/upgrade_2_outboard_autocannons.png")
]
static var cache: Dictionary = {}

# Starboard receiver origins on the flight meshes, in hull-local coordinates.
# The Skiff has a port-side cabin and a taller rescue pod to starboard.
const MOUNTS := {
	"rook": {"pulse": Vector3(0.94, 0.48, -0.67), "outer": Vector3(2.38, 0.75, -0.07), "scale": 1.16},
	"hawk": {"pulse": Vector3(0.77, 0.23, -0.68), "outer": Vector3(1.92, 0.17, -0.72), "scale": 1.13},
	"titan": {"pulse": Vector3(0.80, 1.06, -1.22), "outer": Vector3(1.68, 0.70, -0.19), "scale": 1.38},
	"bastion": {"pulse": Vector3(1.39, 0.78, 0.16), "outer": Vector3(2.35, 0.72, -0.51), "scale": 1.40},
	"emergency": {"pulse": Vector3(0.42, 0.93, -0.35), "outer": Vector3(1.21, 0.86, -0.01), "scale": 0.83,
		"port_pulse": Vector3(-1.20, 0.67, -0.57), "port_outer": Vector3(-1.53, 0.15, 0.38)},
}

static func fit_exterior(hull: Node3D, ship: String, level: int) -> void:
	hull.set_meta("primary_level", level)
	var previous := hull.get_node_or_null("PrimaryGuns")
	if previous != null:
		previous.free()
	if not MOUNTS.has(ship):
		return
	var rack := Node3D.new()
	rack.name = "PrimaryGuns"
	hull.add_child(rack)
	var mounts: Dictionary = MOUNTS[ship]
	_mount_pair(rack, "Pulse", "twin_pulse", mounts.pulse, mounts.scale, mounts.get("port_pulse"))
	if level > 0:
		var outer_model := "quad_plasma" if level == 1 else "tachyon_beam"
		_mount_pair(rack, "Outer", outer_model, mounts.outer, mounts.scale, mounts.get("port_outer"))

static func _mount_pair(rack: Node3D, station: String, design: String, starboard: Vector3, size: float, port_override: Variant) -> void:
	var port := Vector3(-starboard.x, starboard.y, starboard.z)
	if port_override != null:
		port = port_override
	for side in ["Port", "Starboard"]:
		var gun := FleetArt.model(design, "guns")
		gun.name = side + station
		gun.position = port if side == "Port" else starboard
		gun.scale = Vector3.ONE * size
		rack.add_child(gun)

static func texture_for(base: Texture2D, level: int) -> Texture2D:
	if level == 0:
		return base
	if level < 0 or level > OVERLAYS.size():
		push_error("No gun artwork for primary level %d." % level)
		return null
	var key: String = "%s:%d" % [base.resource_path, level]
	if not cache.has(key):
		var frame: Image = base.get_image()
		var guns: Image = OVERLAYS[level - 1].get_image()
		if frame == null or guns == null or frame.get_size() != guns.get_size():
			push_error("Gun and cockpit artwork could not be composited.")
			return null
		cache[key] = ImageTexture.create_from_image(composite(frame, guns))
	return cache[key]

static func composite(frame: Image, guns: Image) -> Image:
	assert(frame.get_size() == guns.get_size())
	var result: Image = guns.duplicate()
	result.convert(Image.FORMAT_RGBA8)
	var cockpit: Image = frame.duplicate()
	cockpit.convert(Image.FORMAT_RGBA8)
	# The canopy, consoles and MFD bezels occlude the gun bases.
	result.blend_rect(cockpit, Rect2i(Vector2i.ZERO, cockpit.get_size()), Vector2i.ZERO)
	return result

static func muzzle_points(level: int) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(548, 452), Vector2(828, 452)])
	if level == 1:
		points.append_array(PackedVector2Array([Vector2(464, 434), Vector2(912, 434)]))
	elif level == 2:
		# Seat the beam between the forked rails, inside the tips of each emitter.
		points.append_array(PackedVector2Array([Vector2(465, 445), Vector2(911, 445)]))
	return points
