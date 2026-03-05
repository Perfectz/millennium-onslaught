## Tests for InputManager and InputActionSet — context switching, device assignment.
extends GdUnitTestSuite


func test_default_context_is_menu() -> void:
	assert_int(InputManager.get_context()).is_equal(InputManager.InputContext.MENU)


func test_set_context_changes_context() -> void:
	InputManager.set_context(InputManager.InputContext.COMBAT)
	assert_int(InputManager.get_context()).is_equal(InputManager.InputContext.COMBAT)
	# Restore.
	InputManager.set_context(InputManager.InputContext.MENU)


func test_keyboard_defaults_to_player_0() -> void:
	var player: int = InputManager.get_player_for_device(-1)
	assert_int(player).is_equal(0)


func test_unknown_device_returns_negative() -> void:
	var player: int = InputManager.get_player_for_device(999)
	assert_int(player).is_equal(-1)


func test_assign_device_to_player() -> void:
	InputManager.assign_device_to_player(5, 2)
	assert_int(InputManager.get_player_for_device(5)).is_equal(2)


func test_connected_player_count() -> void:
	var count: int = InputManager.get_connected_player_count()
	assert_int(count).is_greater(0)


# --- InputActionSet tests ---

func test_action_set_define_action() -> void:
	var action_set := InputActionSet.new(&"test")
	action_set.define_action(&"test_action", "Test Action")
	assert_bool(action_set.has_action(&"test_action")).is_true()


func test_action_set_get_action_names() -> void:
	var action_set := InputActionSet.new(&"test")
	action_set.define_action(&"action_a", "A")
	action_set.define_action(&"action_b", "B")
	var names: Array[StringName] = action_set.get_action_names()
	assert_int(names.size()).is_equal(2)


func test_action_set_display_name() -> void:
	var action_set := InputActionSet.new(&"test")
	action_set.define_action(&"test_action", "My Action")
	assert_str(action_set.get_display_name(&"test_action")).is_equal("My Action")


func test_action_set_missing_action_returns_empty() -> void:
	var action_set := InputActionSet.new(&"test")
	assert_str(action_set.get_display_name(&"missing")).is_equal("")
	assert_int(action_set.get_events(&"missing").size()).is_equal(0)


func test_action_set_bind_key() -> void:
	var action_set := InputActionSet.new(&"test")
	action_set.define_action(&"test_action", "Test")
	action_set.bind_key(&"test_action", KEY_SPACE)
	var events: Array = action_set.get_events(&"test_action")
	assert_int(events.size()).is_equal(1)
	assert_bool(events[0] is InputEventKey).is_true()


func test_combat_set_has_required_actions() -> void:
	var combat := InputActionSet.create_combat_set()
	assert_bool(combat.has_action(&"move_left")).is_true()
	assert_bool(combat.has_action(&"move_right")).is_true()
	assert_bool(combat.has_action(&"jump")).is_true()
	assert_bool(combat.has_action(&"attack_light")).is_true()
	assert_bool(combat.has_action(&"attack_heavy")).is_true()
	assert_bool(combat.has_action(&"dodge")).is_true()


func test_menu_set_has_required_actions() -> void:
	var menu := InputActionSet.create_menu_set()
	assert_bool(menu.has_action(&"ui_up")).is_true()
	assert_bool(menu.has_action(&"ui_down")).is_true()
	assert_bool(menu.has_action(&"ui_accept")).is_true()
	assert_bool(menu.has_action(&"ui_cancel")).is_true()


func test_action_set_context_name() -> void:
	var action_set := InputActionSet.new(&"combat")
	assert_str(action_set.get_context_name()).is_equal("combat")
