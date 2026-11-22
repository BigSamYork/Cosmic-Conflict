class_name PlayerTorpedo
extends Node3D

signal impacted(result: Dictionary)
var direction: Vector3 = Vector3.FORWARD
var age: float = 0.0
var active: bool = true
var homing_target: RangeTarget
var homing: bool = false
var speed: float = 190.0

func _ready() -> void:
	var model: Node3D = VectorArt.enemy_missile(VectorArt.AMBER if homing else VectorArt.CYAN)
	if homing:
		model.scale = Vector3.ONE * 0.65
	add_child(model)
	basis = Basis.looking_at(direction)

func advance(delta: float, colliding: bool = true) -> void:
	if not active:
		return
	age += delta
	if homing and is_instance_valid(homing_target) and homing_target.guided_lockable and not homing_target.destroyed and homing_target.collision_layer != 0:
		var toward: Vector3 = homing_target.aim_point() - global_position
		if toward.length_squared() > 0.01:
			var desired: Vector3 = toward.normalized()
			var angle: float = direction.angle_to(desired)
			direction = direction.slerp(desired, minf(1, delta * 2.8 / maxf(angle, 0.0001))).normalized()
			basis = Basis.looking_at(direction)
	var next: Vector3 = position + direction * delta * speed
	var hit: Dictionary = {}
	if colliding:
		var query := PhysicsRayQueryParameters3D.create(position, next, 7)
		query.collide_with_areas = true
		hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		active = false
		impacted.emit(hit)
	else:
		position = next
	if age >= 4.0:
		active = false
