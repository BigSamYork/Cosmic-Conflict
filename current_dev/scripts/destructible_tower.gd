class_name DestructibleTower
extends RangeTarget

signal fractured(tower: DestructibleTower)
const JOINTS := [-5.5, -2.6, 1.55]
static var collision_meshes: Dictionary[String, Shape3D] = {}
var pivot := Node3D.new()
var stump := Node3D.new()
var intact: Node3D
var collapse_time := -1.0
var has_fractured := false
var sector := "ignis"
var break_band := 0
var fall_axis := Vector3.RIGHT
var local_strike := Vector3.ZERO
var bending := 0.0
var last_wound := Vector3.INF
var concentrated := 0

func _ready() -> void:
	collision_mask = 0
	add_child(pivot)
	add_child(stump)
	intact = GroundArt.tower(sector)
	pivot.add_child(intact)
	# Use the actual exported silhouette, including tips, struts and overhangs.
	if not collision_meshes.has(sector):
		var shape := FleetArt.mesh_for("tower_" + sector, "ground").create_trimesh_shape()
		shape.backface_collision = true
		collision_meshes[sector] = shape
	var collider := CollisionShape3D.new()
	collider.shape = collision_meshes[sector]
	add_child(collider)
	reset()

func animate(_time: float) -> void:
	pass

func reset() -> void:
	clear_impact_marks()
	for section in stump.get_children():
		stump.remove_child(section)
		section.queue_free()
	for section in pivot.get_children():
		if section != intact:
			pivot.remove_child(section)
			section.queue_free()
	armor = 6
	destroyed = false
	collision_layer = 3
	collapse_time = -1.0
	has_fractured = false
	concentrated = 0
	last_wound = Vector3.INF
	bending = 0
	pivot.transform = Transform3D(Basis.IDENTITY, Vector3.UP * JOINTS[0])
	intact.position.y = -pivot.position.y
	intact.show()
	pivot.show()
	show()

func receive_hit_at(damage: int, contact: Vector3, shot_direction: Vector3) -> bool:
	if destroyed or damage <= 0:
		return false
	local_strike = to_local(contact)
	var push := global_basis.inverse() * shot_direction
	# An off-centre shot also twists the upper section away from the torn support.
	var lateral := Vector3(push.x - local_strike.x * 0.25, 0, push.z - local_strike.z * 0.25)
	if lateral.length_squared() < 0.001:
		lateral = Vector3.RIGHT if lane.x >= 0 else Vector3.LEFT
	fall_axis = Vector3.UP.cross(lateral.normalized())
	concentrated = concentrated + 1 if last_wound.distance_squared_to(local_strike) < 0.55 else 1
	last_wound = local_strike
	armor = maxi(0, armor - damage - int(concentrated >= 3))
	bending = 1.0
	if armor > 0:
		return false
	destroyed = true
	collision_layer = 0
	collapse_time = 0
	break_band = 2 if local_strike.y >= JOINTS[2] else 1 if local_strike.y >= JOINTS[1] else 0
	pivot.transform = Transform3D(Basis.IDENTITY, Vector3.UP * JOINTS[break_band])
	intact.hide()
	for i in range(3):
		var section := FleetArt.model("wreck_%s_%d" % [sector, i], "ground")
		if i >= break_band:
			pivot.add_child(section)
			section.position.y = -pivot.position.y
		else:
			stump.add_child(section)
	return true

func receive_hit(damage: int = 1) -> bool:
	return receive_hit_at(damage, aim_point(), -global_basis.z)

func advance(delta: float) -> void:
	if has_fractured:
		return
	if collapse_time < 0:
		if bending > 0:
			bending = maxf(0, bending - delta * 3.5)
			pivot.basis = Basis(fall_axis, sin(bending * TAU) * bending * 0.029)
		return
	collapse_time += delta
	var duration := 1.28 - 0.20 * break_band
	var t := minf(1, collapse_time / duration)
	pivot.basis = Basis(fall_axis, t * t * (1.52 + 0.22 * break_band))
	pivot.position.y = JOINTS[break_band] - t * t * break_band * 2.4
	if t >= 1:
		has_fractured = true
		fractured.emit(self)
		pivot.hide()

func fracture_source() -> Node3D:
	return pivot

func fracture_point() -> Vector3:
	return pivot.to_global(local_strike - Vector3.UP * JOINTS[break_band])

func aim_point() -> Vector3:
	return to_global(Vector3(0, 0, 0))
