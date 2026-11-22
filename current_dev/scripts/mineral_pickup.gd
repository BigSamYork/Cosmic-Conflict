class_name MineralPickup
extends Node3D

const VALUE: int = CampaignState.MINERAL_VALUE
const LIFETIME: float = 12.0
const COLLECT_RADIUS: float = 2.6
const TRACTOR_RANGE: float = 32.0
const TRACTOR_SPEED: float = 65.0

var active: bool = true
var age: float = 0.0
var being_pulled: bool = false
var model: Node3D
var tether: Node3D
var biological: bool = false

func _ready() -> void:
	model = XyloArt.egg_ship(2, true) if biological else create_model()
	add_child(model)
	tether = VectorArt.cached_model("mineral_tether")
	if tether == null:
		tether = Node3D.new()
		tether.add_child(VectorArt.lines(PackedVector3Array([Vector3.ZERO, Vector3.FORWARD]), Color("#57ab96")))
		VectorArt.remember_model("mineral_tether", tether)
	add_child(tether)
	tether.hide()

static func create_model() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("mineral_core")
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	var vertices := PackedVector3Array([Vector3.UP * 1.3, Vector3.DOWN * 1.3, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK])
	var indices := PackedInt32Array([0, 2, 4, 0, 4, 3, 0, 3, 5, 0, 5, 2, 1, 4, 2, 1, 3, 4, 1, 5, 3, 1, 2, 5])
	batch.surface(vertices, indices, Color("#1d4939"))
	for tip in [0, 1]:
		for side in range(2, 6):
			batch.line(vertices[tip], vertices[side], VectorArt.CYAN)
	batch.ring(Vector3.ZERO, 1.6, VectorArt.AMBER, 16)
	return VectorArt.remember_model("mineral_core", batch.build())

func advance(delta: float, previous_pilot: Vector3, pilot: Vector3, tractor: bool) -> bool:
	if not active:
		return false
	age += delta
	if age >= LIFETIME:
		active = false
		hide()
		return false
	var previous: Vector3 = global_position
	being_pulled = false
	if tractor and previous.distance_to(pilot) <= TRACTOR_RANGE:
		var query := PhysicsRayQueryParameters3D.create(previous, pilot, 1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			being_pulled = true
			global_position = previous.move_toward(pilot, TRACTOR_SPEED * delta)
	var closest: Vector3 = Geometry3D.get_closest_point_to_segment(Vector3.ZERO, previous - previous_pilot, global_position - pilot)
	if closest.length() <= COLLECT_RADIUS:
		active = false
		hide()
		return true
	model.rotation = Vector3(age * 0.7, age, 0)
	model.scale = Vector3.ONE * minf(1.0, (LIFETIME - age) / 1.5)
	tether.visible = being_pulled
	if being_pulled:
		var direction: Vector3 = pilot - global_position
		tether.global_transform = Transform3D(Basis.looking_at(direction.normalized()).scaled(Vector3(1, 1, direction.length())), global_position)
	return false
