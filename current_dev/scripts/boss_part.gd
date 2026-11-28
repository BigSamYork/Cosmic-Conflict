class_name BossPart
extends RangeTarget

signal disabled_in_combat(part: BossPart)

var core: bool = false
var armored_interlock := false
var unlocked: bool = true:
	set(value):
		if unlocked == value:
			return
		unlocked = value
		if cardiac_hull != null:
			cardiac_hull.set_instance_shader_parameter(&"cardiac_sealed", not value)
		if shield_cover != null:
			shield_cover.visible = not value
		if cardiac_lid != null:
			cardiac_lid.disabled = value
			target_face.visible = value
var maximum_armor: int = 14
var nacelle_radius: float = 0.0
var nacelle_length: float = 0.0
var face_offset: Vector3 = Vector3.ZERO
var biological: bool = false
var last_blood_contact := Vector3.INF
var last_blood_normal := Vector3.BACK
var sector := "ignis"
var orbital := false
var target_face: Node3D
var shield_cover: Node3D
var cardiac_lid: CollisionShape3D
var cardiac_hull: MeshInstance3D
var face_id: String
var face_mesh: MeshInstance3D
var cardiac_phase := 0.0
var last_beat_time := 0.0
static var cardiac_material := ShaderMaterial.new()

static func _static_init() -> void:
	cardiac_material.shader = preload("res://shaders/cardiac_tissue.gdshader")

func _face_model() -> String:
	if biological:
		return "boss_heart" if core else "boss_spore"
	match sector:
		"cryo":
			return "boss_cold_vent" if core else "boss_coolant"
		"vespera":
			return "boss_phase_prism" if core else "boss_capacitor"
		"thalassa":
			if core:
				return "boss_tide_turbine" if orbital else "boss_bridge"
			return "boss_ballast"
		"kharon":
			return "boss_solar_receiver" if core else "boss_capacitor" if orbital else "boss_bus_relay"
		"ignis":
			if orbital:
				return "boss_furnace" if core else "boss_heat_exchanger"
	return "boss_core" if core else "boss_generator"

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var dimensions := Vector3(8, 5, 3) if core else Vector3(5, 5, 3)
	var radius := nacelle_radius if nacelle_radius > 0 else 2.3
	face_id = _face_model()
	if nacelle_radius > 0 and face_id != "boss_heart":
		var housing := FleetArt.model("boss_organ_body" if biological else "boss_reactor_body")
		var mount_width := radius if biological or face_id in ["boss_core", "boss_generator"] else radius * 0.80
		housing.scale = Vector3(mount_width, mount_width, nacelle_length)
		add_child(housing)
		face_offset.z = nacelle_length * 0.5 + radius * 0.7
	target_face = FleetArt.model(face_id)
	target_face.position = face_offset
	target_face.scale = Vector3.ONE * radius
	add_child(target_face)
	face_mesh = target_face.get_child(0) as MeshInstance3D
	if face_id == "boss_heart":
		face_mesh.material_override = cardiac_material
		shield_cover = FleetArt.model("leviathan_sealed") if orbital else FleetArt.model("bio_titan_sealed", "ground")
	elif (core or armored_interlock) and face_id != "boss_bridge":
		shield_cover = FleetArt.model("boss_iris")
	if shield_cover != null:
		shield_cover.position = face_offset
		if not biological and face_id not in ["boss_core", "boss_generator"]:
			shield_cover.position.z += radius * 0.48
		shield_cover.scale = Vector3.ONE * radius
		shield_cover.visible = not unlocked
		add_child(shield_cover)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	if face_id == "boss_heart":
		# Hull-mounted ribs and wound walls protect the covered myocardium. Rays
		# through the opening must meet the actual organ, including from the side.
		collider.shape = face_mesh.mesh.create_trimesh_shape()
		collider.scale = Vector3.ONE * radius
		var lid_mesh := shield_cover.get_child(0) as MeshInstance3D
		# Continue the same hull-space weathering over the removable patch.
		lid_mesh.set_instance_shader_parameter(&"hull_detail_transform", Vector4(position.x, position.y, position.z, radius))
		cardiac_lid = CollisionShape3D.new()
		cardiac_lid.shape = lid_mesh.mesh.create_trimesh_shape()
		cardiac_lid.transform = shield_cover.transform
		cardiac_lid.disabled = unlocked
		add_child(cardiac_lid)
		target_face.visible = unlocked
	elif nacelle_radius > 0:
		# Include projecting plumbing and face plates at the pilot-facing end.
		var front := face_offset.z + radius * (0.50 if biological else 0.65)
		var rear := -0.52 * nacelle_length
		shape.size = Vector3(radius * 2.3, radius * 2.3, front - rear)
		collider.position.z = (front + rear) * 0.5
	else:
		shape.size = dimensions
	if collider.shape == null:
		collider.shape = shape
	add_child(collider)
	armor = maximum_armor

func animate(_time: float) -> void:
	pass

func animate_reactor(time: float) -> void:
	if destroyed:
		return
	var radius := nacelle_radius if nacelle_radius > 0 else 2.3
	if face_id == "boss_heart":
		var injury := 1.0 - clampf(float(armor) / maximum_armor, 0.0, 1.0)
		var frequency := lerpf(1.25, 2.45, injury)
		cardiac_phase = fposmod(cardiac_phase + maxf(0, time - last_beat_time) * frequency, 1.0)
		last_beat_time = time
		var squeeze := exp(-pow((cardiac_phase - 0.24) / 0.105, 2))
		if face_mesh.get_blend_shape_count() > 0:
			face_mesh.set_blend_shape_value(0, squeeze)
		else:
			target_face.scale = Vector3(1.0 - 0.06 * squeeze, 1.0 - 0.08 * squeeze, 1.0 + 0.08 * squeeze) * radius
			target_face.position.y = face_offset.y + 0.08 * squeeze * radius
	elif face_id == "boss_cold_vent" and face_mesh.get_blend_shape_count() > 0:
		face_mesh.set_blend_shape_value(0, 0.72 + 0.28 * sin(time * 3.1) if unlocked else 0.0)
	elif face_id == "boss_phase_prism" and face_mesh.get_blend_shape_count() > 0:
		face_mesh.set_blend_shape_value(0, 0.5 + 0.5 * sin(time * 1.8))
	elif biological:
		var beat := 1.0 + 0.055 * pow(0.5 + 0.5 * sin(time * 3.4 + position.x), 4.0)
		target_face.scale = Vector3(beat, beat, 1.0 / beat) * radius
	elif face_id in ["boss_core", "boss_generator", "boss_tide_turbine"]:
		target_face.rotation.z = fposmod(time * (0.50 if core else -0.85), TAU)

func aim_point() -> Vector3:
	return to_global(face_offset)

func receive_hit(damage: int = 1) -> bool:
	if not unlocked:
		return false
	var killed := super.receive_hit(damage)
	if killed:
		disabled_in_combat.emit(self)
	return killed
