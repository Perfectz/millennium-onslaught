class_name TestBattlefieldControl
extends GdUnitTestSuite


var _ctl: BattlefieldControl


func before_test() -> void:
	_ctl = BattlefieldControl.new()
	_ctl.add_base(&"north", BattlefieldControl.Side.ENEMY, 3)
	_ctl.add_base(&"south", BattlefieldControl.Side.ENEMY, 2)
	_ctl.add_base(&"camp", BattlefieldControl.Side.ALLY, 0)


func test_initial_owners() -> void:
	assert_int(_ctl.get_owner(&"north")).is_equal(BattlefieldControl.Side.ENEMY)
	assert_int(_ctl.get_owner(&"camp")).is_equal(BattlefieldControl.Side.ALLY)
	assert_int(_ctl.get_enemy_base_count()).is_equal(2)


func test_base_not_captured_until_garrison_cleared() -> void:
	_ctl.register_garrison_ko(&"north")
	_ctl.register_garrison_ko(&"north")
	assert_bool(_ctl.try_capture(&"north")).is_false()
	_ctl.register_garrison_ko(&"north")
	assert_bool(_ctl.try_capture(&"north")).is_true()
	assert_int(_ctl.get_owner(&"north")).is_equal(BattlefieldControl.Side.ALLY)


func test_capture_raises_morale_and_emits() -> void:
	var captured: Array[StringName] = []
	_ctl.base_captured.connect(func(id: StringName) -> void: captured.append(id))
	for i in 2:
		_ctl.register_garrison_ko(&"south")
	_ctl.try_capture(&"south")
	assert_array(captured).is_equal([&"south"])
	assert_float(_ctl.get_morale()).is_equal(Constants.MORALE_PER_BASE_CAPTURE)


func test_cannot_capture_ally_base_twice() -> void:
	for i in 2:
		_ctl.register_garrison_ko(&"south")
	assert_bool(_ctl.try_capture(&"south")).is_true()
	assert_bool(_ctl.try_capture(&"south")).is_false()


func test_remaining_garrison() -> void:
	_ctl.register_garrison_ko(&"north")
	assert_int(_ctl.get_garrison_remaining(&"north")).is_equal(2)
	for i in 10:
		_ctl.register_garrison_ko(&"north")
	assert_int(_ctl.get_garrison_remaining(&"north")).is_equal(0)


func test_all_enemy_bases_captured_signal() -> void:
	var fired: Array[bool] = []
	_ctl.all_enemy_bases_captured.connect(func() -> void: fired.append(true))
	for i in 3:
		_ctl.register_garrison_ko(&"north")
	_ctl.try_capture(&"north")
	assert_int(fired.size()).is_equal(0)
	for i in 2:
		_ctl.register_garrison_ko(&"south")
	_ctl.try_capture(&"south")
	assert_int(fired.size()).is_equal(1)


func test_morale_clamps() -> void:
	for i in 20:
		_ctl.register_officer_ko()
	assert_float(_ctl.get_morale()).is_equal(Constants.MORALE_MAX)


func test_base_lost_lowers_morale() -> void:
	_ctl.lose_base(&"camp")
	assert_int(_ctl.get_owner(&"camp")).is_equal(BattlefieldControl.Side.ENEMY)
	assert_float(_ctl.get_morale()).is_equal(Constants.MORALE_PER_BASE_LOST)


func test_enemy_aggression_scales_with_morale() -> void:
	assert_float(_ctl.get_enemy_aggression()).is_equal(1.0)
	for i in 20:
		_ctl.register_officer_ko()
	assert_float(_ctl.get_enemy_aggression()).is_equal_approx(1.0 - Constants.MORALE_AGGRESSION_SCALE, 0.0001)


func test_unknown_base_is_safe() -> void:
	assert_bool(_ctl.try_capture(&"nope")).is_false()
	_ctl.register_garrison_ko(&"nope")
	assert_int(_ctl.get_owner(&"nope")).is_equal(BattlefieldControl.Side.NEUTRAL)
