class_name TestStatusEffectTracker
extends GdUnitTestSuite


var _tracker: StatusEffectTracker


func before_test() -> void:
	_tracker = StatusEffectTracker.new()


func test_no_effects_initially() -> void:
	assert_bool(_tracker.has_effect(&"burn")).is_false()
	assert_bool(_tracker.has_effect(&"freeze")).is_false()


func test_apply_effect_adds_it() -> void:
	_tracker.apply_effect(&"burn", 3.0)
	assert_bool(_tracker.has_effect(&"burn")).is_true()


func test_effect_expires_after_duration() -> void:
	_tracker.apply_effect(&"burn", 1.0)
	_tracker.tick(1.1)
	assert_bool(_tracker.has_effect(&"burn")).is_false()


func test_effect_expired_signal_emitted() -> void:
	_tracker.apply_effect(&"burn", 0.5)
	var signal_collector := monitor_signals(_tracker)
	_tracker.tick(0.6)
	await assert_signal(signal_collector).is_emitted("effect_expired", [&"burn"])


func test_burn_deals_damage_per_tick() -> void:
	_tracker.apply_effect(&"burn", 3.0)
	var damage := _tracker.tick(1.0)
	assert_float(damage).is_equal_approx(Constants.BURN_DAMAGE_PER_SECOND, 0.01)


func test_freeze_reduces_speed_multiplier() -> void:
	_tracker.apply_effect(&"freeze", 3.0)
	assert_float(_tracker.get_speed_multiplier()).is_equal(Constants.FREEZE_SPEED_REDUCTION)


func test_bleed_increases_damage_taken_multiplier() -> void:
	_tracker.apply_effect(&"bleed", 3.0)
	assert_float(_tracker.get_damage_taken_multiplier()).is_equal(Constants.BLEED_DAMAGE_MULTIPLIER)


func test_remove_effect_clears_it() -> void:
	_tracker.apply_effect(&"burn", 3.0)
	_tracker.remove_effect(&"burn")
	assert_bool(_tracker.has_effect(&"burn")).is_false()


func test_reapply_refreshes_duration() -> void:
	_tracker.apply_effect(&"burn", 1.0)
	_tracker.tick(0.8)
	_tracker.apply_effect(&"burn", 1.0)
	_tracker.tick(0.8)
	assert_bool(_tracker.has_effect(&"burn")).is_true()


func test_multiple_effects_can_coexist() -> void:
	_tracker.apply_effect(&"burn", 3.0)
	_tracker.apply_effect(&"freeze", 3.0)
	assert_bool(_tracker.has_effect(&"burn")).is_true()
	assert_bool(_tracker.has_effect(&"freeze")).is_true()


func test_clear_all_removes_everything() -> void:
	_tracker.apply_effect(&"burn", 3.0)
	_tracker.apply_effect(&"freeze", 3.0)
	_tracker.clear_all()
	assert_bool(_tracker.has_effect(&"burn")).is_false()
	assert_bool(_tracker.has_effect(&"freeze")).is_false()


func test_speed_multiplier_normal_without_freeze() -> void:
	assert_float(_tracker.get_speed_multiplier()).is_equal(1.0)


func test_damage_taken_multiplier_normal_without_bleed() -> void:
	assert_float(_tracker.get_damage_taken_multiplier()).is_equal(1.0)
