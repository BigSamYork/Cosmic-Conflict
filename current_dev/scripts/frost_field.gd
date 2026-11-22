class_name FrostField
extends Node3D

const CYCLE: float = 7.0
const WARNING: float = 1.5
const ACTIVE: float = 2.0
const RADIUS: float = 5.0
const HEIGHT: float = 15.0
const DAMAGE: float = 12.0
var age: float = 0.0
var phase: float = 0.0
var struck_cycle: int = -1
var plume: Node3D
var ring: Node3D
var contact_height: float = HEIGHT

func _ready() -> void:
	var batch := GeometryBatch.new()
	var points := PackedVector3Array()
	for i in range(32):
		var angle: float = i * TAU / 32
		points.append(Vector3(cos(angle) * RADIUS, 0.2, sin(angle) * RADIUS))
	batch.outline(points, CryoArt.ICE)
	for i in range(5):
		var angle: float = i * TAU / 5
		batch.crystal(Vector3(cos(angle) * 3, 0, sin(angle) * 3), 0.5, 1.5, CryoArt.STEEL)
	ring = batch.build()
	add_child(ring)
	plume = CryoArt.frost_plume()
	add_child(plume)
	_update_visual()

func active(at: float) -> bool:
	var cycle: float = fposmod(at + phase, CYCLE)
	return cycle >= WARNING and cycle < WARNING + ACTIVE

func warning() -> bool:
	return fposmod(age + phase, CYCLE) < WARNING

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3) -> bool:
	assert(delta >= 0)
	var before: float = age
	age += delta
	_update_visual()
	if delta == 0:
		return false
	var from: Vector3 = to_local(previous_pilot)
	var to: Vector3 = to_local(pilot)
	if minf(from.z, to.z) > RADIUS or maxf(from.z, to.z) < -RADIUS:
		return false
	var samples: int = maxi(1, ceili(delta * 240))
	for i in range(samples):
		var fraction: float = (i + 0.5) / samples
		var time: float = before + fraction * delta
		var cycle: int = floori((time + phase) / CYCLE)
		var at: Vector3 = from.lerp(to, fraction)
		if cycle != struck_cycle and active(time) and at.y >= 0 and at.y <= contact_height and Vector2(at.x, at.z).length() <= RADIUS:
			struck_cycle = cycle
			return true
	return false

func _update_visual() -> void:
	plume.visible = active(age)
	plume.rotation.y = (age + phase) * 0.7
	ring.visible = warning() or active(age)
