class_name TestSpellSlotResolver
extends GdUnitTestSuite


func _tech(id: StringName, type: int, level: int, dmg: float = 0.0, heal: float = 0.0) -> TechniqueDef:
	var t := TechniqueDef.new()
	t.technique_id = id
	t.spell_type = type
	t.unlock_level = level
	t.base_damage = dmg
	t.heal_amount = heal
	return t


func _kit() -> Array[TechniqueDef]:
	return [
		_tech(&"foi", TechniqueDef.SpellType.PROJECTILE, 1, 20.0),
		_tech(&"gifoi", TechniqueDef.SpellType.PROJECTILE, 12, 45.0),
		_tech(&"res", TechniqueDef.SpellType.HEAL, 3, 0.0, 40.0),
		_tech(&"gires", TechniqueDef.SpellType.HEAL, 20, 0.0, 90.0),
		_tech(&"nafoi", TechniqueDef.SpellType.AOE_BURST, 25, 60.0),
	]


func test_learned_filters_by_level() -> void:
	var learned := SpellSlotResolver.learned(_kit(), 3)
	var ids := learned.map(func(t: TechniqueDef) -> StringName: return t.technique_id)
	assert_array(ids).contains_exactly_in_any_order([&"foi", &"res"])


func test_best_single_target_is_strongest_learned_projectile() -> void:
	assert_str(String(SpellSlotResolver.best(_kit(), 12, SpellSlotResolver.Slot.SINGLE).technique_id)).is_equal("gifoi")
	assert_str(String(SpellSlotResolver.best(_kit(), 5, SpellSlotResolver.Slot.SINGLE).technique_id)).is_equal("foi")


func test_best_heal() -> void:
	assert_str(String(SpellSlotResolver.best(_kit(), 30, SpellSlotResolver.Slot.HEAL).technique_id)).is_equal("gires")


func test_missing_slot_returns_null() -> void:
	assert_object(SpellSlotResolver.best(_kit(), 10, SpellSlotResolver.Slot.AREA)).is_null()
	assert_object(SpellSlotResolver.best(_kit(), 1, SpellSlotResolver.Slot.HEAL)).is_null()


func test_area_slot() -> void:
	assert_str(String(SpellSlotResolver.best(_kit(), 25, SpellSlotResolver.Slot.AREA).technique_id)).is_equal("nafoi")


func test_newly_learned_between_levels() -> void:
	var fresh := SpellSlotResolver.newly_learned(_kit(), 2, 12)
	var ids := fresh.map(func(t: TechniqueDef) -> StringName: return t.technique_id)
	assert_array(ids).contains_exactly_in_any_order([&"res", &"gifoi"])
