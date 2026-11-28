class_name BossEncounter
extends Node3D

signal missile_requested(origin: Vector3, direction: Vector3)
signal sweep_requested(emitter: ThermalEmitter)
signal special_hit(attack_name: String, damage: float)
const BossAttack := preload("res://scripts/boss_attack.gd")
var rage_stage := 0
var aggression := 0.0
var last_armor := -1
var special: BossAttack
var special_cooldown := 1.2
var volleys := 0
var stage_volleys := 0
var orbital: bool = false
var sector: String = "ignis"
var health_scale: float = 1.0
var parts: Array[BossPart] = []
var turrets: Array[BossTurret] = []
var core: BossPart
var age: float = 0.0
var visual_age: float = 0.0
var drive_phase := 0.0
var attack_brace := 0.0
var firing_side := 0.0
var anchor: Vector3
var model: Node3D
var body: StaticBody3D
var pursuing: bool = false
var canyon_start: float = 0.0
var course: Transform3D
var pursuit_range: float = 450.0
var death_time: float = -1.0
var thermal_emitter: ThermalEmitter
var sweep_cooldown: float = 4.0
var radars: Array[BossRadar] = []
var stun_remaining: float = 0.0
var ground_course: Transform3D = Transform3D.IDENTITY
var drill: Node3D
var drone_bay: DroneBay
var cloak: StealthSignature
var core_rings: Array[Node3D] = []
var bio_legs: Array[Node3D] = []
var tempest_legs: Array[Node3D] = []
var collectors: Array[Node3D] = []
var interlock_opened := false
var wreck_direction := 1.0
var mounted_at_failure: Array[Transform3D] = []
var vent_time := 0.0
var vent_started := false
var breaches: Dictionary[BossPart, MultiMeshInstance3D] = {}
static var breach_mesh: MultiMesh
static var breach_material := ShaderMaterial.new()

# A paired subsystem mount (mirrored in X) and the central or cardiac mount.
# Coordinates are local to each hull, with +Z facing the pursuing pilot.
const GROUND_MOUNTS := {
	"ignis": [Vector3(11, 0, 13), Vector3(0, 5, 9)],
	"cryo": [Vector3(14, -2, 14), Vector3(0, 0, 14)],
	"vespera": [Vector3(11, 1, 12), Vector3(0, 15, 6)],
	"xylo": [Vector3(10, 2, 9), Vector3(2.8, 14, 1.6)],
	"thalassa": [Vector3(12, -2, 13), Vector3(0, 9, 5)],
	"kharon": [Vector3(11, 3, 12), Vector3(0, 8, 2)],
}
const ORBITAL_MOUNTS := {
	"ignis": [Vector3(12, 0, 40), Vector3(0, -3, 34)],
	"cryo": [Vector3(21, 2, 36), Vector3(0, -2, 35)],
	"vespera": [Vector3(12, 2, 35), Vector3(0, 8, 15)],
	"xylo": [Vector3(12, 4, 26), Vector3(4, -4, 23.3)],
	"thalassa": [Vector3(22, -2, 29), Vector3(0, 0, 35)],
	"kharon": [Vector3(12, 0, 40), Vector3(0, 15, -12)],
}

func _ready() -> void:
	anchor = position
	if FrontierArt.is_frontier(sector):
		model = FrontierArt.boss(sector, orbital)
	elif sector == "xylo":
		model = XyloArt.leviathan() if orbital else XyloArt.goliath()
	elif sector == "vespera":
		model = VesperaArt.nyx() if orbital else VesperaArt.overlord()
	elif sector == "cryo":
		model = CryoArt.hydra() if orbital else CryoArt.bore_mech()
	else:
		model = EncounterArt.battleship() if orbital else EncounterArt.siege_runner()
	add_child(model)
	if sector == "xylo" and not orbital:
		for side in [-1.0, 1.0]:
			var leg: Node3D = XyloArt.goliath_leg()
			leg.position = Vector3(side * 7.5, -2, -3)
			leg.scale.x = side
			model.add_child(leg)
			bio_legs.append(leg)
	elif sector == "thalassa" and not orbital:
		for side in [-1.0, 1.0]:
			for fore in [-1.0, 1.0]:
				var leg := FleetArt.model("tempest_leg", "ground")
				leg.position = Vector3(side * 12.1, -0.75, -11.4 if fore > 0 else 10.5)
				leg.scale = Vector3(side, 1, fore)
				model.add_child(leg)
				tempest_legs.append(leg)
	if sector == "vespera" and not orbital:
		for i in range(3):
			var ring: Node3D = VesperaArt.core_ring()
			ring.position = Vector3(0, 6 + i * 7, -4)
			model.add_child(ring)
			core_rings.append(ring)
	if sector == "cryo" and not orbital:
		drill = CryoArt.drill()
		drill.position = Vector3(0, 8, 14)
		model.add_child(drill)
	if sector == "kharon" and not orbital:
		for side in [-1.0, 1.0]:
			var lens := FleetArt.model("solar_collector", "ground")
			lens.position = Vector3(side * 11.3, 10, -11)
			model.add_child(lens)
			collectors.append(lens)
	FleetArt.add_pilot_hull(model)
	body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	# Fire can pass between the sponsons and reach recessed chest/deck targets.
	var hull: MeshInstance3D = model.get_child(0)
	collider.shape = hull.mesh.get_meta("pilot_hull")
	collider.transform = hull.transform
	body.add_child(collider)
	add_child(body)
	var mounts: Array = ORBITAL_MOUNTS[sector] if orbital else GROUND_MOUNTS[sector]
	for side in [-1.0, 1.0]:
		var generator := BossPart.new()
		generator.sector = sector
		generator.orbital = orbital
		generator.biological = sector == "xylo"
		generator.armored_interlock = sector == "kharon" and not orbital and side > 0
		generator.unlocked = not generator.armored_interlock
		generator.position = mounts[0] * Vector3(side, 1, 1)
		generator.maximum_armor = ceili((24 if orbital else 18) * health_scale)
		generator.nacelle_radius = 4.3 if orbital else 4.6
		generator.nacelle_length = 9.0 if orbital else 7.0
		add_child(generator)
		parts.append(generator)
	core = BossPart.new()
	core.sector = sector
	core.orbital = orbital
	core.biological = sector == "xylo"
	if core.biological:
		core.cardiac_hull = hull
	core.core = true
	core.unlocked = false
	core.maximum_armor = ceili((64 if orbital else 48) * health_scale)
	core.position = mounts[1]
	core.nacelle_radius = 4.3 if orbital else 4.6
	core.nacelle_length = 8.0
	add_child(core)
	parts.append(core)
	for side in [-1.0, 1.0]:
		for row in range(3 if orbital else 2):
			var turret := BossTurret.new()
			turret.biological = sector == "xylo"
			turret.position = Vector3(side * (22 + row * 16), 9 + row * 4, 27 - row * 22) if orbital else Vector3(side * (19 if row == 0 else 30), 10 if row == 0 else 8, 14 if row == 0 else -4)
			turret.maximum_armor = ceili((14 if orbital else 10) * health_scale)
			if sector == "cryo":
				turret.interval = 6.0 if orbital else 3.5
			elif orbital:
				turret.interval = 4.8
			turret.cooldown = 1.0 + turrets.size() * 0.7
			add_child(turret)
			turret.missile_requested.connect(func(at: Vector3, direction: Vector3) -> void: missile_requested.emit(at, direction))
			turrets.append(turret)
			parts.append(turret)
	if orbital and sector == "cryo":
		drone_bay = DroneBay.new()
		drone_bay.position = Vector3(0, 10, 43)
		drone_bay.maximum_armor = ceili(20 * health_scale)
		add_child(drone_bay)
		parts.append(drone_bay)
	elif orbital and sector == "ignis":
		thermal_emitter = ThermalEmitter.new()
		thermal_emitter.position = Vector3(0, 10, 43)
		thermal_emitter.maximum_armor = ceili(20 * health_scale)
		add_child(thermal_emitter)
		parts.append(thermal_emitter)
	if sector == "vespera" and orbital:
		cloak = StealthSignature.new()
		cloak.attach(model)
	for side in [-1.0, 1.0]:
		var radar := BossRadar.new()
		radar.biological = sector == "xylo"
		radar.position = radar_mount(side)
		var scan_height: float = radar.position.y + 9
		for part in parts:
			if not part is BossRadar:
				scan_height = maxf(scan_height, part.position.y + 15)
		radar.mast_height = maxf(7, scan_height - radar.position.y)
		radar.maximum_armor = ceili(6 * health_scale)
		radar.spin_rate = 0.9 if side < 0 else -0.75
		radar.phase = 0 if side < 0 else PI
		add_child(radar)
		radars.append(radar)
		parts.append(radar)
	for part in parts:
		part.disabled_in_combat.connect(_subsystem_disabled)
		FleetArt.add_pilot_hull(part)

func radar_mount(side: float) -> Vector3:
	var x: float = side * (5 if sector == "xylo" and not orbital else 8)
	var mount := _hull_surface(Vector3(x, 140, 0), Vector3(x, -80, 0))
	assert(mount.is_finite(), "Boss radar must be attached to a real hull surface: " + sector)
	return mount

# Both endpoints and the result are in hull-local coordinates, including while
# the wreck is rolling. Cast against the visible armor, not the combat hitbox.
func _hull_surface(start: Vector3, end: Vector3) -> Vector3:
	var closest := Vector3.INF
	for node in model.get_children():
		if not node is MeshInstance3D or not node.mesh.has_meta("fragment_vertices"):
			continue
		var local: Transform3D = node.transform.affine_inverse()
		var triangles: TriangleMesh = node.mesh.generate_triangle_mesh()
		var hit := triangles.intersect_segment(local * start, local * end)
		if not hit.is_empty():
			var point: Vector3 = node.transform * hit.position
			if start.distance_squared_to(point) < start.distance_squared_to(closest):
				closest = point
	return closest

func radar_interval_multiplier() -> float:
	return 1.0 + _lost(radars) * 0.25

func radar_guidance() -> float:
	match _lost(radars):
		0: return 1.0
		1: return 0.35
	return 0.0

func broken_feeds() -> int:
	return int(parts[0].destroyed) + int(parts[1].destroyed)

func _subsystem_disabled(part: BossPart) -> void:
	if defeated():
		_cancel_special()
		return
	_update_rage()
	if part is BossRadar:
		if special != null and special.needs_emitter():
			_cancel_special()
		special_cooldown = maxf(special_cooldown, 2.0)
		sweep_cooldown = maxf(sweep_cooldown, 3.0)
		for i in range(turrets.size()):
			var turret := turrets[i]
			turret.cooldown = maxf(turret.cooldown, 2.0 + i * 0.18)
			turret.beacon.hide()
		if cloak != null:
			cloak.reveal()
			_update_guidance()
	if part == parts[0] or part == parts[1]:
		for turret in turrets:
			if signf(turret.position.x) == signf(part.position.x):
				turret.feed_lost = true
				turret.cooldown = maxf(turret.cooldown, 2.8)
				turret.beacon.hide()
		if special != null:
			special.update_power(broken_feeds())
	if special != null and special.emitter == part and special.needs_emitter():
		_cancel_special()
		special_cooldown = 1.2

func advance_visuals(delta: float) -> void:
	visual_age += delta
	for reactor in [parts[0], parts[1], core]:
		reactor.animate_reactor(visual_age)
	for part in parts:
		_update_breach(part)
	_animate_drive(delta)
	if cloak != null and death_time < 0:
		if radars[0].destroyed and radars[1].destroyed:
			cloak.reveal(delta + 0.1)
		cloak.advance(delta)
		_update_guidance()
	for radar in radars:
		radar.advance_scanner(drive_phase)

func _update_breach(part: BossPart) -> void:
	var live_heart := part.biological and part.core and not part.destroyed
	if live_heart:
		if not part.unlocked:
			if breaches.has(part):
				breaches[part].hide()
			return
	elif part.armor * 3 >= part.maximum_armor * (2 if part.biological else 1):
		return
	if not breaches.has(part):
		_open_breach(part)
	var plume := breaches[part]
	var jet_axis := part.last_blood_normal
	if live_heart:
		plume.show()
		plume.set_instance_shader_parameter(&"heart_phase", part.cardiac_phase)
		if not part.last_blood_contact.is_finite():
			# The torn pericardium exposes this point on the anterior ventricle.
			plume.global_position = part.target_face.to_global(Vector3(-0.05, -0.04, 0.49))
			jet_axis = Vector3(-0.28, -0.36, 0.89).normalized()
	if part.biological:
		plume.set_instance_shader_parameter(&"pressure", clampf(1.0 - float(part.armor) / part.maximum_armor, 0, 1))
		plume.set_instance_shader_parameter(&"jet_axis", jet_axis)
		if not part.destroyed and part.last_blood_contact.is_finite():
			plume.position = part.last_blood_contact
	if part.destroyed and plume.get_parent() == part:
		var mount := _exposed_mount(part)
		plume.reparent(model, false)
		plume.visible = mount.is_finite()
		if plume.visible:
			plume.position = mount
		plume.set_instance_shader_parameter(&"heart_phase", -1.0)
	plume.set_instance_shader_parameter(&"breach_time", visual_age + part.get_index() * 0.37)

func _animate_drive(delta: float) -> void:
	var charge := 0.0
	if special != null:
		if special.age < special.windup:
			charge = smoothstep(0, special.windup, special.age)
		else:
			charge = -0.65 * (1.0 - smoothstep(0, 0.36, special.age - special.windup))
		firing_side = signf(special.emitter.position.x)
	attack_brace = move_toward(attack_brace, charge, delta * 9)
	var drive_speed := (1.0 + aggression * 0.38) if death_time < 0 and stun_remaining <= 0 else 0.22
	drive_phase += delta * drive_speed
	for i in range(core_rings.size()):
		core_rings[i].rotation.y = drive_phase * (0.32 if i % 2 == 0 else -0.23)
		core_rings[i].rotation.z = attack_brace * (i - 1) * 0.16
	for i in range(collectors.size()):
		collectors[i].rotation.y = drive_phase * (0.8 if i == 0 else -0.8)
		collectors[i].rotation.z = sin(drive_phase * 0.42) * 0.16 + attack_brace * (0.30 if i == 0 else -0.30)
	for i in range(bio_legs.size()):
		var side := -1.0 if i == 0 else 1.0
		var stride := sin(drive_phase * 2.4 + i * PI) * (0.18 + aggression * 0.035)
		var spread := side * (0.20 * attack_brace + 0.035 * aggression)
		bio_legs[i].basis = Basis.from_euler(Vector3(stride, 0, spread)).scaled_local(Vector3(side, 1, 1))
	for i in range(tempest_legs.size()):
		var stride := sin(drive_phase * 1.7) * (1.0 if i == 0 or i == 3 else -1.0)
		var mirror := Vector3(-1 if i < 2 else 1, 1, -1 if i % 2 == 0 else 1)
		var spread := mirror.x * (attack_brace * 0.11 + float(parts[int(i >= 2)].destroyed) * 0.12)
		tempest_legs[i].basis = Basis.from_euler(Vector3(stride * 0.09, 0, spread)).scaled_local(mirror)
	if drill != null:
		drill.rotation.z = fposmod(drive_phase * 2.8, TAU)
		drill.position.z = 14.0 - attack_brace * 2.8

func _exposed_mount(part: BossPart) -> Vector3:
	if part is BossRadar:
		return model.to_local(part.global_position) # Foot of the removed mast.
	var outward := Vector3.BACK # Reactor nacelles mount on the aft-facing armor.
	if part is BossTurret:
		outward = Vector3.UP
	elif part is DroneBay or part is ThermalEmitter:
		outward = (Vector3.UP + Vector3.BACK).normalized()
	var face := model.to_local(part.aim_point())
	return _hull_surface(face + outward * 12, face - outward * 140)

func _open_breach(part: BossPart) -> void:
	if breach_mesh == null:
		breach_material.shader = preload("res://shaders/boss_breach.gdshader")
		breach_mesh = MultiMesh.new()
		breach_mesh.transform_format = MultiMesh.TRANSFORM_3D
		breach_mesh.use_custom_data = true
		breach_mesh.mesh = QuadMesh.new()
		breach_mesh.instance_count = 9
		breach_mesh.custom_aabb = AABB(Vector3(-9, -15, -9), Vector3(18, 26, 18))
		for i in range(9):
			breach_mesh.set_instance_transform(i, Transform3D.IDENTITY)
			breach_mesh.set_instance_custom_data(i, Color(i / 9.0, 0, 0, 1))
	var plume := MultiMeshInstance3D.new()
	plume.multimesh = breach_mesh
	plume.material_override = breach_material
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.set_instance_shader_parameter(&"organic", part.biological)
	plume.set_instance_shader_parameter(&"orbital", orbital)
	part.add_child(plume)
	plume.global_position = part.aim_point()
	breaches[part] = plume

func advance(delta: float, pilot: Vector3, velocity: Vector3, pilot_radius: float = 0.6) -> void:
	var weapon_time: float = maxf(0.0, delta - stun_remaining)
	stun_remaining = maxf(0.0, stun_remaining - delta)
	age += delta
	if death_time < 0:
		_update_rage()
	aggression = move_toward(aggression, float(rage_stage), delta * 1.2)
	advance_visuals(delta)
	if pursuing:
		_update_pursuit()
	elif orbital:
		position = anchor + Vector3(sin(age * 0.3) * 4.0, sin(age * 0.5) * 1.5, 0)
	if death_time >= 0.0:
		death_time += delta
		var fall := clampf(death_time / 1.5, 0, 1)
		model.rotation.z = wreck_direction * fall * fall * (0.55 if orbital else 0.30)
		model.position.y = -fall * fall * (9.0 if sector == "thalassa" and not orbital else 4.5)
		for i in range(parts.size()):
			parts[i].transform = model.transform * mounted_at_failure[i]
		if death_time >= 1.5:
			model.hide()
			for part in parts:
				part.hide()
		return
	if defeated():
		_cancel_special()
		return
	var in_range: bool = not pursuing or pursuit_range < (260.0 if orbital else 230.0)
	for part in parts:
		if part != core:
			part.unlocked = in_range
	if sector == "kharon" and not orbital:
		parts[1].unlocked = in_range and parts[0].destroyed
	if sector == "cryo" and not orbital and (parts[0].destroyed or parts[1].destroyed):
		if vent_started:
			vent_time += delta
		vent_started = true
	var was_open := core.unlocked
	core.unlocked = in_range and _core_exposed()
	if core.biological and core.unlocked != was_open:
		_update_breach(core)
	if core.unlocked and not interlock_opened:
		# The first overload trips the guns while the pilot transfers aim.
		interlock_opened = true
		for turret in turrets:
			turret.cooldown = maxf(turret.cooldown, 1.65)
	var lost_radars := _lost(radars)
	var reload_multiplier := radar_interval_multiplier()
	var guidance := radar_guidance()
	var rail := _weapon_frame()
	for i in range(turrets.size()):
		var turret := turrets[i]
		turret.interval_multiplier = reload_multiplier
		turret.lead_fraction = guidance
		turret.rage_stage = rage_stage
		if weapon_time > 0:
			var target := pilot
			if lost_radars == 2:
				var depth := (rail.affine_inverse() * pilot).z
				target = rail * BossAttack.blind_lane(depth, i + turret.launches)
			turret.advance(weapon_time, target, velocity)
		else:
			turret.beacon.hide()
	if in_range and lost_radars < 2 and thermal_emitter != null and not thermal_emitter.destroyed:
		sweep_cooldown -= weapon_time
		if sweep_cooldown <= 0.0:
			sweep_requested.emit(thermal_emitter)
			sweep_cooldown += 11.0 - rage_stage * 1.6
	if in_range and weapon_time > 0.0:
		_advance_special(weapon_time, pilot, pilot_radius)

func _update_rage() -> void:
	if rage_stage == 2:
		return
	# Optional subsystem hits also provoke the ship, even on a victory route
	# where those parts do not contribute to the HUD's objective-health gauge.
	var armor_left := 0
	var systems_lost := 0.0
	for part in parts:
		armor_left += maxi(0, part.armor)
		systems_lost += 1.0 - clampf(float(part.armor) / part.maximum_armor, 0, 1)
	if armor_left == last_armor:
		return
	last_armor = armor_left
	var health := health_fraction()
	var next_stage := 2 if health <= 0.5 or systems_lost >= 2.75 else 1 if health <= 0.8 or systems_lost >= 0.75 else 0
	if next_stage > rage_stage:
		rage_stage = next_stage
		stage_volleys = 0
		special_cooldown = minf(special_cooldown, 0.55)

func _advance_special(delta: float, pilot: Vector3, pilot_radius: float) -> void:
	var rail := _weapon_frame()
	if special != null:
		special.global_transform = rail
		if special.emitter.destroyed and special.needs_emitter():
			_cancel_special()
			special_cooldown = 1.2
			return
		if special.advance(delta, pilot, pilot_radius):
			special_hit.emit(special.attack_name, special.damage)
		if special.complete():
			_cancel_special()
		return
	special_cooldown -= delta
	if special_cooldown > 0.0:
		return
	# Introduce the new tactic immediately, then alternate with the previous
	# phase so a pilot cannot camp one safe lane through the rest of the fight.
	var move := rage_stage if stage_volleys % 2 == 0 else maxi(0, rage_stage - 1)
	var emitter := _special_emitter(move)
	if emitter == null:
		# Loss of a dedicated mount takes its weapon offline. Try the surviving
		# systems, then let the exposed reactor vent a final desperate discharge.
		for alternate in range(rage_stage, -1, -1):
			emitter = _special_emitter(alternate)
			if emitter != null:
				move = alternate
				break
	var core_discharge := emitter == null
	if core_discharge:
		emitter = core
	special = BossAttack.new()
	add_child(special)
	special.global_transform = rail
	special.configure(sector, orbital, move, volleys, emitter, body, pilot, core_discharge, _lost(radars), broken_feeds())
	if cloak != null:
		cloak.reveal(special.windup + 0.45)
		_update_guidance()
	volleys += 1
	stage_volleys += 1
	special_cooldown = 3.9 - rage_stage * 1.25

func _weapon_frame() -> Transform3D:
	if not pursuing:
		return Transform3D(global_basis, anchor)
	if orbital:
		return course.translated_local(Vector3.FORWARD * FlightState.SPEED * age)
	return ground_course * FlightState.rail_frame(canyon_start + FlightState.SPEED * age)

func _special_emitter(move: int) -> BossPart:
	if sector == "ignis" and orbital and move == 0:
		return thermal_emitter if not thermal_emitter.destroyed else null
	if sector == "thalassa" and orbital and move == 1:
		return core # The Storm Ark channels its lightning lance through the turbine.
	if sector == "vespera" and move == 1:
		return _live_emitter(radars)
	var uses_sacs := sector == "xylo" and move == (2 if orbital else 1)
	var uses_pods := not orbital and move == 1 and sector in ["cryo", "kharon"]
	if uses_sacs or uses_pods:
		return _live_emitter([parts[0], parts[1]])
	return _live_emitter(turrets)

func _live_emitter(bank: Array) -> BossPart:
	for i in range(bank.size()):
		var part: BossPart = bank[(volleys + i) % bank.size()]
		if not part.destroyed and part.unlocked:
			return part
	return null

func attack_warning() -> String:
	return special.warning() if special != null and special.age < special.windup else ""

func _cancel_special() -> void:
	if special != null:
		special.hide()
		special.queue_free()
		special = null

func stun() -> void:
	stun_remaining = FlightState.EMP_STUN_DURATION
	_cancel_special()
	special_cooldown = maxf(special_cooldown, 1.0)
	if cloak != null:
		cloak.reveal()
		_update_guidance()
	for turret in turrets:
		turret.cooldown = maxf(turret.cooldown, GroundTurret.WARNING_TIME)
		turret.beacon.hide()
	sweep_cooldown = maxf(sweep_cooldown, 1.0)

func _update_guidance() -> void:
	for part in parts:
		part.guided_lockable = cloak == null or not cloak.active()

func defeated() -> bool:
	if core == null:
		return false
	if sector == "thalassa" and not orbital and parts[0].destroyed and parts[1].destroyed:
		return true
	if sector == "kharon" and orbital and _lost(turrets) == turrets.size():
		return true
	return core.destroyed

func _lost(bank: Array) -> int:
	var count := 0
	for part: BossPart in bank:
		count += int(part.destroyed)
	return count

func _core_exposed() -> bool:
	var both := parts[0].destroyed and parts[1].destroyed
	var either := parts[0].destroyed or parts[1].destroyed
	match sector:
		"ignis":
			return thermal_emitter.destroyed if orbital else both
		"cryo":
			return (both or (drone_bay.destroyed and either)) if orbital else vent_started and fmod(vent_time, 7.0) < 4.0
		"vespera":
			return _lost(radars) == 2
		"xylo":
			return _lost(turrets) >= 3 if orbital else both
		"thalassa":
			return orbital and either and _lost(turrets) >= 2
		_:
			return both

# Smallest remaining workload among legal target routes. Optional armor never
# pads out the HUD, and a magazine or ballast kill always empties the gauge.
func _remaining(bank: Array, required: int) -> float:
	var ratios: Array[float] = []
	for part: BossPart in bank:
		ratios.append(clampf(float(part.armor) / part.maximum_armor, 0, 1))
	ratios.sort()
	var amount := 0.0
	for i in range(required):
		amount += ratios[i]
	return amount

func health_fraction() -> float:
	if defeated():
		return 0.0
	var cells := [parts[0], parts[1]]
	var heart := float(core.armor) / core.maximum_armor
	var standard := (_remaining(cells, 2) + heart) / 3.0
	match sector:
		"ignis":
			return (_remaining([thermal_emitter], 1) + heart) * 0.5 if orbital else standard
		"cryo":
			if orbital:
				return minf(standard, (_remaining([drone_bay], 1) + _remaining(cells, 1) + heart) / 3.0)
			return (_remaining(cells, 1) + heart) * 0.5
		"vespera":
			return (_remaining(radars, 2) + heart) / 3.0
		"xylo":
			return (_remaining(turrets, 3) + heart) * 0.25 if orbital else standard
		"thalassa":
			return (_remaining(turrets, 2) + _remaining(cells, 1) + heart) * 0.25 if orbital else _remaining(cells, 2) * 0.5
		_:
			return minf(standard, _remaining(turrets, 6) / 6.0) if orbital else standard

func recon_bounty() -> int:
	return 75 if defeated() and _lost(radars) == 0 else 0

func part_label(part: BossPart) -> String:
	if part == core:
		if sector == "thalassa" and not orbital:
			return "ARMORED BRIDGE"
		return _vital_name() + (" / EXPOSED" if part.unlocked else " / SEALED")
	if part is BossRadar:
		if part.biological:
			return "SENSORY FAN"
		return "SHIELD RELAY" if sector == "vespera" else "TRACKING RADAR"
	if part is BossTurret:
		return "SPORE SPITTER" if part.biological else "MAGAZINE" if sector == "kharon" and orbital else "LAUNCHER"
	if part is ThermalEmitter:
		return "THERMAL PROJECTOR"
	if part is DroneBay:
		return "DRONE BAY"
	match sector:
		"xylo": return "SPORE SAC"
		"cryo": return "COOLANT GENERATOR" if orbital else "COOLANT POD"
		"vespera": return "SHIELD CAPACITOR"
		"thalassa": return "PRESSURE GENERATOR" if orbital else "BALLAST POD"
		"kharon":
			if not orbital:
				return "LEFT BUS RELAY" if part == parts[0] else "RIGHT BUS RELAY"
			return "CAPACITOR BANK"
		_: return "HEAT EXCHANGER" if orbital else "GENERATOR"

func target_hint(part: BossPart) -> String:
	var label := part_label(part)
	if part == core:
		return label
	if not part.unlocked:
		return label + " / SHIELDED"
	if part is BossRadar:
		return label + (" / BREAK MISSILE LOCK" if _lost(radars) == 1 else " / DISRUPT GUIDANCE")
	if part is BossTurret:
		return label + " / SILENCE THIS GUN"
	if part is DroneBay:
		return label + " / STOP REINFORCEMENTS"
	if part is ThermalEmitter:
		return label + " / DISABLE HEAT SWEEP"
	if not _has_powered_battery(part):
		return label + " / WEAKEN SPECIAL ATTACKS"
	return label + (" / WEAKEN LEFT BATTERY" if part == parts[0] else " / WEAKEN RIGHT BATTERY")

func _has_powered_battery(feed: BossPart) -> bool:
	for turret in turrets:
		if not turret.destroyed and signf(turret.position.x) == signf(feed.position.x):
			return true
	return false

func destruction_notice(part: BossPart) -> String:
	var label := part_label(part)
	if part is BossRadar:
		if _lost(radars) < 2:
			return "%s LOST / MISSILE GUIDANCE AT %d%%" % [label, roundi(100.0 * radar_guidance())]
		return "MISSILES UNGUIDED / PHASE PRISM EXPOSED" if sector == "vespera" else "MISSILES UNGUIDED / BOSS FIRING BLIND"
	if part is ThermalEmitter:
		return "THERMAL SWEEP OFFLINE / FURNACE CORE EXPOSED"
	if part is DroneBay:
		return "DRONE BAY LOST / REINFORCEMENTS CUT OFF"
	if part is BossTurret:
		return "%s SILENCED / %d OF %d GUNS REMAIN" % [label, turrets.size() - _lost(turrets), turrets.size()]
	if not _has_powered_battery(part):
		return label + " LOST / SPECIAL ATTACK POWER REDUCED"
	var side := "LEFT" if part == parts[0] else "RIGHT"
	return "%s LOST / %s BATTERY RELOAD DOUBLED" % [label, side]

func _vital_name() -> String:
	match sector:
		"xylo": return "HEART"
		"cryo": return "CRYO CORE" if orbital else "CORE VENT"
		"vespera": return "PHASE PRISM"
		"thalassa": return "STORM TURBINE"
		"kharon": return "SOLAR RECEIVER"
		_: return "FURNACE CORE" if orbital else "REACTOR"

func objective() -> String:
	if pursuing and pursuit_range >= (260.0 if orbital else 230.0):
		return "PURSUIT / CLOSING ON THE FLEEING CAPITAL SHIP"
	if sector == "cryo" and not orbital and vent_started:
		var clock := fmod(vent_time, 7.0)
		return "VENT OPEN / HIT CORE / %ds" % ceili(4.0 - clock) if clock < 4.0 else "VENT SEALED / REOPENS IN %ds" % ceili(7.0 - clock)
	if core.unlocked:
		if sector == "xylo":
			return "FIRE INTO THE BLEEDING OPENING BELOW ITS EYES" if orbital else "FIRE BETWEEN THE RIBS / LEFT CHEST"
		return "%s EXPOSED / FIRE" % _vital_name()
	if stun_remaining > 0:
		return "EMP / CAPITAL WEAPON SYSTEMS DISABLED"
	match sector:
		"ignis":
			return "DESTROY THE THERMAL PROJECTOR" if orbital else "BREAK BOTH AMBER GENERATORS"
		"cryo":
			return "BREAK BOTH GENERATORS / OR ONE AND THE DRONE BAY" if orbital else "RUPTURE EITHER COOLANT POD TO OPEN THE VENT"
		"vespera":
			return "SHIMMER / MANUAL FIRE ON BOTH RADARS" if cloak != null and cloak.active() else "DISABLE SHIELD RADARS / %d OF 2" % _lost(radars)
		"xylo":
			return "SILENCE THREE SPORE SPITTERS / %d OF 3" % _lost(turrets) if orbital else "RUPTURE BOTH AMBER SPORE SACS"
		"thalassa":
			return "BREAK ONE GENERATOR AND TWO LAUNCHERS / %d OF 2" % mini(2, _lost(turrets)) if orbital else "RUPTURE BOTH BALLAST PODS TO SINK THE WALKER"
		_:
			if orbital:
				return "GENERATORS THEN CORE / OR DETONATE ALL SIX MAGAZINES"
			return "RIGHT RELAY EXPOSED / BREAK IT" if parts[0].destroyed else "BREAK THE LEFT RELAY FIRST"

func configure_pursuit(entry: Transform3D, canyon_distance: float = 0.0, ground_origin: Transform3D = Transform3D.IDENTITY) -> void:
	pursuing = true
	course = entry
	canyon_start = canyon_distance
	ground_course = ground_origin
	age = 0.0
	for part in parts:
		part.unlocked = false
	_update_pursuit()

func _update_pursuit() -> void:
	var minimum: float = 112.5 if orbital else 82.5
	pursuit_range = minimum + (480.0 - minimum) * exp(-age / 9.0)
	var distance: float = FlightState.SPEED * age + pursuit_range
	var drift: float = sin(age * TAU / 24.0) * (8.0 if orbital else 4.0)
	drift += aggression * sin(age * (0.74 if orbital else 0.93)) * (2.4 if orbital else 1.15)
	if orbital:
		global_transform = course * Transform3D(Basis(Vector3.UP, sin(age * TAU / 28.0) * 0.10), Vector3(drift, sin(age * TAU / 30.0) * 1.5, -distance))
	else:
		var local: Transform3D = FlightState.rail_frame(canyon_start + distance)
		local.origin.y = 9.5 + sin(age * 1.1) * 0.45
		local.origin += local.basis.x * drift
		global_transform = ground_course * local
		rotate_object_local(Vector3.FORWARD, sin(age * 0.7) * 0.025)
	# Bank the entire mount assembly so shots, cover and radar follow the pose.
	if orbital:
		rotate_object_local(Vector3.FORWARD, -firing_side * attack_brace * 0.12 + aggression * sin(age * 0.74) * 0.042)
	elif sector == "thalassa":
		var flooded_side := int(parts[1].destroyed) - int(parts[0].destroyed)
		rotate_object_local(Vector3.FORWARD, flooded_side * 0.095)
	rotate_object_local(Vector3.RIGHT, attack_brace * (0.12 if sector == "xylo" else 0.045))

func begin_destruction() -> void:
	if death_time >= 0.0:
		return
	death_time = 0.0
	_cancel_special()
	var imbalance := 0.0
	for part in parts:
		mounted_at_failure.append(part.transform)
		if part.destroyed:
			imbalance += signf(part.position.x)
	wreck_direction = -signf(imbalance) if imbalance != 0 else 1.0
	if cloak != null:
		cloak.restore()
	body.collision_layer = 0
	for part in parts:
		part.collision_layer = 0
	if thermal_emitter != null:
		thermal_emitter.destroyed = true
	if drone_bay != null:
		drone_bay.destroyed = true
