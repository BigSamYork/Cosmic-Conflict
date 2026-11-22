class_name BossEncounter
extends Node3D

signal missile_requested(origin: Vector3, direction: Vector3)
signal sweep_requested(emitter: ThermalEmitter)
var orbital: bool = false
var sector: String = "ignis"
var health_scale: float = 1.0
var parts: Array[BossPart] = []
var turrets: Array[BossTurret] = []
var core: BossPart
var age: float = 0.0
var visual_age: float = 0.0
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
	body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30, 12, 76) if orbital else Vector3(31, 8, 32)
	collider.position.z = -3 if orbital else -4
	if sector == "vespera":
		shape.size.y = 18 if orbital else 28
		collider.position.y = 3 if orbital else 10
	elif sector == "xylo":
		shape.size = Vector3(36, 32, 40) if orbital else Vector3(22, 38, 24)
		collider.position = Vector3(0, 0, 9) if orbital else Vector3(0, 11, -4)
	collider.shape = shape
	body.add_child(collider)
	if sector == "xylo" and orbital:
		for i in range(6):
			var segment := CollisionShape3D.new()
			var shell := SphereShape3D.new()
			shell.radius = maxf(13 - i * 1.3, 11)
			segment.shape = shell
			segment.position = XyloArt.leviathan_segment(i)
			body.add_child(segment)
	add_child(body)
	for side in [-1.0, 1.0]:
		var generator := BossPart.new()
		generator.biological = sector == "xylo"
		generator.armored_interlock = sector == "kharon" and not orbital and side > 0
		generator.unlocked = not generator.armored_interlock
		generator.position = Vector3(side * (10.0 if orbital else 11.0), 0, 34 if orbital else 13)
		generator.maximum_armor = ceili((24 if orbital else 18) * health_scale)
		generator.nacelle_radius = 4.3 if orbital else 4.6
		generator.nacelle_length = 12.0 if orbital else 18.0
		add_child(generator)
		parts.append(generator)
	core = BossPart.new()
	core.biological = sector == "xylo"
	core.core = true
	core.unlocked = false
	core.maximum_armor = ceili((64 if orbital else 48) * health_scale)
	core.position = Vector3(0, 0, 34 if orbital else 13)
	core.nacelle_radius = 4.3 if orbital else 4.6
	core.nacelle_length = 12.0 if orbital else 18.0
	add_child(core)
	parts.append(core)
	for side in [-1.0, 1.0]:
		for row in range(3 if orbital else 2):
			var turret := BossTurret.new()
			turret.biological = sector == "xylo"
			turret.position = Vector3(side * (22 + row * 16), 9 + row * 4, 27 - row * 22) if orbital else Vector3(side * (19 if row == 0 else 30), 10 if row == 0 else 8, 14 if row == 0 else -4)
			turret.maximum_armor = ceili((14 if orbital else 10) * health_scale)
			turret.interval = (9.0 if orbital else 5.2) if sector == "cryo" else (7.2 if orbital else 5.6)
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
		var scan_height: float = collider.position.y + shape.size.y * 0.5 + 9
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

func radar_mount(side: float) -> Vector3:
	var x: float = side * (5 if sector == "xylo" and not orbital else 8)
	var start := Vector3(x, 140, 0)
	var end := Vector3(x, -80, 0)
	var highest: float = -INF
	for node in model.get_children():
		if not node is MeshInstance3D:
			continue
		var mesh: Mesh = node.mesh
		if not mesh.has_meta("fragment_vertices"):
			continue
		var vertices: PackedVector3Array = mesh.get_meta("fragment_vertices")
		var indices: PackedInt32Array = mesh.get_meta("fragment_indices")
		var transform: Transform3D = model.transform * node.transform
		for i in range(0, indices.size(), 3):
			var hit: Variant = Geometry3D.segment_intersects_triangle(start, end, transform * vertices[indices[i]], transform * vertices[indices[i + 1]], transform * vertices[indices[i + 2]])
			if hit != null:
				highest = maxf(highest, hit.y)
	assert(is_finite(highest), "Boss radar must be attached to a real hull surface: " + sector)
	return Vector3(x, highest, 0)

func radar_interval_multiplier() -> float:
	var destroyed: int = 0
	for radar in radars:
		destroyed += int(radar.destroyed)
	return 1.0 + destroyed * 0.25

func advance_visuals(delta: float) -> void:
	visual_age += delta
	for part in parts:
		if part.armor * 3 >= part.maximum_armor:
			continue
		if not breaches.has(part):
			_open_breach(part)
		breaches[part].set_instance_shader_parameter(&"breach_time", visual_age)
	for reactor in [parts[0], parts[1], core]:
		reactor.animate_reactor(visual_age)
	for i in range(core_rings.size()):
		core_rings[i].rotation.y = visual_age * (0.32 if i % 2 == 0 else -0.23)
	for i in range(collectors.size()):
		collectors[i].rotation.y = visual_age * (0.8 if i == 0 else -0.8)
		collectors[i].rotation.z = sin(visual_age * 0.42) * 0.16
	for i in range(bio_legs.size()):
		var stride := sin(visual_age * 2.4 + i * PI) * 0.18
		bio_legs[i].basis = Basis(Vector3.RIGHT, stride).scaled_local(Vector3(-1 if i == 0 else 1, 1, 1))
	for i in range(tempest_legs.size()):
		var stride := sin(visual_age * 1.7) * (1.0 if i == 0 or i == 3 else -1.0)
		var mirror := Vector3(-1 if i < 2 else 1, 1, -1 if i % 2 == 0 else 1)
		tempest_legs[i].basis = Basis(Vector3.RIGHT, stride * 0.09).scaled_local(mirror)
	if cloak != null and death_time < 0:
		if radars[0].destroyed and radars[1].destroyed:
			cloak.reveal(delta + 0.1)
		cloak.advance(delta)
		_update_guidance()
	if drill != null:
		drill.rotation.z = fposmod(visual_age * 2.8, TAU)
	for radar in radars:
		radar.advance_scanner(visual_age)

func _open_breach(part: BossPart) -> void:
	if breach_mesh == null:
		breach_material.shader = preload("res://shaders/boss_breach.gdshader")
		breach_mesh = MultiMesh.new()
		breach_mesh.transform_format = MultiMesh.TRANSFORM_3D
		breach_mesh.use_custom_data = true
		breach_mesh.mesh = QuadMesh.new()
		breach_mesh.instance_count = 9
		breach_mesh.custom_aabb = AABB(Vector3(-4, -8, -2), Vector3(8, 18, 11))
		for i in range(9):
			breach_mesh.set_instance_transform(i, Transform3D.IDENTITY)
			breach_mesh.set_instance_custom_data(i, Color(i / 9.0, 0, 0, 1))
	var plume := MultiMeshInstance3D.new()
	plume.multimesh = breach_mesh
	plume.material_override = breach_material
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.set_instance_shader_parameter(&"organic", part.biological)
	model.add_child(plume)
	plume.global_position = part.aim_point()
	breaches[part] = plume

func advance(delta: float, pilot: Vector3, velocity: Vector3) -> void:
	var weapon_time: float = maxf(0.0, delta - stun_remaining)
	stun_remaining = maxf(0.0, stun_remaining - delta)
	age += delta
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
	core.unlocked = in_range and _core_exposed()
	if core.unlocked and not interlock_opened:
		# The first overload trips the guns while the pilot transfers aim.
		interlock_opened = true
		for turret in turrets:
			turret.cooldown = maxf(turret.cooldown, 1.65)
	for turret in turrets:
		turret.interval_multiplier = radar_interval_multiplier()
		turret.lead_fraction = 1.0 - 0.4 * (int(radars[0].destroyed) + int(radars[1].destroyed))
		turret.emergency_power = core.unlocked and core.armor * 3 <= core.maximum_armor
		if weapon_time > 0:
			turret.advance(weapon_time, pilot, velocity)
		else:
			turret.beacon.hide()
	if in_range and thermal_emitter != null and not thermal_emitter.destroyed:
		sweep_cooldown -= weapon_time
		if sweep_cooldown <= 0.0:
			sweep_requested.emit(thermal_emitter)
			sweep_cooldown += 11.0

func stun() -> void:
	stun_remaining = FlightState.EMP_STUN_DURATION
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
		return ("HEART" if part.biological else "CORE") + (" / EXPOSED" if part.unlocked else " / SEALED")
	if part is BossRadar:
		return "SHIELD RELAY" if sector == "vespera" else "TRACKING RADAR"
	if part is BossTurret:
		return "SPORE SPITTER" if part.biological else "MAGAZINE" if sector == "kharon" and orbital else "LAUNCHER"
	if part is ThermalEmitter:
		return "THERMAL PROJECTOR"
	if part is DroneBay:
		return "DRONE BAY"
	if sector == "kharon" and not orbital:
		return "FIRST / LEFT RELAY" if part == parts[0] else "SECOND / RIGHT RELAY"
	if sector == "thalassa" and not orbital:
		return "BALLAST POD"
	if sector == "cryo" and not orbital:
		return "COOLANT POD"
	return "SPORE ORGAN" if part.biological else "GENERATOR"

func objective() -> String:
	if pursuing and pursuit_range >= (260.0 if orbital else 230.0):
		return "PURSUIT / CLOSING ON THE FLEEING CAPITAL SHIP"
	if sector == "cryo" and not orbital and vent_started:
		var clock := fmod(vent_time, 7.0)
		return "VENT OPEN / HIT CORE / %ds" % ceili(4.0 - clock) if clock < 4.0 else "VENT SEALED / REOPENS IN %ds" % ceili(7.0 - clock)
	if core.unlocked:
		return "VITAL CORE EXPOSED / DESTROY THE CYAN ORGAN" if sector == "xylo" else "REACTOR EXPOSED / DESTROY THE CYAN CORE"
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
			return "SILENCE THREE SPORE SPITTERS / %d OF 3" % _lost(turrets) if orbital else "RUPTURE BOTH AMBER ORGANS"
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
	if orbital:
		global_transform = course * Transform3D(Basis(Vector3.UP, sin(age * TAU / 28.0) * 0.10), Vector3(drift, sin(age * TAU / 30.0) * 1.5, -distance))
	else:
		var local: Transform3D = FlightState.rail_frame(canyon_start + distance)
		local.origin.y = 9.5 + sin(age * 1.1) * 0.45
		local.origin += local.basis.x * drift
		global_transform = ground_course * local
		rotate_object_local(Vector3.FORWARD, sin(age * 0.7) * 0.025)

func begin_destruction() -> void:
	if death_time >= 0.0:
		return
	death_time = 0.0
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
