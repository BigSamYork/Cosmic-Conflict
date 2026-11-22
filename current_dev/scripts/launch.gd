extends Node

const AUTOMATION := ["--smoke-test", "--benchmark", "--mission-test", "--campaign-test", "--belt-benchmark", "--mining-test", "--orbit-benchmark", "--boss-benchmark", "--entry-benchmark", "--launch-benchmark", "--branch-benchmark", "--ground-benchmark", "--voice-test", "--music-test"]

func _ready() -> void:
	_launch.call_deferred()

func _launch() -> void:
	var args := OS.get_cmdline_user_args()
	var scene := "res://opening.tscn"
	if "--voice-editor" in args:
		scene = "res://voice_editor.tscn"
	elif DisplayServer.get_name() == "headless" or AUTOMATION.any(func(flag: String) -> bool: return flag in args):
		scene = "res://main.tscn"
	var error: Error = get_tree().change_scene_to_file(scene)
	if error != OK:
		push_error("Cannot launch %s: %s" % [scene, error_string(error)])
		get_tree().quit(1)
