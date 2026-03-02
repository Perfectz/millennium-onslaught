## TDD tests for ComboCancelChecker — validates cancel window logic.
class_name TestComboCancelChecker
extends GdUnitTestSuite


var _attack: AttackDef


func before_test() -> void:
	_attack = AttackDef.new()
	_attack.attack_name = &"test_attack"
	_attack.windup_time = 0.1
	_attack.active_time = 0.1
	_attack.recovery_time = 0.2
	_attack.cancel_window_start = 0.5
	_attack.cancel_window_end = 0.9
	_attack.cancel_into = [&"light", &"heavy", &"dodge"]


# --- Window Timing ---

func test_before_cancel_window_returns_false() -> void:
	# Total duration 0.4s, window starts at 0.5 (0.2s), elapsed 0.1s = progress 0.25
	var result := ComboCancelChecker.can_cancel(_attack, 0.1)
	assert_bool(result).is_false()


func test_inside_cancel_window_returns_true() -> void:
	# Progress 0.6 — inside [0.5, 0.9]
	var result := ComboCancelChecker.can_cancel(_attack, 0.24)
	assert_bool(result).is_true()


func test_after_cancel_window_returns_false() -> void:
	# Progress 0.95 — past 0.9 end
	var result := ComboCancelChecker.can_cancel(_attack, 0.38)
	assert_bool(result).is_false()


func test_at_exact_window_start_returns_true() -> void:
	# Progress exactly 0.5
	var result := ComboCancelChecker.can_cancel(_attack, 0.2)
	assert_bool(result).is_true()


func test_at_exact_window_end_returns_true() -> void:
	# Progress exactly 0.9
	var result := ComboCancelChecker.can_cancel(_attack, 0.36)
	assert_bool(result).is_true()


# --- Cancel Type Checking ---

func test_allowed_cancel_type_accepted() -> void:
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"dodge")).is_true()
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"light")).is_true()
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"heavy")).is_true()


func test_disallowed_cancel_type_rejected() -> void:
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"technique")).is_false()
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"jump")).is_false()


func test_empty_cancel_into_rejects_all() -> void:
	_attack.cancel_into = []
	assert_bool(ComboCancelChecker.can_cancel_into(_attack, &"dodge")).is_false()


func test_full_cancel_check_combines_timing_and_type() -> void:
	# In window + allowed type = true
	assert_bool(ComboCancelChecker.check(_attack, 0.24, &"dodge")).is_true()
	# In window + disallowed type = false
	assert_bool(ComboCancelChecker.check(_attack, 0.24, &"technique")).is_false()
	# Out of window + allowed type = false
	assert_bool(ComboCancelChecker.check(_attack, 0.05, &"dodge")).is_false()


# --- Edge Cases ---

func test_zero_duration_attack_always_in_window() -> void:
	var instant := AttackDef.new()
	instant.windup_time = 0.0
	instant.active_time = 0.0
	instant.recovery_time = 0.0
	instant.cancel_window_start = 0.0
	instant.cancel_window_end = 1.0
	instant.cancel_into = [&"dodge"]
	# Can't really be "in window" with zero duration
	assert_bool(ComboCancelChecker.can_cancel(instant, 0.0)).is_true()
