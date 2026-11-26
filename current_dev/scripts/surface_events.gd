extends RefCounted

const CONTACT := 2.5
const DURATION := 5.5
const CLAW := preload("res://scripts/canopy_claw.gd")
const IGNEOUS := preload("res://scripts/igneous_hazard.gd")
const FRONTIER := preload("res://scripts/frontier_hazard.gd")
const NAMES := {"ignis": "VOLCANIC BOMB", "cryo": "GLACIAL RUPTURE", "cryo_creature": "GLACIER MAULER", "vespera": "DERAILED MAGLEV", "xylo": "CANOPY CLAW", "kharon": "METEOR IMPACT", "kharon_walker": "SIEGE WALKER"}
const RADII := {"ignis": 9.0, "cryo": 10.0, "cryo_creature": 10.0, "vespera": 9.0, "xylo": 5.5, "kharon": 12.0, "kharon_walker": 10.0}

var random := RandomNumberGenerator.new()
var effect: Node3D
var carried: Node3D
var sector := ""
var kind := ""
var mauler_slot := 1
var cryo_events := 0
var pilot_caught := false
var grip_offset := Vector3.ZERO
var entry_basis := Basis.IDENTITY
var age := 0.0
var delay := 0.0

func reset() -> void:
	_clear_effect()
	cryo_events = 0
	mauler_slot = random.randi_range(1, 2)
	delay = random.randf_range(4.5, 7.0)

func _clear_effect() -> void:
	if is_instance_valid(effect):
		effect.queue_free()
	effect = null
	carried = null
	pilot_caught = false
	sector = ""
	kind = ""
	age = 0.0

func warning() -> bool:
	return is_instance_valid(effect) and age < CONTACT and not (kind == "kharon_walker" and effect.walker.destroyed)

func warning_text() -> String:
	return NAMES[kind] + " / BREAK AWAY"

func advance(game, delta: float, previous: Vector3, pilot: Vector3) -> void:
	if delta <= 0:
		return
	if effect == null:
		delay -= delta
		if delay > 0:
			return
		_start(game)
		return
	var before := age
	age += delta
	var reduced: bool = game.settings["reduced_effects"]
	if sector == "xylo":
		effect.shake_enabled = game.settings["shake"] and not reduced
	if before < CONTACT and age >= CONTACT:
		effect.advance_event(CONTACT, reduced)
		var pilot_at_contact := previous.lerp(pilot, (CONTACT - before) / delta)
		_impact(game, pilot_at_contact)
	var end_time := CLAW.LAND_AT if pilot_caught else DURATION
	effect.advance_event(minf(age, end_time), reduced)
	if carried != null:
		carried.global_position = effect.grasp_point()
	if pilot_caught and before < CLAW.THROW_AT and age >= CLAW.THROW_AT:
		game.hud.show_message("CLAW RELEASE / BRACE FOR IMPACT")
	if age >= end_time:
		if pilot_caught and game.flight.hull > 0:
			if game._apply_pilot_damage("CANOPY CLAW THROW", 35.0, true):
				game.sound.play_sound(game.sound.impact)
				game.hud.show_message("CLAW THROW / HULL IMPACT")
		_clear_effect()
		delay = random.randf_range(6.5, 13.0)

func _start(game) -> void:
	sector = game.campaign.sector
	kind = sector
	if sector == "cryo":
		cryo_events += 1
		if cryo_events == mauler_slot:
			kind = "cryo_creature"
	elif sector == "kharon" and random.randf() < 0.35:
		kind = "kharon_walker"
	var flight: FlightState = game.flight
	var travel := flight.distance + flight.speed * CONTACT
	var route: GroundRoute = game.director.ground_route
	var rail := GroundRoute.frame(travel) if route != null and route.selected else FlightState.rail_frame(travel)
	# Fix the strike in terrain coordinates. The pilot can steer clear during the warning.
	var at := rail * Vector3(flight.offset.x + random.randf_range(-3.0, 3.0), flight.offset.y, 0)
	var candidates: Array[RangeTarget] = []
	for target: RangeTarget in game.targets:
		if not _eligible(target):
			continue
		var ahead := target.travel - flight.distance
		if ahead < 125.0 or ahead > 232.0:
			continue
		var local: Vector3 = game.world.to_local(target.aim_point())
		var lane := GroundRoute.point(target.travel) if route != null and route.selected else FlightState.rail_point(target.travel)
		if absf(local.x - lane.x) <= 32.0:
			candidates.append(target)
	if kind != "cryo_creature" and not candidates.is_empty() and random.randf() < (0.45 if sector == "xylo" else 0.70):
		at = game.world.to_local(candidates[random.randi_range(0, candidates.size() - 1)].aim_point())
	var script: Script = IGNEOUS if sector in ["ignis", "kharon"] else CLAW if sector == "xylo" else FRONTIER
	effect = script.new()
	if sector == "xylo":
		effect.floor_offset = maxf(0.0, at.y + 1.0)
	else:
		effect.sector = sector
	if sector == "cryo":
		effect.creature_encounter = kind == "cryo_creature"
		at.y -= VectorArt.canyon_clearance(at, game.ground_branch != null, true, 0.0) + 0.35
	elif sector == "kharon":
		effect.walker_encounter = kind == "kharon_walker"
		if effect.walker_encounter:
			var lane := at.x - FlightState.rail_point(-at.z).x
			at.y = FrontierArt.floor_point(lane, -at.z, sector).y
	elif sector == "vespera":
		at.y = -1.0
	elif sector == "ignis" and not game.heat_vents.is_empty():
		var nearest: HeatVent = game.heat_vents[0]
		var point: Vector3 = game.world.to_global(at)
		for vent: HeatVent in game.heat_vents:
			if vent.global_position.distance_squared_to(point) < nearest.global_position.distance_squared_to(point):
				nearest = vent
		effect.source_world = nearest.to_global(Vector3.UP * VolcanoEruption.CRATER_HEIGHT)
	effect.position = at
	game.world.add_child(effect)
	age = 0.0
	effect.advance_event(0.0, game.settings["reduced_effects"])
	game.sound.play_sound(load("res://assets/hazards/%s_warning.wav" % kind))
	if kind == "cryo_creature":
		game.hud.show_message("GLACIER MAULER AHEAD / EVADE ITS PAWS")

func _eligible(target: RangeTarget) -> bool:
	if target.destroyed or target.is_queued_for_deletion() or not target.is_visible_in_tree():
		return false
	if target is EnemyFighter:
		return not target.expired
	return target is GroundTurret or target is RadarDish or (target is DestructibleTower and sector != "xylo")

func _in_reach(at: Vector3, margin: float = 0.0) -> bool:
	var local := effect.to_local(at)
	if sector in ["cryo", "vespera"] or kind == "kharon_walker":
		# The rising ice and the descending railcar sweep a vertical volume.
		var height := 15.0 if sector == "cryo" else 8.0 if kind == "kharon_walker" else 11.0
		if local.y < -margin or local.y > height + margin:
			return false
		local.y = 0.0
	var radius: float = RADII[kind] + margin
	return local.length_squared() <= radius * radius

func _impact(game, pilot: Vector3) -> void:
	if kind == "kharon_walker" and effect.walker.destroyed: return
	game.sound.play_sound(load("res://assets/hazards/%s_impact.wav" % kind))
	if game.flight.roll_remaining <= 0.0 and _in_reach(pilot, game.flight.collision_radius):
		if sector == "xylo" and game.flight.hull > 0.0:
			pilot_caught = true
			effect.pilot_caught = true
			grip_offset = effect.to_local(pilot)
			entry_basis = game.camera.global_basis.orthonormalized()
			game.hud.show_message("CANOPY CLAW / SHIP IN ITS GRIP")
			return # One set of talons can only seize one victim.
		game._apply_pilot_damage(NAMES[kind], 42.0)
	var closest: RangeTarget
	for target: RangeTarget in game.targets:
		if not _eligible(target) or not _in_reach(target.aim_point()):
			continue
		if sector == "xylo":
			if closest == null or target.aim_point().distance_squared_to(effect.global_position) < closest.aim_point().distance_squared_to(effect.global_position):
				closest = target
		else:
			# Reuse the world's fracture and destruction paths without awarding the pilot a kill.
			game._storm_contact(target, target.aim_point(), -effect.global_basis.y)
	if closest != null:
		_snatch(closest)

func pilot_pose(rail: Transform3D) -> Transform3D:
	if not pilot_caught:
		return rail
	var t := minf(age, CLAW.THROW_AT)
	var lift := smoothstep(CONTACT, 3.52, t)
	# Keep the cockpit between the fingers. Preserve the offset at contact so
	# a grazing catch pulls the ship in without teleporting it to the palm.
	var offset := grip_offset.lerp(Vector3(0, -0.7, 3.2), lift)
	var held: Vector3 = effect.to_global(effect.pilot_hold(t) + offset)
	var shake: float = effect.shake_wave(t)
	var attitude := entry_basis * Basis.from_euler(Vector3(-0.25 * lift + 0.04 * shake, 0.08 * lift, 0.14 * lift + 0.13 * shake))
	var thrown := clampf((age - CLAW.THROW_AT) / (CLAW.LAND_AT - CLAW.THROW_AT), 0.0, 1.0)
	var arc := 4.0 * thrown * (1.0 - thrown)
	var position := held.lerp(rail.origin, thrown) + effect.global_basis * Vector3(8.0, 10.0, -9.0) * arc
	var rotation := attitude.slerp(rail.basis, thrown) * Basis.from_euler(Vector3(-0.19 * arc, 0, -0.26 * arc))
	return Transform3D(rotation, position)

func _snatch(victim: RangeTarget) -> void:
	# Carry a render-only snapshot. The original target stops firing and colliding immediately.
	carried = Node3D.new()
	effect.add_child(carried)
	carried.global_position = victim.aim_point()
	for original: MeshInstance3D in victim.find_children("*", "MeshInstance3D", true, false):
		if original.mesh == null or not original.is_visible_in_tree():
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh
		copy.material_override = original.material_override
		copy.material_overlay = original.material_overlay
		for i in original.get_surface_override_material_count():
			copy.set_surface_override_material(i, original.get_surface_override_material(i))
		carried.add_child(copy)
		copy.global_transform = original.global_transform
	victim.receive_hit(victim.armor)
