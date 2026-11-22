extends SceneTree

var failures := 0
const PILOT := Vector3(0, 9, 110)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func hit(part: BossPart) -> void:
	check(part.unlocked, "Route requires an accessible subsystem")
	part.receive_hit(part.maximum_armor)

func run() -> void:
	for sector in SectorCatalog.AVAILABLE:
		for orbital in [false, true]:
			verify_contract(sector, orbital)
		await verify_tower(sector)
	verify_turret()
	await process_frame
	print("SIEGE_TACTICS_FAILURES=", failures)
	quit(failures)

func verify_contract(sector: String, orbital: bool) -> void:
	var boss := BossEncounter.new()
	boss.sector = sector
	boss.orbital = orbital
	root.add_child(boss)
	boss.advance(0.01, PILOT, Vector3.ZERO)
	var armor := boss.core.armor
	boss.core.receive_hit(1000)
	check(boss.core.armor == armor and is_equal_approx(boss.health_fraction(), 1), "Unbroken interlocks protect the " + sector + " reactor")
	match sector:
		"ignis":
			if orbital:
				hit(boss.thermal_emitter)
			else:
				hit(boss.parts[0])
				hit(boss.parts[1])
		"cryo":
			hit(boss.parts[0])
			if orbital:
				hit(boss.drone_bay)
			else:
				boss.advance(0.01, PILOT, Vector3.ZERO)
				check(boss.core.unlocked, "Coolant loss opens the vent immediately")
				boss.advance(4.1, PILOT, Vector3.ZERO)
				check(not boss.core.unlocked and boss.objective().contains("SEALED"), "Glacier vent reseals between opportunities")
				boss.advance(3.0, PILOT, Vector3.ZERO)
		"vespera":
			hit(boss.radars[1])
			hit(boss.radars[0])
		"xylo":
			if orbital:
				for i in [1, 2, 4]:
					hit(boss.turrets[i])
			else:
				hit(boss.parts[0])
				hit(boss.parts[1])
		"thalassa":
			hit(boss.parts[1])
			if orbital:
				hit(boss.turrets[1])
				hit(boss.turrets[4])
			else:
				hit(boss.parts[0])
		"kharon":
			if orbital:
				for turret in boss.turrets:
					hit(turret)
			else:
				boss.parts[1].receive_hit(5000)
				check(not boss.parts[1].destroyed, "The right relay resists fire while the left carries power")
				hit(boss.parts[0])
				boss.advance(0.01, PILOT, Vector3.ZERO)
				hit(boss.parts[1])
	var direct := (sector == "thalassa" and not orbital) or (sector == "kharon" and orbital)
	if direct:
		check(boss.defeated() and not boss.core.destroyed, "Ballast and magazine routes resolve immediately on the lethal subsystem hit")
	else:
		boss.advance(0.02, PILOT, Vector3.ZERO)
		check(boss.health_fraction() > 0 and boss.health_fraction() < 1 and boss.core.unlocked, "Completing the " + sector + " interlock exposes the core")
		hit(boss.core)
	check(boss.defeated() and is_zero_approx(boss.health_fraction()), "Legal subsystem strategy completes " + sector)
	check(boss.recon_bounty() == (0 if sector == "vespera" else 75), "Only intact tracking hardware grants a salvage reward")
	boss.begin_destruction()
	boss.advance(0.7, PILOT, Vector3.ZERO)
	check(boss.model.position.y < 0, "Disabled hull settles on its final trajectory")
	boss.free()

func verify_tower(sector: String) -> void:
	var tower := DestructibleTower.new()
	tower.sector = sector
	root.add_child(tower)
	await physics_frame
	await physics_frame
	var mesh := FleetArt.mesh_for("tower_" + sector, "ground")
	var points: PackedVector3Array = mesh.get_meta("fragment_vertices")
	var triangles: PackedInt32Array = mesh.get_meta("fragment_indices")
	for band in range(3):
		var sample := Vector3.ZERO
		var area := 0.0
		for i in range(0, triangles.size(), 3):
			var a := points[triangles[i]]
			var b := points[triangles[i + 1]]
			var c := points[triangles[i + 2]]
			var center := (a + b + c) / 3.0
			if (2 if center.y >= 1.55 else 1 if center.y >= -2.6 else 0) != band:
				continue
			var projected := absf((b-a).cross(c-a).z)
			if projected > area:
				area = projected
				sample = center
		var ray := PhysicsRayQueryParameters3D.create(sample + Vector3.BACK * 15, sample + Vector3.FORWARD * 15, 3)
		var contact := tower.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not contact.is_empty() and contact["collider"] == tower, "Physical ray reaches %s tower band %s" % [sector, band])
		if not contact.is_empty():
			if band == 0:
				var incoming := EnemyMissile.new()
				incoming.position = sample + Vector3.BACK * 15
				incoming.direction = Vector3.FORWARD
				incoming.age = 1.0
				root.add_child(incoming)
				incoming.advance(0.4, PILOT, PILOT, 0.6)
				check(not incoming.active and tower.armor == 3, "A real hostile missile strikes tower cover before passing it")
				incoming.free()
			elif sector == "ignis":
				var heading := Vector3(0.48 if band == 1 else -0.52, 0, -1).normalized()
				var projectile: Node3D = PlasmaBolt.new() if band == 1 else PlayerTorpedo.new()
				projectile.direction = heading
				projectile.position = sample - heading * 15
				var contacts: Array[Dictionary] = []
				projectile.impacted.connect(func(result: Dictionary) -> void: contacts.append(result))
				root.add_child(projectile)
				projectile.advance(0.2)
				check(contacts.size() == 1 and contacts[0]["collider"] == tower and heading.is_equal_approx(contacts[0]["direction"]), "Player projectile supplies its actual incoming direction to the tower")
				projectile.free()
			tower.receive_hit_at(20, contact["position"], Vector3.RIGHT)
			check(tower.break_band == band and tower.stump.get_child_count() == band, "Strike leaves the matching lower structure standing")
			tower.advance(2.0)
			check(tower.has_fractured and not tower.pivot.visible, "Detached wreck completes its own fracture")
		tower.reset()
		await physics_frame
	tower.free()

func verify_turret() -> void:
	var gun := BossTurret.new()
	root.add_child(gun)
	gun.cooldown = 0.22
	gun.receive_hit(1)
	check(gun.cooldown > 1 and gun.interrupted, "A hit during the ignition window aborts that salvo")
	gun.advance(0.20, PILOT, Vector3.ZERO)
	check(gun.launches == 0, "An interrupted projectile is withheld")
	gun.advance(2, PILOT, Vector3.ZERO)
	check(gun.launches == 1 and gun.recoil == 1, "The turret recovers and visibly recoils on firing")
	gun.free()
