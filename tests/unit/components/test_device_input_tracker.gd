## TDD tests for DeviceInputTracker — per-player input state tracking.
class_name TestDeviceInputTracker
extends GdUnitTestSuite


var _tracker: DeviceInputTracker


func before_test() -> void:
	_tracker = DeviceInputTracker.new(4)


# --- is_pressed ---

func test_unpressed_action_returns_false() -> void:
	assert_bool(_tracker.is_pressed(0, &"jump")).is_false()


func test_pressed_action_returns_true() -> void:
	_tracker.register_action_pressed(0, &"jump")
	assert_bool(_tracker.is_pressed(0, &"jump")).is_true()


func test_released_action_returns_false() -> void:
	_tracker.register_action_pressed(0, &"jump")
	_tracker.register_action_released(0, &"jump")
	assert_bool(_tracker.is_pressed(0, &"jump")).is_false()


func test_pressed_state_persists_across_frames() -> void:
	_tracker.register_action_pressed(0, &"jump")
	_tracker.end_frame()
	assert_bool(_tracker.is_pressed(0, &"jump")).is_true()


# --- consume_just_pressed ---

func test_just_pressed_returns_true_once() -> void:
	_tracker.register_action_pressed(0, &"attack_light")
	assert_bool(_tracker.consume_just_pressed(0, &"attack_light")).is_true()


func test_just_pressed_returns_false_after_consumed() -> void:
	_tracker.register_action_pressed(0, &"attack_light")
	_tracker.consume_just_pressed(0, &"attack_light")
	assert_bool(_tracker.consume_just_pressed(0, &"attack_light")).is_false()


func test_just_pressed_cleared_by_end_frame() -> void:
	_tracker.register_action_pressed(0, &"attack_light")
	_tracker.end_frame()
	assert_bool(_tracker.consume_just_pressed(0, &"attack_light")).is_false()


func test_holding_does_not_re_trigger_just_pressed() -> void:
	_tracker.register_action_pressed(0, &"jump")
	_tracker.consume_just_pressed(0, &"jump")
	_tracker.end_frame()
	# Still held — register again (InputManager calls this every frame while held)
	_tracker.register_action_pressed(0, &"jump")
	assert_bool(_tracker.consume_just_pressed(0, &"jump")).is_false()


func test_release_then_repress_triggers_just_pressed() -> void:
	_tracker.register_action_pressed(0, &"jump")
	_tracker.consume_just_pressed(0, &"jump")
	_tracker.end_frame()
	_tracker.register_action_released(0, &"jump")
	_tracker.register_action_pressed(0, &"jump")
	assert_bool(_tracker.consume_just_pressed(0, &"jump")).is_true()


# --- Multi-player independence ---

func test_players_have_independent_pressed_state() -> void:
	_tracker.register_action_pressed(0, &"jump")
	assert_bool(_tracker.is_pressed(0, &"jump")).is_true()
	assert_bool(_tracker.is_pressed(1, &"jump")).is_false()


func test_players_have_independent_just_pressed() -> void:
	_tracker.register_action_pressed(0, &"attack_light")
	_tracker.register_action_pressed(1, &"attack_heavy")
	assert_bool(_tracker.consume_just_pressed(0, &"attack_light")).is_true()
	assert_bool(_tracker.consume_just_pressed(0, &"attack_heavy")).is_false()
	assert_bool(_tracker.consume_just_pressed(1, &"attack_heavy")).is_true()
	assert_bool(_tracker.consume_just_pressed(1, &"attack_light")).is_false()


# --- Axis values ---

func test_axis_value_tracks_per_player() -> void:
	_tracker.register_axis_value(0, &"move_right", 0.8)
	_tracker.register_axis_value(1, &"move_right", 0.3)
	assert_float(_tracker.get_raw_axis(0, &"move_right")).is_equal_approx(0.8, 0.01)
	assert_float(_tracker.get_raw_axis(1, &"move_right")).is_equal_approx(0.3, 0.01)


func test_get_axis_computes_positive_minus_negative() -> void:
	_tracker.register_axis_value(0, &"move_left", 0.0)
	_tracker.register_axis_value(0, &"move_right", 0.7)
	assert_float(_tracker.get_axis(0, &"move_left", &"move_right")).is_equal_approx(0.7, 0.01)


func test_get_axis_with_digital_fallback() -> void:
	# No axis values set, but button pressed — should fall back to 1.0
	_tracker.register_action_pressed(0, &"move_right")
	assert_float(_tracker.get_axis(0, &"move_left", &"move_right")).is_equal_approx(1.0, 0.01)


# --- Boundary checks ---

func test_invalid_player_index_pressed_returns_false() -> void:
	assert_bool(_tracker.is_pressed(-1, &"jump")).is_false()
	assert_bool(_tracker.is_pressed(99, &"jump")).is_false()


func test_invalid_player_just_pressed_returns_false() -> void:
	assert_bool(_tracker.consume_just_pressed(-1, &"jump")).is_false()
	assert_bool(_tracker.consume_just_pressed(99, &"jump")).is_false()


func test_invalid_player_axis_returns_zero() -> void:
	assert_float(_tracker.get_axis(-1, &"move_left", &"move_right")).is_equal_approx(0.0, 0.01)
