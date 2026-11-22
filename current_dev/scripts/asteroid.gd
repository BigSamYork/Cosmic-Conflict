class_name Asteroid
extends RangeTarget

var radius: float = 2.5
var mineral: bool = false
var indestructible: bool = false
var volatile: bool = false
var variant: int = 0
var near_pass: bool = true
var course: Transform3D = Transform3D.IDENTITY
var course_position: Vector3
var routed: bool = false
var appearance: Node3D
var spin_axis: Vector3
var spin_rate: float
var fragment: bool = false
var fragment_velocity: Vector3
var fragment_age: float = 0.0
const FRAGMENT_LIFETIME: float = 10.0

func _ready() -> void:
	assert(not (mineral and volatile) and not (indestructible and (mineral or volatile)))
	var velocity: Vector3 = AsteroidArt.tumble_velocity(roundi(travel * 10 + phase * 1000))
	spin_axis = velocity.normalized()
	spin_rate = velocity.length()
	collision_layer = 3
	collision_mask = 0
	appearance = create_model()
	appearance.scale = Vector3.ONE * radius
	add_child(appearance)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = collision_radius()
	collider.shape = shape
	add_child(collider)
	armor = ceili(radius)
	if routed:
		global_transform = course * Transform3D(Basis.IDENTITY, course_position)
	else:
		transform = FlightState.rail_frame(travel)
		position += Vector3(lane.x, lane.y, 0)
	animate(0.0)

func create_model() -> Node3D:
	return AsteroidArt.create(variant, tint())

func tint() -> Color:
	return Color("#d49071") if indestructible else Color("#eb80e8") if volatile else VectorArt.AMBER if mineral else Color("#a8a4b6")

static func warm_cache() -> void:
	for shape in range(AsteroidArt.VARIANTS):
		for kind in range(4):
			var rock := Asteroid.new()
			rock.variant = shape
			rock.mineral = kind == 1
			rock.indestructible = kind == 2
			rock.volatile = kind == 3
			var model: Node3D = rock.create_model()
			model.free()
			rock.free()
		var distant: Node3D = AsteroidArt.create(shape, Color("#8e8296"), true)
		distant.free()

func animate(time: float) -> void:
	if destroyed or appearance == null:
		return
	appearance.basis = Basis(spin_axis, time * spin_rate + phase).scaled(Vector3.ONE * radius)

func receive_hit(damage: int = 1) -> bool:
	if indestructible:
		return false
	return super.receive_hit(damage)

func collision_radius() -> float:
	return radius * 1.25
