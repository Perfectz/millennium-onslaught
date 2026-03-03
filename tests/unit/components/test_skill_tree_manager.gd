class_name TestSkillTreeManager
extends GdUnitTestSuite


var _tree: SkillTreeManager


func before_test() -> void:
	_tree = SkillTreeManager.new()
	_tree.load_tree([
		{"skill_id": &"power_strike", "prerequisites": [], "point_cost": 1, "stat_bonuses": {"strength": 2}},
		{"skill_id": &"iron_body", "prerequisites": [], "point_cost": 1, "stat_bonuses": {"defense": 2}},
		{"skill_id": &"fury", "prerequisites": [&"power_strike"], "point_cost": 2, "stat_bonuses": {"strength": 3}},
		{"skill_id": &"titan", "prerequisites": [&"iron_body", &"fury"], "point_cost": 3, "stat_bonuses": {"strength": 2, "defense": 2}},
	])


func test_empty_tree_has_no_skills() -> void:
	var empty := SkillTreeManager.new()
	assert_int(empty.get_skill_count()).is_equal(0)


func test_loaded_tree_has_correct_count() -> void:
	assert_int(_tree.get_skill_count()).is_equal(4)


func test_unlock_skill_with_no_prerequisites() -> void:
	var unlocked: Dictionary = {}
	assert_bool(_tree.unlock(&"power_strike", unlocked, 1)).is_true()
	assert_bool(unlocked.has(&"power_strike")).is_true()


func test_unlock_fails_if_prerequisites_not_met() -> void:
	var unlocked: Dictionary = {}
	assert_bool(_tree.unlock(&"fury", unlocked, 5)).is_false()


func test_unlock_fails_if_insufficient_points() -> void:
	var unlocked: Dictionary = {}
	assert_bool(_tree.unlock(&"power_strike", unlocked, 0)).is_false()


func test_unlock_succeeds_with_met_prerequisites() -> void:
	var unlocked: Dictionary = {&"power_strike": true}
	assert_bool(_tree.unlock(&"fury", unlocked, 2)).is_true()
	assert_bool(unlocked.has(&"fury")).is_true()


func test_already_unlocked_skill_rejected() -> void:
	var unlocked: Dictionary = {&"power_strike": true}
	assert_bool(_tree.unlock(&"power_strike", unlocked, 5)).is_false()


func test_total_bonuses_from_unlocked_skills() -> void:
	var unlocked: Dictionary = {&"power_strike": true}
	var bonuses := _tree.get_total_bonuses(unlocked)
	assert_int(bonuses["strength"]).is_equal(2)


func test_total_bonuses_sums_multiple_skills() -> void:
	var unlocked: Dictionary = {&"power_strike": true, &"iron_body": true}
	var bonuses := _tree.get_total_bonuses(unlocked)
	assert_int(bonuses["strength"]).is_equal(2)
	assert_int(bonuses["defense"]).is_equal(2)


func test_chained_prerequisites() -> void:
	# titan requires iron_body AND fury; fury requires power_strike
	var unlocked: Dictionary = {&"power_strike": true, &"iron_body": true, &"fury": true}
	assert_bool(_tree.unlock(&"titan", unlocked, 3)).is_true()


func test_get_skill_cost_returns_correct_value() -> void:
	assert_int(_tree.get_skill_cost(&"fury")).is_equal(2)
	assert_int(_tree.get_skill_cost(&"titan")).is_equal(3)


func test_skill_unlocked_signal_emitted() -> void:
	var signal_collector := monitor_signals(_tree)
	var unlocked: Dictionary = {}
	_tree.unlock(&"power_strike", unlocked, 1)
	await assert_signal(signal_collector).is_emitted("skill_unlocked", [&"power_strike"])
