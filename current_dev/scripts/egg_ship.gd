class_name EggShip
extends RangeTarget

var radius: float = 5.0
var cargo: bool = false
var infested: bool = false
var variant: int = 0
var near_pass: bool = true
var course: Transform3D = Transform3D.IDENTITY
var course_position: Vector3
var appearance: Node3D
var spin: Vector3

func _ready() -> void:
	collision_layer = 3
	collision_mask = 0
	armor = ceili(radius * 0.7)
	appearance = FleetArt.model("brood_egg", "ground") if infested else XyloArt.egg_ship(2 if cargo else variant)
	add_child(appearance)
	var shape := SphereShape3D.new()
	shape.radius = collision_radius()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	global_transform = course * Transform3D(Basis.IDENTITY, course_position)
	spin = AsteroidArt.tumble_velocity(roundi(travel * 13 + phase * 100)) * 0.4
	animate(0)

func animate(time: float) -> void:
	if not destroyed and appearance != null:
		appearance.basis = Basis(spin.normalized(), time * spin.length() + phase).scaled(Vector3.ONE * radius)

func collision_radius() -> float:
	return radius * 1.4

func tint() -> Color:
	if infested:
		return Color("#ff4b7b")
	return VectorArt.AMBER if cargo else XyloArt.SHELL
