## Tests for ComboTracker — step progression, windows, drops, and finishers.
extends GdUnitTestSuite


var _combo: ComboTracker


func before_test() -> void:
	_combo = ComboTracker.new()
	add_child(_combo)
	_combo.setup(3)


func after_test() -> void:
	_combo.queue_free()


func test_initial_state_is_inactive() -> void:
	assert_int(_combo.get_current_step()).is_equal(0)
	assert_bool(_combo.is_active()).is_false()
	assert_bool(_combo.is_finished()).is_false()


func test_first_advance_starts_combo() -> void:
	var result: bool = _combo.try_advance()
	assert_bool(result).is_true()
	assert_int(_combo.get_current_step()).is_equal(1)
	assert_bool(_combo.is_active()).is_true()


func test_advance_through_full_chain() -> void:
	_combo.try_advance()  # Step 1.
	_combo.try_advance()  # Step 2 (in window from step 1).
	_combo.try_advance()  # Step 3 = finish.
	assert_int(_combo.get_current_step()).is_equal(3)
	assert_bool(_combo.is_finished()).is_true()


func test_advance_after_finish_fails() -> void:
	_combo.try_advance()
	_combo.try_advance()
	_combo.try_advance()
	var result: bool = _combo.try_advance()
	assert_bool(result).is_false()


func test_window_timeout_drops_combo() -> void:
	_combo.try_advance()
	# Simulate time passing beyond the window.
	_combo.process_combo(Constants.COMBO_INPUT_WINDOW + 0.1)
	assert_int(_combo.get_current_step()).is_equal(0)
	assert_bool(_combo.is_active()).is_false()


func test_advance_outside_window_fails() -> void:
	_combo.try_advance()
	# Close the window.
	_combo.process_combo(Constants.COMBO_INPUT_WINDOW + 0.1)
	# Try to advance — combo was dropped, so this starts fresh.
	var result: bool = _combo.try_advance()
	assert_bool(result).is_true()
	assert_int(_combo.get_current_step()).is_equal(1)


func test_reset_clears_state() -> void:
	_combo.try_advance()
	_combo.try_advance()
	_combo.reset()
	assert_int(_combo.get_current_step()).is_equal(0)
	assert_bool(_combo.is_active()).is_false()
	assert_bool(_combo.is_finished()).is_false()


func test_window_does_not_expire_early() -> void:
	_combo.try_advance()
	# Process less than window time.
	_combo.process_combo(Constants.COMBO_INPUT_WINDOW * 0.5)
	assert_bool(_combo.is_in_window()).is_true()
	# Should still be able to advance.
	var result: bool = _combo.try_advance()
	assert_bool(result).is_true()
	assert_int(_combo.get_current_step()).is_equal(2)


func test_open_window_resets_timer() -> void:
	_combo.try_advance()
	_combo.process_combo(Constants.COMBO_INPUT_WINDOW * 0.8)
	_combo.open_window()
	# Should have a fresh timer now.
	_combo.process_combo(Constants.COMBO_INPUT_WINDOW * 0.8)
	assert_bool(_combo.is_in_window()).is_true()
