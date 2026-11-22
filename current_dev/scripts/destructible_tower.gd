class_name DestructibleTower
extends RangeTarget

signal fractured(tower: DestructibleTower)
var pivot: Node3D
var collapse_time: float = -1.0
var has_fractured: bool = false
var sector: String = "ignis"

func _ready() -> void:
	collision_layer = 3
	collision_mask = 0
	pivot = Node3D.new()
	pivot.position.y = -5.5
	add_child(pivot)
	var structure: Node3D = FrontierArt.pylon(sector) if FrontierArt.is_frontier(sector) else XyloArt.pylon() if sector == "xylo" else VesperaArt.pylon() if sector == "vespera" else CryoArt.ice_pylon() if sector == "cryo" else VectorArt.tower()
	structure.position.y = 5.5
	pivot.add_child(structure)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.2, 11, 4)
	collider.shape = shape
	add_child(collider)
	reset()

func animate(_time: float) -> void:
	pass

func reset() -> void:
	clear_impact_marks()
	armor = 6
	destroyed = false
	collision_layer = 3
	collapse_time = -1.0
	has_fractured = false
	pivot.rotation = Vector3.ZERO
	pivot.show()
	show()

func vulnerable_at(world_point: Vector3) -> bool:
	return not destroyed and to_local(world_point).y <= -3.2

func receive_hit(damage: int = 1) -> bool:
	if destroyed:
		return false
	armor -= damage
	if armor <= 0:
		destroyed = true
		collision_layer = 0
		collapse_time = 0.0
	return destroyed

func advance(delta: float) -> void:
	if collapse_time < 0:
		return
	collapse_time += delta
	var direction: float = -1.0 if lane.x < 0 else 1.0
	pivot.rotation.z = direction * minf(1.55, collapse_time * collapse_time * 0.7)
	if collapse_time >= 1.35 and not has_fractured:
		has_fractured = true
		fractured.emit(self)
		pivot.hide()

func aim_point() -> Vector3:
	return to_global(Vector3(0, -4.5, 2.05))
