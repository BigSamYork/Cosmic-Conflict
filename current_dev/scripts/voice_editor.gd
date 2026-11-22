class_name VoiceEditor
extends Control

const WHITE := Color("#e5f2f2")
const MUTED := Color("#a0b3c5")
const CYAN := Color("#70e2e7")
const AMBER := Color("#ffa65c")
const BACKGROUND := Color("#0b1220")
const SURFACE := Color("#131f30")

var document := VoiceDocument.new()
var initial_path: String = ""
var preview_cache_directory: String = "user://voice-cache"
var selected: Dictionary = {}
var previous_chances: Dictionary = {}
var pending_action: Callable
var loading_fields: bool = false
var preview_busy: bool = false
var preview_request: int = 0
var previous_auto_quit: bool = true
var preview: ComputerVoice
var search: LineEdit
var categories: OptionButton
var sayings: ItemList
var details_scroll: ScrollContainer
var library_count: Label
var file_label: Label
var state_label: Label
var heading: Label
var event_label: Label
var words: TextEdit
var enabled_toggle: CheckButton
var chance: SpinBox
var chance_slider: HSlider
var cooldown: SpinBox
var frequency_hint: Label
var character_count: Label
var status: Label
var preview_status: Label
var save_button: Button
var save_as_button: Button
var add_button: Button
var exit_button: Button
var play_button: Button
var stop_button: Button
var file_dialog: FileDialog
var unsaved_dialog: ConfirmationDialog
var error_dialog: AcceptDialog
var add_dialog: ConfirmationDialog
var add_category: OptionButton
var add_event: OptionButton
var add_words: TextEdit
var add_error: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var window := get_window()
	window.title = "Cosmic Conflict - Voice Editor"
	window.content_scale_size = Vector2i.ZERO
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.min_size = Vector2i(1000, 740)
	window.size = Vector2i(1280, 860)
	previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	window.close_requested.connect(_request_exit)
	theme = _make_theme()
	_build_ui()
	_build_dialogs()
	_show_selection()
	if initial_path.is_empty():
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--voice-file="):
				initial_path = argument.trim_prefix("--voice-file=")
	if initial_path.is_empty():
		initial_path = ProjectSettings.globalize_path(VoiceCatalog.DEFAULT_PATH if OS.has_feature("editor") else VoiceCatalog.USER_PATH)
	_open_document(initial_path)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var page := _column(margin, 18)
	var header := _row(page, 16)
	var brand := _column(header, 4)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(brand, "COSMIC CONFLICT  /  VOICE STUDIO", 13, CYAN)
	_label(brand, "Give your computer a personality.", 27)
	_label(brand, "Edit the words. Set the timing. Hear the result.", 15, MUTED)
	var tools := _row(header, 8)
	tools.alignment = BoxContainer.ALIGNMENT_END
	tools.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_button(tools, "Open...", func() -> void: _request_action(_open_dialog))
	save_as_button = _button(tools, "Save as...", _save_as_dialog)
	save_button = _button(tools, "Save changes", _save_current, true)
	var file_bar := _row(page, 12)
	state_label = _label(file_bar, "SAVED", 12, CYAN)
	state_label.custom_minimum_size.x = 142
	file_label = _label(file_bar, "", 13, MUTED)
	file_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_button(file_bar, "Game file", func() -> void: _request_action(_open_document.bind(ProjectSettings.globalize_path(VoiceCatalog.USER_PATH))))
	if OS.has_feature("editor"):
		_button(file_bar, "Source file", func() -> void: _request_action(_open_document.bind(ProjectSettings.globalize_path(VoiceCatalog.DEFAULT_PATH))))
	_button(file_bar, "Show folder", _show_folder)
	var workspace := HSplitContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.split_offset = -220
	page.add_child(workspace)
	var library := _card(workspace)
	library.custom_minimum_size.x = 310
	var library_header := _row(library, 10)
	_label(library_header, "SAYING LIBRARY", 13, CYAN).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button = _button(library_header, "Add saying", _open_add_dialog, true)
	search = LineEdit.new()
	search.placeholder_text = "Search words, IDs or events..."
	search.clear_button_enabled = true
	search.text_changed.connect(func(_value: String) -> void: _refresh_list())
	library.add_child(search)
	categories = OptionButton.new()
	categories.fit_to_longest_item = false
	categories.item_selected.connect(func(_index: int) -> void: _refresh_list())
	library.add_child(categories)
	library_count = _label(library, "", 13, MUTED)
	sayings = ItemList.new()
	sayings.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sayings.icon_mode = ItemList.ICON_MODE_TOP
	sayings.max_text_lines = 2
	sayings.item_selected.connect(_select_line)
	library.add_child(sayings)
	_label(library, "Your original IDs and events stay intact.", 12, MUTED)
	details_scroll = ScrollContainer.new()
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.custom_minimum_size.x = 500
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	workspace.add_child(details_scroll)
	var detail := _card(details_scroll)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail_header := _row(detail, 12)
	var titles := _column(detail_header, 4)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading = _label(titles, "Choose a saying", 22)
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	event_label = _label(titles, "", 13, MUTED)
	event_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	enabled_toggle = CheckButton.new()
	enabled_toggle.text = "Enabled"
	enabled_toggle.toggled.connect(_toggle_enabled)
	detail_header.add_child(enabled_toggle)
	_label(detail, "WHAT THE COMPUTER SAYS", 13, CYAN)
	words = TextEdit.new()
	words.custom_minimum_size.y = 150
	words.size_flags_vertical = Control.SIZE_EXPAND_FILL
	words.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	words.placeholder_text = "Type the words you want to hear..."
	words.add_theme_font_size_override("font_size", 20)
	words.text_changed.connect(_change_text)
	detail.add_child(words)
	character_count = _label(detail, "", 12, MUTED)
	var settings_row := _row(detail, 28)
	var chance_column := _column(settings_row, 8)
	chance_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(chance_column, "CHANCE WHEN SELECTED", 12, CYAN)
	var chance_row := _row(chance_column, 12)
	chance_slider = HSlider.new()
	chance_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chance_slider.max_value = 100
	chance_slider.step = 1
	chance_slider.value_changed.connect(_change_chance)
	chance_row.add_child(chance_slider)
	chance = SpinBox.new()
	chance.min_value = 0
	chance.max_value = 100
	chance.step = 1
	chance.suffix = "%"
	chance.custom_minimum_size.x = 104
	chance.value_changed.connect(_change_chance)
	chance_row.add_child(chance)
	var cooldown_column := _column(settings_row, 8)
	_label(cooldown_column, "MINIMUM REPEAT DELAY", 12, CYAN)
	cooldown = SpinBox.new()
	cooldown.min_value = 0
	cooldown.max_value = 86400
	cooldown.step = 0.01
	cooldown.suffix = "sec"
	cooldown.custom_minimum_size.x = 196
	cooldown.value_changed.connect(_change_cooldown)
	cooldown_column.add_child(cooldown)
	frequency_hint = _label(detail, "", 14, MUTED)
	frequency_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frequency_hint.custom_minimum_size.y = 54
	var separator := HSeparator.new()
	detail.add_child(separator)
	var preview_row := _row(detail, 12)
	play_button = _button(preview_row, "Play voice preview", _play_preview, true)
	stop_button = _button(preview_row, "Stop", _stop_preview)
	stop_button.disabled = true
	var preview_note := _label(preview_row, "Offline audio\nNo need to save first.", 12, MUTED)
	preview_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview_status = _label(detail, "Preview uses the game's voice and radio effects.", 13, MUTED)
	preview_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer := _row(page, 12)
	status = _label(footer, "Ready.", 13, MUTED)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label(footer, "Ctrl+O  Open     Ctrl+S  Save     Ctrl+Shift+S  Save as", 12, MUTED)
	exit_button = _button(footer, "Exit editor", _request_exit)

func _build_dialogs() -> void:
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; Computer voice JSON"])
	file_dialog.use_native_dialog = DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE)
	file_dialog.file_selected.connect(_file_selected)
	file_dialog.canceled.connect(func() -> void: pending_action = Callable())
	add_child(file_dialog)
	unsaved_dialog = ConfirmationDialog.new()
	unsaved_dialog.title = "Keep your changes?"
	unsaved_dialog.dialog_text = "This voice file has unsaved changes.\nSave them before continuing?"
	unsaved_dialog.ok_button_text = "Save changes"
	unsaved_dialog.add_button("Discard changes", false, "discard")
	unsaved_dialog.confirmed.connect(_save_current)
	unsaved_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard":
			unsaved_dialog.hide()
			_continue_pending())
	unsaved_dialog.canceled.connect(func() -> void: pending_action = Callable())
	add_child(unsaved_dialog)
	error_dialog = AcceptDialog.new()
	error_dialog.title = "Voice editor"
	error_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(error_dialog)
	add_dialog = ConfirmationDialog.new()
	add_dialog.title = "Add a new computer saying"
	add_dialog.ok_button_text = "Add saying"
	add_dialog.dialog_hide_on_ok = false
	add_dialog.confirmed.connect(_add_saying)
	add_child(add_dialog)
	var form := _card(add_dialog)
	form.custom_minimum_size.x = 500
	_label(form, "CATEGORY", 13, CYAN)
	add_category = OptionButton.new()
	add_category.fit_to_longest_item = false
	add_category.item_selected.connect(_refresh_add_events)
	form.add_child(add_category)
	_label(form, "WHEN SHOULD THE COMPUTER SAY THIS?", 13, CYAN)
	add_event = OptionButton.new()
	add_event.fit_to_longest_item = false
	form.add_child(add_event)
	_label(form, "WHAT THE COMPUTER SAYS", 13, CYAN)
	add_words = TextEdit.new()
	add_words.custom_minimum_size.y = 130
	add_words.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_words.placeholder_text = "Type your new saying..."
	add_words.text_changed.connect(func() -> void:
		add_dialog.get_ok_button().disabled = add_words.text.strip_edges().is_empty()
		add_error.text = "")
	form.add_child(add_words)
	var note := _label(form, "A unique ID is assigned automatically. Set chance and repeat delay in the editor after adding.", 13, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_error = _label(form, "", 13, AMBER)
	add_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _open_add_dialog() -> void:
	if document.data.is_empty():
		_show_error("Open a voice file before adding a saying.")
		return
	_commit_fields()
	_stop_preview()
	add_category.clear()
	var current_category: int = maxi(0, categories.selected - 1)
	for index in range(document.data["sections"].size()):
		var section: Dictionary = document.data["sections"][index]
		add_category.add_item(str(section.get("title", section.get("id", "Sayings"))))
		if not selected.is_empty() and section["lines"].any(func(line: Dictionary) -> bool: return line["id"] == selected["id"]):
			current_category = index
	add_category.select(current_category)
	_refresh_add_events(current_category)
	add_words.text = ""
	add_error.text = ""
	add_dialog.get_ok_button().disabled = true
	add_dialog.popup_centered(Vector2i(640, 500))
	add_words.grab_focus.call_deferred()

func _refresh_add_events(section_index: int) -> void:
	add_event.clear()
	var events: Array[String] = []
	for line in document.data["sections"][section_index]["lines"]:
		if not events.has(line["event"]):
			events.append(line["event"])
	if events.is_empty():
		events.assign(ComputerVoice.RULES.keys())
	events.sort()
	for event in events:
		var index: int = add_event.item_count
		add_event.add_item(event.replace("_", " ").capitalize())
		add_event.set_item_metadata(index, event)
		if event == selected.get("event"):
			add_event.select(index)

func _add_saying() -> void:
	var section_index: int = add_category.selected
	var event: String = add_event.get_item_metadata(add_event.selected) if add_event.selected >= 0 else ""
	var message: String = document.add_line(section_index, event, add_words.text)
	if not message.is_empty():
		add_error.text = message
		return
	selected = document.data["sections"][section_index]["lines"].back()
	search.text = ""
	categories.select(section_index + 1)
	add_dialog.hide()
	_refresh_list()
	sayings.ensure_current_is_visible.call_deferred()
	details_scroll.ensure_control_visible(words)
	words.grab_focus.call_deferred()
	_document_changed()
	status.text = "Saying added. Set its frequency, preview it, then save your changes."

func _open_document(path: String) -> void:
	var message: String
	if path == ProjectSettings.globalize_path(VoiceCatalog.USER_PATH) and not FileAccess.file_exists(path):
		message = document.new_game_file()
	else:
		message = document.open_file(path)
	if not message.is_empty():
		_show_error(message)
		_update_state()
		return
	_stop_preview()
	selected = {}
	previous_chances.clear()
	search.text = ""
	categories.clear()
	categories.add_item("All categories")
	for section in document.data["sections"]:
		categories.add_item(str(section.get("title", section.get("id", "Sayings"))))
	categories.select(0)
	_refresh_list()
	status.text = "Save to create your game voice file." if document.has_changes() else "File opened. Changes take effect after restarting the game."
	status.add_theme_color_override("font_color", MUTED)
	_update_state()

func _refresh_list() -> void:
	if sayings == null:
		return
	var keep_id: String = selected.get("id", "")
	sayings.clear()
	var total: int = 0
	var next_selection: int = -1
	var query: String = search.text.strip_edges().to_lower()
	for section_index in range(document.data.get("sections", []).size()):
		var section: Dictionary = document.data["sections"][section_index]
		for line in section["lines"]:
			total += 1
			if categories.selected > 0 and section_index != categories.selected - 1:
				continue
			var haystack: String = "%s %s %s %s" % [line["id"], line["event"], line["text"], section.get("title", "")]
			if not query.is_empty() and not haystack.to_lower().contains(query):
				continue
			var index: int = sayings.add_item(_item_text(line))
			sayings.set_item_metadata(index, line)
			sayings.set_item_tooltip(index, line["text"])
			sayings.set_item_custom_fg_color(index, MUTED if line["chance_percent"] == 0 else WHITE)
			if line["id"] == keep_id:
				next_selection = index
	library_count.text = "%d of %d sayings" % [sayings.item_count, total]
	if sayings.item_count > 0:
		next_selection = maxi(0, next_selection)
		sayings.select(next_selection)
		_select_line(next_selection)
	else:
		selected = {}
		_show_selection()
	_update_state()

func _item_text(line: Dictionary) -> String:
	var state: String = "OFF" if line["chance_percent"] == 0 else "%d%%" % line["chance_percent"]
	return "%s   /   %s\n%s" % [line["id"].replace("_", " ").capitalize(), state, line["text"].replace("\n", " ")]

func _select_line(index: int) -> void:
	_stop_preview()
	selected = sayings.get_item_metadata(index)
	_show_selection()

func _show_selection() -> void:
	loading_fields = true
	var available: bool = not selected.is_empty()
	words.editable = available
	enabled_toggle.disabled = not available
	chance.editable = available
	chance_slider.editable = available
	cooldown.editable = available
	heading.text = selected.get("id", "No matching sayings").replace("_", " ").capitalize()
	event_label.text = "EVENT  /  " + str(selected.get("event", "")).replace("_", " ")
	words.text = selected.get("text", "")
	chance.set_value_no_signal(selected.get("chance_percent", 0))
	chance_slider.set_value_no_signal(chance.value)
	cooldown.set_value_no_signal(selected.get("cooldown_seconds", 0))
	enabled_toggle.set_pressed_no_signal(chance.value > 0)
	loading_fields = false
	_update_state()

func _change_text() -> void:
	if loading_fields or selected.is_empty():
		return
	selected["text"] = words.text
	_document_changed()

func _change_chance(value: float) -> void:
	if loading_fields or selected.is_empty():
		return
	selected["chance_percent"] = int(value)
	if value > 0:
		previous_chances[selected["id"]] = int(value)
	chance.set_value_no_signal(value)
	chance_slider.set_value_no_signal(value)
	enabled_toggle.set_pressed_no_signal(value > 0)
	_document_changed()

func _change_cooldown(value: float) -> void:
	if loading_fields or selected.is_empty():
		return
	selected["cooldown_seconds"] = value
	_document_changed()

func _toggle_enabled(value: bool) -> void:
	if loading_fields or selected.is_empty():
		return
	var default_chance: int = 25 if selected["event"].begins_with("route_") else 100
	if not value and selected["chance_percent"] > 0:
		previous_chances[selected["id"]] = selected["chance_percent"]
	_change_chance(previous_chances.get(selected["id"], default_chance) if value else 0)

func _document_changed() -> void:
	var indices: PackedInt32Array = sayings.get_selected_items()
	if not indices.is_empty():
		var index: int = indices[0]
		sayings.set_item_text(index, _item_text(selected))
		sayings.set_item_tooltip(index, selected["text"])
		sayings.set_item_custom_fg_color(index, MUTED if selected["chance_percent"] == 0 else WHITE)
	status.text = "Unsaved edits. Save when ready, then restart the game."
	status.add_theme_color_override("font_color", MUTED)
	_update_state()

func _update_state() -> void:
	var dirty: bool = document.has_changes()
	state_label.text = "UNSAVED CHANGES" if dirty else "SAVED"
	state_label.add_theme_color_override("font_color", AMBER if dirty else CYAN)
	file_label.text = document.path.replace("/", "\\")
	file_label.tooltip_text = file_label.text
	save_button.disabled = not dirty
	save_as_button.disabled = document.data.is_empty()
	add_button.disabled = document.data.is_empty()
	get_window().title = "%sCosmic Conflict - Voice Editor" % ("* " if dirty else "")
	character_count.text = "%d characters  /  Plain text; quotation marks are saved safely." % words.text.length()
	play_button.disabled = selected.is_empty() or words.text.strip_edges().is_empty() or preview_busy
	if selected.is_empty():
		frequency_hint.text = "Try another category or search term."
	elif selected["chance_percent"] == 0:
		frequency_hint.text = "This saying is disabled in the game. You can still preview it here."
	else:
		var delay: float = selected["cooldown_seconds"]
		frequency_hint.text = "%d%% chance when this saying is selected. %s\nGame events, quiet intervals and warning priorities still apply." % [
			selected["chance_percent"], "No extra repeat delay." if delay == 0 else "At least %s seconds between repeats." % str(delay)]

func _request_action(action: Callable) -> void:
	_commit_fields()
	if document.has_changes():
		pending_action = action
		unsaved_dialog.popup_centered(Vector2i(520, 180))
	else:
		action.call()

func _request_exit() -> void:
	_request_action(func() -> void: get_tree().quit())

func _continue_pending() -> void:
	var action: Callable = pending_action
	pending_action = Callable()
	if action.is_valid():
		action.call()

func _open_dialog() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "Open a computer voice file"
	file_dialog.current_dir = document.path.get_base_dir() if not document.path.is_empty() else OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.popup_centered_ratio(0.75)

func _save_as_dialog() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "Save computer voice file as"
	file_dialog.current_path = document.path
	file_dialog.popup_centered_ratio(0.75)

func _file_selected(path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		_save_to(path)
	else:
		_open_document(path)

func _save_current() -> void:
	_save_to(document.path)

func _save_to(path: String) -> void:
	_commit_fields()
	var message: String = document.save_file(path)
	if not message.is_empty():
		pending_action = Callable()
		_show_error(message)
		return
	status.text = "Saved. The previous file is backed up as .bak. Restart the game to apply changes."
	status.add_theme_color_override("font_color", CYAN)
	_update_state()
	_continue_pending()

func _show_folder() -> void:
	if document.path.is_empty():
		_show_error("Open a voice file before showing its folder.")
		return
	var error: Error = OS.shell_open(document.path.get_base_dir())
	if error != OK:
		_show_error("Cannot open the voice-file folder: " + error_string(error))

func _play_preview() -> void:
	_commit_fields()
	if selected.is_empty() or selected["text"].strip_edges().is_empty():
		_show_error("Enter some words before previewing this saying.")
		return
	_stop_preview()
	var request: int = preview_request
	preview_busy = true
	preview_status.text = "Preparing offline audio..."
	_update_state()
	var line: Dictionary = selected.duplicate(true)
	line["chance_percent"] = 100
	line["cooldown_seconds"] = 0
	var data: Dictionary = {"voice": document.data["voice"], "sections": [{"lines": [line]}]}
	await get_tree().process_frame
	if request != preview_request:
		preview_busy = false
		_update_state()
		return
	var path: String = "user://voice-editor-preview-%d-%d.json" % [OS.get_process_id(), get_instance_id()]
	var message: String = VoiceCatalog.write_text(path, JSON.stringify(data))
	if message.is_empty():
		preview = ComputerVoice.new()
		preview.catalog_path = path
		preview.cache_directory = preview_cache_directory
		add_child(preview)
		message = preview.failure_message
	if FileAccess.file_exists(path):
		var error: Error = DirAccess.remove_absolute(path)
		if error != OK:
			message += "\nCannot remove preview request: " + error_string(error)
	preview_busy = false
	if not message.is_empty():
		_stop_preview()
		_show_error(message)
	elif preview != null:
		preview.speaking_changed.connect(func(active: bool) -> void:
			stop_button.disabled = not active
			preview_status.text = "Playing preview. Frequency settings are ignored here." if active else "Preview finished. Save your changes when ready.")
		preview.set_level(70, false)
		if not preview.say(line["event"]):
			_show_error(preview.failure_message if not preview.failure_message.is_empty() else "Voice preview requires a desktop audio device.")
	_update_state()

func _stop_preview() -> void:
	preview_request += 1
	if is_instance_valid(preview):
		preview.stop_speech()
		preview.queue_free()
	preview = null
	if stop_button != null:
		stop_button.disabled = true
		preview_status.text = "Preview uses the game's voice and radio effects."

func _commit_fields() -> void:
	for control in [chance, cooldown]:
		if control.get_line_edit().has_focus():
			control.apply()

func _show_error(message: String) -> void:
	status.text = message.replace("\n", " ")
	status.tooltip_text = message
	status.add_theme_color_override("font_color", AMBER)
	error_dialog.dialog_text = message
	error_dialog.popup_centered(Vector2i(660, 240))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not event.ctrl_pressed:
		return
	if event.keycode == KEY_S:
		if event.shift_pressed:
			_save_as_dialog()
		else:
			_save_current()
	elif event.keycode == KEY_O:
		_request_action(_open_dialog)
	else:
		return
	get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	_stop_preview()
	get_tree().auto_accept_quit = previous_auto_quit

func _column(parent: Node, gap: int = 12) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

func _row(parent: Node, gap: int = 12) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	return _column(margin, 14)

func _label(parent: Node, value: String, font_size: int = 16, color: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 40
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _style(color: Color, border: Color = Color("#2a3b50")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	result.set_color("font_color", "Label", WHITE)
	result.set_stylebox("panel", "PanelContainer", _style(SURFACE))
	result.set_stylebox("panel", "PopupMenu", _style(SURFACE))
	result.set_type_variation("PrimaryButton", "Button")
	for control in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			result.set_stylebox(state, control, _style(Color("#1b2c40") if state == "normal" else Color("#294157")))
		result.set_stylebox("focus", control, _style(Color(0, 0, 0, 0), CYAN))
		result.set_color("font_color", control, WHITE)
		result.set_color("font_hover_color", control, WHITE)
		result.set_color("font_disabled_color", control, Color("#6a8195"))
	for state in ["normal", "hover", "pressed"]:
		result.set_stylebox(state, "PrimaryButton", _style(CYAN if state == "normal" else Color("#a5f4f3"), CYAN))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		result.set_color(state, "PrimaryButton", BACKGROUND)
	for control in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", control, _style(Color("#0c1726")))
		result.set_stylebox("focus", control, _style(Color(0, 0, 0, 0), CYAN))
		result.set_stylebox("read_only", control, _style(Color("#0c1726")))
		result.set_color("font_color", control, WHITE)
		result.set_color("caret_color", control, CYAN)
		result.set_color("selection_color", control, Color("#285969"))
	result.set_stylebox("panel", "ItemList", _style(Color("#101b2a")))
	for state in ["selected", "selected_focus"]:
		result.set_stylebox(state, "ItemList", _style(Color("#203f50"), Color("#478d9a")))
	result.set_color("font_color", "ItemList", WHITE)
	result.set_color("font_selected_color", "ItemList", WHITE)
	result.set_constant("v_separation", "ItemList", 16)
	return result
