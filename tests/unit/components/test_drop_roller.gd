class_name TestDropRoller
extends GdUnitTestSuite


func test_empty_table_returns_empty() -> void:
	var drops := DropRoller.roll_drops([])
	assert_int(drops.size()).is_equal(0)


func test_guaranteed_drop_always_appears() -> void:
	var table: Array[Dictionary] = [{"item_id": &"iron_sword", "chance": 1.0}]
	var drops := DropRoller.roll_drops(table)
	assert_bool(drops.has(&"iron_sword")).is_true()


func test_zero_chance_never_drops() -> void:
	var table: Array[Dictionary] = [{"item_id": &"iron_sword", "chance": 0.0}]
	# Run 50 times — should never drop
	for i in 50:
		var drops := DropRoller.roll_drops(table)
		assert_int(drops.size()).is_equal(0)


func test_multiple_guaranteed_entries_all_drop() -> void:
	var table: Array[Dictionary] = [
		{"item_id": &"iron_sword", "chance": 1.0},
		{"item_id": &"leather_armor", "chance": 1.0},
	]
	var drops := DropRoller.roll_drops(table)
	assert_int(drops.size()).is_equal(2)
	assert_bool(drops.has(&"iron_sword")).is_true()
	assert_bool(drops.has(&"leather_armor")).is_true()


func test_expected_drop_count_calculation() -> void:
	var table: Array[Dictionary] = [
		{"item_id": &"iron_sword", "chance": 0.5},
		{"item_id": &"leather_armor", "chance": 0.25},
	]
	var expected := DropRoller.expected_drop_count(table)
	assert_float(expected).is_equal_approx(0.75, 0.01)


func test_probabilistic_drops_are_within_range() -> void:
	# 50% chance drop — run 200 times, expect between 50-150 drops
	var table: Array[Dictionary] = [{"item_id": &"iron_sword", "chance": 0.5}]
	var drop_count: int = 0
	for i in 200:
		var drops := DropRoller.roll_drops(table)
		drop_count += drops.size()
	assert_int(drop_count).is_greater(30)
	assert_int(drop_count).is_less(170)
