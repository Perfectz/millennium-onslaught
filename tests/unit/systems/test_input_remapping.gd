## TDD tests for keyboard + joypad remapping logic in InputManager.
class_name TestInputRemapping
extends GdUnitTestSuite


func before_test() -> void:
	_reset_input_manager_state()


func after_test() -> void:
	_reset_input_manager_state()


# --- Keyboard Defaults ---

func test_default_keyboard_keys_covers_all_remappable_actions() -> void:
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		assert_bool(InputManager.DEFAULT_KEYBOARD_KEYS.has(action)).is_true()


func test_default_joypad_buttons_covers_all_remappable_actions() -> void:
	for action: StringName in InputManager.REMAPPABLE_ACTIONS:
		assert_bool(InputManager.DEFAULT_JOYPAD_BUTTONS.has(action)).is_true()


# --- Keyboard Query ---

func test_get_keyboard_key_returns_default_for_jump() -> void:
	# Ensure defaults are loaded before testing.
	InputManager.reset_keyboard_defaults()
	var key: int = InputManager.get_keyboard_key_for_action(&"jump")
	assert_int(key).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"jump"])


func test_get_keyboard_key_returns_default_for_technique_cycle() -> void:
	InputManager.reset_keyboard_defaults()
	var key: int = InputManager.get_keyboard_key_for_action(&"technique_cycle")
	assert_int(key).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"technique_cycle"])


func test_get_key_display_name_returns_readable_string() -> void:
	var name: String = InputManager.get_key_display_name(KEY_SPACE)
	assert_str(name).is_not_empty()
	# Should contain "Space" or similar, not be blank.
	assert_bool(name.length() > 0).is_true()


# --- Keyboard Remapping ---

func test_remap_keyboard_changes_inputmap() -> void:
	InputManager.reset_keyboard_defaults()
	# Remap jump from default (Space) to KEY_F.
	InputManager.remap_action_keyboard(&"jump", KEY_F)
	var key: int = InputManager.get_keyboard_key_for_action(&"jump")
	assert_int(key).is_equal(KEY_F)
	# Restore default.
	InputManager.reset_keyboard_defaults()


func test_remap_keyboard_preserves_joypad_binding() -> void:
	var joy_before: int = InputManager.get_joypad_button_for_action(&"jump")
	InputManager.remap_action_keyboard(&"jump", KEY_G)
	var joy_after: int = InputManager.get_joypad_button_for_action(&"jump")
	assert_int(joy_after).is_equal(joy_before)


func test_remap_joypad_preserves_keyboard_binding() -> void:
	var key_before: int = InputManager.get_keyboard_key_for_action(&"jump")
	InputManager.remap_action_joypad(&"jump", 3)  # Remap to Y/Triangle.
	var key_after: int = InputManager.get_keyboard_key_for_action(&"jump")
	assert_int(key_after).is_equal(key_before)


func test_remap_keyboard_swaps_conflicting_binding_instead_of_duplicate_binding() -> void:
	var jump_default: int = InputManager.DEFAULT_KEYBOARD_KEYS[&"jump"]
	var dodge_default: int = InputManager.DEFAULT_KEYBOARD_KEYS[&"dodge"]
	InputManager.remap_action_keyboard(&"jump", dodge_default)
	assert_int(InputManager.get_keyboard_key_for_action(&"jump")).is_equal(dodge_default)
	assert_int(InputManager.get_keyboard_key_for_action(&"dodge")).is_equal(jump_default)


func test_remap_joypad_swaps_conflicting_binding_instead_of_duplicate_binding() -> void:
	var jump_default: int = InputManager.DEFAULT_JOYPAD_BUTTONS[&"jump"]
	var dodge_default: int = InputManager.DEFAULT_JOYPAD_BUTTONS[&"dodge"]
	InputManager.remap_action_joypad(&"jump", dodge_default)
	assert_int(InputManager.get_joypad_button_for_action(&"jump")).is_equal(dodge_default)
	assert_int(InputManager.get_joypad_button_for_action(&"dodge")).is_equal(jump_default)


func test_reset_keyboard_defaults_restores_all() -> void:
	# Remap several actions away from defaults.
	InputManager.remap_action_keyboard(&"jump", KEY_1)
	InputManager.remap_action_keyboard(&"dodge", KEY_2)
	# Reset should restore originals.
	InputManager.reset_keyboard_defaults()
	assert_int(InputManager.get_keyboard_key_for_action(&"jump")).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"jump"])
	assert_int(InputManager.get_keyboard_key_for_action(&"dodge")).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"dodge"])


func test_reset_controller_defaults_restores_extended_gameplay_actions() -> void:
	InputManager.remap_action_joypad(&"technique", JOY_BUTTON_B)
	InputManager.remap_action_joypad(&"technique_cycle", JOY_BUTTON_A)
	InputManager.remap_action_joypad(&"character_next", JOY_BUTTON_X)
	InputManager.reset_controller_defaults()
	assert_int(InputManager.get_joypad_button_for_action(&"technique")).is_equal(InputManager.DEFAULT_JOYPAD_BUTTONS[&"technique"])
	assert_int(InputManager.get_joypad_button_for_action(&"technique_cycle")).is_equal(InputManager.DEFAULT_JOYPAD_BUTTONS[&"technique_cycle"])
	assert_int(InputManager.get_joypad_button_for_action(&"character_next")).is_equal(InputManager.DEFAULT_JOYPAD_BUTTONS[&"character_next"])


func test_menu_context_blocks_gameplay_events_from_being_tracked() -> void:
	_send_keyboard_binding(&"jump", true)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_false()

	InputManager.set_context(InputManager.InputContext.COMBAT)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_false()


func test_context_switch_clears_stale_gameplay_state() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	_send_keyboard_binding(&"attack_light", true)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"attack_light")).is_true()

	InputManager.set_context(InputManager.InputContext.MENU)
	InputManager.set_context(InputManager.InputContext.COMBAT)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"attack_light")).is_false()
	assert_bool(InputManager.is_action_just_pressed_for_player(0, &"attack_light")).is_false()


func test_joypad_disconnect_preserves_keyboard_state_for_shared_player() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	InputManager.assign_device_to_player(1, 0)
	_send_keyboard_binding(&"jump", true)
	_send_joypad_button(&"jump", 1, true)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_true()

	InputManager._on_joy_connection_changed(1, false)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_true()

	_send_keyboard_binding(&"jump", false)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_false()


func test_unknown_joypad_button_auto_assigns_on_first_input() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	_send_joypad_button(&"jump", 7, true)
	assert_int(InputManager.get_player_for_device(7)).is_equal(0)
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_true()


func test_unknown_joypad_motion_auto_assigns_on_first_input() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	_send_joypad_motion(JOY_AXIS_LEFT_X, 0.6, 8)
	var expected_strength := (0.6 - InputMap.action_get_deadzone(&"move_right")) / (1.0 - InputMap.action_get_deadzone(&"move_right"))
	assert_int(InputManager.get_player_for_device(8)).is_equal(0)
	assert_float(InputManager.get_axis_for_player(0, &"move_left", &"move_right")).is_equal_approx(expected_strength, 0.01)


func test_player_zero_falls_back_to_global_input_for_tracked_button_actions() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	Input.action_press(&"jump")
	assert_bool(InputManager.is_action_pressed_for_player(0, &"jump")).is_true()
	Input.action_release(&"jump")


func test_player_zero_falls_back_to_global_input_for_tracked_axes() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	Input.action_press(&"move_right", 0.75)
	assert_float(InputManager.get_axis_for_player(0, &"move_left", &"move_right")).is_equal_approx(0.75, 0.01)
	Input.action_release(&"move_right")


func test_tracker_just_pressed_does_not_double_consume_when_global_input_matches() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	Input.action_press(&"jump")
	_send_keyboard_binding(&"jump", true)
	assert_bool(InputManager.is_action_just_pressed_for_player(0, &"jump")).is_true()
	assert_bool(InputManager.is_action_just_pressed_for_player(0, &"jump")).is_false()
	Input.action_release(&"jump")
	_send_keyboard_binding(&"jump", false)


func test_joypad_motion_respects_deadzone_and_normalizes_strength() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	InputManager.assign_device_to_player(2, 1)

	var deadzone := InputMap.action_get_deadzone(&"move_right")
	_send_joypad_motion(JOY_AXIS_LEFT_X, deadzone - 0.01, 2)
	assert_float(InputManager.get_axis_for_player(1, &"move_left", &"move_right")).is_equal_approx(0.0, 0.01)

	_send_joypad_motion(JOY_AXIS_LEFT_X, 0.6, 2)
	var expected_strength := (0.6 - deadzone) / (1.0 - deadzone)
	assert_float(InputManager.get_axis_for_player(1, &"move_left", &"move_right")).is_equal_approx(expected_strength, 0.01)

	_send_joypad_motion(JOY_AXIS_LEFT_X, 0.0, 2)
	assert_float(InputManager.get_axis_for_player(1, &"move_left", &"move_right")).is_equal_approx(0.0, 0.01)


func test_debug_snapshot_reports_active_device_player_and_action() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	InputManager.assign_device_to_player(3, 2)
	_send_joypad_button(&"jump", 3, true)

	var snapshot := InputManager.get_debug_snapshot()
	var active: Dictionary = snapshot.get("active", {})
	var player_snapshot := _find_player_snapshot(snapshot, 2)

	assert_int(active.get("device", -99)).is_equal(3)
	assert_int(active.get("player", -99)).is_equal(2)
	assert_str(active.get("action", "")).is_equal("jump")
	assert_str(active.get("state", "")).is_equal("pressed")
	var player_devices: Array = player_snapshot.get("devices", [])
	assert_int(player_devices.size()).is_equal(1)
	assert_int(player_devices[0]).is_equal(3)
	assert_bool(player_snapshot.get("active", false)).is_true()
	assert_str(player_snapshot.get("last_action", "")).is_equal("jump")


func test_auxiliary_debug_actions_exist_in_inputmap() -> void:
	for action: StringName in [
		&"debug_toggle_ai",
		&"debug_toggle_perf",
		&"debug_toggle_input",
		&"debug_toggle_events",
		&"debug_restart_dungeon",
		&"debug_capture_bundle",
		&"debug_validate_stage",
		&"photo_toggle",
	]:
		assert_bool(InputMap.has_action(action)) \
			.override_failure_message("missing auxiliary action %s" % String(action)) \
			.is_true()


func test_photo_mode_actions_keep_expected_keyboard_defaults() -> void:
	assert_int(_get_first_keyboard_key(&"photo_toggle")).is_equal(KEY_F8)
	assert_int(_get_first_keyboard_key(&"debug_capture_bundle")).is_equal(KEY_F9)
	assert_int(_get_first_keyboard_key(&"debug_validate_stage")).is_equal(KEY_F10)
	assert_int(_get_first_keyboard_key(&"photo_move_forward")).is_equal(KEY_W)
	assert_int(_get_first_keyboard_key(&"photo_move_backward")).is_equal(KEY_S)
	assert_int(_get_first_keyboard_key(&"photo_move_left")).is_equal(KEY_A)
	assert_int(_get_first_keyboard_key(&"photo_move_right")).is_equal(KEY_D)
	assert_int(_get_first_keyboard_key(&"photo_move_up")).is_equal(KEY_E)
	assert_int(_get_first_keyboard_key(&"photo_move_down")).is_equal(KEY_Q)
	assert_int(_get_first_keyboard_key(&"photo_speed_modifier")).is_equal(KEY_SHIFT)
	assert_int(_get_first_keyboard_key(&"photo_roll_left")).is_equal(KEY_Z)
	assert_int(_get_first_keyboard_key(&"photo_roll_right")).is_equal(KEY_X)
	assert_int(_get_first_keyboard_key(&"photo_roll_reset")).is_equal(KEY_R)


func _get_first_keyboard_key(action: StringName) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).keycode
	return -1


func _reset_input_manager_state() -> void:
	InputManager.reset_keyboard_defaults()
	InputManager.reset_controller_defaults()
	InputManager._tracker.clear_all_state()
	InputManager._device_to_player.clear()
	InputManager._device_to_player[-1] = 0
	InputManager._current_context = InputManager.InputContext.MENU
	InputManager._clear_polled_fallback_cache()
	InputManager._record_context_debug()


func _send_keyboard_binding(action: StringName, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.device = -1
	event.keycode = InputManager.get_keyboard_key_for_action(action)
	event.pressed = pressed
	InputManager._input(event)


func _send_joypad_button(action: StringName, device_id: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device_id
	event.button_index = InputManager.get_joypad_button_for_action(action)
	event.pressed = pressed
	InputManager._input(event)


func _send_joypad_motion(axis: JoyAxis, axis_value: float, device_id: int) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device_id
	event.axis = axis
	event.axis_value = axis_value
	InputManager._input(event)


func _find_player_snapshot(snapshot: Dictionary, player_idx: int) -> Dictionary:
	for player_info in snapshot.get("players", []):
		if int(player_info.get("player", -1)) == player_idx:
			return player_info
	return {}
