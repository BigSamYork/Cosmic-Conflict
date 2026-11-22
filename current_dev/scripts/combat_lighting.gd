class_name CombatLighting
extends Node3D

const LIMIT := 5
var lamps: Array[OmniLight3D] = []
var remaining := PackedFloat32Array()
var lifetimes := PackedFloat32Array()
var strengths := PackedFloat32Array()
var reduced := false

func flash(at: Vector3, tint: Color, radius: float, duration: float, strength: float) -> void:
	if reduced:
		return
	var slot := remaining.find(0.0)
	if slot < 0 and lamps.size() < LIMIT:
		slot = lamps.size()
		var lamp := OmniLight3D.new()
		lamp.shadow_enabled = false
		lamp.omni_attenuation = 1.0
		add_child(lamp)
		lamps.append(lamp)
		remaining.append(0.0)
		lifetimes.append(0.0)
		strengths.append(0.0)
	elif slot < 0:
		slot = 0
		for i in range(1, lamps.size()):
			if remaining[i] < remaining[slot]:
				slot = i
	var lamp := lamps[slot]
	lamp.global_position = at
	lamp.light_color = tint
	lamp.light_energy = strength
	lamp.omni_range = radius
	lamp.show()
	remaining[slot] = duration
	lifetimes[slot] = duration
	strengths[slot] = strength

func advance(delta: float) -> void:
	for i in range(lamps.size()):
		if remaining[i] <= 0.0:
			continue
		remaining[i] = maxf(0.0, remaining[i] - delta)
		lamps[i].light_energy = strengths[i] * pow(remaining[i] / lifetimes[i], 2)
		if remaining[i] == 0.0:
			lamps[i].hide()

func clear() -> void:
	remaining.fill(0.0)
	for lamp in lamps:
		lamp.hide()
