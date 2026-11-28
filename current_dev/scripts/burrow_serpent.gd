class_name BurrowSerpent
extends Node3D

enum State { BURIED, RISING, HUNTING, FALLING, DOWN, WITHDRAWN }
const APPROACH := 220.0
const JOINTS := 15
const RISE_TIME := 1.12
const FALL_TIME := 1.52
const GRAVITY := 19.0
const VOLLEY_PERIOD := 1.65
const CHARGE_TIME := 0.68
const BEAM_END := 1.30
const ImpactSpray := preload("res://scripts/impact_spray.gd")

var state := State.BURIED
var age := 0.0
var centers := PackedVector3Array()
var fall_start := PackedVector3Array()
var facing := Vector3.BACK
var fall_facing := Vector3.BACK
var model: Node3D
var collar: Node3D
var turf_chunk: Node3D
var armor_body := StaticBody3D.new()
var armor_links: Array[CollisionShape3D] = []
var eyes: Array[BurrowEye] = []
var markers: Array[Node3D] = []
var beams: Array[Node3D] = []
var aim := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
var firing := [false, false]
var dealt := [false, false]
var stones: Array[Dictionary] = []
var struck_ship := false
var touched_living_body := false
var contact_shape := CapsuleShape3D.new()
var query := PhysicsShapeQueryParameters3D.new()

func _ready() -> void:
	model = BurrowSerpentArt.build()
	add_child(model)
	model.hide()
	collar = BurrowSerpentArt.burrow()
	add_child(collar)
	collar.hide()
	for id in ["EyeLeft", "EyeRight"]:
		var marker: Node3D = model.get_node(id)
		markers.append(marker)
		var eye := BurrowEye.new()
		eye.travel = XyloArt.SERPENT_TRAVEL
		add_child(eye)
		eye.blinded.connect(_eye_lost.bind(eyes.size()))
		eyes.append(eye)
		var beam := _make_beam()
		add_child(beam)
		beam.hide()
		beams.append(beam)
	centers.resize(JOINTS)
	armor_body.collision_layer = 0
	armor_body.collision_mask = 0
	add_child(armor_body)
	for i in JOINTS:
		var link := CollisionShape3D.new()
		link.shape = CapsuleShape3D.new()
		armor_body.add_child(link)
		armor_links.append(link)
	query.shape = contact_shape
	query.collision_mask = 7 | SurfacePatrol.STORM_LAYER | FleetArt.PILOT_LAYER
	query.collide_with_areas = true

func advance(game, delta: float, previous_world: Vector3, pilot_world: Vector3) -> void:
	if delta <= 0.0 or state == State.WITHDRAWN:
		return
	var distance: float = game.flight.distance
	if state == State.BURIED:
		if distance < XyloArt.SERPENT_TRAVEL - APPROACH or distance > XyloArt.SERPENT_TRAVEL:
			return
		_erupt(game, pilot_world)
	var pilot := to_local(pilot_world)
	var previous := to_local(previous_world)
	var falling := state == State.FALLING
	var old := centers.duplicate() if falling else PackedVector3Array()
	age += delta
	var charge := 0.0
	if state == State.RISING or state == State.HUNTING:
		var rise := _rise_toward(pilot)
		if state == State.RISING and rise >= 0.88:
			state = State.HUNTING
			for eye in eyes:
				eye.collision_layer = 2
				game.targets.append(eye)
		if state == State.HUNTING:
			var pulse := fposmod(maxf(0.0, age - RISE_TIME), VOLLEY_PERIOD)
			charge = smoothstep(0.0, CHARGE_TIME, pulse) * (1.0 - smoothstep(BEAM_END, VOLLEY_PERIOD, pulse))
	elif state == State.FALLING:
		_fall_across_lane()
		if age >= FALL_TIME:
			state = State.DOWN
			game.sound.play_cue("ruin_landing")
			_dust(game, centers[9], 2.8)
			_flatten_reeds(centers, 3.8)
	if state != State.DOWN or falling:
		var gape := 0.28 + charge * 0.67 if state == State.HUNTING else 0.82
		BurrowSerpentArt.pose(model, centers, facing, gape, [not eyes[0].destroyed, not eyes[1].destroyed], charge)
		for i in 2:
			eyes[i].global_position = markers[i].global_position
		_pose_armor()
	if state == State.HUNTING:
		_lasers(game, previous, pilot, delta)
	if state in [State.RISING, State.HUNTING] and not touched_living_body:
		for i in range(1, JOINTS):
			var nearest := Geometry3D.get_closest_points_between_segments(centers[i-1], centers[i], previous, pilot)
			if nearest[0].distance_to(nearest[1]) < 3.1 + game.flight.collision_radius:
				touched_living_body = game._apply_pilot_damage("BURROW SERPENT", 32.0)
				break
	if state in [State.FALLING, State.DOWN]:
		_crush(game, old, previous, pilot)
	_advance_stones(game, delta, previous, pilot)
	if distance > XyloArt.SERPENT_TRAVEL + 100.0 and state != State.FALLING:
		state = State.WITHDRAWN
		armor_body.collision_layer = 0
		for i in 2:
			beams[i].hide()
			eyes[i].collision_layer = 0
			game.targets.erase(eyes[i])

func _rise_toward(pilot: Vector3) -> float:
	var rise := clampf(age / RISE_TIME, 0.0, 1.0)
	var buried_depth := (1.0 - ease(rise, 0.55)) * 24.0
	for i in JOINTS:
		var u := float(i) / (JOINTS - 1)
		# An S-bend lets the head turn toward the ship while the tail stays in the hole.
		var spine := Vector3(
			-7.6 * u * u + 3.2 * sin(u * TAU),
			-4.5 + 34.0 * u - 9.3 * pow(u, 4),
			9.0 * pow(u, 3) - 2.8 * sin(PI * u))
		var sway := Vector3(sin(age * 2.9 - u * 5.0) * 1.1,
			sin(age * 2.6 - u * 3.1) * 0.65, cos(age * 2.3 - u * 4.6) * 0.85)
		var joint := spine + sway * u * u + Vector3.DOWN * buried_depth
		# Every joint first passes through the same shaft. It can bend
		# sideways only once its armor clears the torn rim.
		var clearance := smoothstep(0.0, 13.0, joint.y)
		centers[i] = Vector3(joint.x * clearance, joint.y, joint.z * clearance)
	facing = centers[-1].direction_to(pilot)
	return rise

func _fall_across_lane() -> void:
	for i in JOINTS:
		var u := float(i) / (JOINTS - 1)
		var lag := 0.14 * (1.0 - u)
		var t := smoothstep(0.0, 1.0, (age / FALL_TIME - lag) / (1.0 - lag))
		var ground := Vector3(-37.0 * u, 2.45 + sin(u * PI) * 0.96, -8.5 * u + 2.0 * sin(u * TAU))
		ground.y = lerpf(-3.5, ground.y, smoothstep(0, 0.18, u))
		centers[i] = fall_start[i].lerp(ground, t) + Vector3.UP * (5.0 * u * sin(t * PI))
	facing = fall_facing.lerp(Vector3(-0.93, -0.1, -0.28), smoothstep(0.05, FALL_TIME, age)).normalized()

func _erupt(game, pilot: Vector3) -> void:
	state = State.RISING
	for chunk in game.ground_chunks:
		var cap: MeshInstance3D = chunk.get_node_or_null("UnbrokenTurf")
		if cap != null:
			turf_chunk = chunk
			cap.hide()
			var hitbox: CollisionShape3D = chunk.find_child("UnbrokenTurfCollider", true, false)
			hitbox.disabled = true
			break
	collar.show()
	_flatten_reeds(PackedVector3Array([Vector3.ZERO, Vector3.UP*0.2]), 4.8)
	model.show()
	var rng := RandomNumberGenerator.new()
	rng.seed = 27106
	var intercept: Vector3 = to_local(pilot) + Vector3.FORWARD * game.flight.speed * 2.1
	for i in 19:
		var angle := TAU*i/19.0 + rng.randf_range(-0.13,0.13)
		var outward := Vector3(cos(angle), 0, sin(angle))
		var rock := AsteroidArt.create(i % 3, Color("#695341"), true)
		add_child(rock)
		var radius := rng.randf_range(0.55,1.55)
		rock.scale = Vector3(1.0, rng.randf_range(0.55,0.84), rng.randf_range(0.76,1.08))*radius
		rock.position = outward * 3.4 + Vector3.UP * 2.2
		var velocity := outward*rng.randf_range(8.0,23.0) + Vector3.UP*rng.randf_range(12.0,23.0)
		if i < 4:
			var land := intercept + Vector3((i-1.5)*4.1, rng.randf_range(-1.8,1.8), 0)
			velocity = (land-rock.position)/2.1 + Vector3.UP*GRAVITY*1.05
		stones.append({"node":rock,"velocity":velocity,"radius":radius,"spin":outward*rng.randf_range(2.4,5.2)})
	_dust(game, Vector3.UP, 3.0)
	game.sound.play_cue("ruin_landing")
	game.hud.show_message("BURROW SERPENT / TARGET ITS EYES")

func _pose_armor() -> void:
	# Non-penetrating hull for incoming rounds. Eye volumes protrude from
	# the skull, and the ship's collision is handled by its swept flight path.
	armor_body.collision_layer = 2
	for i in JOINTS:
		var start := centers[i]
		var end := centers[i+1] if i+1 < JOINTS else start + facing*2.4
		var radius := 2.35 if i == JOINTS-1 else lerpf(2.0,3.3,sin(PI*i/JOINTS))
		var link := armor_links[i]
		var shape := link.shape as CapsuleShape3D
		shape.radius = radius
		shape.height = start.distance_to(end) + radius*2.0
		link.transform = Transform3D(Basis(Quaternion(Vector3.UP,start.direction_to(end))), start.lerp(end,0.5))

func _flatten_reeds(path: PackedVector3Array, radius: float) -> void:
	if not is_instance_valid(turf_chunk):
		return
	for bank in turf_chunk.get_children():
		if not bank is MultiMeshInstance3D or not bank.multimesh.has_meta("decorative_ground_cover"):
			continue
		_make_placements_local(bank)
		for i in bank.multimesh.instance_count:
			var tuft: Transform3D = bank.multimesh.get_instance_transform(i)
			var local := to_local(bank.to_global(tuft.origin))
			for j in range(1,path.size()):
				if Geometry3D.get_closest_point_to_segment(local,path[j-1],path[j]).distance_to(local) <= radius:
					tuft.origin.y -= 1200.0
					bank.multimesh.set_instance_transform(i,tuft)
					break

func _dust(game, point: Vector3, size: float) -> void:
	var spray := ImpactSpray.new()
	game.add_child(spray)
	spray.build(to_global(point), global_basis.y, ImpactSpray.Surface.STONE, size, game.settings["reduced_effects"])
	game.impact_sprays.append(spray)

func _eye_lost(i: int) -> void:
	beams[i].hide()
	firing[i] = false
	if eyes[0].destroyed and eyes[1].destroyed:
		state = State.FALLING
		age = 0.0
		fall_start = centers.duplicate()
		fall_facing = facing

func _lasers(game, previous: Vector3, pilot: Vector3, delta: float) -> void:
	# Both pupils strike on the same beat. Aim at opposite sides of the
	# canopy so the two hot cores remain visible even on a head-on pass.
	var t := age - RISE_TIME
	var pulse := fposmod(t, VOLLEY_PERIOD)
	var live := t > 0.0 and pulse >= CHARGE_TIME and pulse < BEAM_END
	var volley_started := false
	var across: Vector3 = (global_basis.inverse() * game.camera.global_basis.x).normalized()
	for i in 2:
		if eyes[i].destroyed:
			continue
		var origin := to_local(eyes[i].global_position)
		if not live:
			var shoulder := signf((origin-centers[-1]).dot(across))
			aim[i] = pilot + (pilot-previous) / delta * 0.12 + across * shoulder * 0.85
			dealt[i] = false
			beams[i].hide()
		else:
			if not firing[i]:
				volley_started = true
			var direction := origin.direction_to(aim[i])
			var end := origin + direction * 350.0
			var ray := PhysicsRayQueryParameters3D.create(to_global(origin), to_global(end), 1)
			var cover := get_world_3d().direct_space_state.intersect_ray(ray)
			if not cover.is_empty():
				end = to_local(cover.position)
			_place_beam(beams[i], origin, end)
			var closest := Geometry3D.get_closest_points_between_segments(origin, end, previous, pilot)
			if not dealt[i] and closest[0].distance_squared_to(closest[1]) < pow(game.flight.collision_radius + 0.78, 2):
				dealt[i] = game._apply_pilot_damage("SERPENT EYE BEAM", 14.0)
		firing[i] = live
	if volley_started:
		game.sound.play_cue("enemy_laser")

func _advance_stones(game, delta: float, previous: Vector3, pilot: Vector3) -> void:
	for i in range(stones.size()-1, -1, -1):
		var rock: Dictionary = stones[i]
		var node: Node3D = rock.node
		var start := node.position
		node.position += rock.velocity*delta + Vector3.DOWN * (0.5*GRAVITY*delta*delta)
		rock.velocity += Vector3.DOWN*GRAVITY*delta
		node.rotation += rock.spin*delta
		var relative := Geometry3D.get_closest_point_to_segment(Vector3.ZERO, previous-start, pilot-node.position)
		var hit: bool = relative.length() < game.flight.collision_radius + rock.radius
		if hit:
			game._apply_pilot_damage("BURROW EJECTA", 21.0)
		var impacted := _world_contact(game, start, node.position, rock.radius, 4)
		if hit or impacted or node.position.y < rock.radius:
			node.queue_free()
			stones.remove_at(i)

func _crush(game, old: PackedVector3Array, previous: Vector3, pilot: Vector3) -> void:
	for i in range(1,JOINTS):
		var radius := lerpf(2.4, 3.75, sin(PI*i/JOINTS))
		var segment := Geometry3D.get_closest_points_between_segments(centers[i-1], centers[i], previous, pilot)
		if not struck_ship and segment[0].distance_to(segment[1]) < radius + game.flight.collision_radius:
			struck_ship = game._apply_pilot_damage("FALLEN BURROW SERPENT", 48.0)
		if not old.is_empty():
			var relative := Geometry3D.get_closest_point_to_segment(Vector3.ZERO, previous - old[i], pilot - centers[i])
			if not struck_ship and relative.length() < radius + game.flight.collision_radius:
				struck_ship = game._apply_pilot_damage("FALLING BURROW SERPENT", 48.0)
			_world_contact(game, centers[i-1], centers[i], radius, 10000)
			if old[i].distance_to(centers[i]) > radius:
				_world_contact(game, old[i], centers[i], radius, 10000)

func _world_contact(game, a: Vector3, b: Vector3, radius: float, damage: int) -> bool:
	var start := to_global(a)
	var end := to_global(b)
	var length := start.distance_to(end)
	contact_shape.radius = radius
	contact_shape.height = length + 2.0*radius
	var axis := (end-start)/length if length > 0.0001 else Vector3.UP
	query.transform = Transform3D(Basis(Quaternion(Vector3.UP, axis)), (start+end)*0.5)
	var touched := false
	var seen := {}
	for contact in get_world_3d().direct_space_state.intersect_shape(query, 64):
		var body: CollisionObject3D = contact.collider
		var shape := body.shape_owner_get_owner(body.shape_find_owner(contact.shape))
		if shape.has_meta("serpent_scenery"):
			var batch: MultiMeshInstance3D = shape.get_meta("serpent_scenery")
			if not shape.disabled:
				_make_placements_local(batch)
				var index: int = shape.get_meta("placement_index")
				var placement := batch.multimesh.get_instance_transform(index)
				placement.origin.y -= 1200.0
				batch.multimesh.set_instance_transform(index, placement)
				shape.disabled = true
				touched = true
			continue
		if body is EnemyMissile and body.active:
			body.receive_hit()
			touched = true
			continue
		if game.ground_branch != null and body == game.ground_branch.patrol.storm_hull:
			game._storm_contact(body, end, axis)
			touched = true
			continue
		var actor: Node = body
		while actor != null and actor != game.world and not actor is RangeTarget and not actor.has_meta("xylo_rover"):
			actor = actor.get_parent()
		if actor == null or actor == game.world or actor is BurrowEye or seen.has(actor):
			continue
		seen[actor] = true
		if not actor.is_visible_in_tree():
			continue
		if actor is RangeTarget and not actor.destroyed:
			var killed: bool = actor.receive_hit_at(damage, end, axis) if actor is DestructibleTower else actor.receive_hit(damage)
			if killed and not actor is DestructibleTower:
				game._spawn_breakup(actor, true)
		elif actor.has_meta("xylo_rover"):
			game._spawn_breakup(actor, true)
			actor.hide()
		touched = true
	return touched

static func _make_placements_local(batch: MultiMeshInstance3D) -> void:
	if batch.has_meta("damaged"):
		return
	# Terrain chunks share their cached instance buffers between sorties.
	var source := batch.multimesh
	var local := MultiMesh.new()
	local.transform_format = source.transform_format
	local.use_custom_data = source.use_custom_data
	local.mesh = source.mesh
	local.instance_count = source.instance_count
	for key in source.get_meta_list():
		local.set_meta(key, source.get_meta(key))
	for i in source.instance_count:
		local.set_instance_transform(i, source.get_instance_transform(i))
		if source.use_custom_data:
			local.set_instance_custom_data(i, source.get_instance_custom_data(i))
	batch.multimesh = local
	batch.set_meta("damaged", true)

static func _make_beam() -> Node3D:
	var beam := Node3D.new()
	for i in 2:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.105 if i == 0 else 0.38
		mesh.bottom_radius = mesh.top_radius
		mesh.height = 1.0
		mesh.radial_segments = 8
		mesh.rings = 0
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/burrow_eye_beam.gdshader")
		material.set_shader_parameter("corona", i == 1)
		var core := MeshInstance3D.new()
		core.mesh = mesh
		core.material_override = material
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.add_child(core)
	return beam

static func _place_beam(beam: Node3D, a: Vector3, b: Vector3) -> void:
	var span := b-a
	if span.length_squared() < 0.0001:
		beam.hide()
		return
	beam.transform = Transform3D(Basis(Quaternion(Vector3.UP,span.normalized())).scaled_local(Vector3(1,span.length(),1)), (a+b)*0.5)
	beam.show()
