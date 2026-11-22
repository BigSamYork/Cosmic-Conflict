class_name OffshorePlatform
extends StaticBody3D

# A streamed rig owns its collider and renderer; cached meshes stay shared.
func configure(mesh: Mesh, pose: Transform3D) -> void:
	transform = pose
	collision_layer = 1
	collision_mask = 0
	var deck := MeshInstance3D.new()
	deck.mesh = mesh
	deck.material_override = FleetArt.hull_material
	deck.set_instance_shader_parameter(&"weathered", true)
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(deck)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.get_meta("ground_cover")
	add_child(collider)
	add_to_group(&"offshore_platforms")
