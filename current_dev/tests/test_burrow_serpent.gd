extends SceneTree

var game: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	print("PASS: " if value else "FAIL: ", description)
	if not value:
		failures += 1

func move_pilot(distance: float) -> void:
	game.flight.distance = distance
	game.flight.elapsed = distance / game.flight.speed
	game.director.advance("ground", 0, distance, game.flight.elapsed, game.targets)
	game._stream_ground(distance)
	game._update_camera()

func surface_hit(snake: BurrowSerpent) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(snake.to_global(Vector3.UP*0.4), snake.to_global(Vector3.DOWN*0.4), 1)
	return not snake.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func frame_image() -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	return image

func verify_visible_pair(snake: BurrowSerpent) -> void:
	var pair := await frame_image()
	for i in 2:
		snake.beams[i].hide()
		var single := await frame_image()
		snake.beams[i].show()
		var red_pixels := 0
		for y in range(36, 275):
			for x in range(75, 565):
				var lit := pair.get_pixel(x, y)
				var other := single.get_pixel(x, y)
				if lit.r > other.r + 0.09 and lit.r > lit.g + 0.15:
					red_pixels += 1
		check(red_pixels > 22, "Eye %d contributes its own visible red beam in the cockpit (%d pixels)" % [i, red_pixels])

func run() -> void:
	root.unfocusable = true
	root.mouse_passthrough = true
	game = load("res://main.tscn").instantiate()
	game.automation = "--native-fixture"
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.campaign = CampaignState.new()
	game.campaign.phase = "ground"
	game.campaign.sector = "xylo"
	game.is_campaign = true
	await game._load_phase()
	var snake: BurrowSerpent = game.burrow_serpent
	var trigger := XyloArt.SERPENT_TRAVEL - BurrowSerpent.APPROACH
	move_pilot(trigger - 4.0)
	await physics_frame
	await physics_frame
	check(surface_hit(snake) and not snake.model.visible and not snake.collar.visible, "Intact, solid turf hides both the creature and its burrow")
	move_pilot(trigger + 2.0)
	var pilot: Vector3 = game.camera.global_position
	snake.advance(game, 0.02, pilot, pilot)
	await physics_frame
	await physics_frame
	check(not surface_hit(snake) and snake.collar.visible and snake.state == BurrowSerpent.State.RISING, "The eruption opens a real hole in the roadside floor")
	check(snake.stones.size() >= 12, "The eruption throws a fan of physical stones")
	# Put the pilot in a moving rock's swept path, then test collateral
	# against an actual course tower through the same contact routine.
	var rock: Dictionary = snake.stones.back()
	var start: Vector3 = rock.node.position
	game.flight.impact_cooldown = 0
	var shields: float = game.flight.shields
	snake._advance_stones(game, 0.016, start, start)
	check(game.flight.shields < shields, "A thrown rock damages the ship")
	var tower: DestructibleTower = game.towers[4]
	var tower_at := snake.to_local(tower.aim_point())
	var armor := tower.armor
	snake._world_contact(game, tower_at - Vector3.RIGHT*3.0, tower_at + Vector3.RIGHT*3.0, 2.2, 4)
	check(tower.armor < armor and not tower.destroyed, "Rock damage also reaches the nearby Xylo pylon")
	move_pilot(759.0)
	pilot = game.camera.global_position
	for i in 115:
		snake.advance(game, 1.0/60.0, pilot, pilot)
	await physics_frame
	await physics_frame
	check(snake.state == BurrowSerpent.State.HUNTING and snake.eyes.all(func(e: BurrowEye) -> bool: return e.collision_layer == 2), "Both eyes become independent weapon targets on emergence")
	game.flight.impact_cooldown = 0
	shields = game.flight.shields
	var simultaneous := 0
	var mismatched := 0
	for i in 115:
		snake.advance(game, 1.0/60.0, pilot, pilot)
		if snake.beams[0].visible != snake.beams[1].visible:
			mismatched += 1
		if snake.beams[0].visible and snake.beams[1].visible:
			simultaneous += 1
			if simultaneous == 4 and DisplayServer.get_name() != "headless":
				await verify_visible_pair(snake)
			for j in 2:
				var beam := snake.beams[j]
				var beam_start := beam.to_global(Vector3.DOWN * 0.5)
				if beam_start.distance_to(snake.eyes[j].global_position) > 0.05:
					mismatched += 1
	check(simultaneous > 28 and mismatched == 0, "Both healthy eyes fire together for the full volley, each beam starting at its own pupil")
	check(game.flight.shields < shields, "A live eye beam damages a pilot who holds position")
	for i in 2:
		var eye := snake.eyes[i]
		game.cursor = game.camera.unproject_position(eye.global_position)
		game.flight.primary_level = 0
		for shot in 2:
			game.fire_primary()
		check(eye.destroyed, "Cockpit primary fire can shoot out eye %d" % i)
		if i == 0:
			var second_fired := false
			var first_fired := false
			for frame in 100:
				snake.advance(game, 1.0/60.0, pilot, pilot)
				first_fired = first_fired or snake.beams[0].visible
				second_fired = second_fired or snake.beams[1].visible
			check(not first_fired and second_fired and snake.state == BurrowSerpent.State.HUNTING, "Shooting one eye stops only its laser")
			await physics_frame
			await physics_frame
	check(snake.state == BurrowSerpent.State.FALLING, "Blinding both eyes starts the articulated fall")
	if snake.state == BurrowSerpent.State.FALLING:
		for i in 100:
			snake.advance(game, 1.0/60.0, pilot, pilot)
		check(tower.destroyed, "The falling body destroys the pylon beside the track")
		check(snake.state == BurrowSerpent.State.DOWN and snake.centers[-1].x < -30.0, "The serpent comes to rest across the flight path")
		game.flight.impact_cooldown = 0
		shields = game.flight.shields + game.flight.hull
		var across := snake.to_global(snake.centers[6])
		snake.advance(game, 0.016, across+Vector3.UP*25, across+Vector3.UP*26)
		check(game.flight.shields + game.flight.hull == shields, "A ship flying above the fallen body clears it")
		snake.advance(game, 0.016, across + snake.global_basis.z*8, across - snake.global_basis.z*8)
		check(game.flight.shields + game.flight.hull < shields, "A ship crossing the fallen body takes collision damage")
	await game._load_phase()
	move_pilot(550)
	await physics_frame
	await physics_frame
	check(surface_hit(game.burrow_serpent) and game.burrow_serpent.state == BurrowSerpent.State.BURIED, "A new sortie restores intact terrain and a fresh encounter")
	game.free()
	print("BURROW_SERPENT_FAILURES=", failures)
	quit(failures)
