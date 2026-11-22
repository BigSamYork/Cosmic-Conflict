extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for variant in range(AsteroidArt.VARIANTS):
		var model: Node3D = AsteroidArt.create(variant, Color.WHITE)
		var hull: MeshInstance3D = model.get_child(0)
		var vertices: PackedVector3Array = hull.mesh.get_meta("fragment_vertices")
		var bound: float = 0.0
		for vertex in vertices:
			bound = maxf(bound, vertex.length())
		check(bound < 1.25 and vertices.size() > 500, "Cratered variant %d stays inside its collision envelope" % variant)
		var center: Vector3 = AsteroidArt.crater_center(0, variant)
		var tangent: Vector3 = center.cross(Vector3.UP).normalized()
		var edge: Vector3 = center * cos(AsteroidArt.crater_radius(0)) + tangent * sin(AsteroidArt.crater_radius(0))
		check(AsteroidArt.point(center, variant).length() < AsteroidArt.point(edge, variant).length(), "Variant %d has a recessed crater rather than a painted circle" % variant)
		model.free()
	var pickup := MineralPickup.new()
	pickup.position = Vector3(10, 0, 0)
	root.add_child(pickup)
	var original: Vector3 = pickup.position
	pickup.advance(0.1, Vector3.ZERO, Vector3.ZERO, false)
	check(pickup.position == original and pickup.active, "Without a tractor, distant mineral cores require manual collection")
	var collected: bool = false
	for _i in range(20):
		if pickup.advance(0.02, Vector3.ZERO, Vector3.ZERO, true):
			collected = true
			break
	check(collected and not pickup.active and not pickup.advance(0.1, Vector3.ZERO, Vector3.ZERO, true), "Tractor pulls in a core and allows only one collection")
	pickup.queue_free()
	var swept := MineralPickup.new()
	root.add_child(swept)
	check(swept.advance(0.1, Vector3(-10, 0, 0), Vector3(10, 0, 0), false), "Fast flight through a core uses swept collection detection")
	swept.queue_free()
	var cover := StaticBody3D.new()
	cover.position = Vector3(5, 0, 0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 8, 8)
	collision.shape = shape
	cover.add_child(collision)
	root.add_child(cover)
	var occluded := MineralPickup.new()
	occluded.position = Vector3(10, 0, 0)
	root.add_child(occluded)
	await physics_frame
	await physics_frame
	occluded.advance(0.1, Vector3.ZERO, Vector3.ZERO, true)
	check(occluded.position == Vector3(10, 0, 0) and not occluded.being_pulled, "The tractor does not pull mineral cores through solid rocks")
	occluded.advance(MineralPickup.LIFETIME, Vector3.ZERO, Vector3.ZERO, false)
	check(not occluded.active, "Uncollected cores expire without a reward")
	occluded.queue_free()
	cover.queue_free()
	await process_frame
	var scene: PackedScene = load("res://main.tscn")
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.start_flight()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2.ZERO
	var scripted_cursor: Vector2 = game.cursor
	game.automation = "--belt-benchmark"
	game._unhandled_input(motion)
	var ignored_live_motion: bool = game.cursor == scripted_cursor
	game.automation = ""
	game._unhandled_input(motion)
	check(ignored_live_motion and game.cursor == Vector2.ZERO, "Scripted belt aim ignores desktop mouse motion without disabling interactive steering")
	game.pause_flight()
	game.set_physics_process(false)
	game.set_process(false)
	game.campaign = CampaignState.new()
	game.is_campaign = true
	game.flight.configure_campaign(game.campaign)
	game.camera.global_position = Vector3(0, 0, 8)
	game.targets.clear()
	var rocks: Array[Asteroid] = []
	for index in range(4):
		var rock := Asteroid.new()
		rock.radius = 2.0
		rock.volatile = index <= 1
		rock.mineral = index == 2
		rock.indestructible = index == 3
		game.add_child(rock)
		rock.global_position = Vector3(index * 4.0, 0, 0)
		rocks.append(rock)
		game.targets.append(rock)
	game._strike({"collider": rocks[0], "position": rocks[0].global_position}, 2)
	check(game.volatile_blasts.size() == 1 and game.campaign.stats["asteroids"] == 1, "Destroying a volatile rock starts one telegraphed blast")
	var shield: float = game.flight.shields
	var clock: float = game.volatile_blasts[0].age
	game._physics_process(1.0)
	check(game.volatile_blasts[0].age == clock and game.flight.shields == shield, "Pause freezes the volatile fuse and pilot damage")
	game._advance_salvage(VolatileBlast.FUSE - 0.01, game.camera.position, game.camera.position)
	check(game.flight.shields == shield, "Volatile damage waits until the warning fuse ends")
	game._advance_salvage(0.02, game.camera.position, game.camera.position)
	check(game.flight.shields == shield - VolatileBlast.DAMAGE, "An approved close-range volatile blast damages the pilot")
	check(rocks[1].destroyed and rocks[2].destroyed and not rocks[3].destroyed, "Blast destroys nearby ordinary/volatile rocks but preserves iron cores")
	check(game.volatile_blasts.size() == 2 and game.mineral_pickups.size() == 1, "A chain schedules another blast and releases a mineral core")
	var credited: int = game.campaign.credits
	var hits: int = game.flight.hits
	game._advance_salvage(VolatileBlast.FUSE, game.camera.position, game.camera.position)
	check(game.campaign.credits == credited and game.flight.hits == hits and game.campaign.combo_kills == 0, "Chain reactions cannot duplicate rewards or inflate accuracy/combat streaks")
	var core: MineralPickup = game.mineral_pickups[0]
	game._advance_salvage(0.01, core.global_position, core.global_position)
	check(game.campaign.stats["minerals"] == 1 and game.campaign.credits == credited, "Mineral collection records salvage and leaves the wallet alone")
	game._clear_stage()
	check(game.mineral_pickups.is_empty() and game.volatile_blasts.is_empty(), "Phase cleanup removes uncollected cores and outstanding blasts")
	game.queue_free()
	await process_frame
	print("ASTEROID_MINING_FAILURES=", failures)
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
