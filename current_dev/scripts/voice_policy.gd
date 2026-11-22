class_name VoicePolicy
extends RefCounted

var clock: float = 0.0
var silence: float = INF
var speaking: bool = false
var priority: int = 0
var event: String = ""
var next_allowed: Dictionary = {}

func advance(delta: float) -> void:
	assert(delta >= 0)
	clock += delta
	if not speaking:
		silence += delta

static func group_for(key: String) -> String:
	if key.begins_with("reactor_"):
		return "reactor"
	if key.begins_with("primary_"):
		return "primary"
	return key

func can_start(key: String, urgency: int, minimum_silence: float = 6.0) -> bool:
	if clock + 0.000001 < float(next_allowed.get(group_for(key), 0.0)):
		return false
	if speaking:
		return urgency >= 80 and urgency > priority
	return urgency >= 80 or silence + 0.000001 >= minimum_silence

func route_allowed() -> bool:
	return not speaking and silence + 0.000001 >= 4.0

func started(key: String, urgency: int, cooldown: float) -> void:
	speaking = true
	priority = urgency
	event = key
	silence = 0
	next_allowed[group_for(key)] = clock + cooldown

func finished() -> void:
	speaking = false
	priority = 0
	event = ""
	silence = 0

func reset() -> void:
	finished()
	next_allowed.clear()
	silence = INF
