class_name TestElementCalculator
extends GdUnitTestSuite


func test_neutral_element_returns_1_0() -> void:
	assert_float(ElementCalculator.get_multiplier(&"", &"fire", &"")).is_equal(1.0)


func test_no_weakness_no_resistance_returns_1_0() -> void:
	assert_float(ElementCalculator.get_multiplier(&"fire", &"", &"")).is_equal(1.0)


func test_weakness_returns_bonus_multiplier() -> void:
	var mult := ElementCalculator.get_multiplier(&"fire", &"fire", &"")
	assert_float(mult).is_equal(Constants.ELEMENT_WEAKNESS_MULTIPLIER)


func test_resistance_returns_reduced_multiplier() -> void:
	var mult := ElementCalculator.get_multiplier(&"fire", &"", &"fire")
	assert_float(mult).is_equal(Constants.ELEMENT_RESISTANCE_MULTIPLIER)


func test_both_weakness_and_resistance_cancels() -> void:
	# If somehow weak AND resistant to same element, weakness takes priority
	var mult := ElementCalculator.get_multiplier(&"fire", &"fire", &"fire")
	assert_float(mult).is_equal(Constants.ELEMENT_WEAKNESS_MULTIPLIER)


func test_different_element_no_effect() -> void:
	assert_float(ElementCalculator.get_multiplier(&"fire", &"ice", &"lightning")).is_equal(1.0)


func test_status_effect_mapping_fire_burn() -> void:
	assert_str(String(ElementCalculator.get_status_for_element(&"fire"))).is_equal("burn")


func test_status_effect_mapping_ice_freeze() -> void:
	assert_str(String(ElementCalculator.get_status_for_element(&"ice"))).is_equal("freeze")


func test_status_effect_mapping_lightning_shock() -> void:
	assert_str(String(ElementCalculator.get_status_for_element(&"lightning"))).is_equal("shock")


func test_status_effect_mapping_dark_bleed() -> void:
	assert_str(String(ElementCalculator.get_status_for_element(&"dark"))).is_equal("bleed")


func test_status_effect_mapping_neutral_returns_empty() -> void:
	assert_str(String(ElementCalculator.get_status_for_element(&""))).is_equal("")
