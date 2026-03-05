## Tests for ResourceValidator — field validation, missing fields, range checks.
extends GdUnitTestSuite


var _valid_character: Dictionary = {
	"id": &"chaz",
	"display_name": "Chaz",
	"base_hp": 100.0,
	"base_strength": 8,
	"base_defense": 6,
	"base_agility": 7,
	"base_magic": 5,
	"combo_chain": [&"light_1", &"light_2", &"light_3"],
	"techniques": [&"fireslash"],
}

var _valid_enemy: Dictionary = {
	"id": &"rusher",
	"display_name": "Rusher",
	"hp": 50.0,
	"damage": 10.0,
	"speed": 4.0,
	"xp_reward": 10,
	"ai_type": &"rusher",
}

var _valid_attack: Dictionary = {
	"id": &"light_1",
	"base_damage": 10.0,
	"knockback": 3.0,
}


func test_valid_character_passes() -> void:
	var result := ResourceValidator.validate_character_def(_valid_character)
	assert_bool(result.is_valid).is_true()
	assert_int(result.errors.size()).is_equal(0)


func test_character_missing_id_fails() -> void:
	var data: Dictionary = _valid_character.duplicate()
	data.erase("id")
	var result := ResourceValidator.validate_character_def(data)
	assert_bool(result.is_valid).is_false()


func test_character_missing_display_name_fails() -> void:
	var data: Dictionary = _valid_character.duplicate()
	data.erase("display_name")
	var result := ResourceValidator.validate_character_def(data)
	assert_bool(result.is_valid).is_false()


func test_character_hp_below_minimum_fails() -> void:
	var data: Dictionary = _valid_character.duplicate()
	data["base_hp"] = 0.0
	var result := ResourceValidator.validate_character_def(data)
	assert_bool(result.is_valid).is_false()


func test_character_stat_above_max_fails() -> void:
	var data: Dictionary = _valid_character.duplicate()
	data["base_strength"] = 100
	var result := ResourceValidator.validate_character_def(data)
	assert_bool(result.is_valid).is_false()


func test_valid_enemy_passes() -> void:
	var result := ResourceValidator.validate_enemy_def(_valid_enemy)
	assert_bool(result.is_valid).is_true()


func test_enemy_missing_id_fails() -> void:
	var data: Dictionary = _valid_enemy.duplicate()
	data.erase("id")
	var result := ResourceValidator.validate_enemy_def(data)
	assert_bool(result.is_valid).is_false()


func test_enemy_negative_hp_fails() -> void:
	var data: Dictionary = _valid_enemy.duplicate()
	data["hp"] = -10.0
	var result := ResourceValidator.validate_enemy_def(data)
	assert_bool(result.is_valid).is_false()


func test_valid_attack_passes() -> void:
	var result := ResourceValidator.validate_attack_def(_valid_attack)
	assert_bool(result.is_valid).is_true()


func test_attack_with_valid_element_passes() -> void:
	var data: Dictionary = _valid_attack.duplicate()
	data["element"] = &"fire"
	var result := ResourceValidator.validate_attack_def(data)
	assert_bool(result.is_valid).is_true()


func test_attack_with_invalid_element_fails() -> void:
	var data: Dictionary = _valid_attack.duplicate()
	data["element"] = &"void"
	var result := ResourceValidator.validate_attack_def(data)
	assert_bool(result.is_valid).is_false()


func test_generic_dict_validation() -> void:
	var schemas: Array[ResourceValidator.FieldSchema] = []
	var s := ResourceValidator.FieldSchema.new("name", "string")
	s.min_length = 1
	schemas.append(s)
	var result := ResourceValidator.validate_dict({"name": "test"}, schemas)
	assert_bool(result.is_valid).is_true()


func test_generic_dict_missing_required_field() -> void:
	var schemas: Array[ResourceValidator.FieldSchema] = []
	schemas.append(ResourceValidator.FieldSchema.new("name", "string"))
	var result := ResourceValidator.validate_dict({}, schemas)
	assert_bool(result.is_valid).is_false()


func test_generic_dict_optional_field_missing_ok() -> void:
	var schemas: Array[ResourceValidator.FieldSchema] = []
	schemas.append(ResourceValidator.FieldSchema.new("name", "string", false))
	var result := ResourceValidator.validate_dict({}, schemas)
	assert_bool(result.is_valid).is_true()
