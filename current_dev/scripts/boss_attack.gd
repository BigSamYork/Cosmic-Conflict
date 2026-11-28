extends Node3D

# One attack owns its charge, visible flight paths, and collision window. Its
# coordinate frame follows the flight rail so a locked lane can be dodged.
enum Pattern { LANCE, RAKE, PINCER, FAN, RIPPLE, BLOOM, HELIX }
const ARSENAL := {
	"ignis": [
		[["SIEGE SHELLS", Pattern.RIPPLE], ["FURNACE RAKE", Pattern.RAKE], ["INCENDIARY CLUSTER", Pattern.BLOOM]],
		[["SOLAR LANCE", Pattern.LANCE], ["PLASMA BROADSIDE", Pattern.FAN], ["CORONAL PINCER", Pattern.PINCER]]],
	"cryo": [
		[["ICE SHARDS", Pattern.FAN], ["BORE SPIRAL", Pattern.HELIX], ["GLACIAL LANCE", Pattern.LANCE]],
		[["FROST TORPEDOES", Pattern.RIPPLE], ["CRYSTAL PINCER", Pattern.PINCER], ["SHARD BLOOM", Pattern.BLOOM]]],
	"vespera": [
		[["PRISM LANCE", Pattern.LANCE], ["PRISM SCISSORS", Pattern.PINCER], ["DEFENSE GRID SWEEP", Pattern.RAKE]],
		[["AMBUSH FAN", Pattern.FAN], ["PHASE RAKE", Pattern.RAKE], ["PHANTOM SPIRAL", Pattern.HELIX]]],
	"xylo": [
		[["ACID SPIT", Pattern.RIPPLE], ["SPORE BLOOM", Pattern.BLOOM], ["VENOM SPRAY", Pattern.FAN]],
		[["BROOD SPIRAL", Pattern.HELIX], ["SPINE VOLLEY", Pattern.FAN], ["BROOD ERUPTION", Pattern.BLOOM]]],
	"thalassa": [
		[["PRESSURE FAN", Pattern.FAN], ["TIDAL RAKE", Pattern.RAKE], ["DEPTH CHARGES", Pattern.RIPPLE]],
		[["ARC PINCER", Pattern.PINCER], ["LIGHTNING LANCE", Pattern.LANCE], ["ION CYCLONE", Pattern.HELIX]]],
	"kharon": [
		[["SOLAR RAKE", Pattern.RAKE], ["FOCUSING LENSES", Pattern.PINCER], ["SUNBURST", Pattern.BLOOM]],
		[["MASS DRIVER", Pattern.RIPPLE], ["MAGAZINE BROADSIDE", Pattern.FAN], ["OBELISK LANCE", Pattern.LANCE]]],
}
const TINTS := {"ignis": Color("#ff803d"), "cryo": Color("#8eeaff"), "vespera": Color("#c594ff"), "xylo": Color("#bfed54"), "thalassa": Color("#63cfff"), "kharon": Color("#ffd15e")}
const RANGE := 330.0
const PULSE_SPEED := 100.0
const DODGE_HINT := ["BREAK AIM", "CLIMB OR DIVE", "CLEAR THE CENTER", "CLIMB OR DIVE", "KEEP MOVING", "CLEAR THE BURST", "BREAK SIDEWAYS"]

var pattern: Pattern
var attack_name: String
var damage: float
var full_damage: float
var age := 0.0
var windup: float
var duration: float
var clockwise: float
var emitter: BossPart
var ignored_body: RID
var locked_lane: Vector3
var fired_from: Vector3
var previous_pilot: Vector3
var struck := false
var charge_ring: MeshInstance3D
var guides: Array[MeshInstance3D] = []
var shots: Array[Node3D] = []
var spent: Array[bool] = []

func configure(sector: String, orbital: bool, stage: int, volley: int, source: BossPart, hull: StaticBody3D, pilot: Vector3, discharge := false, radar_losses := 0, broken_feeds := 0) -> void:
	var move: Array = ARSENAL[sector][int(orbital)][stage]
	attack_name = move[0]
	pattern = move[1]
	if discharge:
		attack_name = "CARDIAC RUPTURE" if sector == "xylo" else "EMERGENCY DISCHARGE"
		pattern = Pattern.BLOOM
	elif radar_losses == 2:
		attack_name = "BLIND BARRAGE"
		pattern = Pattern.FAN if volley % 2 == 0 else Pattern.RIPPLE
	full_damage = 9.0 if radar_losses == 2 else 10.0 + stage * 2.0
	update_power(broken_feeds)
	emitter = source
	ignored_body = hull.get_rid()
	clockwise = 1.0 if volley % 2 == 0 else -1.0
	locked_lane = to_local(pilot)
	previous_pilot = locked_lane
	if radar_losses == 2:
		locked_lane = blind_lane(locked_lane.z, volley)
	fired_from = _muzzle()
	windup = 1.45 - stage * 0.12 + radar_losses * 0.6
	var count := 1
	match pattern:
		Pattern.PINCER: count = 2
		Pattern.FAN, Pattern.RIPPLE, Pattern.HELIX: count = 3
		Pattern.BLOOM: count = 5
	duration = 1.2 if _beam() else RANGE / PULSE_SPEED + _delay(count - 1)
	var tint: Color = TINTS[sector]
	var arcs := PackedVector3Array()
	for i in range(24):
		if i % 6 == 5:
			continue
		for end in [i, i + 1]:
			var angle: float = end * TAU / 24
			arcs.append(Vector3(cos(angle), sin(angle), 0))
	charge_ring = VectorArt.lines(arcs, tint.lightened(0.48))
	add_child(charge_ring)
	var guide_points := PackedVector3Array()
	for i in range(14):
		var z := -float(i) / 14.0
		guide_points.append(Vector3(0, 0, z))
		guide_points.append(Vector3(0, 0, z - 0.035))
	var guide := VectorArt.lines(guide_points, tint.lerp(Color.WHITE, 0.4))
	for i in range(count):
		var track := guide if i == 0 else guide.duplicate() as MeshInstance3D
		add_child(track)
		guides.append(track)
		var shot := _ordnance(sector, tint)
		add_child(shot)
		shots.append(shot)
		spent.append(false)
		shot.hide()
	_draw_warning()

static func blind_lane(depth: float, volley: int) -> Vector3:
	return Vector3(((volley % 3) - 1) * 5.0, 1.7 if volley % 2 == 0 else -1.7, depth)

func update_power(broken_feeds: int) -> void:
	damage = full_damage * (1.0 - 0.2 * broken_feeds)

func warning() -> String:
	return attack_name + " / " + DODGE_HINT[pattern]

func _ordnance(sector: String, tint: Color) -> Node3D:
	if sector == "xylo":
		return XyloArt.spore_bolt()
	var key := "boss_weapon_" + sector + ("_beam" if _beam() else "_round")
	var cached := VectorArt.cached_model(key)
	if cached != null:
		return cached
	var batch := GeometryBatch.new()
	if _beam():
		# A narrow hot core and luminous outer rails leave the cockpit view clear.
		batch.tube(Vector3(0, 0, -0.5), 0.23, 1, tint, 6)
		for i in range(3):
			var edge := Vector3(cos(i * TAU / 3), sin(i * TAU / 3), 0) * 0.45
			batch.line(edge, edge + Vector3.FORWARD, tint.lightened(0.45))
	elif sector == "cryo" or sector == "vespera":
		batch.crystal(Vector3.ZERO, 0.95, 2.3, tint)
		batch.ring(Vector3.ZERO, 1.12, tint.lightened(0.45))
	elif sector == "kharon":
		batch.tube(Vector3.ZERO, 0.6, 3.4, tint, 8, 0.28)
		batch.ring(Vector3(0, 0, 0.8), 0.8, tint.lightened(0.5))
	else:
		batch.ellipsoid(Vector3.ZERO, Vector3(1.04, 1.04, 1.4), tint, 5, 8)
		batch.ring(Vector3.ZERO, 1.2, tint.lightened(0.5))
		for i in range(3):
			var tail := Vector3(cos(i * TAU / 3), sin(i * TAU / 3), 0) * 0.8
			batch.line(tail, Vector3.BACK * 2.5, tint)
	return VectorArt.remember_model(key, batch.build())

func _muzzle() -> Vector3:
	return to_local(emitter.head.to_global(Vector3(0, 0, -4.2)) if emitter is BossTurret else emitter.aim_point())

func _beam() -> bool:
	return pattern in [Pattern.LANCE, Pattern.RAKE, Pattern.PINCER]

func needs_emitter() -> bool:
	return age < windup or _beam()

func _delay(index: int) -> float:
	return index * 0.23 if pattern == Pattern.RIPPLE else 0.0

func _offset(index: int, elapsed: float) -> Vector2:
	match pattern:
		Pattern.RAKE:
			return Vector2(clockwise * lerpf(-8, 8, clampf(elapsed / duration, 0, 1)), 0)
		Pattern.PINCER:
			var width := lerpf(8.0, -3.0, clampf(elapsed / duration, 0, 1))
			return Vector2(width * (1.0 if index == 0 else -1.0), 0)
		Pattern.FAN:
			return Vector2((index - 1) * 4.4, 0)
		Pattern.RIPPLE:
			return Vector2((index - 1) * 3.2 * clockwise, (index - 1) * 1.6)
		Pattern.BLOOM:
			return Vector2.ZERO if index == 0 else Vector2.RIGHT.rotated(index * PI * 0.5) * 4.6
	return Vector2.ZERO

func _axis(index: int, elapsed: float) -> Vector3:
	var offset := _offset(index, elapsed)
	return fired_from.direction_to(locked_lane + Vector3(offset.x, offset.y, 0))

func _pulse(index: int, time: float) -> Vector3:
	var travel := maxf(time - _delay(index), 0) * PULSE_SPEED
	var point := fired_from + _axis(index, time) * travel
	if pattern == Pattern.HELIX:
		var phase := index * TAU / shots.size() + travel * 0.035 * clockwise
		var spread := clampf(absf(travel - fired_from.distance_to(locked_lane)) / 18, 0.15, 1)
		point += Vector3(cos(phase), sin(phase), 0) * 3.7 * spread * minf(1, travel / 15.0)
	return point

func _draw_warning() -> void:
	var facing := fired_from.direction_to(locked_lane)
	charge_ring.position = fired_from + facing * 0.85
	var radius := lerpf(2.8, 0.85, clampf(age / windup, 0, 1))
	charge_ring.basis = (Basis.looking_at(facing) * Basis(Vector3.BACK, age * 3.2 * clockwise)).scaled_local(Vector3.ONE * radius)
	for i in range(guides.size()):
		var guide := guides[i]
		var direction := _axis(i, 0)
		if pattern == Pattern.HELIX:
			direction = fired_from.direction_to(_pulse(i, fired_from.distance_to(locked_lane) / PULSE_SPEED))
		guide.position = fired_from
		guide.basis = Basis.looking_at(direction).scaled_local(Vector3(1, 1, maxf(1, fired_from.distance_to(locked_lane) * 0.89)))
		guide.visible = fmod(age, 0.26) < 0.21

func advance(delta: float, pilot: Vector3, radius: float) -> bool:
	var before := age
	age += delta
	var current := to_local(pilot)
	if before < windup or _beam():
		fired_from = _muzzle()
	if age < windup:
		_draw_warning()
		previous_pilot = current
		return false
	# Sweep in rail space, including large frames straddling the firing instant.
	var begin := maxf(0, before - windup)
	charge_ring.hide()
	var finish := clampf(age - windup, 0, duration)
	var steps := maxi(1, ceili((finish - begin) * 45.0))
	var hit := false
	for i in range(shots.size()):
		guides[i].hide()
		if spent[i]:
			continue
		var previous_t := begin
		for j in range(steps + 1):
			var t := lerpf(begin, finish, float(j) / steps)
			var fraction := clampf((t + windup - before) / maxf(delta, 0.00001), 0, 1)
			var ship := previous_pilot.lerp(current, fraction)
			if _beam():
				var end := fired_from + _axis(i, t) * RANGE
				if not struck and Geometry3D.get_closest_point_to_segment(ship, fired_from, end).distance_to(ship) <= radius + 0.55:
					hit = _cover(fired_from, ship).is_empty()
			elif t > _delay(i) and t > previous_t:
				var start_t := maxf(previous_t, _delay(i))
				var start_fraction := clampf((start_t + windup - before) / delta, 0, 1)
				if _pulse_hits(i, start_t, t, previous_pilot.lerp(current, start_fraction), ship, radius):
					hit = true
			previous_t = t
			struck = struck or hit
			if spent[i]:
				break
		var shot := shots[i]
		shot.visible = finish >= _delay(i) and not spent[i]
		if _beam():
			var axis := _axis(i, finish)
			var block := _cover(fired_from, fired_from + axis * RANGE)
			var reach := RANGE if block.is_empty() else fired_from.distance_to(to_local(block.position))
			shot.position = fired_from
			shot.basis = Basis.looking_at(axis).scaled_local(Vector3(1, 1, maxf(0.001, reach)))
		else:
			shot.position = _pulse(i, finish)
			shot.basis = Basis.looking_at(_axis(i, finish)) * Basis(Vector3.BACK, finish * 3 + i)
	previous_pilot = current
	return hit

func _pulse_hits(index: int, start_t: float, end_t: float, ship_before: Vector3, ship: Vector3, radius: float) -> bool:
	var start := _pulse(index, start_t)
	var end := _pulse(index, end_t)
	var cover := _cover(start, end)
	if not cover.is_empty():
		var stop := to_local(cover.position)
		var fraction := clampf(start.distance_to(stop) / maxf(0.0001, start.distance_to(end)), 0, 1)
		ship = ship_before.lerp(ship, fraction)
		end = stop
		spent[index] = true
	var a := start - ship_before
	var b := end - ship
	var closest := a if a.is_equal_approx(b) else Geometry3D.get_closest_point_to_segment(Vector3.ZERO, a, b)
	if closest.length() > radius + 1.15:
		return false
	spent[index] = true
	return not struck

func _cover(start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(to_global(start), to_global(end), 1, [ignored_body])
	query.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func complete() -> bool:
	return age >= windup + duration or not spent.has(false)
