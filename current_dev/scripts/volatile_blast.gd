class_name VolatileBlast
extends Node3D

signal detonated(blast: VolatileBlast)

const FUSE: float = 0.65
const ROCK_RADIUS: float = 28.0
const PILOT_RADIUS: float = 18.0
const DAMAGE: float = 28.0
const DURATION: float = 1.25

var age: float = 0.0
var fired: bool = false
var pilot_checked: bool = false
var ring: Node3D

func _ready() -> void:
	ring = VectorArt.cached_model("volatile_blast")
	if ring == null:
		var batch := GeometryBatch.new()
		batch.ring(Vector3.ZERO, 1.0, Color("#ed91f7"), 36)
		batch.ring(Vector3.ZERO, 0.88, VectorArt.CYAN, 36)
		ring = batch.build()
		VectorArt.remember_model("volatile_blast", ring)
	add_child(ring)
	_update_visual()

func advance(delta: float, pilot: Vector3) -> void:
	age += delta
	if not fired and age >= FUSE:
		fired = true
		detonated.emit(self)
	if global_position.distance_squared_to(pilot) > 0.001:
		look_at(pilot, Vector3.UP)
	_update_visual()

func _update_visual() -> void:
	var radius: float = (2.0 + age / FUSE * 3.0) if not fired else minf(ROCK_RADIUS, (age - FUSE) / DURATION * ROCK_RADIUS)
	ring.scale = Vector3.ONE * maxf(0.01, radius)

func complete() -> bool:
	return age >= FUSE + DURATION
