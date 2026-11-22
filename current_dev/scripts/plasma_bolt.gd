class_name PlasmaBolt
extends Node3D

signal impacted(result: Dictionary)

const SPEED: float = 650.0
const RANGE: float = 490.0
var direction: Vector3 = Vector3.FORWARD
var travelled: float = 0.0
var active: bool = true
var dangerous: bool = true

func _ready() -> void:
	var trail: MeshInstance3D = PrimaryArt.segment(1)
	trail.rotation.y = PI
	trail.scale.z = 14.0
	add_child(trail)
	global_basis = Basis.looking_at(direction)

func advance(delta: float) -> void:
	if not active:
		return
	var distance: float = minf(SPEED * delta, RANGE - travelled)
	var next: Vector3 = global_position + direction * distance
	var hit: Dictionary = {}
	if dangerous:
		var query := PhysicsRayQueryParameters3D.create(global_position, next, 7)
		query.collide_with_areas = true
		hit = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit["position"]
		active = false
		hit["direction"] = direction
		impacted.emit(hit)
	else:
		global_position = next
	travelled += distance
	if travelled >= RANGE:
		active = false
