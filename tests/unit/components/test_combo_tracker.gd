class_name TestComboTracker
extends GdUnitTestSuite


var _tracker: ComboTracker


func before_test() -> void:
	_tracker = ComboTracker.new(3, 0.4)


func test_initial_step_is_zero() -> void:
	assert_int(_tracker.get_current_step()).is_equal(0)


func test_advance_step_increments() -> void:
	_tracker.advance_step()
	assert_int(_tracker.get_current_step()).is_equal(1)


func test_advance_past_max_resets_to_zero() -> void:
	_tracker.advance_step()  # 0 -> 1
	_tracker.advance_step()  # 1 -> 2
	_tracker.advance_step()  # 2 -> finished -> reset to 0
	assert_int(_tracker.get_current_step()).is_equal(0)


func test_reset_sets_step_to_zero() -> void:
	_tracker.advance_step()
	_tracker.advance_step()
	_tracker.reset()
	assert_int(_tracker.get_current_step()).is_equal(0)


func test_combo_window_active_after_advance() -> void:
	_tracker.advance_step()
	assert_bool(_tracker.is_in_window()).is_true()


func test_combo_window_not_active_initially() -> void:
	assert_bool(_tracker.is_in_window()).is_false()


func test_combo_window_expires_after_timeout() -> void:
	_tracker.advance_step()
	_tracker.tick(0.41)
	assert_bool(_tracker.is_in_window()).is_false()


func test_combo_window_still_active_before_timeout() -> void:
	_tracker.advance_step()
	_tracker.tick(0.3)
	assert_bool(_tracker.is_in_window()).is_true()


func test_step_resets_on_window_expiry() -> void:
	_tracker.advance_step()  # step 1
	_tracker.tick(0.41)       # window expires
	assert_int(_tracker.get_current_step()).is_equal(0)


func test_full_combo_sequence() -> void:
	var step1 := _tracker.advance_step()
	assert_int(step1).is_equal(1)
	var step2 := _tracker.advance_step()
	assert_int(step2).is_equal(2)
	var step3 := _tracker.advance_step()  # finisher -> reset
	assert_int(step3).is_equal(0)
	assert_int(_tracker.get_current_step()).is_equal(0)


func test_window_not_active_after_combo_finish() -> void:
	_tracker.advance_step()  # 0 -> 1
	_tracker.advance_step()  # 1 -> 2
	_tracker.advance_step()  # 2 -> finish -> reset
	assert_bool(_tracker.is_in_window()).is_false()
