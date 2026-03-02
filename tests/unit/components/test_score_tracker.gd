## TDD tests for ScoreTracker — tracks kills, time, combo, and calculates final score.
class_name TestScoreTracker
extends GdUnitTestSuite


var _tracker: ScoreTracker


func before_test() -> void:
	_tracker = ScoreTracker.new()


# --- Initialization ---

func test_initial_state() -> void:
	assert_int(_tracker.get_kill_count()).is_equal(0)
	assert_float(_tracker.get_elapsed_time()).is_equal(0.0)
	assert_int(_tracker.get_max_combo()).is_equal(0)
	assert_int(_tracker.get_total_damage_dealt()).is_equal(0)


# --- Kills ---

func test_record_kill_increments_count() -> void:
	_tracker.record_kill(&"rusher")
	assert_int(_tracker.get_kill_count()).is_equal(1)


func test_multiple_kill_types_tracked() -> void:
	_tracker.record_kill(&"rusher")
	_tracker.record_kill(&"rusher")
	_tracker.record_kill(&"ranged")
	assert_int(_tracker.get_kill_count()).is_equal(3)
	assert_int(_tracker.get_kill_count_by_type(&"rusher")).is_equal(2)
	assert_int(_tracker.get_kill_count_by_type(&"ranged")).is_equal(1)


func test_unknown_type_returns_zero() -> void:
	assert_int(_tracker.get_kill_count_by_type(&"nonexistent")).is_equal(0)


# --- Time ---

func test_tick_accumulates_time() -> void:
	_tracker.tick(0.5)
	_tracker.tick(0.3)
	assert_float(_tracker.get_elapsed_time()).is_equal_approx(0.8, 0.001)


# --- Combo ---

func test_update_max_combo() -> void:
	_tracker.update_combo(3)
	assert_int(_tracker.get_max_combo()).is_equal(3)


func test_max_combo_only_increases() -> void:
	_tracker.update_combo(5)
	_tracker.update_combo(2)
	assert_int(_tracker.get_max_combo()).is_equal(5)


func test_combo_of_ten_tracked() -> void:
	_tracker.update_combo(10)
	assert_int(_tracker.get_max_combo()).is_equal(10)


# --- Damage ---

func test_record_damage() -> void:
	_tracker.record_damage(25.0)
	_tracker.record_damage(10.0)
	assert_int(_tracker.get_total_damage_dealt()).is_equal(35)


# --- Score Calculation ---

func test_score_increases_with_kills() -> void:
	_tracker.record_kill(&"rusher")
	_tracker.record_kill(&"rusher")
	var score_2_kills := _tracker.calculate_score()
	_tracker.record_kill(&"rusher")
	var score_3_kills := _tracker.calculate_score()
	assert_int(score_3_kills).is_greater(score_2_kills)


func test_score_penalized_by_time() -> void:
	_tracker.record_kill(&"rusher")
	_tracker.record_kill(&"rusher")
	_tracker.record_kill(&"rusher")
	var fast_score := _tracker.calculate_score()

	var slow_tracker := ScoreTracker.new()
	slow_tracker.record_kill(&"rusher")
	slow_tracker.record_kill(&"rusher")
	slow_tracker.record_kill(&"rusher")
	slow_tracker.tick(300.0)
	var slow_score := slow_tracker.calculate_score()

	assert_int(fast_score).is_greater_equal(slow_score)


func test_score_boosted_by_combo() -> void:
	_tracker.record_kill(&"rusher")
	var no_combo := _tracker.calculate_score()

	var combo_tracker := ScoreTracker.new()
	combo_tracker.record_kill(&"rusher")
	combo_tracker.update_combo(10)
	var with_combo := combo_tracker.calculate_score()

	assert_int(with_combo).is_greater(no_combo)


func test_score_never_negative() -> void:
	_tracker.tick(9999.0)
	assert_int(_tracker.calculate_score()).is_greater_equal(0)


# --- Reset ---

func test_reset_clears_all() -> void:
	_tracker.record_kill(&"rusher")
	_tracker.tick(5.0)
	_tracker.update_combo(8)
	_tracker.record_damage(100.0)
	_tracker.reset()
	assert_int(_tracker.get_kill_count()).is_equal(0)
	assert_float(_tracker.get_elapsed_time()).is_equal(0.0)
	assert_int(_tracker.get_max_combo()).is_equal(0)
	assert_int(_tracker.get_total_damage_dealt()).is_equal(0)
