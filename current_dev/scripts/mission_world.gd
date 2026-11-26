class_name MissionWorld
extends Node3D

signal missile_requested(origin: Vector3, direction: Vector3)
signal sweep_requested(emitter: ThermalEmitter)
signal rock_shattered(rock: Asteroid)
signal encounter_notice(text: String)
const CrossingRock := preload("res://scripts/crossing_rock.gd")
const DOGFIGHT_BRIEFS := {
	"ignis": "SOLAR SLINGSHOT / LEAD THE BOOSTING INTERCEPTORS",
	"cryo": "FROST RELAY / BREAK A GUNSHIP TO STUN ITS ESCORTS",
	"vespera": "PHASE SKIP / SCOUTS CAN BLINK AFTER THE FIRST HIT",
	"xylo": "BROOD NURSE / SEPARATE ESCORTS FROM THEIR HEAVY",
	"thalassa": "FORKED SALVOS / WATCH BOTH WINGTIPS",
	"kharon": "SENTRY ANCHOR / FLANK THE BRAKING GUNSHIPS",
}
var crossing: CrossingRock
var event_rng := RandomNumberGenerator.new()
var crossing_clock := 0.0
var next_meteor := false
var nurse_clock := 0.0
var targets: Array[RangeTarget] = []
var boss: BossEncounter
var phase: String = ""
var sector: String = "ignis"
var health_scale: float = 1.0
var wave_clock: float = 0.0
var wave_index: int = 0
var elapsed: float = 0.0
var backdrop: BeltBackdrop
var webs: Array[LaserWeb] = []
var pilot_frame: Transform3D
var web_index: int = 0
var pending_webs: int = 0
var pirates: Array[PirateSkirmisher] = []
var pirate_index: int = 0
var asteroid_course: Transform3D
var visual_time: float = 0.0
var drone_clock: float = 3.0
var carrier_drones: Array[EnemyFighter] = []
var drone_launches: int = 0

func build(next_phase: String, entry: Transform3D = Transform3D.IDENTITY, destination: String = "ignis", arrival: PackedVector3Array = PackedVector3Array()) -> void:
	phase = next_phase
	sector = destination
	crossing_clock = event_rng.randf_range(8.0, 15.0)
	next_meteor = event_rng.randf() < 0.5
	if phase.ends_with("_boss"):
		boss = BossEncounter.new()
		boss.orbital = phase == "orbit_boss"
		boss.sector = sector
		boss.health_scale = health_scale
		add_child(boss)
		boss.configure_pursuit(entry)
		boss.missile_requested.connect(func(at: Vector3, direction: Vector3) -> void: missile_requested.emit(at, direction))
		boss.sweep_requested.connect(func(emitter: ThermalEmitter) -> void: sweep_requested.emit(emitter))
		targets.assign(boss.parts)
	elif phase == "orbit":
		spawn_wave(entry)
	elif phase == "asteroids":
		asteroid_course = entry
		if sector == "xylo":
			_build_hive(entry, arrival)
			return
		for i in range(58):
			var travel: float = 70 + i * 51.0
			for slot in range(4):
				var asteroid := Asteroid.new()
				asteroid.travel = travel + (9 if slot % 2 == 1 else 0)
				asteroid.radius = 5.0 + (i % 4) * 1.2
				asteroid.variant = (i + slot) % AsteroidArt.VARIANTS
				asteroid.near_pass = slot < 2
				asteroid.phase = i * 1.7 + slot
				asteroid.indestructible = slot < 2 and (i + (1 if slot == 1 else -1)) % 3 == 0
				asteroid.volatile = not asteroid.indestructible and i % 7 == 2 and slot % 2 == 0
				asteroid.mineral = not asteroid.indestructible and not asteroid.volatile and i % 5 == 0
				asteroid.routed = true
				asteroid.course = entry
				var angle: float = i * 1.4 + (PI if slot % 2 == 0 else 0.0) + (0.22 if slot >= 2 else 0.0)
				var clearance: float = asteroid.collision_radius() + (3.3 if slot < 2 else 20.0 + (i % 3) * 7.0)
				var corridor: Transform3D = FlightDirector.asteroid_frame(asteroid.travel)
				asteroid.course_position = corridor * Vector3(cos(angle) * clearance, sin(angle) * clearance, 0)
				add_child(asteroid)
				targets.append(asteroid)
		backdrop = BeltBackdrop.new()
		add_child(backdrop)
		backdrop.build(entry, sector == "cryo", arrival, FrontierArt.OCEAN if sector == "thalassa" else FrontierArt.SAND if sector == "kharon" else Color("#b28dc8") if sector == "vespera" else Color("#8e8296"))

func _build_hive(entry: Transform3D, arrival: PackedVector3Array) -> void:
	for i in range(58):
		for slot in range(4):
			var egg := EggShip.new()
			egg.travel = 70 + i * 51.0 + (9 if slot % 2 == 1 else 0)
			egg.radius = 5.0 + i % 4 * 1.2
			egg.variant = (i + slot) % 2
			egg.cargo = i % 5 == 0 and slot % 2 == 0
			egg.infested = not egg.cargo and i % 4 == 2 and slot == (i / 4) % 4
			egg.near_pass = slot < 2
			egg.phase = i * 1.7 + slot
			egg.course = entry
			var angle: float = i * 1.4 + (PI if slot % 2 == 0 else 0) + (0.22 if slot >= 2 else 0)
			var clearance: float = egg.collision_radius() + (3.3 if slot < 2 else 20.0 + i % 3 * 7)
			egg.course_position = FlightDirector.asteroid_frame(egg.travel) * Vector3(cos(angle) * clearance, sin(angle) * clearance, 0)
			add_child(egg)
			targets.append(egg)
	var hive := HiveBackdrop.new()
	add_child(hive)
	hive.build_hive(entry, arrival)
	backdrop = hive

func advance(delta: float, pilot: Transform3D) -> void:
	pilot_frame = pilot
	if phase == "orbit_boss" and sector == "cryo":
		_advance_carrier_drones(delta, pilot)
		return
	if phase == "asteroids":
		elapsed += delta
		animate_belt(delta, pilot)
		if sector in ["cryo", "ignis"]:
			_advance_crossings(delta, pilot)
		if pirate_index < 3 and elapsed >= 10.0 + pirate_index * 16.0 and elapsed < 55.0:
			var pirate := PirateSkirmisher.new()
			pirate.biological = sector == "xylo"
			pirate.health_scale = health_scale
			pirate.travel = elapsed * FlightDirector.ASTEROID_SPEED + 65.0
			pirate.phase = pirate_index * 1.7
			pirate.course = asteroid_course
			add_child(pirate)
			pirate.missile_requested.connect(func(at: Vector3, direction: Vector3) -> void: missile_requested.emit(at, direction))
			pirates.append(pirate)
			targets.append(pirate)
			pirate_index += 1
		for i in range(pirates.size() - 1, -1, -1):
			var pirate: PirateSkirmisher = pirates[i]
			if pirate.destroyed or pirate.expired:
				targets.erase(pirate)
				pirate.queue_free()
				pirates.remove_at(i)
		return
	if phase != "orbit":
		return
	elapsed += delta
	_advance_crossings(delta, pilot)
	_advance_formation(delta)
	while pending_webs > 0:
		pending_webs -= 1
		_deploy_web()
	wave_clock += delta
	if wave_clock >= 8.0 and elapsed < 82.0:
		wave_clock -= 8.0
		spawn_wave(pilot)
	for i in range(targets.size() - 1, -1, -1):
		if not targets[i] is EnemyFighter:
			continue
		var target := targets[i] as EnemyFighter
		if target.expired or target.destroyed:
			target.queue_free()
			targets.remove_at(i)

func spawn_wave(pilot: Transform3D) -> void:
	for i in range(3):
		var fighter := EnemyFighter.new()
		fighter.sector = sector
		fighter.health_scale = health_scale
		fighter.dogfight = true
		fighter.sector_tactic = true
		fighter.new_design = true
		fighter.delta_wing = (wave_index + i) % 3 == 2
		fighter.winged = not fighter.delta_wing and (wave_index + i) % 2 == 1
		fighter.heavy = i == 2
		fighter.web_layer = i == 1 and wave_index % 2 == 1
		fighter.phase = wave_index * 1.7 + i
		fighter.spawn_frame = pilot
		var angles: PackedFloat32Array = PackedFloat32Array([35.0, -100.0, 145.0]) if wave_index % 2 == 0 else PackedFloat32Array([-40.0, 105.0, -145.0])
		var bearing: float = deg_to_rad(angles[i])
		var distance: float = 85.0 + i * 18
		fighter.spawn_position = pilot * Vector3(sin(bearing) * distance, (i - 1) * 16, -cos(bearing) * distance)
		var heading: Vector3 = (pilot.origin - fighter.spawn_position).normalized()
		fighter.velocity = (-pilot.basis.z * 13.0 + heading * 3.0) if i < 2 else -pilot.basis.z * 10.0
		add_child(fighter)
		fighter.global_position = fighter.spawn_position
		fighter.cooldown = 2.5 + i
		fighter.missile_requested.connect(func(at: Vector3, direction: Vector3) -> void: missile_requested.emit(at, direction))
		if fighter.web_layer:
			fighter.web_requested.connect(_request_web)
		targets.append(fighter)
	wave_index += 1

func _advance_crossings(delta: float, pilot: Transform3D) -> void:
	if crossing == null:
		crossing_clock -= delta
		if crossing_clock > 0 or (phase == "asteroids" and elapsed > 54):
			return
		var center := pilot * Vector3(event_rng.randf_range(-6, 6), event_rng.randf_range(-4, 4), -70)
		if phase == "asteroids":
			var closest := INF
			var victim: Asteroid
			for target in targets:
				if not target is Asteroid or target.fragment or target.destroyed or target.indestructible:
					continue
				var ahead := -pilot.basis.z.dot(target.global_position - pilot.origin)
				if ahead < 60 or ahead > 150: continue
				var weight := target.global_position.distance_squared_to(center)
				if weight < closest:
					closest = weight
					victim = target
			if victim == null: return
			center = victim.global_position
		crossing = CrossingRock.new()
		crossing.meteor = sector == "ignis" if phase == "asteroids" else next_meteor
		var axis := -pilot.basis.y if event_rng.randf() < 0.5 else pilot.basis.x
		if crossing.meteor: axis = (pilot.basis.x * 0.45 - pilot.basis.y).normalized()
		crossing.drift = axis * (58 if crossing.meteor else 45)
		crossing.routed = true
		crossing.course_position = center - axis * 66.0
		crossing.radius = 3.2 if crossing.meteor else 5.0
		crossing.variant = event_rng.randi_range(0, AsteroidArt.VARIANTS - 1)
		add_child(crossing)
		targets.append(crossing)
		next_meteor = not next_meteor
		encounter_notice.emit("METEOR INBOUND / WATCH THE FIRE TRAIL" if crossing.meteor else "ROGUE ASTEROID / CROSSING TRAFFIC")
	var before := crossing.global_position
	if not crossing.destroyed:
		crossing.advance_crossing(delta)
		if phase == "asteroids":
			for target in targets.duplicate():
				if not target is Asteroid or target == crossing or target.destroyed or target.fragment or target.indestructible:
					continue
				var point := Geometry3D.get_closest_point_to_segment(target.global_position, before, crossing.global_position)
				if point.distance_to(target.global_position) <= crossing.collision_radius() + target.collision_radius():
					target.receive_hit(target.armor)
					rock_shattered.emit(target)
					if crossing.meteor:
						crossing.receive_hit(crossing.armor)
						rock_shattered.emit(crossing)
						break
	if crossing.destroyed or crossing.age >= 4.0:
		targets.erase(crossing)
		crossing.queue_free()
		crossing = null
		crossing_clock = event_rng.randf_range(14, 23)

func _advance_formation(delta: float) -> void:
	if sector not in ["cryo", "xylo"]: return
	nurse_clock -= delta
	for leader in targets:
		if not leader is EnemyFighter or not leader.heavy: continue
		var discharge: bool = sector == "cryo" and leader.destroyed
		var nurse: bool = sector == "xylo" and not leader.destroyed and leader.stun_remaining <= 0 and nurse_clock <= 0
		if not discharge and not nurse: continue
		for escort in targets:
			if not escort is EnemyFighter or escort.heavy or escort.destroyed or leader.global_position.distance_to(escort.global_position) > 155: continue
			if discharge:
				escort.stun()
			elif escort.armor < escort.initial_armor:
				escort.armor += 1
				encounter_notice.emit("BROOD NURSE / ESCORT REGENERATED")
		if discharge: encounter_notice.emit("FROST RELAY BROKEN / NEARBY ESCORTS STUNNED")
	if nurse_clock <= 0: nurse_clock = 5.0

func _advance_carrier_drones(delta: float, pilot: Transform3D) -> void:
	for i in range(carrier_drones.size() - 1, -1, -1):
		var drone: EnemyFighter = carrier_drones[i]
		if drone.destroyed or drone.expired:
			targets.erase(drone)
			carrier_drones.remove_at(i)
			drone.queue_free()
	if boss == null or boss.defeated() or boss.drone_bay == null or boss.drone_bay.destroyed or not boss.drone_bay.unlocked or boss.stun_remaining > 0:
		return
	drone_clock -= delta
	if drone_clock > 0 or carrier_drones.size() > 2:
		return
	drone_clock = 9.0
	for side in [-1.0, 1.0]:
		var drone := EnemyFighter.new()
		drone.sector = "cryo"
		drone.health_scale = health_scale
		drone.new_design = true
		drone.dogfight = true
		drone.lifetime = 12.0
		drone.spawn_frame = pilot
		drone.spawn_position = boss.drone_bay.global_position + boss.global_basis * Vector3(side * 10, 3, 10)
		drone.velocity = -pilot.basis.z * 20 + pilot.basis.x * side * 4
		drone.phase = side
		add_child(drone)
		drone.global_position = drone.spawn_position
		drone.cooldown = 2.5
		drone.missile_requested.connect(func(at: Vector3, direction: Vector3) -> void: missile_requested.emit(at, direction))
		targets.append(drone)
		carrier_drones.append(drone)
		drone_launches += 1

func animate_belt(delta: float, pilot: Transform3D) -> void:
	visual_time += delta
	backdrop.animate(visual_time, pilot.origin)
	for target in targets:
		if (target is Asteroid or target is EggShip) and pilot.origin.distance_squared_to(target.global_position) <= pow(VectorArt.VIEW_DISTANCE + 30.0, 2):
			target.animate(visual_time)

func _request_web() -> void:
	pending_webs = mini(3, pending_webs + 1)

func _deploy_web() -> void:
	if webs.size() >= 3:
		return
	var web := LaserWeb.new()
	add_child(web)
	web.global_transform = pilot_frame * Transform3D(Basis(Vector3.FORWARD, (-0.25 if web_index % 2 == 0 else 0.25)), Vector3(0, 0, -72))
	web_index += 1
	webs.append(web)
	targets.append_array(web.nodes)

func advance_webs(delta: float, previous_pilot: Vector3, pilot: Vector3, radius: float) -> bool:
	var hit: bool = false
	for i in range(webs.size() - 1, -1, -1):
		var web: LaserWeb = webs[i]
		if web.advance(delta, previous_pilot, pilot, radius):
			hit = true
		if web.complete():
			for node in web.nodes:
				targets.erase(node)
			web.queue_free()
			webs.remove_at(i)
	return hit

static func station() -> Node3D:
	return StationHangar.new()
