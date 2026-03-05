## Tests for LocalizationManager — string lookup, fallback, language switching.
extends GdUnitTestSuite


var _loc: LocalizationManager


func before_test() -> void:
	_loc = LocalizationManager.new()
	add_child(_loc)
	_loc.load_language("en", {
		&"ui_start": "Start Game",
		&"ui_quit": "Quit",
		&"ui_health": "Health: %d",
		&"ui_welcome": "Welcome, %s!",
	})
	_loc.load_language("es", {
		&"ui_start": "Iniciar Juego",
		&"ui_quit": "Salir",
	})
	_loc.set_language("en")


func after_test() -> void:
	_loc.queue_free()


func test_lookup_existing_key() -> void:
	assert_str(_loc.tr_key(&"ui_start")).is_equal("Start Game")


func test_lookup_missing_key_returns_key() -> void:
	var result: String = _loc.tr_key(&"nonexistent_key")
	assert_str(result).is_equal("nonexistent_key")


func test_switch_language() -> void:
	_loc.set_language("es")
	assert_str(_loc.tr_key(&"ui_start")).is_equal("Iniciar Juego")


func test_fallback_to_english() -> void:
	_loc.set_language("es")
	# "ui_health" only exists in English — should fall back.
	assert_str(_loc.tr_key(&"ui_health")).is_equal("Health: %d")


func test_format_string() -> void:
	var result: String = _loc.tr_format(&"ui_welcome", ["Chaz"])
	assert_str(result).is_equal("Welcome, Chaz!")


func test_has_key_true() -> void:
	assert_bool(_loc.has_key(&"ui_start")).is_true()


func test_has_key_false() -> void:
	assert_bool(_loc.has_key(&"nonexistent")).is_false()


func test_get_available_languages() -> void:
	var langs: Array[String] = _loc.get_available_languages()
	assert_int(langs.size()).is_equal(2)


func test_get_string_count() -> void:
	assert_int(_loc.get_string_count("en")).is_equal(4)
	assert_int(_loc.get_string_count("es")).is_equal(2)


func test_get_all_keys() -> void:
	var keys: Array[StringName] = _loc.get_all_keys()
	assert_int(keys.size()).is_equal(4)


func test_set_invalid_language_no_crash() -> void:
	_loc.set_language("xx")
	# Should stay at current language.
	assert_str(_loc.get_language()).is_equal("en")
