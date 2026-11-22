extends Node

func _ready() -> void:
	_launch.call_deferred()

func _launch() -> void:
	var scene: String = "res://voice_editor.tscn" if "--voice-editor" in OS.get_cmdline_user_args() else "res://main.tscn"
	var error: Error = get_tree().change_scene_to_file(scene)
	if error != OK:
		push_error("Cannot launch %s: %s" % [scene, error_string(error)])
		get_tree().quit(1)
