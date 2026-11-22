extends SceneTree

var failures: int = 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fixture-output="):
			var state := CampaignState.new()
			state.phase = "market"
			state.sector = "cryo"
			state.reward(5000)
			state.purchase("primary")
			state.purchase("secondary")
			var store := CampaignStore.new(argument.trim_prefix("--fixture-output="))
			if store.save_game(state) != OK:
				push_error(store.message)
				quit(1)
				return
			print("INSTALLER_FIXTURE_FAILURES=0")
			quit(0)
			return
	call_deferred("run")

func run() -> void:
	verify_recovery()
	await verify_ice()
	await verify_gameplay()
	await verify_backdrop_bounds()
	verify_recordings()
	print("RELEASE_POLISH_FAILURES=", failures)
	quit(failures)

func verify_recovery() -> void:
	for fps in [30, 45, 120]:
		var flight := FlightState.new()
		flight.training = false
		flight.impact("MISSILE", EnemyMissile.DAMAGE)
		for _i in range(fps):
			flight.advance(1.0 / fps, false)
		check(is_equal_approx(flight.shields, 86), "Ordinary missile deals fourteen shield-first damage; recovery waits at %d Hz" % fps)
		for _i in range(fps):
			flight.advance(1.0 / fps, false)
		check(is_equal_approx(flight.shields, 88.5), "Exactly half a second of shield recovery occurs after the 1.5-second delay at %d Hz" % fps)
	var combined := FlightState.new()
	combined.training = false
	combined.impact("MISSILE", EnemyMissile.DAMAGE)
	combined.advance(2, false)
	check(combined.shields == 88.5, "Crossing the recovery deadline in one step cannot grant early recharge")
	combined.impact_cooldown = 0
	combined.impact("ACID", XyloField.ACID_DAMAGE)
	check(combined.shields == 70.5, "The approved acid hazard remains eighteen damage")

func verify_ice() -> void:
	for fps in [30, 45, 120]:
		var parent := Node3D.new()
		parent.transform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(800, 200, -500))
		root.add_child(parent)
		var ice := FallingIce.new()
		ice.travel = 560
		ice.lane.x = 8
		parent.add_child(ice)
		var at: Vector3 = parent.global_transform * Vector3(ice.position.x, 12, -420)
		ice.advance(0.1, at, at, 0.6)
		check(ice.warning() and ice.position.y == FallingIce.DROP_HEIGHT, "Falling ice begins with a visible, stationary warning at %d Hz" % fps)
		var held: Vector3 = ice.position
		var clock: float = ice.age
		ice.advance(0, at, at, 0.6)
		check(ice.position == held and ice.age == clock, "A held ice simulation does not consume warning time")
		var hits: int = 0
		ice.age = 0
		for i in range(fps * 5):
			var previous: Vector3 = parent.global_transform * Vector3(ice.position.x, 12, -420 - i * FlightState.SPEED / fps)
			var pilot: Vector3 = parent.global_transform * Vector3(ice.position.x, 12, -420 - (i + 1) * FlightState.SPEED / fps)
			hits += int(ice.advance(1.0 / fps, previous, pilot, 0.6))
			if i + 1 < fps * 2:
				check_once(i + 1 == fps * 2 - 1, ice.position.y == FallingIce.DROP_HEIGHT, "The two-second warning cannot cause a premature fall")
		check(hits == 1 and ice.expired and ice.collision_layer == 0, "One side-lane crossing causes one contact, then clears the fallen chunk at %d Hz" % fps)
		parent.queue_free()
		await process_frame
	var world := Node3D.new()
	root.add_child(world)
	for side in [-8.0, 8.0]:
		var ice := FallingIce.new()
		ice.travel = 560
		ice.lane.x = side
		world.add_child(ice)
		var hits: int = 0
		for i in range(300):
			var from: Vector3 = FlightState.rail_point(420 + i * FlightState.SPEED / 60)
			var to: Vector3 = FlightState.rail_point(420 + (i + 1) * FlightState.SPEED / 60)
			hits += int(ice.advance(1.0 / 60, from, to, 0.6))
		check(hits == 0, "A falling chunk cannot hit the automatic centerline from lane %.0f" % side)
	world.queue_free()
	await process_frame

func verify_gameplay() -> void:
	var game: Node3D = load("res://main.tscn").instantiate()
	game.automation = "--unit-fixture"
	game.normal_save_path = "user://polish-test-%d.json" % OS.get_process_id()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.campaign = CampaignState.new()
	game.campaign.sector = "cryo"
	game.campaign.phase = "ground"
	game.is_campaign = true
	await game._load_phase()
	game._process(0.0)
	check(game.music.requested == "cryo", "Cryo ground flight requests its world theme")
	check(game.falling_ice.size() == 8 and game.flight.duration == 90, "Cryo has eight side-lane chunks without consuming ground-combat time")
	var chunk: FallingIce = game.falling_ice[0]
	var credits: int = game.campaign.credits
	var kills: int = game.campaign.stats["enemies"]
	var streak: int = game.campaign.combo_kills
	var hit: Dictionary = {"collider": chunk, "position": chunk.global_position}
	check(game._strike(hit, 1) and not chunk.destroyed and game._strike(hit, 1) and chunk.destroyed, "Two actual baseline weapon hits shatter hanging ice")
	check(game.campaign.credits == credits and game.campaign.stats["enemies"] == kills and game.campaign.combo_kills == streak, "Clearing environmental ice cannot farm credits, enemy kills or streaks")
	check(not game._strike(hit, 1), "A shattered chunk cannot record another hit")
	game.flight.shields = 10
	game.flight.hull = 100
	game._missile_impact()
	check(game.flight.shields == 0 and game.flight.hull == 96 and game.campaign.hull_damage == 4, "Real missile impact applies the gentler damage through shield overflow and campaign damage accounting")
	game.flight.impact_cooldown = 0
	game._apply_pilot_damage("FALLING ICE", FallingIce.DAMAGE)
	check(game.flight.hull == 82 and game.flight.frost_remaining == 0, "Falling ice contact applies fourteen damage without freezing controls")
	var untouched: FallingIce = game.falling_ice[1]
	var age: float = untouched.age
	game.pause_flight()
	game._physics_process(3)
	check(untouched.age == age, "The actual pause path freezes falling ice")
	game.resume_flight()
	game.campaign.phase = "ground_boss"
	await game._load_phase()
	game._process(0.0)
	check(game.music.requested == "cryo", "Entering a boss keeps the current world's theme")
	check(game.falling_ice.is_empty(), "Ground boss entry cannot retain old falling-ice hazards")
	game.campaign.sector = "ignis"
	game.campaign.phase = "ground"
	await game._load_phase()
	check(game.falling_ice.is_empty(), "Falling ice does not leak into other planetary environments")
	game.queue_free()
	await process_frame

func verify_backdrop_bounds() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	var backdrop := BeltBackdrop.new()
	parent.add_child(backdrop)
	backdrop.build(Transform3D.IDENTITY, true)
	var all_enclosed: bool = true
	for batch in backdrop.batches:
		for mesh: MultiMesh in batch["meshes"]:
			var extent: AABB = mesh.mesh.get_aabb()
			for i in range(mesh.instance_count):
				var source: Transform3D = batch["transforms"][i]
				for angle in [0.0, 1.1, 2.8]:
					var pose: Transform3D = source
					pose.basis = Basis(batch["axes"][i], angle) * source.basis
					for corner in range(8):
						var vertex: Vector3 = extent.get_endpoint(corner)
						all_enclosed = all_enclosed and mesh.custom_aabb.has_point(pose * vertex)
	check(all_enclosed, "Cached backdrop bounds enclose every tested rotating mesh, including both giant forms")
	parent.queue_free()
	await process_frame

func verify_recordings() -> void:
	var credits := FileAccess.get_file_as_string("res://assets/music/credits.txt")
	check("Kevin MacLeod" in credits and "https://creativecommons.org/licenses/by/4.0/" in credits, "Music credits name the artist and license")
	var titles: Array = AmbientMusic.TRACKS.values()
	titles.append("Fanfare for Space")
	for title: String in titles:
		var stream := load("res://assets/music/licensed/%s.ogg" % title) as AudioStreamOggVorbis
		check(stream != null and stream.get_length() > 30 and title in credits, "Packaged and credited recording: " + title)
	for sector: String in SectorCatalog.AVAILABLE:
		check(AmbientMusic.TRACKS.has(sector) and titles.count(AmbientMusic.TRACKS[sector]) == 1, "Exclusive world theme: " + sector)
	for effect: AudioStreamWAV in [SynthAudio.ORGANIC_RUPTURE, SynthAudio.TARGET_IGNITION]:
		check(effect.get_length() > 0.4 and effect.get_length() < 1 and effect.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Destruction uses one short, non-looping take")

func check_once(when: bool, condition: bool, description: String) -> void:
	if when:
		check(condition, description)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
