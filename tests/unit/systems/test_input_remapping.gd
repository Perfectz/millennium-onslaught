## TDD tests for keyboard + joypad remapping logic in InputManager.
class_name TestInputRemapping
extends GdUnitTestSuite


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
	InputManager.reset_keyboard_defaults()
	InputManager.reset_controller_defaults()
	var joy_before: int = InputManager.get_joypad_button_for_action(&"jump")
	InputManager.remap_action_keyboard(&"jump", KEY_G)
	var joy_after: int = InputManager.get_joypad_button_for_action(&"jump")
	assert_int(joy_after).is_equal(joy_before)
	# Restore default.
	InputManager.reset_keyboard_defaults()


func test_remap_joypad_preserves_keyboard_binding() -> void:
	InputManager.reset_keyboard_defaults()
	InputManager.reset_controller_defaults()
	var key_before: int = InputManager.get_keyboard_key_for_action(&"jump")
	InputManager.remap_action_joypad(&"jump", 3)  # Remap to Y/Triangle.
	var key_after: int = InputManager.get_keyboard_key_for_action(&"jump")
	assert_int(key_after).is_equal(key_before)
	# Restore default.
	InputManager.reset_controller_defaults()


func test_reset_keyboard_defaults_restores_all() -> void:
	# Remap several actions away from defaults.
	InputManager.remap_action_keyboard(&"jump", KEY_1)
	InputManager.remap_action_keyboard(&"dodge", KEY_2)
	# Reset should restore originals.
	InputManager.reset_keyboard_defaults()
	assert_int(InputManager.get_keyboard_key_for_action(&"jump")).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"jump"])
	assert_int(InputManager.get_keyboard_key_for_action(&"dodge")).is_equal(InputManager.DEFAULT_KEYBOARD_KEYS[&"dodge"])
