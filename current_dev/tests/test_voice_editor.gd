extends SceneTree

var failures: int = 0
var fixture: String

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if "--editor-exit-test" in OS.get_cmdline_user_args():
		await verify_exit()
		return
	fixture = "user://voice-editor-test-%d" % OS.get_process_id()
	check(DirAccess.make_dir_recursive_absolute(fixture) == OK, "Editor tests use an isolated writable folder")
	verify_document()
	verify_additions()
	await verify_editor()
	for name in ["lines.json", "lines.json.bak", "copy.json", "broken.json", "additions.json", "ui.json", "ui.json.bak"]:
		var path: String = fixture.path_join(name)
		if FileAccess.file_exists(path):
			check(DirAccess.remove_absolute(path) == OK, "Removed test file " + name)
	check(DirAccess.remove_absolute(fixture) == OK, "Editor fixture folder is empty and removed")
	print("VOICE_EDITOR_FAILURES=", failures)
	quit(failures)

func verify_document() -> void:
	var path: String = fixture.path_join("lines.json")
	var source: String = FileAccess.get_file_as_string(VoiceCatalog.DEFAULT_PATH)
	check(VoiceCatalog.write_text(path, source).is_empty(), "A voice document fixture can be written")
	var document := VoiceDocument.new()
	check(document.open_file(path).is_empty() and not document.has_changes(), "Opening a catalog does not manufacture unsaved changes")
	var metadata: Dictionary = document.data["sections"][0]["lines"][0].duplicate(true)
	var text: String = "Pilot says \"hello\".\nBackslash: \\ and caf\u00e9."
	document.data["sections"][0]["lines"][0]["text"] = text
	document.data["sections"][0]["lines"][0]["chance_percent"] = 37
	document.data["sections"][0]["lines"][0]["cooldown_seconds"] = 90.5
	check(document.has_changes(), "Text and frequency edits mark the document dirty")
	check(document.save_file(path).is_empty() and not document.has_changes(), "Validated edits save atomically and clear the dirty state")
	check(FileAccess.get_file_as_string(path + ".bak") == source, "The backup preserves the exact original bytes and formatting")
	var loaded := VoiceDocument.new()
	check(loaded.open_file(path).is_empty(), "A saved editor document is accepted by the game's shared validator")
	var line: Dictionary = loaded.data["sections"][0]["lines"][0]
	check(line["text"] == text and line["chance_percent"] == 37 and line["cooldown_seconds"] == 90.5, "Unicode, quotes, newlines and both frequency settings round-trip exactly")
	check(line["id"] == metadata["id"] and line["event"] == metadata["event"] and line["added"] == metadata["added"] and loaded.data["sections"].size() == 8, "Saving preserves event IDs, category metadata and the rest of the catalog")
	var external: String = FileAccess.get_file_as_string(path) + "\n"
	VoiceCatalog.write_text(path, external)
	document.data["sections"][0]["lines"][0]["text"] = "Unsaved local edit."
	check(not document.save_file(path).is_empty() and FileAccess.get_file_as_string(path) == external and document.has_changes(), "An external edit cannot be silently overwritten")
	check(not document.save_file(ProjectSettings.globalize_path(path).replace("/", "\\")).is_empty(), "Alternate Windows path spelling cannot bypass external-change protection")
	var copy: String = fixture.path_join("copy.json")
	check(document.save_file(copy).is_empty() and document.path == copy, "Save as recovers local changes without replacing the externally edited file")
	var before: String = FileAccess.get_sha256(copy)
	document.data["sections"][0]["lines"][0]["text"] = "  "
	check(not document.save_file(copy).is_empty() and FileAccess.get_sha256(copy) == before, "Invalid dialogue never replaces a valid file")
	var broken: String = fixture.path_join("broken.json")
	VoiceCatalog.write_text(broken, "{broken")
	check(not document.open_file(broken).is_empty() and document.path == copy and document.has_changes(), "Opening malformed JSON leaves the current document and its edits intact")
	check(not FileAccess.file_exists(copy + ".editing-%d.tmp" % OS.get_process_id()), "Failed validation leaves no temporary save file")

func verify_additions() -> void:
	var document := VoiceDocument.new()
	check(document.open_file(VoiceCatalog.DEFAULT_PATH).is_empty(), "An existing catalog can be opened for adding sayings")
	var original: Dictionary = document.data.duplicate(true)
	check(not document.add_line(-1, "reactor_weapons", "Invalid category.").is_empty() and not document.add_line(99, "reactor_weapons", "Invalid category.").is_empty(), "Adding a saying requires a real category")
	check(not document.add_line(0, "unknown_event", "Invalid event.").is_empty() and not document.add_line(0, "reactor_weapons", " \n ").is_empty(), "Unknown triggers and blank sayings are rejected")
	check(document.data == original and not document.has_changes(), "Rejected additions do not mutate the document")
	check(document.add_line(0, "reactor_weapons", "New weapons announcement.").is_empty(), "An extra saying can be added to an existing event")
	var first: Dictionary = document.data["sections"][0]["lines"].back()
	check(document.add_line(1, "reactor_weapons", "Another weapons announcement.").is_empty(), "ID allocation works across categories")
	var second: Dictionary = document.data["sections"][1]["lines"].back()
	check(first["id"] != second["id"] and first["chance_percent"] == 100 and first["cooldown_seconds"] == 0 and first["added"], "New sayings have globally unique IDs and normal frequency defaults")
	check(document.add_line(7, "route_easy", "A new safe route announcement.").is_empty(), "Route events also accept extra sayings")
	check(document.data["sections"][7]["lines"].back()["chance_percent"] == 25, "New route sayings preserve the default route chance")
	var path: String = fixture.path_join("additions.json")
	check(document.save_file(path).is_empty(), "New entries save without a fixed line-count limit")
	var reopened := VoiceDocument.new()
	check(reopened.open_file(path).is_empty() and reopened.data == document.data, "All new entries survive saving and reopening with the shared game validator")
	for index in range(original["sections"].size()):
		var previous: Array = original["sections"][index]["lines"]
		check(reopened.data["sections"][index]["lines"].slice(0, previous.size()) == previous, "Adding entries preserves every existing line in category %d" % index)

func verify_editor() -> void:
	AudioServer.set_bus_mute(0, true)
	var path: String = fixture.path_join("ui.json")
	VoiceCatalog.write_text(path, FileAccess.get_file_as_string(VoiceCatalog.DEFAULT_PATH))
	var editor := VoiceEditor.new()
	editor.initial_path = path
	editor.preview_cache_directory = fixture.path_join("cache")
	root.add_child(editor)
	await process_frame
	check(editor.sayings.item_count == 83 and editor.words.editable, "The desktop editor opens all sayings and selects an editable line")
	editor.categories.select(8)
	editor.categories.item_selected.emit(8)
	check(editor.sayings.item_count == 12, "Category selection filters the library to its twelve route sayings")
	editor.search.text = "insurance"
	editor.search.text_changed.emit(editor.search.text)
	check(editor.sayings.item_count == 1 and editor.selected["id"] == "routes_02", "Search finds dialogue text inside the selected category")
	editor.words.text = "Edited in the desktop interface."
	editor.words.text_changed.emit()
	editor.chance.value = 37
	editor.cooldown.value = 90.5
	editor.enabled_toggle.button_pressed = false
	check(editor.selected["chance_percent"] == 0 and not editor.play_button.disabled, "The off toggle disables game speech without disabling preview")
	editor.enabled_toggle.button_pressed = true
	check(editor.selected["chance_percent"] == 37 and editor.chance_slider.value == 37, "Re-enabling restores the previous chance and keeps controls synchronized")
	var action_state: Dictionary = {"continued": false}
	var action: Callable = func() -> void: action_state["continued"] = true
	editor._request_action(action)
	check(editor.unsaved_dialog.visible and not action_state["continued"], "Opening or closing with unsaved edits requires a decision")
	editor.unsaved_dialog.hide()
	editor.unsaved_dialog.canceled.emit()
	check(not editor.pending_action.is_valid() and editor.document.has_changes(), "Cancel preserves unsaved edits and cancels the pending action")
	editor._request_action(action)
	editor.unsaved_dialog.custom_action.emit(&"discard")
	check(action_state["continued"] and not editor.unsaved_dialog.visible, "Discard allows the pending action to continue")
	editor.chance.get_line_edit().grab_focus()
	editor.chance.get_line_edit().text = "41"
	editor.save_button.pressed.emit()
	var saved := VoiceDocument.new()
	check(saved.open_file(path).is_empty(), "The Save button writes valid game-compatible JSON")
	var saved_line: Dictionary = saved.data["sections"][7]["lines"][1]
	check(saved_line["text"] == "Edited in the desktop interface." and saved_line["chance_percent"] == 41 and saved_line["cooldown_seconds"] == 90.5, "Save commits typed numeric input even before it loses focus: " + JSON.stringify(saved_line))
	check(not editor.document.has_changes() and editor.save_button.disabled, "A successful save updates the UI's dirty indicator")
	editor.search.text = "no matching saying in this file"
	editor.search.text_changed.emit(editor.search.text)
	check(editor.sayings.item_count == 0 and not editor.words.editable and editor.play_button.disabled, "An empty search result safely disables line editing")
	editor.add_button.pressed.emit()
	check(editor.add_dialog.visible and editor.add_category.selected == 7 and editor.add_dialog.get_ok_button().disabled, "Add saying remains available with no search results and starts in the filtered category")
	editor.add_words.text = " \n "
	editor.add_words.text_changed.emit()
	check(editor.add_dialog.get_ok_button().disabled, "The add dialog cannot confirm an empty or whitespace-only saying")
	editor.add_dialog.hide()
	editor.add_dialog.canceled.emit()
	check(not editor.document.has_changes() and editor.document.data["sections"][7]["lines"].size() == 12, "Canceling an addition leaves the saved file unchanged")
	editor.add_button.pressed.emit()
	editor.add_category.select(0)
	editor.add_category.item_selected.emit(0)
	var event_index: int = -1
	for index in range(editor.add_event.item_count):
		if editor.add_event.get_item_metadata(index) == "reactor_weapons":
			event_index = index
	check(event_index >= 0, "The new-entry form offers existing game events for the chosen category")
	editor.add_event.select(event_index)
	editor.add_words.text = "Welcome aboard, pilot. Your computer now takes requests. Please use this new power responsibly."
	editor.add_words.text_changed.emit()
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--voice-editor-add-shot="):
				check(root.get_texture().get_image().save_png(argument.trim_prefix("--voice-editor-add-shot=")) == OK, "The add-saying dialog can be captured for visual validation")
	editor.add_dialog.confirmed.emit()
	var new_id: String = editor.selected["id"]
	check(not editor.add_dialog.visible and editor.search.text.is_empty() and editor.categories.selected == 1 and editor.sayings.item_count == 14, "Adding clears stale search filters and selects the new saying in its category")
	check(editor.selected["event"] == "reactor_weapons" and editor.words.text == editor.add_words.text and editor.document.has_changes(), "The new saying is immediately editable and marks the document unsaved")
	editor.exit_button.pressed.emit()
	check(editor.unsaved_dialog.visible and editor.pending_action.is_valid(), "Exit editor asks before losing the newly added unsaved saying")
	editor.unsaved_dialog.hide()
	editor.unsaved_dialog.canceled.emit()
	check(not editor.pending_action.is_valid() and editor.document.has_changes(), "Canceling Exit keeps the new saying and the editor open")
	await process_frame
	editor.chance.value = 50
	editor.cooldown.value = 120
	editor.save_button.pressed.emit()
	var updated := VoiceDocument.new()
	check(updated.open_file(path).is_empty(), "A catalog with a newly added saying reopens successfully")
	var saved_addition: Dictionary = updated.data["sections"][0]["lines"].back()
	check(saved_addition["id"] == new_id and saved_addition["chance_percent"] == 50 and saved_addition["cooldown_seconds"] == 120, "The added saying and its custom frequency survive the real Save button: " + JSON.stringify(saved_addition))
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--voice-editor-shot="):
				var output: String = argument.trim_prefix("--voice-editor-shot=")
				check(root.get_texture().get_image().save_png(output) == OK, "The actual editor window can be captured for visual validation")
		root.size = Vector2i(1000, 740)
		await process_frame
		editor.details_scroll.ensure_control_visible(editor.play_button)
		await process_frame
		var preview_rect: Rect2 = editor.play_button.get_global_rect()
		check(preview_rect.position.y >= 0 and preview_rect.end.y <= root.size.y and editor.words.get_global_rect().end.x <= root.size.x, "At minimum window size, scrolling keeps preview reachable without horizontal clipping")
		root.size = Vector2i(1280, 860)
		editor.enabled_toggle.button_pressed = false
		await editor._play_preview()
		check(editor.preview != null and editor.preview.failure_message.is_empty() and editor.preview.player.playing and editor.preview.last_line == new_id, "A newly added ID generates and plays real speech even when disabled in the editor")
		if editor.preview != null and editor.preview.failure_message.is_empty():
			await create_timer(0.5).timeout
			var bus: int = AudioServer.get_bus_index(editor.preview.bus_name)
			check(editor.preview.player.get_playback_position() > 0.1 and AudioServer.get_bus_peak_volume_left_db(bus, 0) > -65, "Preview produces real processed speech while test master output stays muted")
			var recording: String = editor.preview.recording_paths[editor.selected["id"]]
			editor.stop_button.pressed.emit()
			check(editor.preview == null and editor.stop_button.disabled, "Stop immediately releases preview playback")
			check(DirAccess.remove_absolute(recording) == OK, "The test preview recording is removed")
		if DirAccess.dir_exists_absolute(editor.preview_cache_directory):
			check(DirAccess.remove_absolute(editor.preview_cache_directory) == OK, "The isolated preview cache is empty and removed")
	editor.queue_free()
	await process_frame
	check(auto_accept_quit, "Closing the editor restores the previous window-close behavior")

func verify_exit() -> void:
	var editor := VoiceEditor.new()
	editor.initial_path = VoiceCatalog.DEFAULT_PATH
	root.add_child(editor)
	await process_frame
	root.tree_exiting.connect(func() -> void: print("VOICE_EDITOR_EXIT_FAILURES=", failures))
	editor.exit_button.pressed.emit()
	await create_timer(2).timeout
	check(false, "Exit editor must terminate the application when there are no unsaved changes")
	quit(failures)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1
