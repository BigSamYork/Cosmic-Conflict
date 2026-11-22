extends Node3D

signal reactor_burst

const BREACH := 0.35
const FRACTURE := 1.85
const DURATION := 5.65
var age := 0.0
var span := 1.0
var reduced := false
var ship: Node3D
var hull: MeshInstance3D
var pod_camera := Camera3D.new()
var engine_fire: DestructionEffect
var core_fire: DestructionEffect
var shards: BreakupEffect
var panels: Array[Node3D] = []
var velocities: Array[Vector3] = []
var ring: MeshInstance3D
var status := Label.new()
var fade := ColorRect.new()

func begin(pose: Transform3D, ship_id: String, primary: int, low_effects: bool) -> void:
	global_transform = pose.orthonormalized()
	reduced = low_effects
	ship = FrontierArt.player_ship(ship_id, primary)
	add_child(ship)
	hull = ship.get_child(0) as MeshInstance3D
	span = hull.get_aabb().size.length()
	add_child(pod_camera)
	pod_camera.fov = 54
	pod_camera.far = VectorArt.VIEW_DISTANCE
	pod_camera.make_current()
	var overlay := CanvasLayer.new()
	overlay.layer = 4
	add_child(overlay)
	overlay.add_child(status)
	status.position = Vector2(30, 22)
	status.add_theme_constant_override("outline_size", 4)
	status.modulate = Color("#ffcf92")
	status.text = "ESCAPE POD  /  AFT CAMERA\nHULL BREACH"
	overlay.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advance(0)

func _fire(target: Node3D, radius: float) -> DestructionEffect:
	var fire := DestructionEffect.new()
	fire.source = target
	fire.size = radius
	fire.reduced = reduced
	add_child(fire)
	return fire

func _fracture() -> void:
	# The large pieces retain the actual paint, hull outline and fitted guns.
	var arrays := hull.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var groups: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	var bounds := hull.get_aabb()
	for i in range(0, indices.size(), 3):
		var center := (vertices[indices[i]] + vertices[indices[i+1]] + vertices[indices[i+2]]) / 3.0 - bounds.get_center()
		var group := 0 if center.z < 0 else 1
		if absf(center.x) > bounds.size.x * 0.18:
			group = 2 if center.x < 0 else 3
		for corner in range(3):
			groups[group].append(indices[i + corner])
	shards = BreakupEffect.new()
	add_child(shards)
	shards.top_level = true
	shards.global_transform = Transform3D.IDENTITY
	shards.build(ship, true, Color.WHITE, 50 if reduced else 180, DURATION - FRACTURE, span * 0.45)
	for group in groups:
		if group.is_empty():
			continue
		var center := Vector3.ZERO
		for index in group:
			center += vertices[index]
		center /= group.size()
		arrays[Mesh.ARRAY_INDEX] = group
		var panel_mesh := ArrayMesh.new()
		panel_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var panel := Node3D.new()
		ship.add_child(panel)
		panel.position = center
		var skin := MeshInstance3D.new()
		skin.mesh = panel_mesh
		skin.material_override = hull.material_override
		skin.position = -center
		panel.add_child(skin)
		_detach(panel)
	var guns := ship.get_node_or_null("PrimaryGuns")
	if guns:
		for mount: Node3D in guns.get_children():
			_detach(mount)
	core_fire = _fire(ship, span * 0.85)
	ship.hide()
	if not reduced:
		ring = MeshInstance3D.new()
		ring.mesh = PlaneMesh.new()
		var ring_material := ShaderMaterial.new()
		ring_material.shader = preload("res://shaders/reactor_shock.gdshader")
		ring.material_override = ring_material
		add_child(ring)
		ring.position = ship.position
		ring.rotation.z = 0.22
	status.text = "ESCAPE POD  /  AFT CAMERA\nREACTOR LOST"
	reactor_burst.emit()

func _detach(part: Node3D) -> void:
	part.reparent(self, true)
	panels.append(part)
	var outward := (part.position - ship.position).normalized()
	velocities.append((outward * 0.55 + Vector3(0, 0.12, -0.23)) * span)

func advance(delta: float) -> void:
	age += delta
	if not core_fire:
		ship.position = Vector3(0, 0.12, -0.28) * span * minf(age, FRACTURE)
		ship.rotation = Vector3(-0.09, 0.15, -0.27) * minf(age, FRACTURE)
	if age >= BREACH and not engine_fire:
		var engine := Node3D.new()
		ship.add_child(engine)
		var bounds := hull.get_aabb()
		engine.position = bounds.get_center() + bounds.size * Vector3(-0.30, 0.08, 0.32)
		engine_fire = _fire(engine, span * 0.28)
	if engine_fire:
		engine_fire.advance(delta)
	if age >= FRACTURE and not core_fire:
		_fracture()
	if core_fire:
		core_fire.advance(delta)
		shards.advance(delta)
		for i in panels.size():
			panels[i].position += velocities[i] * delta
			panels[i].rotate_object_local(Vector3(0.4, 0.2 + i * 0.16, -0.6).normalized(), delta * (0.5 + i * 0.17))
		var t := age - FRACTURE
		if not reduced:
			ring.scale = Vector3.ONE * span * (0.15 + 2.6 * t)
			ring.set_instance_shader_parameter(&"elapsed", t)
			ring.visible = t < 0.96
		if t > 1.45:
			status.text = "ESCAPE POD  /  AFT CAMERA\nASTRA RECOVERY SIGNAL ACQUIRED"
	var pull := 1.0 - exp(-age * 0.64)
	pod_camera.position = ship.position + span * Vector3(0.45 + pull * 0.85, 0.30 + pull * 0.80, -0.82 - pull * 1.32)
	pod_camera.look_at(ship.global_position, global_basis.y)
	var kick := maxf(0.0, age - FRACTURE)
	if not reduced and age > FRACTURE:
		pod_camera.rotate_object_local(Vector3.FORWARD, 0.024 * sin(kick * 28) * exp(-kick * 5))
	fade.color = Color(0, 0, 0, smoothstep(DURATION - 0.55, DURATION, age))
