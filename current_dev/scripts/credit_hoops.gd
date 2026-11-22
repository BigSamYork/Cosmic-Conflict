extends Node3D

const RADIUS := 4.8
var rng := RandomNumberGenerator.new()
var phase_key := ""
var next_time := 0.0
var hoop: Node3D
var symbol: Label3D
var value := 0
var age := 0.0

func clear() -> void:
	phase_key = ""
	_remove_hoop()

func _remove_hoop() -> void:
	if hoop != null:
		hoop.hide()
		hoop.queue_free()
		hoop = null

static func prize(roll: int) -> int:
	if roll < 60: return 100
	if roll < 83: return 200
	if roll < 94: return 350
	if roll < 99: return 500
	return 1000

static func crossed(previous: Vector3, current: Vector3, clearance: float) -> bool:
	if (previous.z > 0) == (current.z > 0) or is_equal_approx(previous.z, current.z):
		return false
	var point := previous.lerp(current, previous.z / (previous.z - current.z))
	return Vector2(point.x, point.y).length() <= RADIUS - clearance

func advance(delta: float, previous: Vector3, current: Vector3, campaign: CampaignState, flight: FlightState, director: FlightDirector) -> int:
	if not campaign.phase in ["ground", "orbit", "asteroids"] or flight.hull <= 0:
		return 0
	var key := "%s/%d/%s/%s" % [campaign.operation_id, campaign.sortie_id, campaign.sector, campaign.phase]
	if key != phase_key:
		clear()
		phase_key = key
		rng.seed = key.hash()
		next_time = rng.randf_range(9, 24)
	if hoop != null:
		age += delta
		symbol.position.y = 0.45 * sin(age * 2.5)
		if crossed(hoop.to_local(previous), hoop.to_local(current), flight.collision_radius):
			_remove_hoop()
			campaign.reward(value)
			return value
		if age > 15:
			_remove_hoop()
	if flight.elapsed >= next_time and flight.elapsed < flight.duration - 6:
		next_time = flight.elapsed + rng.randf_range(29, 44)
		var ahead := flight.speed * rng.randf_range(3.0, 4.3)
		var distance := flight.distance + ahead
		var pose := director.frame.translated_local(Vector3.FORWARD * ahead)
		if campaign.phase == "ground":
			pose = director.ground_course * (GroundRoute.frame(distance) if director.ground_route != null and director.ground_route.selected else FlightState.rail_frame(distance))
		elif campaign.phase == "asteroids":
			pose = director.origin * FlightDirector.asteroid_frame(distance)
		_spawn(pose.translated_local(Vector3(rng.randf_range(-8, 8), rng.randf_range(-2, 3), 0)))
	return 0

func _spawn(pose: Transform3D) -> void:
	_remove_hoop()
	age = 0
	value = prize(rng.randi_range(0, 99))
	hoop = Node3D.new()
	add_child(hoop)
	hoop.global_transform = pose
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS
	torus.outer_radius = RADIUS + 0.34
	ring.mesh = torus
	ring.rotation.x = PI / 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.09, 1.7, 0.28)
	ring.material_override = material
	hoop.add_child(ring)
	symbol = Label3D.new()
	symbol.text = "$"
	symbol.font_size = 96
	symbol.pixel_size = 0.043
	symbol.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbol.modulate = Color("#99ffb0")
	hoop.add_child(symbol)
