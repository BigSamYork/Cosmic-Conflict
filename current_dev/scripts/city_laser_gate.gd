class_name CityLaserGate
extends Node3D

const CYCLE: float = 8.0
const WARNING: float = 2.0
const ACTIVE: float = 3.0
const SAFE_HALF_WIDTH: float = 5.5
const OUTER: float = 17.3
const BEAM_RADIUS: float = 0.22
const DAMAGE: float = 18.0
var emitters: Array[GateEmitter] = []
var beams: Array[Node3D] = []
var warnings: Array[Node3D] = []
var age: float = 0
var phase: float = 0
var struck: bool = false

func _ready() -> void:
	for side in [-1.0, 1.0]:
		var emitter := GateEmitter.new()
		emitter.position.x = side * 18.2
		emitter.disabled.connect(_refresh)
		add_child(emitter)
		emitters.append(emitter)
		var active_lines := PackedVector3Array()
		var warning_lines := PackedVector3Array()
		for row in range(11):
			var y: float = -8 + row * 2
			active_lines.append_array(PackedVector3Array([Vector3(side * SAFE_HALF_WIDTH, y, 0), Vector3(side * OUTER, y, 0)]))
			for dash in range(6):
				var x: float = SAFE_HALF_WIDTH + dash * 2
				warning_lines.append_array(PackedVector3Array([Vector3(side * x, y, 0), Vector3(side * (x + 0.75), y, 0)]))
		var beam: MeshInstance3D = VectorArt.lines(active_lines, VesperaArt.NEON if side < 0 else VesperaArt.SIGNAL)
		add_child(beam)
		beams.append(beam)
		var warning: MeshInstance3D = VectorArt.lines(warning_lines, VectorArt.AMBER)
		add_child(warning)
		warnings.append(warning)
	_refresh()

func active_at(time: float, side_index: int) -> bool:
	var cycle: float = fposmod(time + phase + side_index * 4, CYCLE)
	return cycle >= WARNING and cycle < WARNING + ACTIVE

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, radius: float, harmful: bool = true) -> bool:
	var before: float = age
	age += delta
	var from: Vector3 = to_local(previous_pilot)
	var to: Vector3 = to_local(pilot)
	var hit: bool = false
	for side_index in range(2):
		var jam_before: float = emitters[side_index].jam_remaining
		emitters[side_index].jam_remaining = maxf(0, jam_before - delta)
		if not harmful or struck or emitters[side_index].destroyed or delta == 0:
			continue
		if minf(from.z, to.z) > radius + BEAM_RADIUS or maxf(from.z, to.z) < -radius - BEAM_RADIUS:
			continue
		var samples: int = maxi(1, ceili(delta * 240))
		for i in range(samples):
			var fraction: float = (i + 0.5) / samples
			var time: float = before + fraction * delta
			if fraction * delta < jam_before or not active_at(time, side_index):
				continue
			var at: Vector3 = from.lerp(to, fraction)
			var x: float = at.x * (-1 if side_index == 0 else 1)
			var y: float = at.y - sin(time * 1.5 + side_index) * 0.45
			var row: int = clampi(roundi((y + 8) / 2), 0, 10)
			if x >= SAFE_HALF_WIDTH - radius and x <= OUTER + radius and absf(at.z) <= radius + BEAM_RADIUS and absf(y - (-8 + row * 2)) <= radius + BEAM_RADIUS:
				struck = true
				hit = true
				break
	_refresh()
	return hit

func _refresh() -> void:
	for i in range(beams.size()):
		var available: bool = not emitters[i].destroyed
		var cycle: float = fposmod(age + phase + i * 4, CYCLE)
		beams[i].visible = available and emitters[i].jam_remaining <= 0 and active_at(age, i)
		warnings[i].visible = available and (cycle < WARNING or emitters[i].jam_remaining > 0) and fmod(age, 0.3) < 0.22
		beams[i].position.y = sin(age * 1.5 + i) * 0.45
		warnings[i].position.y = beams[i].position.y
