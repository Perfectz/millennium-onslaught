class_name TestBattleTally
extends GdUnitTestSuite


var _tally: BattleTally


func before_test() -> void:
	_tally = BattleTally.new()


func test_starts_at_zero() -> void:
	assert_int(_tally.get_ko_count()).is_equal(0)
	assert_int(_tally.get_officer_ko_count()).is_equal(0)


func test_register_ko_counts_grunts_and_officers() -> void:
	_tally.register_ko(false)
	_tally.register_ko(false)
	_tally.register_ko(true)
	assert_int(_tally.get_ko_count()).is_equal(3)
	assert_int(_tally.get_officer_ko_count()).is_equal(1)


func test_rewards_use_constants() -> void:
	for i in 10:
		_tally.register_ko(false)
	_tally.register_ko(true)
	assert_int(_tally.get_xp_reward()).is_equal(
		10 * Constants.BATTLE_XP_PER_KO + Constants.BATTLE_XP_PER_OFFICER + Constants.BATTLE_XP_PER_KO)
	assert_int(_tally.get_gold_reward()).is_equal(
		10 * Constants.BATTLE_GOLD_PER_KO + Constants.BATTLE_GOLD_PER_OFFICER + Constants.BATTLE_GOLD_PER_KO)


func test_rank_thresholds() -> void:
	assert_str(BattleTally.rank_for_kos(0)).is_equal("D")
	assert_str(BattleTally.rank_for_kos(Constants.BATTLE_RANK_KO_THRESHOLDS[3])).is_equal("C")
	assert_str(BattleTally.rank_for_kos(Constants.BATTLE_RANK_KO_THRESHOLDS[2])).is_equal("B")
	assert_str(BattleTally.rank_for_kos(Constants.BATTLE_RANK_KO_THRESHOLDS[1])).is_equal("A")
	assert_str(BattleTally.rank_for_kos(Constants.BATTLE_RANK_KO_THRESHOLDS[0] + 50)).is_equal("S")


func test_milestone_detection() -> void:
	var milestones: Array[int] = []
	_tally.milestone_reached.connect(func(count: int) -> void: milestones.append(count))
	for i in Constants.BATTLE_KO_MILESTONE * 2:
		_tally.register_ko(false)
	assert_array(milestones).is_equal([Constants.BATTLE_KO_MILESTONE, Constants.BATTLE_KO_MILESTONE * 2])


func test_best_combo_tracks_maximum() -> void:
	_tally.register_combo(12)
	_tally.register_combo(5)
	_tally.register_combo(30)
	assert_int(_tally.get_best_combo()).is_equal(30)
