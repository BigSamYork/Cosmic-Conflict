class_name SurfaceRig
extends RefCounted

# Keep the imported armature and animations when fitting the game's hull finish.
static func model(id: String) -> Node3D:
	var scene: PackedScene = load("res://assets/ground/%s.glb" % id)
	var assembly: Node3D = scene.instantiate()
	for surface: MeshInstance3D in assembly.find_children("*", "MeshInstance3D", true, false):
		surface.material_override = FleetArt.hull_material
		surface.set_instance_shader_parameter(&"weathered", true)
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return assembly

static func start(model_root: Node3D, clip: StringName, phase: float) -> AnimationPlayer:
	var player := model_root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var animation := player.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR
	player.play(clip)
	player.seek(fposmod(phase, animation.length), true)
	return player
