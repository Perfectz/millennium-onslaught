## Version-aware save migration pipeline.
## Migrates save data forward through version chain: v1 → v2 → ... → vN.
class_name SaveMigration
extends RefCounted


## Current save format version.
const CURRENT_VERSION: int = 1

## CRC32 polynomial table for checksum calculation.
static var _crc_table: Array[int] = []
static var _crc_table_initialized: bool = false


## Migrate save data from any version to the current version.
static func migrate(data: Dictionary) -> Dictionary:
	var version: int = data.get("save_version", 0)
	if version >= CURRENT_VERSION:
		return data
	# Apply migrations in order.
	if version < 1:
		data = _migrate_v0_to_v1(data)
	# Future migrations go here:
	# if version < 2:
	#     data = _migrate_v1_to_v2(data)
	return data


## Check if a save needs migration.
static func needs_migration(data: Dictionary) -> bool:
	return data.get("save_version", 0) < CURRENT_VERSION


## Get the version of a save data dictionary.
static func get_version(data: Dictionary) -> int:
	return data.get("save_version", 0)


## Add version and checksum to save data before writing.
static func prepare_for_save(data: Dictionary) -> Dictionary:
	data["save_version"] = CURRENT_VERSION
	data["save_timestamp"] = Time.get_unix_time_from_system()
	# Calculate checksum of the data (excluding the checksum field itself).
	var data_for_checksum: Dictionary = data.duplicate(true)
	data_for_checksum.erase("checksum")
	var json_str: String = JSON.stringify(data_for_checksum, "", false)
	data["checksum"] = calculate_crc32(json_str)
	return data


## Verify save data integrity via checksum.
static func verify_checksum(data: Dictionary) -> bool:
	if "checksum" not in data:
		return false  # No checksum = pre-versioning save, can't verify.
	var stored_checksum: int = data["checksum"]
	var data_for_checksum: Dictionary = data.duplicate(true)
	data_for_checksum.erase("checksum")
	var json_str: String = JSON.stringify(data_for_checksum, "", false)
	var calculated: int = calculate_crc32(json_str)
	return stored_checksum == calculated


## Calculate CRC32 checksum of a string.
static func calculate_crc32(text: String) -> int:
	_ensure_crc_table()
	var bytes: PackedByteArray = text.to_utf8_buffer()
	var crc: int = 0xFFFFFFFF
	for b: int in bytes:
		var index: int = (crc ^ b) & 0xFF
		crc = (crc >> 8) ^ _crc_table[index]
	return crc ^ 0xFFFFFFFF


## Validate save data structure has required fields.
static func validate_structure(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var required: Array[String] = [
		"party_roster", "character_data", "inventory", "gold",
		"story_flags", "active_party"
	]
	for field: String in required:
		if field not in data:
			errors.append("Missing required field: '%s'" % field)
	if "gold" in data and not (data["gold"] is int or data["gold"] is float):
		errors.append("Field 'gold' must be numeric")
	if "party_roster" in data and not (data["party_roster"] is Array):
		errors.append("Field 'party_roster' must be an array")
	return errors


# --- Migration functions ---

static func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	# v0 → v1: Add save_version field, ensure all required fields exist.
	data["save_version"] = 1
	if "party_roster" not in data:
		data["party_roster"] = []
	if "character_data" not in data:
		data["character_data"] = {}
	if "inventory" not in data:
		data["inventory"] = []
	if "gold" not in data:
		data["gold"] = 0
	if "story_flags" not in data:
		data["story_flags"] = {}
	if "active_party" not in data:
		data["active_party"] = []
	return data


static func _ensure_crc_table() -> void:
	if _crc_table_initialized:
		return
	_crc_table.resize(256)
	for i: int in 256:
		var crc: int = i
		for _j: int in 8:
			if crc & 1:
				crc = (crc >> 1) ^ 0xEDB88320
			else:
				crc >>= 1
		_crc_table[i] = crc
	_crc_table_initialized = true
