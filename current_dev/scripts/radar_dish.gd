class_name RadarDish
extends RangeTarget

const JAM_DURATION: float = 12.0
const JAM_RANGE: float = 700.0
const ROTATION_SPEED: float = 0.75
var biological := false
var dish: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	armor = 5
	transform = FlightState.rail_frame(travel)
	position = VectorArt.ground_point(lane.x, travel) + Vector3.UP * 1.5
	add_child(EncounterArt.radar_mast(11.0, biological))
	dish = EncounterArt.radar_dish(biological)
	dish.position.y = 11
	add_child(dish)
	var collider := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 5.0
	collider.position.y = 11
	collider.shape = shape
	add_child(collider)
	animate(0.0)

func animate(time: float) -> void:
	if destroyed or dish == null:
		return
	dish.rotation.y = fposmod(time * ROTATION_SPEED + phase, TAU)

func aim_point() -> Vector3:
	return dish.global_position
