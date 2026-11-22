class_name EnemyFighter
extends RangeTarget

signal missile_requested(origin: Vector3, direction: Vector3)
signal web_requested
var web_layer: bool = false
var heavy: bool = false
var cooldown: float = 2.0
var dogfight: bool = false
var expired: bool = false
var age: float = 0.0
var spawn_frame: Transform3D
var approach_axis := Vector3.BACK
var spawn_position: Vector3
var velocity: Vector3
var lifetime: float = 23.0
var new_design: bool = false
var winged: bool = false
var delta_wing: bool = false
var sector: String = "ignis"
var cloak: StealthSignature
var insect_legs: Array[Node3D] = []
const SHIELD_CYCLE: float = 6.0
const SHIELD_OPEN_START: float = 3.4
const SHIELD_OPEN_END: float = 5.2
const STUN_DURATION: float = FlightState.EMP_STUN_DURATION
var motion_age: float = 0.0
var stun_remaining: float = 0.0
var shield_flash: float = 0.0
var shield_visual: Node3D
static var shield_material: StandardMaterial3D

func _ready() -> void:
	super._ready()
	if sector != "ignis" or winged or delta_wing or new_design or (dogfight and heavy):
		for child in get_children():
			if child is CollisionShape3D:
				child.shape.size = Vector3(8.5, 5.0, 16.0) if dogfight and heavy else Vector3(8.5, 2.4, 7.0) if sector != "ignis" and not web_layer else Vector3(12.4, 4.0, 10.0) if winged else Vector3(9.2, 2, 11) if delta_wing else Vector3(8.3, 3.0, 7.0)
				if sector == "vespera" and not heavy and not web_layer:
					child.shape.size.z = 8.4
					child.position.z = -0.5
				elif sector == "xylo":
					child.shape.size = Vector3(10, 5, 16) if dogfight and heavy else Vector3(8.5, 3.2, 8)
				elif sector == "thalassa":
					child.shape.size = Vector3(14, 4, 10)
				elif sector == "kharon":
					child.shape.size = Vector3(9.5, 4, 9)
	if sector == "xylo" and not heavy:
		for side in [-1.0, 1.0]:
			for i in range(3):
				var leg: Node3D = XyloArt.insect_leg()
				leg.position = Vector3(side, 0, -0.7 + i * 0.8)
				leg.scale.x = side
				get_child(0).add_child(leg)
				insect_legs.append(leg)
	if sector == "vespera" and not heavy and not web_layer:
		cloak = StealthSignature.new()
		cloak.phase = phase
		cloak.attach(get_child(0))
	if heavy and sector != "xylo":
		var plating := FleetArt.model("heavy_armor")
		add_child(plating)
	if has_directional_shield():
		shield_visual = _create_shield()
		add_child(shield_visual)
	reset()

func reset() -> void:
	super.reset()
	armor = ceili((10 if has_directional_shield() else 4 if web_layer else 5 if heavy else 2) * health_scale)
	cooldown = 1.0 + fmod(phase, 2.0)
	expired = false
	age = 0.0
	motion_age = 0.0
	stun_remaining = 0.0
	shield_flash = 0.0
	if cloak != null:
		cloak.age = 0
		cloak.revealed_remaining = 0
		cloak.refresh()
	guided_lockable = cloak == null or not cloak.active()
	_update_shield()

func animate(time: float) -> void:
	for i in range(insect_legs.size()):
		insect_legs[i].rotation.z = sin(time * 4 + phase + i) * 0.18
	if dogfight:
		return
	super.animate(time)

func _animate_rail(time: float) -> void:
	super._animate_rail(time)
	# The firing window follows the course even after the bow tracks a passing pilot.
	approach_axis = global_basis.z
	if not heavy:
		position.x += sin(time * 1.7 + phase) * 2.0
		if sector == "thalassa":
			position.y += sin(time * 0.6 + phase) * 2.0
			rotate_object_local(Vector3.FORWARD, sin(time * 0.6 + phase) * 0.16)
		elif sector == "kharon":
			position.x += sin(time * 0.8 + phase) * 1.2

func advance(delta: float, pilot: Vector3, velocity: Vector3) -> void:
	if destroyed or expired:
		return
	if cloak != null:
		cloak.advance(delta)
		guided_lockable = not cloak.active()
	var moving_delta: float = maxf(0.0, delta - stun_remaining)
	stun_remaining = maxf(0.0, stun_remaining - delta)
	shield_flash = maxf(0.0, shield_flash - delta)
	if dogfight:
		age += delta
		motion_age += moving_delta
		if age >= lifetime:
			expired = true
			collision_layer = 0
			hide()
			return
		global_position = spawn_position + self.velocity * motion_age + spawn_frame.basis * Vector3(sin(motion_age * 0.9 + phase) * 5, sin(motion_age * 0.7 + phase) * 3, 0)
		if sector == "thalassa":
			global_position += spawn_frame.basis.y * sin(motion_age * 0.45 + phase) * 5
		elif sector == "kharon":
			global_position += spawn_frame.basis.x * sin(motion_age * 0.65 + phase) * 3
		global_basis = Basis.looking_at(self.velocity.normalized(), Vector3.UP)
		var bank: float = sin(motion_age * 0.8 + phase) * 0.28
		if has_directional_shield():
			var cycle: float = fposmod(age + phase, SHIELD_CYCLE)
			var opening: float = clampf((cycle - SHIELD_OPEN_START) / (SHIELD_OPEN_END - SHIELD_OPEN_START), 0.0, 1.0)
			bank += sin(opening * PI) * 0.7
		rotate_object_local(Vector3.FORWARD, bank)
	_update_shield()
	if stun_remaining > 0.0:
		return
	if (not dogfight and (pilot - global_position).dot(approach_axis) < 35.0) or global_position.distance_to(pilot) > (180.0 if dogfight else 330.0):
		return
	if dogfight and not web_layer and velocity.length_squared() > 0.1 and velocity.normalized().dot((global_position - pilot).normalized()) < -0.15:
		return
	cooldown -= moving_delta
	if cooldown <= 0.0:
		if web_layer:
			web_requested.emit()
			cooldown += 7.0
		else:
			var origin: Vector3 = global_position + (pilot - global_position).normalized() * 5
			missile_requested.emit(origin, EnemyMissile.aim_direction(origin, pilot, velocity))
			if cloak != null:
				cloak.reveal(1.4)
				guided_lockable = true
			cooldown += (5.0 if heavy else 6.5) if dogfight else (3.2 if heavy else 4.5)

func has_directional_shield() -> bool:
	return dogfight and heavy

func shield_active() -> bool:
	if not has_directional_shield() or destroyed or expired or stun_remaining > 0.0:
		return false
	var cycle: float = fposmod(age + phase, SHIELD_CYCLE)
	return cycle < SHIELD_OPEN_START or cycle >= SHIELD_OPEN_END

func shield_blocks(shooter: Vector3) -> bool:
	if not shield_active():
		return false
	var toward_shooter: Vector3 = (shooter - global_position).normalized()
	return (-global_basis.z).dot(toward_shooter) >= 0.42

func flash_shield() -> void:
	shield_flash = 0.2
	_update_shield()

func stun() -> void:
	stun_remaining = STUN_DURATION
	if cloak != null:
		cloak.reveal()
		guided_lockable = true
	_update_shield()

func receive_hit(damage: int = 1) -> bool:
	var killed: bool = super.receive_hit(damage)
	if killed and cloak != null:
		cloak.restore()
	return killed

func _update_shield() -> void:
	if shield_visual == null:
		return
	shield_visual.visible = shield_active()
	shield_visual.scale = Vector3.ONE * (1.0 + shield_flash * 0.5)

static func _create_shield() -> Node3D:
	var cached: Node3D = VectorArt.cached_model("gunship_directional_shield")
	if cached != null:
		return cached
	var root := Node3D.new()
	var vertices := PackedVector3Array([Vector3(0, 0, -9.2)])
	var triangles := PackedInt32Array()
	var rim := PackedVector3Array()
	const SEGMENTS: int = 24
	for i in range(SEGMENTS):
		var angle: float = i * TAU / SEGMENTS
		vertices.append(Vector3(cos(angle) * 5.0, sin(angle) * 3.1, -8.5))
	for i in range(SEGMENTS):
		var a: int = i + 1
		var b: int = (i + 1) % SEGMENTS + 1
		triangles.append_array(PackedInt32Array([0, a, b]))
		rim.append_array(PackedVector3Array([vertices[a], vertices[b]]))
		if i % 4 == 0:
			rim.append_array(PackedVector3Array([vertices[0], vertices[a]]))
	var face: MeshInstance3D = VectorArt.solid(vertices, triangles, Color.WHITE)
	if shield_material == null:
		shield_material = StandardMaterial3D.new()
		shield_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shield_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		shield_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shield_material.albedo_color = Color(0.15, 0.6, 1.0, 0.12)
	face.material_override = shield_material
	root.add_child(face)
	root.add_child(VectorArt.lines(rim, Color("#52bcff")))
	return VectorArt.remember_model("gunship_directional_shield", root)

func create_model() -> Node3D:
	if FrontierArt.is_frontier(sector):
		return FrontierArt.fighter(sector, heavy)
	if sector == "xylo":
		var model: Node3D = XyloArt.hive_mother() if dogfight and heavy else XyloArt.insect()
		if dogfight and heavy:
			model.scale = Vector3.ONE * 2.5
		return model
	if web_layer:
		return EncounterArt.web_drone()
	if dogfight and heavy:
		return EncounterArt.escort_gunship()
	if sector == "cryo":
		return CryoArt.fighter()
	if sector == "vespera":
		return VesperaArt.fighter()
	if delta_wing:
		return EncounterArt.delta_fighter()
	if winged:
		return EncounterArt.strike_fighter()
	return EncounterArt.light_fighter() if new_design else super.create_model()
