class_name HeatVent
extends Node3D

const CYCLE: float = 6.0
const WARNING: float = 1.5
const ERUPTION: float = 2.0
const RADIUS: float = 5.0
const HEIGHT: float = 19.0
const HEAT_PER_SECOND: float = 85.0

var age: float = 0.0
var phase: float = 0.0
var plume: Node3D
var warning_ring: Node3D
var volcano: VolcanoEruption
var cone_body: StaticBody3D
var terrain_mounted: bool = false

func _ready() -> void:
	rotation.y = phase * 0.9
	var batch := GeometryBatch.new()
	for radius in [5.0, 5.5]:
		var ring := PackedVector3Array()
		for i in range(24):
			var angle: float = i * TAU / 24
			var point := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
			point.y = _rim_height(point) + 0.4
			ring.append(point)
		batch.outline(ring, VectorArt.AMBER)
	warning_ring = batch.build()
	add_child(warning_ring)
	volcano = VolcanoEruption.new()
	volcano.terrain_height = _rim_height
	add_child(volcano)
	plume = volcano.jet
	cone_body = StaticBody3D.new()
	cone_body.collision_layer = 1
	cone_body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	var solid: MeshInstance3D = volcano.cone.get_child(0)
	var points: PackedVector3Array = solid.mesh.get_meta("fragment_vertices").duplicate()
	if terrain_mounted:
		var apron: Node3D = _build_apron()
		add_child(apron)
		var foundation: MeshInstance3D = apron.get_child(0)
		points.append_array(foundation.mesh.get_meta("fragment_vertices"))
	shape.points = points
	collider.shape = shape
	cone_body.add_child(collider)
	add_child(cone_body)
	_update_visual()

func erupting(at: float) -> bool:
	var cycle: float = fposmod(at + phase, CYCLE)
	return cycle >= WARNING and cycle < WARNING + ERUPTION

func warning() -> bool:
	return fposmod(age + phase, CYCLE) < WARNING

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3) -> float:
	var before: float = age
	age += delta
	_update_visual()
	if delta <= 0.0:
		return 0.0
	var from: Vector3 = to_local(previous_pilot)
	var to: Vector3 = to_local(pilot)
	if minf(from.z, to.z) > RADIUS or maxf(from.z, to.z) < -RADIUS:
		return 0.0
	var samples: int = maxi(1, ceili(delta * 240.0))
	var exposure: float = 0.0
	for i in range(samples):
		var fraction: float = (i + 0.5) / samples
		var location: Vector3 = from.lerp(to, fraction)
		if location.y >= 0 and location.y <= HEIGHT and Vector2(location.x, location.z).length() <= RADIUS and erupting(before + fraction * delta):
			exposure += delta / samples
	return exposure * HEAT_PER_SECOND

func _update_visual() -> void:
	var cycle: float = fposmod(age + phase, CYCLE)
	var cooling: float = clampf((cycle - WARNING - ERUPTION) / (CYCLE - WARNING - ERUPTION), 0, 1)
	volcano.update_visual(age + phase, cycle - WARNING, erupting(age), cooling, HEIGHT)
	warning_ring.visible = cycle < WARNING + ERUPTION
	var pulse: float = 1.0 + 0.05 * sin(age * 14)
	warning_ring.scale = Vector3(pulse, 1, pulse)

func _ground_height(point: Vector3) -> float:
	if not terrain_mounted:
		return 0.0
	var location: Vector3 = transform * point
	var travel: float = -location.z
	var lane: float = location.x - FlightState.rail_point(travel).x
	return VectorArt.ground_point(lane, travel).y - position.y

func _rim_height(point: Vector3) -> float:
	var inner: Vector3 = VolcanoEruption._cone_point(atan2(point.z, point.x), 0)
	var outer: Vector3 = inner * 1.12
	var radius: float = Vector2(point.x, point.z).length()
	var ground: float = _ground_height(point)
	if radius >= outer.length():
		return ground
	var fraction: float = clampf((radius - inner.length()) / (outer.length() - inner.length()), 0, 1)
	return maxf(ground, lerpf(0, _ground_height(outer) - 0.08, fraction))

func _build_apron() -> Node3D:
	var batch := GeometryBatch.new()
	for i in range(32):
		var a: Vector3 = VolcanoEruption._cone_point(i * TAU / 32, 0)
		var b: Vector3 = VolcanoEruption._cone_point((i + 1) * TAU / 32, 0)
		var outer_a: Vector3 = a * 1.12
		var outer_b: Vector3 = b * 1.12
		outer_a.y = _ground_height(outer_a) - 0.08
		outer_b.y = _ground_height(outer_b) - 0.08
		batch.surface(PackedVector3Array([a, b, outer_b, outer_a]), PackedInt32Array([0, 1, 2, 0, 2, 3]), Color("#251d27"))
		if i % 4 == 0:
			batch.line(a, outer_a, Color("#684a43"))
	return batch.build()
