class_name FlightState
extends RefCounted

const DURATION: float = 75.0
const SPEED: float = 42.0
const FIRE_INTERVAL: float = 0.125
const PRIMARY_NAMES: Array[String] = ["Twin Pulse", "Quad Plasma", "Tachyon Beam"]
const CORRIDOR: Vector2 = Vector2(12.0, 7.2)
const WIDE_HALF_WIDTH: float = 60.0
const RESPONSE_RATES: Array[float] = [5.0, 9.0, 14.0]
const EVADE_DURATION: float = 0.65
const EVADE_COOLDOWN: float = 6.0
const ROLL_DURATION := 0.92
const SURGE_RECHARGE := 16.0
const SURGE_HEAT := 34.0
const EMP_STUN_DURATION: float = 2.0
const COUNTERMEASURE_COOLDOWN: float = 8.0
const FROST_DURATION: float = 2.0
const FROST_RESPONSE: float = 0.65
const SPORE_DURATION: float = 2.0
const SHIELD_RECOVERY_DELAY: float = 1.5
const EVADE_EDGE: float = CORRIDOR.x * 0.85

var elapsed: float = 0.0
var distance: float = 0.0
var offset: Vector2 = Vector2.ZERO
var lateral_limit: float = CORRIDOR.x
var aim: Vector2 = Vector2.ZERO
var strafe := Vector2.ZERO
var precision_hold := false
var holding_line := false
var held_offset := Vector2.ZERO
var offset_velocity := Vector2.ZERO
var contact_direction := Vector2.ZERO
var contact_recovery := 0.0
var last_solid_contact := -INF
var last_rebound := -INF
var response: float = 9.0
var shields: float = 100.0
var impacts: int = 0
var shots: int = 0
var hits: int = 0
var destroyed: int = 0
var turrets_destroyed: int = 0
var towers_destroyed: int = 0
var interceptions: int = 0
var missiles_launched: int = 0
var missile_hits: int = 0
var last_impact: String = "PROXIMITY IMPACT"
var fire_cooldown: float = 0.0
var impact_cooldown: float = 0.0
var hit_flash: float = 0.0
var damage_flash: float = 0.0
var last_hit_hull := false
var training: bool = true
var duration: float = DURATION
var speed: float = SPEED
var hull: float = 100.0
var max_hull: float = 100.0
var max_shields: float = 100.0
var weapon_damage: int = 1
var primary_level: int = 0
var ammo: int = 0
var collision_radius: float = 0.6
var recharge_delay: float = 0.0
var secondary_cooldown: float = 0.0
var heat: float = 0.0
var overheat_remaining: float = 0.0
var overheat_events: int = 0
var heat_sink_level: int = 0
var cooling_multiplier: float = 1.0
var power_mode: String = "balanced"
var zero_heat: bool = false
var evade_remaining: float = 0.0
var evade_cooldown: float = 0.0
var evade_start_x: float = 0.0
var evade_target_x: float = 0.0
var evade_bank: float = 0.0
var evasions: int = 0
var roll_remaining := 0.0
var roll_side := 1.0
var roll_count := 0
var surge_remaining := 0.0
var heat_governor := false
var governor_cooling := false
var deflections: int = 0
var countermeasure_cooldown: float = 0.0
var frost_remaining: float = 0.0
var frost_events: int = 0
var frost_slowdown: bool = true
var radar_static_remaining: float = 0.0
var spore_events: int = 0

func advance(delta: float, firing: bool, active: bool = true) -> int:
	assert(delta >= 0.0)
	if not active or complete():
		return 0
	var step: float = minf(delta, duration - elapsed)
	elapsed = minf(duration, elapsed + step)
	distance += step * speed
	var before := offset
	var stick := flight_stick()
	# A progressive throw preserves a quiet gunsight near centre and lets a half
	# throw reach halfway to the outside route with a small additional push.
	var travel_x := lerpf(stick.x, stick.x * stick.x * stick.x, 0.40)
	if lateral_limit <= CORRIDOR.x:
		travel_x = lerpf(stick.x, sin(stick.x * PI * 0.5), 0.38)
	var lift_y := lerpf(stick.y, sin(stick.y * PI * 0.5), 0.38)
	var desired := Vector2(travel_x * lateral_limit, -lift_y * CORRIDOR.y)
	if precision_hold:
		if not holding_line:
			held_offset = offset
		if strafe.x == 0.0:
			desired.x = held_offset.x
		if strafe.y == 0.0:
			desired.y = held_offset.y
	holding_line = precision_hold
	if contact_recovery > 0.0:
		contact_recovery = maxf(0, contact_recovery - step)
		var rebound := offset + contact_direction * 4.5
		desired = rebound.lerp(desired, smoothstep(0, 0.46, 0.46 - contact_recovery))
		desired = desired.clamp(Vector2(-lateral_limit, -CORRIDOR.y), Vector2(lateral_limit, CORRIDOR.y))
	var steering_response: float = response * (1.4 if power_mode == "engines" else 1.0)
	var cold_time: float = minf(step, frost_remaining) if frost_slowdown else 0.0
	radar_static_remaining = maxf(0, radar_static_remaining - step)
	if radar_static_remaining < 0.000001:
		radar_static_remaining = 0.0
	frost_remaining = maxf(0, frost_remaining - step)
	if frost_remaining < 0.000001:
		frost_remaining = 0.0
	var free_steering_time: float = advance_evasion(step)
	if roll_remaining > 0:
		var angle := roll_progress() * TAU
		desired += Vector2(roll_side * 2.8 * sin(angle), 1.4 * (1.0 - cos(angle)))
		desired = desired.clamp(Vector2(-lateral_limit, -CORRIDOR.y), Vector2(lateral_limit, CORRIDOR.y))
	var horizontal_cold: float = clampf(cold_time - (step - free_steering_time), 0, free_steering_time)
	offset.x = lerpf(offset.x, desired.x, 1.0 - exp(-steering_response * (free_steering_time - horizontal_cold * (1.0 - FROST_RESPONSE))))
	offset.y = lerpf(offset.y, desired.y, 1.0 - exp(-steering_response * (step - cold_time * (1.0 - FROST_RESPONSE))))
	if step > 0.0:
		offset_velocity = (offset - before) / step
	if precision_hold and strafe.x != 0.0:
		held_offset.x = offset.x
	if precision_hold and strafe.y != 0.0:
		held_offset.y = offset.y
	impact_cooldown = maxf(0.0, impact_cooldown - step)
	hit_flash = maxf(0.0, hit_flash - step)
	damage_flash = maxf(0.0, damage_flash - step)
	var recovery_time: float = maxf(0.0, step - recharge_delay)
	recharge_delay = maxf(0.0, recharge_delay - step)
	secondary_cooldown = maxf(0.0, secondary_cooldown - step)
	countermeasure_cooldown = maxf(0.0, countermeasure_cooldown - step)
	if recharge_delay == 0.0:
		shields = minf(max_shields, shields + recovery_time * (8.0 if power_mode == "shields" else 5.0))
	return advance_primary(step, firing)

func rebound(outward: Vector2) -> bool:
	# A sustained scrape is one strike. Swept queries may hit several adjacent
	# triangles, or briefly lose contact as the ship rides over their seam.
	var fresh := elapsed - last_solid_contact > 0.30 and elapsed - last_rebound > 0.80
	last_solid_contact = elapsed
	if not fresh or hull <= 0:
		return false
	last_rebound = elapsed
	contact_direction = outward.normalized()
	contact_recovery = 0.46
	evade_remaining = 0.0
	offset = (offset + contact_direction * 1.2).clamp(Vector2(-lateral_limit, -CORRIDOR.y), Vector2(lateral_limit, CORRIDOR.y))
	if precision_hold:
		held_offset = offset
	return true

func apply_frost() -> bool:
	if training or hull <= 0 or complete() or frost_remaining > 0:
		return false
	frost_remaining = FROST_DURATION
	frost_events += 1
	return true

func apply_spores() -> bool:
	if training or hull <= 0 or complete() or radar_static_remaining > 0:
		return false
	radar_static_remaining = SPORE_DURATION
	spore_events += 1
	return true

func request_evasion() -> String:
	if complete() or hull <= 0.0:
		return "Evasion unavailable outside an active flight."
	if evade_cooldown > 0.000001:
		return "EVASION CAPACITOR / %.1fs TO RECHARGE" % evade_cooldown
	evade_start_x = offset.x
	evade_target_x = -EVADE_EDGE if offset.x >= 0.0 else EVADE_EDGE
	evade_remaining = EVADE_DURATION
	evade_cooldown = EVADE_COOLDOWN
	evade_bank = 0.0
	evasions += 1
	return ""

func flight_stick() -> Vector2:
	# Manual thrusters on one axis leave the other axis under pointer control.
	var stick := Vector2.ZERO if precision_hold else aim
	if strafe.x != 0.0:
		stick.x = strafe.x
	if strafe.y != 0.0:
		stick.y = strafe.y
	return stick.clamp(-Vector2.ONE, Vector2.ONE)

func request_barrel_roll() -> String:
	if complete() or hull <= 0.0:
		return "ROLL UNAVAILABLE"
	if evade_cooldown > 0.000001:
		return "MANEUVER CAPACITOR / %.1fs" % evade_cooldown
	var horizontal := flight_stick().x
	roll_side = signf(horizontal) if absf(horizontal) > 0.12 else (-1.0 if offset.x > 0 else 1.0)
	roll_remaining = ROLL_DURATION
	evade_cooldown = EVADE_COOLDOWN
	roll_count += 1
	return ""

func roll_progress() -> float:
	return 1.0 - roll_remaining / ROLL_DURATION

func roll_bank(reduced_motion: bool) -> float:
	if roll_remaining <= 0.0:
		return 0.0
	var progress := roll_progress()
	return roll_side * (0.16 * sin(progress * TAU) if reduced_motion else TAU * smoothstep(0.0, 1.0, progress))

func request_shield_surge() -> String:
	if training or hull <= 0.0 or complete():
		return "SHIELD SURGE / CAMPAIGN FLIGHT ONLY"
	if shields >= max_shields - 0.01:
		return "DEFLECTOR FULL"
	if surge_remaining > 0:
		return "SURGE BANK / %.1fs TO CHARGE" % surge_remaining
	if overheat_remaining > 0.0 or heat + SURGE_HEAT >= 100.0:
		return "SURGE INHIBITED / COOL WEAPONS"
	var restored := minf(max_shields - shields, max_shields * 0.23)
	shields += restored
	add_external_heat(SURGE_HEAT)
	surge_remaining = SURGE_RECHARGE
	return "SHIELD SURGE / +%d SHIELD" % roundi(restored)

func add_external_heat(amount: float) -> bool:
	assert(amount >= 0)
	if training or zero_heat or overheat_remaining > 0:
		return false
	heat = minf(100.0, heat + amount)
	if heat >= 100.0:
		overheat_remaining = 2.0
		overheat_events += 1
		return true
	return false

func advance_evasion(delta: float) -> float:
	assert(delta >= 0.0)
	surge_remaining = maxf(0.0, surge_remaining - delta)
	roll_remaining = maxf(0.0, roll_remaining - delta)
	if roll_remaining < 0.000001:
		roll_remaining = 0.0
	evade_cooldown = maxf(0.0, evade_cooldown - delta)
	if evade_remaining <= 0.0:
		evade_bank = 0.0
		return delta
	var active_time: float = minf(delta, evade_remaining)
	evade_remaining = maxf(0.0, evade_remaining - active_time)
	if evade_remaining < 0.000001:
		evade_remaining = 0.0
	var progress: float = 1.0 - evade_remaining / EVADE_DURATION
	offset.x = lerpf(evade_start_x, evade_target_x, smoothstep(0.0, 1.0, progress))
	evade_bank = signf(evade_target_x - evade_start_x) * deg_to_rad(14.0) * sin(progress * PI)
	return delta - active_time

func deflect_projectile() -> bool:
	if (evade_remaining <= 0.0 and roll_remaining <= 0.0) or hull <= 0.0:
		return false
	deflections += 1
	return true

func inherit_evasion(previous: FlightState) -> void:
	roll_remaining = previous.roll_remaining
	roll_side = previous.roll_side
	roll_count = previous.roll_count
	surge_remaining = previous.surge_remaining
	heat_governor = previous.heat_governor
	governor_cooling = previous.governor_cooling
	evade_remaining = previous.evade_remaining
	evade_cooldown = previous.evade_cooldown
	evade_start_x = previous.evade_start_x
	evade_target_x = previous.evade_target_x
	evade_bank = previous.evade_bank
	evasions = previous.evasions
	deflections = previous.deflections

func advance_primary(delta: float, firing: bool) -> int:
	assert(delta >= 0.0)
	var remaining: float = delta
	var emitted: int = 0
	if training or zero_heat:
		heat = 0.0
		overheat_remaining = 0.0
	# Consume time up to firing/cooldown events, so the 2s vent is frame-rate independent.
	while remaining > 0.0000001:
		if not heat_governor or training or zero_heat or not firing:
			governor_cooling = false
		elif heat >= 76.0:
			governor_cooling = true
		if overheat_remaining > 0.0000001:
			var vent_time: float = minf(remaining, overheat_remaining)
			heat = maxf(0.0, heat - 50.0 * vent_time)
			overheat_remaining = maxf(0.0, overheat_remaining - vent_time)
			fire_cooldown = maxf(0.0, fire_cooldown - vent_time)
			remaining -= vent_time
		elif governor_cooling:
			var cooling := maxf(60.0 * cooling_multiplier, 0.01)
			var wait := minf(remaining, maxf(0.0, (heat - 35.0) / cooling))
			heat = maxf(0.0, heat - cooling * wait)
			fire_cooldown = maxf(0.0, fire_cooldown - wait)
			remaining -= wait
			governor_cooling = heat > 35.000001
		elif fire_cooldown > 0.0000001:
			var wait: float = minf(remaining, fire_cooldown)
			heat = maxf(0.0, heat - (14.0 if firing else 60.0) * cooling_multiplier * wait)
			fire_cooldown = maxf(0.0, fire_cooldown - wait)
			remaining -= wait
		elif not firing:
			heat = maxf(0.0, heat - 60.0 * cooling_multiplier * remaining)
			remaining = 0.0
		else:
			emitted += 1
			fire_cooldown = (0.1 if power_mode == "weapons" else FIRE_INTERVAL) * (2.0 if primary_level == 1 else 1.0)
			if not training and not zero_heat:
				var base_heat: float = 14.0 if primary_level == 1 else 9.0 if primary_level == 2 else 7.0
				var per_shot: float = base_heat * (1.0 - heat_sink_level * 0.18) * (0.72 if power_mode == "weapons" else 1.0)
				heat = minf(100.0, heat + per_shot)
				if heat >= 100.0:
					overheat_remaining = 2.0
					overheat_events += 1
	shots += emitted * primary_samples()
	return emitted

func primary_samples() -> int:
	return 4 if primary_level == 1 else 1

func primary_name() -> String:
	return PRIMARY_NAMES[primary_level]

func primary_damage_label() -> String:
	return "4 x 1 / VOLLEY" if primary_level == 1 else "3 / BEAM TICK" if primary_level == 2 else "DAMAGE 1"

func impact(reason: String = "PROXIMITY IMPACT", damage: float = 18.0, direct_hull: bool = false) -> bool:
	if roll_remaining > 0.0 and not direct_hull:
		return false
	if impact_cooldown > 0.0 and not direct_hull:
		return false
	var previous_hull := hull
	impacts += 1
	if direct_hull:
		hull = maxf(1.0 if training else 0.0, hull - damage)
	elif training:
		shields = maxf(1.0, shields - damage)
	else:
		var absorbed: float = minf(shields, damage)
		shields -= absorbed
		hull = maxf(0.0, hull - (damage - absorbed))
	if not direct_hull:
		impact_cooldown = 2.0 if training else 0.7
		recharge_delay = 2.0 if training else SHIELD_RECOVERY_DELAY
	damage_flash = 0.35
	last_hit_hull = hull < previous_hull
	last_impact = reason
	return true

func accuracy() -> float:
	return 100.0 * float(hits) / float(shots) if shots > 0 else 0.0

func complete() -> bool:
	return elapsed >= duration

func configure_campaign(campaign: CampaignState) -> void:
	training = false
	lateral_limit = WIDE_HALF_WIDTH if campaign.phase in ["ground", "ground_boss", "orbit_boss", "asteroids"] else CORRIDOR.x
	max_hull = campaign.hull_capacity()
	max_shields = campaign.shield_capacity()
	hull = campaign.hull
	shields = campaign.shields
	primary_level = campaign.primary_level
	weapon_damage = 3 if primary_level == 2 else 1
	ammo = campaign.ammo
	collision_radius = float(CampaignState.SHIPS[campaign.ship]["radius"])
	heat_sink_level = campaign.heat_sink_level
	power_mode = campaign.power_mode
	cooling_multiplier = 1.25 if campaign.ship == "hawk" else 1.0

static func rail_point(travel: float) -> Vector3:
	return Vector3(sin(travel * 0.0035) * 16.0, 12.0 + sin(travel * 0.005) * 2.0, -travel)

static func rail_frame(travel: float) -> Transform3D:
	var point := rail_point(travel)
	var direction: Vector3 = (rail_point(travel + 2.0) - point).normalized()
	return Transform3D(Basis.looking_at(direction), point)
