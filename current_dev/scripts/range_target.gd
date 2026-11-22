class_name RangeTarget
extends StaticBody3D

var travel: float = 0.0
var lane: Vector2 = Vector2.ZERO
var armor: int = 2
var health_scale: float = 1.0
var destroyed: bool = false
var phase: float = 0.0
var guided_lockable: bool = true
var ground_pilot: Camera3D
const SCAR_SHADER := preload("res://shaders/impact_scar.gdshader")
var scar_slot := 0
var scar_surfaces: Array[MeshInstance3D] = []
var armor_before_damage := 0

func mark_impact(at: Vector3, shot_axis: Vector3, organic: bool, previous_armor: int) -> void:
	if armor_before_damage == 0:
		armor_before_damage = previous_armor
		for surface: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			if surface.mesh == null or not surface.mesh.has_meta("fragment_vertices") or not surface.is_visible_in_tree():
				continue
			if surface.material_override is BaseMaterial3D and surface.material_override.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var material := ShaderMaterial.new()
			material.shader = SCAR_SHADER
			material.set_shader_parameter("organic", organic)
			var strikes := PackedVector4Array()
			var axes := PackedVector3Array()
			strikes.resize(3)
			axes.resize(3)
			material.set_shader_parameter("strikes", strikes)
			material.set_shader_parameter("axes", axes)
			surface.material_overlay = material
			scar_surfaces.append(surface)
	var wear := 1.0 - float(maxi(0, armor)) / armor_before_damage
	for surface in scar_surfaces:
		var material := surface.material_overlay as ShaderMaterial
		var strikes: PackedVector4Array = material.get_shader_parameter("strikes")
		var axes: PackedVector3Array = material.get_shader_parameter("axes")
		var dimensions := surface.global_basis.get_scale().abs()
		var center := surface.to_local(at) * dimensions
		strikes[scar_slot] = Vector4(center.x, center.y, center.z, 1.0 + wear * 1.65)
		axes[scar_slot] = ((surface.global_basis.inverse() * shot_axis) * dimensions).normalized()
		material.set_shader_parameter("strikes", strikes)
		material.set_shader_parameter("axes", axes)
	scar_slot = (scar_slot + 1) % 3

func clear_impact_marks() -> void:
	for surface in scar_surfaces:
		surface.material_overlay = null
	scar_surfaces.clear()
	scar_slot = 0
	armor_before_damage = 0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var hull := create_model()
	add_child(hull)
	FleetArt.add_pilot_hull(hull)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.4, 2.1, 5.5)
	collider.shape = shape
	add_child(collider)
	animate(0.0)

func animate(time: float) -> void:
	if destroyed:
		return
	_animate_rail(time)
	if ground_pilot != null:
		var direction := global_position.direction_to(ground_pilot.global_position)
		var up := global_basis.y
		if not direction.is_zero_approx():
			if absf(up.dot(direction)) > 0.999:
				up = direction.cross(global_basis.x).normalized()
			global_basis = Basis.looking_at(direction, up)

func _animate_rail(time: float) -> void:
	transform = FlightState.rail_frame(travel)
	position += basis * Vector3(lane.x + sin(time * 0.9 + phase) * 1.3, lane.y + sin(time * 1.2 + phase) * 0.45, 0)
	rotate_object_local(Vector3.FORWARD, sin(time + phase) * 0.18)

func receive_hit(damage: int = 1) -> bool:
	if destroyed:
		return false
	armor -= damage
	if armor <= 0:
		destroyed = true
		hide()
		collision_layer = 0
	return destroyed

func reset() -> void:
	clear_impact_marks()
	destroyed = false
	armor = 2
	collision_layer = 2
	show()
	animate(0.0)

func create_model() -> Node3D:
	return VectorArt.ship()

func aim_point() -> Vector3:
	return global_position
