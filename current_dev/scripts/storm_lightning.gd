class_name StormLightning
extends FrostField

signal aim_requested(field: StormLightning, cycle: int)
signal contact(body: CollisionObject3D, at: Vector3, direction: Vector3)
signal grounded(at: Vector3)

const CHANNEL := preload("res://shaders/storm_channel.gdshader")
const STROKES := [0.0, 0.22, 0.53]
const HEIGHT_M := 105.0
const VIEW_RANGE := 680.0
var site := 0
var landing := Vector3.DOWN
var reduced := false
var pilot_radius := 2.5
var paths: Array[PackedVector3Array] = []
var parents := PackedInt32Array()
var cycle_id := -1
var next_stroke := 0
var channel := MeshInstance3D.new()
var ink := ShaderMaterial.new()

func _ready() -> void:
	var warning_ring := GeometryBatch.new()
	var rim := PackedVector3Array()
	for i in range(32):
		var angle := TAU * i / 32.0
		rim.append(Vector3(cos(angle) * RADIUS, 0.3, sin(angle) * RADIUS))
	warning_ring.outline(rim, VectorArt.AMBER)
	ring = warning_ring.build()
	add_child(ring)
	ink.shader = CHANNEL
	channel.material_override = ink
	channel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume = channel
	add_child(channel)
	ring.hide()
	channel.hide()

func active(at: float) -> bool:
	var t := fposmod(at + phase, CYCLE) - WARNING
	return t >= 0 and t < 0.85

func advance(delta: float, previous: Vector3, pilot: Vector3) -> bool:
	if delta <= 0:
		return false
	var before := age
	age += delta
	if global_position.distance_squared_to(pilot) > VIEW_RANGE * VIEW_RANGE:
		ring.hide()
		channel.hide()
		return false
	var hit_pilot := false
	var first_cycle := floori((before + phase) / CYCLE)
	var last_cycle := floori((age + phase) / CYCLE)
	for cycle in range(first_cycle, last_cycle + 1):
		if cycle_id != cycle:
			_prepare(cycle)
		var start := cycle * CYCLE - phase + WARNING
		while next_stroke < STROKES.size() and start + STROKES[next_stroke] <= age:
			var when: float = start + STROKES[next_stroke]
			if when >= before:
				var at := previous.lerp(pilot, clampf((when - before) / delta, 0, 1))
				var hit := _discharge(at)
				hit_pilot = hit_pilot or hit
			next_stroke += 1
	_update_visual()
	return hit_pilot

func _prepare(cycle: int) -> void:
	cycle_id = cycle
	next_stroke = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(site + 173, cycle))
	landing = Vector3(rng.randf_range(-2, 2), -1.0, rng.randf_range(-3, 3))
	aim_requested.emit(self, cycle)
	ring.position = landing + Vector3.UP * 1.2
	var cloud := Vector3(rng.randf_range(-29, 29), HEIGHT_M, rng.randf_range(-22, 22))
	var trunk := _channel_points(cloud, landing, 5, rng)
	paths.assign([trunk])
	parents = PackedInt32Array([-1])
	for i in range(6):
		var fork := trunk[3 + i * 4]
		var reach := rng.randf_range(20, 42) * (1.0 - 0.055 * i)
		var angle := rng.randf_range(0, TAU)
		var tip := fork + Vector3(cos(angle) * reach, -reach * rng.randf_range(0.42, 1.1), sin(angle) * reach)
		var branch := _channel_points(fork, tip, 3, rng)
		paths.append(branch)
		parents.append(0)
		if i % 2 == 0:
			var spur := branch[4]
			var split := Vector3(-sin(angle), -0.82, cos(angle)) * reach * 0.42
			parents.append(paths.size() - 1)
			paths.append(_channel_points(spur, spur + split, 2, rng))
	_upload()

func _channel_points(a: Vector3, b: Vector3, levels: int, rng: RandomNumberGenerator) -> PackedVector3Array:
	var points := PackedVector3Array([a, b])
	for _level in range(levels):
		var stepped := PackedVector3Array([points[0]])
		for i in range(1, points.size()):
			var span := points[i].distance_to(points[i - 1])
			var bend := Vector3(rng.randf_range(-0.21, 0.21), rng.randf_range(-0.05, 0.05), rng.randf_range(-0.21, 0.21))
			stepped.append(points[i - 1].lerp(points[i], 0.5) + bend * span)
			stepped.append(points[i])
		points = stepped
	return points

func _discharge(pilot: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.new()
	query.collision_mask = 3 | SurfacePatrol.STORM_LAYER
	query.hit_back_faces = true
	var space := get_world_3d().direct_space_state
	var hit_pilot := false
	var changed := false
	for branch in range(paths.size()):
		var path := paths[branch]
		if path.is_empty():
			continue
		if branch > 0 and not paths[parents[branch]].has(path[0]):
			paths[branch] = PackedVector3Array()
			changed = true
			continue
		for i in range(1, path.size()):
			query.from = to_global(path[i - 1])
			query.to = to_global(path[i])
			var result := space.intersect_ray(query)
			var end: Vector3 = result.get("position", query.to)
			# Compare the pilot with the first solid contact on the same segment.
			var nearest := Geometry3D.get_closest_point_to_segment(pilot, query.from, end) if not end.is_equal_approx(query.from) else end
			if pilot_radius > 0 and nearest.distance_squared_to(pilot) <= pilot_radius * pilot_radius:
				end = nearest
				hit_pilot = hit_pilot or struck_cycle != cycle_id
				struck_cycle = cycle_id
			elif result.is_empty():
				continue
			else:
				contact.emit(result.collider, end, query.from.direction_to(query.to))
			path.resize(i + 1)
			path[i] = to_local(end)
			paths[branch] = path
			changed = true
			break
	if next_stroke == 0:
		grounded.emit(to_global(paths[0][-1]))
	if changed:
		_upload()
	return hit_pilot

func _upload() -> void:
	var batch := GeometryBatch.new()
	for branch in range(paths.size()):
		var points := paths[branch]
		var tint := Color.WHITE if branch == 0 else Color(0.55, 0.67, 1.0, 0.46)
		for i in range(1, points.size()):
			batch.line(points[i - 1], points[i], tint)
	var strokes := VectorArt.lines(batch.edges, Color.WHITE, batch.edge_colors)
	channel.mesh = strokes.mesh
	channel.extra_cull_margin = 3.0
	strokes.free()

func _update_visual() -> void:
	var t := fposmod(age + phase, CYCLE) - WARNING
	ring.visible = t < 0.0
	channel.visible = t >= -0.26 and t < 0.85
	if channel.visible:
		ink.set_shader_parameter("stroke_age", t)
		ink.set_shader_parameter("quiet", reduced)

func cloud_brightness() -> float:
	if reduced or not channel.visible:
		return 0.0
	var t := fposmod(age + phase, CYCLE) - WARNING
	if t < 0.0:
		return 0.12 * smoothstep(-0.26, -0.01, t)
	var glow := 0.0
	for i in range(STROKES.size()):
		if t >= STROKES[i]:
			glow += exp(-9.5 * (t - STROKES[i])) / (1.0 + i * 0.6)
	return glow
