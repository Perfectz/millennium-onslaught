class_name TestItemEffectResolver
extends GdUnitTestSuite


func _item(hp: float = 0.0, ratio: float = 0.0, tp: float = 0.0, cures: Array[StringName] = [], revive: bool = false) -> ItemDef:
	var d := ItemDef.new()
	d.heal_hp = hp
	d.heal_hp_ratio = ratio
	d.heal_tp = tp
	d.cures = cures
	d.revive = revive
	return d


func test_flat_heal_clamps_to_max() -> void:
	var r := ItemEffectResolver.resolve(_item(30.0), 90.0, 100.0, 0.0, 50.0, [])
	assert_float(r["hp"]).is_equal(100.0)
	assert_float(r["hp_restored"]).is_equal(10.0)


func test_ratio_heal_uses_max_hp() -> void:
	var r := ItemEffectResolver.resolve(_item(0.0, 0.5), 10.0, 200.0, 0.0, 50.0, [])
	assert_float(r["hp"]).is_equal(110.0)


func test_flat_and_ratio_stack() -> void:
	var r := ItemEffectResolver.resolve(_item(20.0, 0.1), 10.0, 100.0, 0.0, 50.0, [])
	assert_float(r["hp"]).is_equal(40.0)


func test_tp_restore_clamps() -> void:
	var r := ItemEffectResolver.resolve(_item(0.0, 0.0, 30.0), 50.0, 100.0, 40.0, 50.0, [])
	assert_float(r["tp"]).is_equal(50.0)


func test_dead_target_needs_revive() -> void:
	var r := ItemEffectResolver.resolve(_item(30.0), 0.0, 100.0, 0.0, 50.0, [])
	assert_float(r["hp"]).is_equal(0.0)
	assert_bool(r["useful"]).is_false()


func test_revive_restores_dead_target() -> void:
	var r := ItemEffectResolver.resolve(_item(0.0, 0.25, 0.0, [], true), 0.0, 100.0, 0.0, 50.0, [])
	assert_float(r["hp"]).is_equal(25.0)
	assert_bool(r["revived"]).is_true()


func test_revive_only_item_is_not_useful_on_living_target() -> void:
	var r := ItemEffectResolver.resolve(_item(0.0, 0.25, 0.0, [], true), 50.0, 100.0, 0.0, 50.0, [])
	assert_bool(r["useful"]).is_false()


func test_cures_listed_statuses_only() -> void:
	var cures: Array[StringName] = [&"poison"]
	var r := ItemEffectResolver.resolve(_item(0.0, 0.0, 0.0, cures), 50.0, 100.0, 0.0, 50.0, [&"poison", &"burn"])
	assert_array(r["cured"]).is_equal([&"poison"])
	assert_bool(r["useful"]).is_true()


func test_full_hp_heal_is_not_useful() -> void:
	var r := ItemEffectResolver.resolve(_item(30.0), 100.0, 100.0, 0.0, 50.0, [])
	assert_bool(r["useful"]).is_false()
