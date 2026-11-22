class_name FlightHUD
extends Control

signal launch_requested
signal resume_requested
signal title_requested
signal opening_requested
signal quit_requested
signal setting_changed(key: String, value: Variant)
signal mission_requested
signal continue_requested
signal purchase_requested(item: String)
signal secondary_selected(weapon: String)
signal depart_requested
signal sector_selected(sector: String)
signal sector_cancelled
signal debug_action(action: String)
signal hall_requested
signal named_games_requested

const WHITE := Color("#e5f2f2")
const MUTED := Color("#82969f")
const AMBER := Color("#ffa65c")
const CYAN := Color("#70e2e7")

var flight: FlightState
var mode: String = "title"
var cursor: Vector2 = Vector2(960, 540)
var show_target_ranges := false
var contacts: Array[Dictionary] = []
var radar_contacts: Array[Dictionary] = []
var sensors := FlightDeckSensors.new()
var lead_marker := Vector2.ZERO
var show_lead := false
var incoming: Array[Vector2] = []
var salvage_contacts: Array[Vector2] = []
var blast_warning: bool = false
var tractor_active: bool = false
var web_warning: bool = false
var radar_jam: float = 0.0
var thermal_warning: bool = false
var vent_warning: bool = false
var frost_warning: bool = false
var gate_warning: bool = false
var lightning_warning := false
var acid_warning: bool = false
var autopilot: bool = false
var transit_seconds: int = 0
var menu: PanelContainer
var message: String = ""
var message_until: float = 0.0
var fps: float = 60.0
var settings: Dictionary = {}
var font: Font
var credits_text: String = ""
var campaign: CampaignState
var can_resume: bool = false
var phase_title: String = "01 // CANYON APPROACH"
var objective: String = "DISABLE TURRETS / SHOOT OR EVADE MISSILES"
var boss_fraction: float = -1.0
var instrument_viewport: SubViewport
var instrument_canvas: CockpitInstruments
var instrument_panels: Node2D
var next_instrument_update: int = 0
var instruments_active: bool = false
var displayed_ammo: int = -1
var displayed_hull: int = -1
var displayed_shields: int = -1
var displayed_incoming: int = -1
var displayed_power: String = ""
var displayed_overheat: bool = false
var displayed_evasion: bool = false
var displayed_combo: int = 1
var displayed_secondary: String = ""
var displayed_flares: int = -1

func _menu_stack(width: float = 620.0, y: float = 180.0) -> VBoxContainer:
	queue_redraw()
	menu.visible = true
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	menu.position = Vector2(110, y)
	menu.size = Vector2(width, 0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	menu.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	return stack

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	theme = _make_theme()
	menu = PanelContainer.new()
	menu.position = Vector2(110, 245)
	menu.size = Vector2(620, 0)
	menu.z_index = 20
	add_child(menu)
	_build_instrument_panels()

func _process(_delta: float) -> void:
	var active: bool = mode in ["flight", "pause", "debug", "notice"]
	instrument_panels.visible = active
	if active and flight != null:
		instrument_panels.transform = CockpitInstruments.artwork_transform(size)
		var now: int = Time.get_ticks_usec()
		var multiplier: int = campaign.combo_multiplier() if campaign != null and not flight.training else 1
		var station: String = campaign.selected_secondary if campaign != null and not flight.training else ""
		var flares: int = campaign.flares if campaign != null and not flight.training else -1
		var immediate: bool = not instruments_active or flight != instrument_canvas.flight or phase_title != instrument_canvas.phase_title or flight.ammo != displayed_ammo or int(flight.hull) != displayed_hull or int(flight.shields) != displayed_shields or incoming.size() != displayed_incoming or flight.power_mode != displayed_power or (flight.overheat_remaining > 0) != displayed_overheat or (flight.evade_remaining > 0) != displayed_evasion or multiplier != displayed_combo or station != displayed_secondary or flares != displayed_flares
		# Digital instruments refresh at 30 Hz; controls, reticle and world stay full-rate.
		if immediate or (autopilot and transit_seconds != instrument_canvas.transit_seconds) or now >= next_instrument_update:
			next_instrument_update = now + 33333
			displayed_ammo = flight.ammo
			displayed_hull = int(flight.hull)
			displayed_shields = int(flight.shields)
			displayed_incoming = incoming.size()
			displayed_power = flight.power_mode
			displayed_overheat = flight.overheat_remaining > 0
			displayed_evasion = flight.evade_remaining > 0
			displayed_combo = multiplier
			displayed_secondary = station
			displayed_flares = flares
			instrument_canvas.flight = flight
			instrument_canvas.campaign = campaign
			instrument_canvas.phase_title = phase_title
			instrument_canvas.objective = objective
			instrument_canvas.incoming_count = incoming.size()
			instrument_canvas.blast_warning = blast_warning
			instrument_canvas.tractor_active = tractor_active
			instrument_canvas.web_warning = web_warning
			instrument_canvas.radar_jam = radar_jam
			instrument_canvas.thermal_warning = thermal_warning
			instrument_canvas.vent_warning = vent_warning
			instrument_canvas.frost_warning = frost_warning
			instrument_canvas.gate_warning = gate_warning
			instrument_canvas.acid_warning = acid_warning
			instrument_canvas.autopilot = autopilot
			instrument_canvas.transit_seconds = transit_seconds
			instrument_canvas.boss_fraction = boss_fraction
			instrument_canvas.show_target_ranges = show_target_ranges
			instrument_canvas.radar_contacts = radar_contacts
			instrument_canvas.scope_range = sensors.range_m
			instrument_canvas.intercept_seconds = sensors.intercept_seconds
			instrument_canvas.collision_seconds = sensors.collision_seconds
			instrument_canvas.escape_side = sensors.escape_side
			instrument_canvas.fps = fps
			instrument_canvas.queue_redraw()
			instrument_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		instrument_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	instruments_active = active
	if mode == "flight":
		queue_redraw()

func _build_instrument_panels() -> void:
	instrument_viewport = SubViewport.new()
	instrument_viewport.name = "CockpitInstrumentAtlas"
	instrument_viewport.size = Vector2i(CockpitInstruments.ATLAS_SIZE)
	instrument_viewport.transparent_bg = true
	instrument_viewport.disable_3d = true
	instrument_viewport.gui_disable_input = true
	add_child(instrument_viewport)
	instrument_canvas = CockpitInstruments.new()
	instrument_canvas.size = CockpitInstruments.ATLAS_SIZE
	instrument_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instrument_viewport.add_child(instrument_canvas)
	instrument_panels = Node2D.new()
	instrument_panels.name = "ProjectedCockpitDisplays"
	add_child(instrument_panels)
	for kind: String in CockpitInstruments.PANELS:
		var layout: Dictionary = CockpitInstruments.PANELS[kind]
		var quad := PackedVector2Array(layout["corners"])
		var inverse: Basis = CockpitInstruments.inverse_projection(quad)
		var rect: Rect2 = layout["rect"]
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/cockpit_display.gdshader")
		material.set_shader_parameter("inverse_row_0", Vector3(inverse.x.x, inverse.y.x, inverse.z.x))
		material.set_shader_parameter("inverse_row_1", Vector3(inverse.x.y, inverse.y.y, inverse.z.y))
		material.set_shader_parameter("inverse_row_2", Vector3(inverse.x.z, inverse.y.z, inverse.z.z))
		material.set_shader_parameter("atlas_rect", Vector4(rect.position.x / CockpitInstruments.ATLAS_SIZE.x, rect.position.y / CockpitInstruments.ATLAS_SIZE.y, rect.size.x / CockpitInstruments.ATLAS_SIZE.x, rect.size.y / CockpitInstruments.ATLAS_SIZE.y))
		var panel := Polygon2D.new()
		panel.name = kind
		panel.polygon = quad
		panel.texture = instrument_viewport.get_texture()
		panel.material = material
		panel.antialiased = true
		instrument_panels.add_child(panel)

func show_message(text: String) -> void:
	message = text
	message_until = Time.get_ticks_msec() / 1000.0 + 3.0

func scan_flight_deck(pilot: Camera3D, targets: Array[RangeTarget], missiles: Array[EnemyMissile], pickups: Array[MineralPickup], supplies: Array, tracked: EnemyFighter) -> void:
	sensors.scan(pilot, flight, targets, missiles, pickups, supplies, tracked, cursor)
	radar_contacts = sensors.returns
	show_lead = flight.radar_static_remaining <= 0 and is_instance_valid(sensors.lead_target)
	if show_lead:
		show_lead = not sensors.lead_target.destroyed and not pilot.is_position_behind(sensors.lead_world)
		if show_lead:
			lead_marker = pilot.unproject_position(sensors.lead_world)

func show_menu(next_mode: String, current_settings: Dictionary) -> void:
	mode = next_mode
	settings = current_settings
	menu.visible = mode != "flight"
	if not menu.visible:
		return
	var stack: VBoxContainer = _menu_stack(620, 140 if mode == "pause" else 180)
	if mode == "credits":
		_add_label(stack, "CREDITS & LICENSES", 30, AMBER)
		var legal := TextEdit.new()
		legal.custom_minimum_size = Vector2(550, 310)
		legal.editable = false
		legal.text = credits_text
		legal.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		stack.add_child(legal)
		_add_button(stack, "BACK", func() -> void: title_requested.emit())
		return
	if mode == "title":
		_add_label(stack, "CAPTAIN TOMAS VALE  /  FLIGHT COMPUTER LARK", 18, CYAN)
		_add_label(stack, "TWO KNOCKS HOME", 34, WHITE)
		_add_label(stack, "Six convoys lift at dawn. Clear the ground lanes,\nbreak the blockades, and bring them home to Astra.", 21, MUTED)
		_add_button(stack, "NEW OPERATION / CHOOSE SECTOR", func() -> void: mission_requested.emit())
		if can_resume:
			_add_button(stack, "CONTINUE SAVED OPERATION / MARKET", func() -> void: continue_requested.emit())
		_add_button(stack, "LAUNCH TRAINING FLIGHT", func() -> void: launch_requested.emit())
		var extras := HBoxContainer.new()
		stack.add_child(extras)
		_add_button(extras, "HALL OF FAME", func() -> void: hall_requested.emit())
		_add_button(extras, "REPLAY OPENING", func() -> void: opening_requested.emit())
	elif mode == "pause":
		_add_label(stack, "TACTICAL STATUS / SIMULATION HELD", 18, CYAN)
		_add_label(stack, "TAKE A BREATH, PILOT.", 32, WHITE)
		if flight.training:
			_add_label(stack, "Training shield  %03d%%     Hull  %03d%%     Impacts  %02d\nNon-lethal proving range / no campaign changes" % [int(flight.shields), int(flight.hull), flight.impacts], 21, MUTED)
		else:
			_add_label(stack, "Shield  %03d / %03d       Hull  %03d / %03d\nPrimary: %s / %s\nSecondary ammo  %d\nHeat %02d%% / Vent %.1fs / Cooling Lv %d\nReactor: %s / Evasion recharge %.1fs\nStreak %d kills / %dX / Combat score %d\nCheckpoint: %s\nExiting restarts this phase at its saved boundary." % [int(flight.shields), int(flight.max_shields), int(flight.hull), int(flight.max_hull), flight.primary_name(), flight.primary_damage_label(), flight.ammo, int(flight.heat), flight.overheat_remaining, flight.heat_sink_level, flight.power_mode.to_upper(), flight.evade_cooldown, campaign.combo_kills, campaign.combo_multiplier(), campaign.combat_score, phase_title], 20, MUTED)
			_add_secondary_selector(stack, campaign)
			if campaign.countermeasures:
				_add_label(stack, "C / FLARES %d OF %d / RECHARGE %.1fs" % [campaign.flares, CampaignState.FLARE_CAPACITY, flight.countermeasure_cooldown], 16, CYAN)
		var actions := HBoxContainer.new()
		stack.add_child(actions)
		_add_button(actions, "RESUME FLIGHT", func() -> void: resume_requested.emit()).grab_focus()
		_add_button(actions, "LOAD GAME" if flight.training else "SAVE / LOAD GAME", func() -> void: named_games_requested.emit())
		if flight.training:
			_add_button(stack, "RESTART TRAINING", func() -> void: launch_requested.emit())
	else:
		_add_label(stack, "PROVING RANGE / FLIGHT COMPLETE", 18, CYAN)
		_add_label(stack, "TELEMETRY RECEIVED.", 32, WHITE)
		_add_label(stack, "Targets disabled  %02d      Accuracy  %02d%%\nGround turrets  %02d       Missiles intercepted  %02d\nShots fired  %03d              Impacts  %02d\nTraining shield  %03d%%     Hull  %03d%%" % [flight.destroyed, int(flight.accuracy()), flight.turrets_destroyed, flight.interceptions, flight.shots, flight.impacts, int(flight.shields), int(flight.hull)], 23, WHITE)
		_add_label(stack, "Prototype only. No campaign progress or credits saved.", 18, MUTED)
		_add_button(stack, "FLY AGAIN", func() -> void: launch_requested.emit())
	_add_settings(stack)
	_add_label(stack, "Mouse aim + steer / WASD thrusters / Hold F to hold line\nShift dash / B roll / LMB fire / V burst governor / Space secondary\nC flares / X shield surge / R scope range / I repeat boss recon\n0–3 reactor / RMB or Esc pause / F11 fullscreen / ` developer panel", 16, MUTED)
	if mode == "title":
		_add_button(stack, "CREDITS & LICENSES", func() -> void: show_menu("credits", settings))
	else:
		_add_button(stack, "RETURN TO BRIEFING", func() -> void: title_requested.emit())
	_add_button(stack, "EXIT", func() -> void: quit_requested.emit())
	for child in stack.get_children():
		if mode != "pause" and child is Button:
			child.grab_focus()
			break

func show_notice(title: String, body: String, actions: Array[Dictionary]) -> void:
	mode = "notice"
	var stack: VBoxContainer = _menu_stack(760)
	_add_label(stack, title, 28, AMBER)
	var label: Label = _add_label(stack, body, 21, WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 690
	for action in actions:
		_add_button(stack, action["label"], action["action"])

func _show_equipped_ship(state: CampaignState) -> void:
	# A separate render keeps the canopy rails from covering the fitted guns.
	# The market refreshes on purchase, so a single frame per loadout suffices.
	var mount := Node2D.new()
	mount.position = Vector2(1160, 100)
	menu.add_child(mount)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(480, 310)
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	mount.add_child(viewport)
	var ship := FrontierArt.player_ship(state.ship, state.primary_level)
	viewport.add_child(ship)
	ship.get_child(0).set_instance_shader_parameter("parked", true)
	var bounds := FleetArt.mesh_for(state.ship).get_aabb()
	var view := Camera3D.new()
	view.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.size = maxf(bounds.size.x, bounds.size.z) * 0.91
	viewport.add_child(view)
	view.position = bounds.get_center() + Vector3(6, 8, -10)
	view.look_at(bounds.get_center())
	var screen := Sprite2D.new()
	screen.centered = false
	screen.texture = viewport.get_texture()
	mount.add_child(screen)
	var caption := Label.new()
	caption.position = Vector2(16, 10)
	caption.text = FlightState.PRIMARY_NAMES[state.primary_level].to_upper()
	caption.add_theme_color_override("font_color", CYAN)
	mount.add_child(caption)

func show_market(state: CampaignState, error: String = "") -> void:
	campaign = state
	mode = "market"
	var stack: VBoxContainer = _menu_stack(1140, 160)
	if not state.ship.is_empty():
		_show_equipped_ship(state)
	_add_label(stack, "ASTRA MARKET / SAFE HARBOR", 28, CYAN)
	var ship_name: String = "NO SHIP / EJECTION POD" if state.ship.is_empty() else CampaignState.SHIPS[state.ship]["name"]
	_add_label(stack, "%s     |     %d CREDITS     |     PRIMARY LV %d" % [ship_name, state.credits, state.primary_level], 22, WHITE)
	var result: String = SectorCatalog.name_for(state.sector).to_upper() + " COMPLETE" if state.last_result == "completed" else "PILOT RECOVERED" if state.last_result == "ejected" else "DOCKED"
	_add_label(stack, "%s / Ships and shields are fully repaired here, free of charge.\nHull purchases transfer fitted upgrades. Ejection loses the ship and its equipment." % result, 18, MUTED)
	if state.last_result == "completed":
		var dispatch := _add_label(stack, "LARK   /   " + SectorCatalog.DISPATCH[state.sector], 18, CYAN)
		dispatch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not error.is_empty():
		_add_label(stack, error, 19, VectorArt.HOSTILE)
	if state.ship.is_empty() and state.credits < state.price("rook"):
		_add_button(stack, "CLAIM FREE RESCUE SKIFF / NO DEBT", func() -> void: purchase_requested.emit("emergency"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	_add_label(stack, "SHIP EQUIPMENT / SCROLL FOR ALL MODULES", 16, CYAN)
	_add_secondary_selector(stack, state)
	var scroll := ScrollContainer.new()
	scroll.name = "EquipmentScroll"
	scroll.custom_minimum_size = Vector2(0, 270)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	scroll.add_child(grid)
	var descriptions: Dictionary = {
		"rook": ["Rook Scout", "100 hull / 100 shield. Balanced response.\n6-round bay. Replaces the current hull."],
		"hawk": ["Vector Hawk", "80 hull / 80 shield. 35% faster response.\nSmaller hitbox; 8-round bay."],
		"titan": ["Aegis Titan / PLAYER BATTLESHIP", "240 hull / 160 shield / 12-round bay.\n70% steering; larger hull. Transfers upgrades."],
		"bastion": ["Nova Bastion / PLAYER BATTLESHIP", "200 hull / 220 shield / 16-round bay.\n80% steering; larger hull. Transfers upgrades."],
		"primary": ["Advanced primary", "Quad Plasma -> Tachyon Beam.\nTransfers with hull; lost on ejection."],
		"shield": ["Deflector expansion", "+25 maximum shield. Two tiers.\nRecharged at stage boundaries."],
		"secondary": ["Concussion launcher", "8 damage / 1 ordnance. Manual aiming.\nIncludes 3 shared ordnance units."],
		"swarm": ["Swarm Rockets", "Three homing rockets / 2 ordnance per salvo.\nLocks up to 3 enemies. Includes 3 ordnance."],
		"emp": ["EMP Nova", "Clear visible missiles; stun systems for 2s.\n220m range / 3 ordnance. Includes 3 units."],
		"ammo": ["Shared ordnance reload", "Add up to 6 units, limited by the same bay.\nConcussion 1 / Swarm 2 / EMP 3 per use."],
		"cooling": ["Cooling vents / Lv %d of 2" % state.heat_sink_level, "-18% base heat per volley per level.\nTransfers with hull swaps; lost on ejection."],
		"headlight": ["Forward headlight", "Projects a wide beam ahead of the ship.\nActivates automatically in flight."],
		"tractor": ["Tractor beam", "Pulls mineral cores within 32m if unobstructed.\nAutomatic. Transfers with hull; lost on ejection."],
		"armor": ["Hull plating / Lv %d of 2" % state.hull_armor_level, "+25 maximum hull per level. Two tiers.\nTransfers with hull swaps; lost on ejection."],
		"countermeasures": ["Chaff / flare pod", "C diverts up to 4 nearby missiles; 8s cooldown.\nIncludes 3 separate charges; does not use ordnance."],
		"flare_reload": ["Flare reload / %d of %d" % [state.flares, CampaignState.FLARE_CAPACITY], "Refill the dedicated pod to 3 flare charges.\nSeparate from secondary ammunition."]
	}
	if state.primary_level == 0:
		descriptions["primary"] = ["Quad Plasma Repeaters", "4 converging bolts x1 damage; 4 volleys/s.\nWide, bright plasma. Heat, not ordnance."]
	elif state.primary_level == 1:
		descriptions["primary"] = ["Tachyon Beam Cannon", "3 damage/tick; 8 ticks/s; pierces small ships.\nWide continuous beam; cover/shields stop it."]
	for item: String in descriptions:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(520, 115)
		grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := MarketIcon.new()
		icon.kind = item
		icon.custom_minimum_size = Vector2(78, 96)
		row.add_child(icon)
		var details := VBoxContainer.new()
		row.add_child(details)
		_add_label(details, descriptions[item][0], 22, WHITE)
		_add_label(details, descriptions[item][1], 16, MUTED)
		var item_id: String = item
		var button: Button = _add_button(details, "BUY / %d CR" % state.price(item), func() -> void: purchase_requested.emit(item_id))
		var fitted: bool = item == state.ship or (item == "secondary" and state.secondary) or (item == "tractor" and state.tractor) or (item == "headlight" and state.headlight) or (item == "swarm" and state.swarm_launcher) or (item == "emp" and state.emp_launcher) or (item == "countermeasures" and state.countermeasures)
		var maximum: bool = (item == "primary" and state.primary_level >= 2) or (item == "shield" and state.shield_level >= 2) or (item == "cooling" and state.heat_sink_level >= 2) or (item == "armor" and state.hull_armor_level >= 2)
		if fitted or maximum:
			button.text = "EQUIPPED" if fitted else "MAXIMUM LEVEL"
			button.disabled = true
	_add_label(stack, "Enemies %d    Bosses %d    Asteroids %d    Ejections %d    Earned %d / Spent %d%s" % [state.stats["enemies"], state.stats["bosses"], state.stats["asteroids"], state.stats["ejections"], state.earned, state.spent, "    DEVELOPER-ASSISTED" if state.assisted else ""], 17, MUTED)
	_add_label(stack, "SCORE %d / BEST STREAK %d / MINERAL CORES %d\nFLY THROUGH GREEN $ HOOPS TO EARN CREDITS" % [state.combat_score, state.best_streak, state.stats["minerals"]], 17, AMBER)
	var accuracy: float = minf(100.0, 100.0 * state.debrief["hits"] / state.debrief["shots"]) if state.debrief["shots"] > 0 else 0.0
	_add_label(stack, "LAST SORTIE: %d SHOTS / %.1f%% ACCURACY\nRADARS %d / WEBS DISABLED %d / PIRATES %d" % [state.debrief["shots"], accuracy, state.stats["radars"], state.stats["webs"], state.stats["pirates"]], 16, MUTED)
	_add_label(stack, "TOUR %d / SECTORS CLEARED %d / %d / ENEMY HEALTH %.0f%%" % [state.tour, state.cleared_sectors.size(), state.required_sectors.size(), state.health_multiplier() * 100], 17, CYAN)
	var actions := HBoxContainer.new()
	stack.add_child(actions)
	_add_button(actions, "SECTOR MAP / CHOOSE DEPARTURE", func() -> void: depart_requested.emit())
	_add_button(actions, "SAVE / LOAD GAME", func() -> void: named_games_requested.emit())
	_add_button(stack, "RETURN TO TITLE / PROGRESS SAVED", func() -> void: title_requested.emit())

func show_named_games(names: PackedStringArray, can_save: bool, status: String, save: Callable, load_slot: Callable, back: Callable) -> void:
	mode = "named_games"
	var stack := _menu_stack(760)
	_add_label(stack, "NAMED GAMES", 28, CYAN)
	if can_save:
		_add_label(stack, "Flight saves restart the phase. Market saves keep your purchases.", 19, WHITE)
		var entry := LineEdit.new()
		entry.placeholder_text = "Save name (1-40 letters, numbers, spaces, - or _)"
		entry.max_length = 40
		stack.add_child(entry)
		entry.text_submitted.connect(save)
		_add_button(stack, "SAVE AS", func() -> void: save.call(entry.text))
	if not status.is_empty():
		_add_label(stack, status, 18, AMBER)
	if names.is_empty():
		_add_label(stack, "No named games yet.", 19, MUTED)
	else:
		var slots := OptionButton.new()
		for label in names:
			slots.add_item(label)
		stack.add_child(slots)
		_add_button(stack, "LOAD SELECTED GAME", func() -> void: load_slot.call(slots.get_item_text(slots.selected)))
	_add_button(stack, "BACK", back)

func show_sector_map(state: CampaignState = null) -> void:
	mode = "sector"
	var stack: VBoxContainer = _menu_stack(1100, 145)
	_add_label(stack, "SECTOR NAVIGATION / CHOOSE YOUR DESTINATION", 28, CYAN)
	_add_label(stack, "Lark has the distress traffic. Choose the next convoy to reach.", 20, WHITE)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 18)
	stack.add_child(grid)
	for id: String in SectorCatalog.NAMES:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(510, 170)
		grid.add_child(card)
		var contents := VBoxContainer.new()
		contents.add_theme_constant_override("separation", 12)
		card.add_child(contents)
		var heading := HBoxContainer.new()
		heading.add_theme_constant_override("separation", 12)
		contents.add_child(heading)
		var icon := SectorIcon.new()
		icon.sector = id
		icon.custom_minimum_size = Vector2(82, 92)
		heading.add_child(icon)
		var labels := VBoxContainer.new()
		heading.add_child(labels)
		var cleared: bool = state != null and state.cleared_sectors.has(id)
		_add_label(labels, SectorCatalog.name_for(id).to_upper() + ("  ✓ COMPLETED" if cleared else ""), 23, Color("#7ee9aa") if cleared else SectorCatalog.ACCENTS[id])
		var description: Label = _add_label(labels, SectorCatalog.DESCRIPTIONS[id], 16, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size.x = 380
		var request := _add_label(labels, SectorCatalog.DISTRESS[id], 16, WHITE)
		request.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		request.custom_minimum_size.x = 380
		var available: bool = SectorCatalog.AVAILABLE.has(id)
		var permitted: bool = available and (state == null or state.can_visit(id))
		var destination: String = id
		var button: Button = _add_button(contents, "IN DEVELOPMENT" if not available else "REPLAY SECTOR" if cleared and permitted else "CLEARED / FINISH REMAINING SECTOR" if cleared else "SELECT SECTOR", func() -> void: sector_selected.emit(destination))
		button.disabled = not permitted
	if state != null and state.replays_unlocked:
		_add_label(stack, "TOUR %d / REPLAYS UNLOCKED / ENEMY HEALTH %.0f%%\nClear all %d required worlds for this tour's debrief." % [state.tour, state.health_multiplier() * 100, state.required_sectors.size()], 18, MUTED)
	_add_button(stack, "BACK", func() -> void: sector_cancelled.emit())

func show_campaign_result(record: Dictionary, actions: Array[Dictionary], final_sector: String = "") -> void:
	mode = "campaign_result"
	var stack: VBoxContainer = _menu_stack(1450, 145)
	stack.add_theme_constant_override("separation", 10)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 24)
	stack.add_child(heading)
	var medal := CampaignMedal.new()
	medal.name = "CampaignMedal"
	medal.rank = int(record["rank"])
	medal.custom_minimum_size = Vector2(150, 155)
	heading.add_child(medal)
	var title := VBoxContainer.new()
	heading.add_child(title)
	_add_label(title, "%d WORLDS SECURED / TOUR %d COMPLETE" % [CampaignHonors.record_sectors(record).size(), record["tour"]], 23, CYAN)
	_add_label(title, CampaignHonors.RANKS[record["rank"]], 34, WHITE)
	_add_label(title, "%s MEDAL / RATING %d OF 1000" % [CampaignHonors.MEDALS[record["rank"]].to_upper(), record["rating"]], 24, AMBER)
	_add_label(title, "%s / %s" % ["DEVELOPER-ASSISTED / SEPARATE RECORDS" if record["assisted"] else "UNASSISTED", record["completed_at"]], 17, MUTED)
	if CampaignHonors.record_sectors(record).size() == SectorCatalog.AVAILABLE.size() and record["tour"] == 1:
		var last_arrival: String = SectorCatalog.DISPATCH.get(final_sector, "")
		var epilogue := _add_label(stack, ("LARK   /   " + last_arrival + "\n" if not last_arrival.is_empty() else "") + "I read the arrivals aloud, Tomas. Every name. When I finished, someone knocked twice on the hangar wall.", 19, CYAN)
		epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_label(stack, CampaignHonors.loadout_text(record["loadout"]), 19, WHITE)
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignStatistics"
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 95)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	for text in ["STATISTICS / SCROLL FOR ALL", "THIS TOUR", "LIFETIME"]:
		_add_label(grid, text, 20, CYAN)
	var labels: Dictionary = {
		"enemies": "Enemy ships / turrets defeated", "bosses": "Bosses defeated", "asteroids": "Asteroids destroyed",
		"eggs": "Egg ships destroyed", "guardians": "Hive guardians defeated", "pirates": "Pirates defeated",
		"shots": "Shots / accuracy samples", "hits": "Successful hit samples", "ejections": "Ship losses / ejections",
		"sorties": "Successful sorties", "radars": "Radars disabled", "webs": "Tripwires disabled",
		"minerals": "Salvage collected", "chain_rocks": "Chain-reaction shatters", "earned": "Credits earned",
		"spent": "Credits spent", "combat_score": "Combat score", "best_streak": "Best combat streak",
		"combo_bonus_credits": "Streak bonus credits", "mineral_credits": "Salvage credits",
		"accuracy_bonus_credits": "Accuracy bonus credits"
	}
	for key: String in labels:
		_add_label(grid, labels[key], 19, MUTED)
		_add_label(grid, str(record["totals"][key]), 19, WHITE)
		_add_label(grid, str(record["lifetime"][key]), 19, WHITE)
	_add_label(grid, "Accuracy", 19, MUTED)
	for key in ["totals", "lifetime"]:
		var metrics: Dictionary = record[key]
		_add_label(grid, "%.1f%%" % minf(100, 100.0 * metrics["hits"] / metrics["shots"]) if metrics["shots"] > 0 else "No shots fired", 19, WHITE)
	_add_label(grid, "Hull damage sustained", 19, MUTED)
	for key in ["totals", "lifetime"]:
		var complete: bool = record["damage_complete" if key == "totals" else "lifetime_damage_complete"]
		_add_label(grid, "%.1f%s" % [record[key]["hull_damage"], "" if complete else " (since upgrade only)"], 19, WHITE)
	var parts: Dictionary = CampaignHonors.score_parts(record["totals"], record["damage_complete"])
	_add_label(stack, "RATING: ACCURACY %d/300 + COMBAT %d/300 + SURVIVAL %d/250 + STREAK %d/150\nSpending credits never reduces your rank." % [parts["accuracy"], parts["combat"], parts["survival"], parts["streak"]], 18, AMBER)
	if not record["damage_complete"]:
		_add_label(stack, "LEGACY SAVE: earlier hull damage was not tracked. Survival points unavailable this tour.", 17, MUTED)
	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 14)
	buttons.add_theme_constant_override("v_separation", 10)
	stack.add_child(buttons)
	for action in actions:
		var button: Button = _add_button(buttons, action["label"], action["action"])
		button.custom_minimum_size.x = 660
		if buttons.get_child_count() == 1:
			button.grab_focus()

func show_hall_of_fame(records: Array[Dictionary], assisted: bool, back: Callable, toggle: Callable) -> void:
	mode = "hall_of_fame"
	var stack: VBoxContainer = _menu_stack(1450, 145)
	_add_label(stack, "HALL OF FAME / " + ("DEVELOPER-ASSISTED" if assisted else "UNASSISTED"), 30, CYAN)
	_add_label(stack, "Completed tours / highest rating first / select a record for its medal, statistics and loadout.", 20, MUTED)
	_add_button(stack, "SHOW " + ("UNASSISTED" if assisted else "DEVELOPER-ASSISTED") + " RECORDS", toggle)
	var scroll := ScrollContainer.new()
	scroll.name = "HallOfFameRecords"
	scroll.custom_minimum_size = Vector2(0, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	scroll.add_child(rows)
	if records.is_empty():
		_add_label(rows, "No completed tours in this category yet.", 23, WHITE)
	for record in records:
		var entry: Dictionary = record
		var label: String = "%04d / %s / TOUR %d / %d WORLDS\n%s / %s / %s" % [record["rating"], CampaignHonors.RANKS[record["rank"]], record["tour"], CampaignHonors.record_sectors(record).size(), record["completed_at"], CampaignState.SHIPS[record["loadout"]["ship"]]["name"], record["operation_id"].left(8)]
		_add_button(rows, label, func() -> void:
			show_campaign_result(entry, [{"label": "BACK TO RECORDS", "action": func() -> void: show_hall_of_fame(records, assisted, back, toggle)}]))
	_add_button(stack, "BACK", back)

func _add_secondary_selector(stack: VBoxContainer, state: CampaignState) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	stack.add_child(row)
	_add_label(row, "SPACE / WEAPON STATION", 16, CYAN)
	var selector := OptionButton.new()
	selector.custom_minimum_size.x = 280
	row.add_child(selector)
	var weapons: Array = CampaignState.SECONDARIES.keys()
	for i in range(weapons.size()):
		var weapon: String = weapons[i]
		selector.add_item("%s / %d ORDNANCE" % [CampaignState.SECONDARIES[weapon]["name"].to_upper(), CampaignState.SECONDARIES[weapon]["ammo"]])
		selector.set_item_disabled(i, not state.owns_secondary(weapon))
		if state.selected_secondary == weapon:
			selector.select(i)
	selector.disabled = not (state.secondary or state.swarm_launcher or state.emp_launcher)
	selector.item_selected.connect(func(index: int) -> void: secondary_selected.emit(weapons[index]))

func show_debug(god_mode: bool, zero_heat: bool = false, infinite_ammo: bool = false, one_hit: bool = false) -> void:
	mode = "debug"
	var stack: VBoxContainer = _menu_stack(860)
	_add_label(stack, "DEVELOPER TESTING / ASSISTED RUN", 27, AMBER)
	_add_label(stack, "Training jumps use a separate test save.\nCampaign cheats mark the current operation as assisted.", 20, MUTED)
	var sectors := HBoxContainer.new()
	stack.add_child(sectors)
	for id in SectorCatalog.AVAILABLE:
		var destination: String = id
		_add_button(sectors, "TEST: " + SectorCatalog.name_for(id).to_upper(), func() -> void: debug_action.emit("sector:" + destination))
	var actions := GridContainer.new()
	actions.columns = 2
	stack.add_child(actions)
	for entry in [["reset_credits", "RESET WALLET TO ZERO"], ["refill", "REFILL HULL / SHIELDS / ALL AMMO"], ["max", "MAX EQUIPMENT"], ["god", "GOD MODE: " + ("ON" if god_mode else "OFF")], ["zero_heat", "ZERO HEAT: " + ("ON" if zero_heat else "OFF")], ["infinite_ammo", "INFINITE ORDNANCE: " + ("ON" if infinite_ammo else "OFF")], ["one_hit", "ONE-HIT EXPOSED TARGETS: " + ("ON" if one_hit else "OFF")], ["kill_boss", "DEFEAT CURRENT BOSS"], ["rook", "EQUIP ROOK"], ["hawk", "EQUIP HAWK"]]:
		var action: String = entry[0]
		_add_button(actions, entry[1], func() -> void: debug_action.emit(action))
	var grid := GridContainer.new()
	grid.columns = 2
	stack.add_child(grid)
	for phase: String in CampaignState.PHASES:
		var destination: String = phase
		_add_button(grid, "JUMP: " + phase.to_upper(), func() -> void: debug_action.emit("phase:" + destination))
	_add_button(stack, "CLOSE DEBUG PANEL", func() -> void: debug_action.emit("close"))

class SectorIcon extends Control:
	var sector: String = "ignis"
	func _draw() -> void:
		var tint: Color = SectorCatalog.ACCENTS[sector]
		var center := Vector2(41, 46)
		draw_circle(center, 32, tint.darkened(0.78))
		draw_arc(center, 33, 0, TAU, 48, tint, 2, true)
		for offset in [-17.0, 0.0, 17.0]:
			var width: float = sqrt(32 * 32 - offset * offset)
			draw_line(center + Vector2(-width, offset), center + Vector2(width, offset), tint.darkened(0.3), 1, true)
		for curve in [-0.5, 0.5]:
			var points := PackedVector2Array()
			for i in range(25):
				var angle: float = PI * i / 24
				points.append(center + Vector2(sin(angle) * 32 * curve, cos(angle) * 32))
			draw_polyline(points, tint.darkened(0.2), 1, true)
		if sector == "cryo":
			draw_colored_polygon(PackedVector2Array([center + Vector2(-18, -22), center + Vector2(0, -32), center + Vector2(18, -22), center + Vector2(5, -17), center + Vector2(-8, -20)]), tint)

class MarketIcon extends Control:
	var kind: String = "rook"
	func _draw() -> void:
		var center := Vector2(39, 48)
		var points: PackedVector2Array
		if kind in ["titan", "bastion"]:
			var tint := Color("#d3b3ef") if kind == "bastion" else Color("#70e2e7")
			draw_rect(Rect2(center + Vector2(-14, -34), Vector2(28, 68)), Color("#263c48"))
			draw_rect(Rect2(center + Vector2(-14, -34), Vector2(28, 68)), tint, false, 2)
			for side in [-1, 1]:
				draw_rect(Rect2(center + Vector2(side * 25 - 6, -17), Vector2(12, 47)), tint, false, 2)
				for i in range(3):
					draw_line(center + Vector2(side * 13, -20 + i * 18), center + Vector2(side * 29, -20 + i * 18), Color("#ffa65c"), 3)
			if kind == "bastion":
				draw_arc(center, 30, 0, TAU, 24, tint, 1.5, true)
			return
		elif kind == "armor":
			for i in range(3):
				draw_rect(Rect2(center + Vector2(-24 + i * 6, -23 + i * 8), Vector2(36, 34)), Color("#263c48"))
				draw_rect(Rect2(center + Vector2(-24 + i * 6, -23 + i * 8), Vector2(36, 34)), Color("#ffa65c"), false, 2)
			return
		elif kind == "shield":
			points = PackedVector2Array([Vector2(-24, -23), Vector2(24, -23), Vector2(20, 7), Vector2(0, 30), Vector2(-20, 7)])
		elif kind == "primary":
			for i in range(3):
				draw_line(center + Vector2(-23, -16 + i * 16), center + Vector2(24, -16 + i * 16), Color("#ffa65c"), 3, true)
			return
		elif kind == "cooling":
			for i in range(5):
				var x: float = center.x - 24 + i * 12
				draw_rect(Rect2(x, center.y - 27, 5, 54), Color("#70e2e7"))
			draw_line(center + Vector2(-30, 0), center + Vector2(30, 0), Color("#ffa65c"), 2)
			return
		elif kind == "tractor":
			for radius in [12.0, 21.0, 30.0]:
				draw_arc(center, radius, PI * 0.25, PI * 1.75, 20, Color("#70e2e7"), 2, true)
			draw_circle(center + Vector2(23, 0), 5, Color("#ffa65c"))
			return
		elif kind == "swarm":
			for i in range(3):
				var x: float = center.x - 20 + i * 20
				draw_line(Vector2(x, center.y + 23), Vector2(x, center.y - 20), Color("#ffa65c"), 3)
				draw_polyline(PackedVector2Array([Vector2(x - 6, center.y - 13), Vector2(x, center.y - 24), Vector2(x + 6, center.y - 13)]), Color("#70e2e7"), 2, true)
			return
		elif kind == "emp":
			for radius in [10.0, 20.0, 30.0]:
				draw_arc(center, radius, 0, TAU, 32, Color("#70e2e7"), 2, true)
			return
		elif kind in ["countermeasures", "flare_reload"]:
			for i in range(3):
				var at: Vector2 = center + Vector2((i - 1) * 21, -absf(i - 1) * 12)
				draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), Color("#ffa65c"), 2)
				draw_line(at + Vector2(0, -7), at + Vector2(0, 7), Color("#ffa65c"), 2)
				draw_line(at, center + Vector2((i - 1) * 9, 28), Color("#70e2e7"), 2)
			return
		elif kind == "secondary" or kind == "ammo":
			points = PackedVector2Array([Vector2(0, -30), Vector2(11, -12), Vector2(11, 15), Vector2(20, 27), Vector2(-20, 27), Vector2(-11, 15), Vector2(-11, -12)])
		else:
			points = PackedVector2Array([Vector2(0, -28), Vector2(30, 25), Vector2(8, 15), Vector2(0, 29), Vector2(-8, 15), Vector2(-30, 25)])
			if kind == "hawk":
				for i in range(points.size()):
					points[i].y *= 0.65
		for i in range(points.size()):
			points[i] += center
		draw_colored_polygon(points, Color("#172c37"))
		points.append(points[0])
		draw_polyline(points, Color("#70e2e7"), 2, true)

func _add_settings(stack: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	stack.add_child(row)
	for item in [["reduced_effects", "Reduced effects"], ["mute", "Mute audio"], ["shake", "Camera motion"], ["target_ranges", "Target brackets and distances"]]:
		var check := CheckBox.new()
		check.text = item[1]
		check.button_pressed = bool(settings.get(item[0], false))
		var key: String = item[0]
		check.toggled.connect(func(value: bool) -> void: setting_changed.emit(key, value))
		row.add_child(check)
	var response_row := HBoxContainer.new()
	stack.add_child(response_row)
	_add_label(response_row, "Flight response  ", 18, MUTED)
	var options := OptionButton.new()
	for option in ["Soft", "Balanced", "Responsive"]:
		options.add_item(option)
	options.selected = int(settings.get("response", 1))
	options.item_selected.connect(func(index: int) -> void: setting_changed.emit("response", index))
	response_row.add_child(options)
	for entry in [["voice_volume", "Voices / Lark & Vale  ", 70], ["music_volume", "Ambient music (0 = off)    ", AmbientMusic.DEFAULT_VOLUME]]:
		var volume_row := HBoxContainer.new()
		stack.add_child(volume_row)
		_add_label(volume_row, entry[1], 18, MUTED)
		var volume := HSlider.new()
		volume.min_value = 0
		volume.max_value = 100
		volume.step = 5
		volume.custom_minimum_size = Vector2(180, 28)
		volume.value = int(settings.get(entry[0], entry[2]))
		var key: String = entry[0]
		volume.value_changed.connect(func(value: float) -> void: setting_changed.emit(key, int(value)))
		volume_row.add_child(volume)

func _add_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _add_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.022, 0.04, 0.06, 0.97)
	panel.border_color = Color("#40545b")
	panel.set_border_width_all(1)
	panel.border_width_left = 3
	panel.corner_radius_top_right = 16
	result.set_stylebox("panel", "PanelContainer", panel)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#182b37") if style_name == "normal" else Color("#27424a")
		style.border_color = AMBER if style_name == "focus" else Color("#4a777f")
		style.set_border_width_all(1)
		style.content_margin_left = 16
		style.content_margin_right = 16
		result.set_stylebox(style_name, "Button", style)
	result.set_color("font_color", "Button", WHITE)
	result.set_color("font_hover_color", "Button", CYAN)
	return result

func _text(at: Vector2, text: String, size_px: int = 20, color: Color = WHITE) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _draw_console() -> void:
	var reduced: bool = settings.get("reduced_effects", false)
	var shield_hit := AMBER if flight.last_hit_hull else CYAN
	var impact := clampf(flight.damage_flash / 0.35, 0, 1)
	var muzzle := clampf(flight.fire_cooldown / (0.25 if flight.primary_level == 1 else 0.125), 0, 1)
	var electrical := gate_warning or lightning_warning
	var interference := flight.radar_static_remaining > 0 or electrical or thermal_warning
	var hazard := interference or flight.hull < flight.max_hull * 0.30
	var power := Color("#69c4d1")
	if flight.power_mode == "weapons":
		power = AMBER
	elif flight.power_mode == "shields":
		power = Color("#81aaff")
	elif flight.power_mode == "engines":
		power = Color("#84deb1")
	draw_set_transform_matrix(CockpitInstruments.artwork_transform(size))
	for side in [-1.0, 1.0]:
		# The louvered annunciators bolt into the sill below each MFD. Outer
		# bevels catch the currently routed bus and immediate weapon light.
		var x: float = 447.0 if side < 0 else 798.0
		var plate := PackedVector2Array([Vector2(x, 717), Vector2(x + 104, 717), Vector2(x + 111, 724), Vector2(x + 107, 749), Vector2(x + 3, 749), Vector2(x - 4, 740)])
		draw_colored_polygon(plate, Color("#101b20"))
		draw_line(plate[0], plate[1], Color("#5a7379"), 1.4, true)
		draw_line(plate[1], plate[2], Color("#577079"), 1.5, true)
		draw_line(plate[3], plate[4], Color("#050a0c"), 2.0, true)
		for bolt in [Vector2(x + 3, 722), Vector2(x + 103, 743)]:
			draw_circle(bolt, 2.2, Color("#80969a"))
			draw_line(bolt - Vector2(1.4, -0.7), bolt + Vector2(1.4, -0.7), Color("#1b262a"), 1.1)
		var warning := hazard if side < 0 else flight.overheat_remaining > 0.0
		var tint := (AMBER if warning else power) if side < 0 else (AMBER if flight.heat > 55 else CYAN)
		_text(Vector2(x + 13, 730), ("CAUTION" if hazard else "DEFLECTOR") if side < 0 else "THERMAL LOAD", 8, Color("#afc3c6"))
		for i in range(8):
			var lamp := Rect2(x + 12 + i * 10, 735, 7, 5)
			var level := flight.shields / flight.max_shields if side < 0 else flight.heat / 100.0
			var lit := level * 8.0 > i or warning
			draw_rect(lamp, Color("#324046"))
			if lit:
				draw_rect(lamp.grow(-1), tint)
				if not reduced:
					draw_rect(lamp.grow(1.5), Color(tint, 0.13))
		var rail := PackedVector2Array([Vector2(688 + side * 553, 655), Vector2(688 + side * 463, 617), Vector2(688 + side * 389, 578)])
		var spill := power
		var intensity := 0.15
		if muzzle > 0.0 and not reduced:
			spill = Color("#fbd398") if flight.primary_level == 0 else Color("#85dcff")
			intensity += 0.37 * muzzle * muzzle
		if impact > 0.0:
			spill = shield_hit
			intensity += (0.10 if reduced else 0.50) * impact
		if interference:
			spill = Color("#baacff") if electrical else Color("#f1a666") if thermal_warning else Color("#92d89e")
			intensity += 0.06 if reduced else 0.13 * (0.5 + 0.5 * sin(floorf(flight.elapsed * 8.0) * 2.7))
		draw_polyline(rail, Color(spill, intensity * 0.25), 12, true)
		draw_polyline(rail, Color(spill, intensity * 0.5), 4, true)
		draw_polyline(rail, Color(spill, intensity), 1.3, true)
		_draw_canopy_rail(side, spill, intensity)
		if flight.hull / flight.max_hull < (0.62 if side < 0 else 0.31) and not flight.training:
			_draw_glass_fracture(side)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_canopy_rail(side: float, spill: Color, intensity: float) -> void:
	var hinge := Vector2(688 + side * 446, 210)
	var knee := Vector2(688 + side * 561, 391)
	var sill := Vector2(688 + side * 627, 563)
	var rail := PackedVector2Array([hinge, knee, sill])
	# A recessed fiber-optic bus follows the metal spar down to the console.
	draw_polyline(rail, Color("#142126"), 6.5, true)
	draw_polyline(rail, Color(spill, 0.24 + intensity * 0.55), 2.4, true)
	for i in [0.17, 0.47, 0.84]:
		var at := hinge.lerp(knee, i)
		var along := hinge.direction_to(knee)
		var cross := along.orthogonal()
		var bracket := PackedVector2Array([at - along * 5 - cross * 6, at + along * 5 - cross * 6, at + along * 5 + cross * 6, at - along * 5 + cross * 6])
		draw_colored_polygon(bracket, Color("#3a444a"))
		draw_line(bracket[0], bracket[3], Color("#adbbba"), 1.2, true)
		draw_line(bracket[1], bracket[2], Color("#111a20"), 1.4, true)
		draw_circle(at, 2.2, Color("#12191c"))
		draw_line(at - cross * 1.3, at + cross * 1.3, Color("#738888"), 1)
	var ship := campaign.ship if campaign != null and not flight.training else "rook"
	var paint: Color = Color("#db985c") if ship == "titan" else Color("#8bb3d2") if ship == "hawk" else Color("#adb775") if ship == "bastion" else Color("#74b3b4")
	for i in range(3):
		var at := knee.lerp(sill, 0.23 + 0.035 * i)
		var axis := knee.direction_to(sill).orthogonal()
		draw_line(at - axis * 5, at + axis * 5, paint, 2.6, true)

func _draw_glass_fracture(side: float) -> void:
	var origin := Vector2(145, 359) if side < 0 else Vector2(1250, 395)
	var paths := [
		[Vector2.ZERO, Vector2(14, -6), Vector2(21, -3), Vector2(38, -15), Vector2(57, -16)],
		[Vector2(21, -3), Vector2(29, 6), Vector2(45, 12), Vector2(51, 25)],
		[Vector2(38, -15), Vector2(40, -22), Vector2(55, -31)],
		[Vector2.ZERO, Vector2(11, 9), Vector2(17, 24), Vector2(35, 32)]]
	for path: Array in paths:
		var crack := PackedVector2Array()
		for vertex: Vector2 in path:
			crack.append(origin + vertex * Vector2(-side, 1))
		draw_polyline(crack, Color(0.86, 0.94, 0.95, 0.44), 1.1, true)

func _draw_flight_path(center: Vector2) -> void:
	if autopilot:
		return
	# Horizon wings roll with the outside world. The small velocity pip follows
	# lateral motion independently of the gun reticle.
	var level := Vector2.from_angle(sensors.horizon_bank)
	var horizon := center + Vector2(0, -sensors.below_horizon * 90)
	for side in [-1.0, 1.0]:
		draw_line(horizon + side * level * 58, horizon + side * level * 84, Color(CYAN, 0.36), 1.2, true)
		draw_line(horizon + side * level * 84, horizon + side * level * 84 + level.orthogonal() * 5, Color(CYAN, 0.36), 1.2, true)
	if flight.offset_velocity.length_squared() > 2.5:
		var motion := Vector2(flight.offset_velocity.x, -flight.offset_velocity.y) / maxf(1, flight.speed)
		var pip := center + motion.limit_length(1.0) * size.y * 0.12
		draw_arc(pip, 5, 0, TAU, 16, Color(WHITE, 0.75), 1.4, true)
		draw_line(pip - Vector2(12, 0), pip - Vector2(5, 0), Color(WHITE, 0.75), 1.4)
		draw_line(pip + Vector2(5, 0), pip + Vector2(12, 0), Color(WHITE, 0.75), 1.4)
	if show_lead and flight.primary_level == 1 and Rect2(Vector2.ZERO, size).has_point(lead_marker):
		draw_arc(lead_marker, 7, 0, TAU, 20, AMBER, 1.7, true)
		draw_circle(lead_marker, 1.5, AMBER)
	if sensors.collision_seconds < 1.9:
		var escape := Vector2(sensors.escape_side, 0)
		var arrow := center + escape * 92 + Vector2.DOWN * 62
		draw_polyline(PackedVector2Array([arrow - escape * 10 + Vector2.UP * 7, arrow, arrow - escape * 10 + Vector2.DOWN * 7]), AMBER, 2.3, true)

func _draw() -> void:
	if flight == null or font == null:
		return
	var width: float = size.x
	var height: float = size.y
	draw_line(Vector2(44, 48), Vector2(88, 48), AMBER, 3.0, true)
	draw_line(Vector2(44, 48), Vector2(60, 78), AMBER, 3.0, true)
	draw_line(Vector2(88, 48), Vector2(60, 78), CYAN, 2.0, true)
	_text(Vector2(108, 72), "COSMIC CONFLICT", 30)
	_text(Vector2(108, 99), "FLIGHT LAB  /  %s  /  ORIGINAL VECTOR WORLDS" % ProjectSettings.get_setting("application/config/version"), 14, MUTED)
	_text(Vector2(width - 300, 58), SectorCatalog.name_for(campaign.sector).to_upper() if campaign != null and not flight.training else "IGNIS PRIME", 23, SectorCatalog.ACCENTS[campaign.sector] if campaign != null else AMBER)
	_text(Vector2(width - 300, 85), "LOCAL SIMULATION  //  NO UPLINK", 14, MUTED)
	draw_line(Vector2(44, 125), Vector2(width - 44, 125), Color("#33424c"), 1)
	if mode != "flight":
		if mode in ["title", "credits", "market"]:
			_text(Vector2(width - 530, height - 168), "ASTRA / ORBITAL STATION" if mode == "market" else "ROOK / HANGAR PREVIEW", 28, CYAN)
			_text(Vector2(width - 530, height - 130), "BOUNDED FLIGHT. UNBOUNDED HORIZONS.", 16, MUTED)
		_text(Vector2(110, height - 34), "SIX SECTORS / PLAYER BATTLESHIPS / LOCAL HALL OF FAME", 15, MUTED)
		return
	_draw_console()
	_text(Vector2(width - 260, 170), "%02d  TARGETS DISABLED" % flight.destroyed, 18, CYAN)
	_text(Vector2(width - 260, 198), "%02d%%  ACCURACY" % int(flight.accuracy()), 18, MUTED)
	if not flight.training and campaign != null:
		_text(Vector2(width - 310, 226), "%d CR / STREAK %dX" % [campaign.credits, campaign.combo_multiplier()], 17, AMBER)
		_text(Vector2(width - 310, 250), "SCORE %d%s" % [campaign.combat_score, " / ASSISTED" if campaign.assisted else ""], 14, MUTED)
	for contact in contacts:
		var screen: Vector2 = contact["screen"]
		var distance: float = contact["distance"]
		var tint: Color = contact["color"]
		var label: String = contact.get("label", "")
		if not label.is_empty():
			_text(screen + Vector2(-60, -30), label, 13, tint)
		if not show_target_ranges:
			continue
		tint.a = 0.65
		if contact.get("boss_part", false):
			if contact["shielded"]:
				tint = Color(MUTED, 0.65)
			for i in range(3):
				var angle := i * TAU / 3.0 - PI / 2.0
				draw_arc(screen, 20, angle - 0.36, angle + 0.36, 10, tint, 1.5, true)
				var radial := Vector2.from_angle(angle)
				draw_line(screen + radial * 20, screen + radial * 25, tint, 1.5, true)
		else:
			draw_line(screen + Vector2(-22, -14), screen + Vector2(-22, -22), tint, 1.2)
			draw_line(screen + Vector2(-22, -22), screen + Vector2(-14, -22), tint, 1.2)
			draw_line(screen + Vector2(22, 14), screen + Vector2(22, 22), tint, 1.2)
			draw_line(screen + Vector2(22, 22), screen + Vector2(14, 22), tint, 1.2)
		_text(screen + Vector2(30, 5), "%03dm" % int(distance), 14, tint)
	for location in incoming:
		var marker: Vector2 = location.clamp(Vector2(35, 245), Vector2(width - 35, height - 200))
		draw_polyline(PackedVector2Array([marker + Vector2(0, -18), marker + Vector2(18, 0), marker + Vector2(0, 18), marker + Vector2(-18, 0), marker + Vector2(0, -18)]), VectorArt.HOSTILE, 1.5, true)
	for location in salvage_contacts:
		draw_arc(location, 15, 0, TAU, 24, CYAN, 1.5, true)
		_text(location + Vector2(21, 5), "SALVAGE CORE", 14, CYAN)
	var center := Vector2(width * 0.5, height * 0.5)
	_draw_flight_path(center)
	draw_circle(center, 3, Color(CYAN, 0.25), false, 1, true)
	draw_line(center, cursor, Color(CYAN, 0.09), 1, true)
	var reticle_color: Color = AMBER if flight.hit_flash > 0.0 else CYAN
	draw_arc(cursor, 12, 0, TAU, 40, reticle_color, 1.5, true)
	if not flight.training and flight.heat > 2.0:
		var hot := VectorArt.HOSTILE if flight.heat >= 76.0 else AMBER
		draw_arc(cursor, 16.0, PI * 0.12, PI * (0.12 + 0.76 * flight.heat / 100.0), 24, hot, 2.0, true)
	for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(cursor + direction * 17, cursor + direction * 27, reticle_color, 2, true)
	draw_circle(cursor, 1.8, WHITE)
	if flight.hit_flash > 0.0:
		for side in [-1, 1]:
			draw_line(cursor + Vector2(side * 7, -7), cursor + Vector2(side * 3, -3), AMBER, 2)
			draw_line(cursor + Vector2(side * 7, 7), cursor + Vector2(side * 3, 3), AMBER, 2)
	if flight.damage_flash > 0.0:
		draw_rect(Rect2(5, 5, width - 10, height - 10), Color(1, 0.35, 0.16, flight.damage_flash), false, 9)
		_text(Vector2(center.x - 100, center.y + 125), flight.last_impact, 20, AMBER)
	if Time.get_ticks_msec() / 1000.0 < message_until:
		_text(Vector2(center.x - 280, height - 250), message, 20, AMBER)
	_text(Vector2(48, height - 24), "WASD  THRUST    B  ROLL    R  RADAR    RMB / ESC  FLIGHT CONTROLS", 14, MUTED)
