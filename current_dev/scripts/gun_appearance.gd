class_name GunAppearance
extends RefCounted

const OVERLAYS: Array[Texture2D] = [
	preload("res://assets/guns/upgrade_1_plasma_shroud.png"),
	preload("res://assets/guns/upgrade_2_outboard_autocannons.png")
]
static var cache: Dictionary = {}

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
		points.append_array(PackedVector2Array([Vector2(493, 431), Vector2(883, 431)]))
	return points
