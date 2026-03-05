## Tests for SaveMigration — version migration, checksum, validation.
extends GdUnitTestSuite


func test_current_version_is_positive() -> void:
	assert_int(SaveMigration.CURRENT_VERSION).is_greater(0)


func test_prepare_for_save_adds_version() -> void:
	var data: Dictionary = {"gold": 100}
	var prepared: Dictionary = SaveMigration.prepare_for_save(data)
	assert_int(prepared["save_version"]).is_equal(SaveMigration.CURRENT_VERSION)


func test_prepare_for_save_adds_checksum() -> void:
	var data: Dictionary = {"gold": 100}
	var prepared: Dictionary = SaveMigration.prepare_for_save(data)
	assert_bool("checksum" in prepared).is_true()
	assert_int(prepared["checksum"]).is_not_equal(0)


func test_prepare_for_save_adds_timestamp() -> void:
	var data: Dictionary = {"gold": 100}
	var prepared: Dictionary = SaveMigration.prepare_for_save(data)
	assert_bool("save_timestamp" in prepared).is_true()


func test_verify_checksum_valid() -> void:
	var data: Dictionary = {"gold": 100, "party_roster": []}
	var prepared: Dictionary = SaveMigration.prepare_for_save(data)
	assert_bool(SaveMigration.verify_checksum(prepared)).is_true()


func test_verify_checksum_detects_corruption() -> void:
	var data: Dictionary = {"gold": 100, "party_roster": []}
	var prepared: Dictionary = SaveMigration.prepare_for_save(data)
	# Tamper with data.
	prepared["gold"] = 9999
	assert_bool(SaveMigration.verify_checksum(prepared)).is_false()


func test_verify_checksum_missing_returns_false() -> void:
	var data: Dictionary = {"gold": 100}
	assert_bool(SaveMigration.verify_checksum(data)).is_false()


func test_needs_migration_old_version() -> void:
	var data: Dictionary = {"save_version": 0}
	assert_bool(SaveMigration.needs_migration(data)).is_true()


func test_needs_migration_current_version() -> void:
	var data: Dictionary = {"save_version": SaveMigration.CURRENT_VERSION}
	assert_bool(SaveMigration.needs_migration(data)).is_false()


func test_needs_migration_no_version_field() -> void:
	var data: Dictionary = {"gold": 100}
	assert_bool(SaveMigration.needs_migration(data)).is_true()


func test_migrate_v0_to_v1_adds_required_fields() -> void:
	var data: Dictionary = {"gold": 100}
	var migrated: Dictionary = SaveMigration.migrate(data)
	assert_int(migrated["save_version"]).is_equal(1)
	assert_bool("party_roster" in migrated).is_true()
	assert_bool("character_data" in migrated).is_true()
	assert_bool("inventory" in migrated).is_true()
	assert_bool("story_flags" in migrated).is_true()
	assert_bool("active_party" in migrated).is_true()


func test_migrate_preserves_existing_data() -> void:
	var data: Dictionary = {
		"gold": 250,
		"party_roster": [&"chaz"],
	}
	var migrated: Dictionary = SaveMigration.migrate(data)
	assert_int(migrated["gold"]).is_equal(250)
	assert_int(migrated["party_roster"].size()).is_equal(1)


func test_get_version_with_field() -> void:
	assert_int(SaveMigration.get_version({"save_version": 3})).is_equal(3)


func test_get_version_without_field() -> void:
	assert_int(SaveMigration.get_version({})).is_equal(0)


func test_validate_structure_valid() -> void:
	var data: Dictionary = {
		"party_roster": [],
		"character_data": {},
		"inventory": [],
		"gold": 0,
		"story_flags": {},
		"active_party": [],
	}
	var errors: Array[String] = SaveMigration.validate_structure(data)
	assert_int(errors.size()).is_equal(0)


func test_validate_structure_missing_field() -> void:
	var data: Dictionary = {"gold": 0}
	var errors: Array[String] = SaveMigration.validate_structure(data)
	assert_int(errors.size()).is_greater(0)


func test_crc32_consistency() -> void:
	var a: int = SaveMigration.calculate_crc32("hello world")
	var b: int = SaveMigration.calculate_crc32("hello world")
	assert_int(a).is_equal(b)


func test_crc32_different_strings_differ() -> void:
	var a: int = SaveMigration.calculate_crc32("hello")
	var b: int = SaveMigration.calculate_crc32("world")
	assert_int(a).is_not_equal(b)
