## File-based save/load with atomic writes.
## Writes to a temp file first, then promotes it to the active slot.
class_name SaveManagerSingleton
extends Node


const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_PREFIX: String = "save_slot_"
const SAVE_FILE_EXT: String = ".json"
const BACKUP_EXT: String = ".backup"
const TEMP_EXT: String = ".tmp"

## Holds parsed JSON data from the last successful _try_load_file call.
var _last_parsed_data: Dictionary = {}
var _last_load_error: String = ""


func _ready() -> void:
	_ensure_save_dir()


## Save persistent game state to a slot.
func save_game(slot: int = 0) -> bool:
	if slot < 0:
		return _emit_save_failure(slot, "Invalid save slot %d." % slot)

	_ensure_save_dir()

	var data := GameState.serialize_persistent()
	var json_string := JSON.stringify(data, "\t")
	var final_path := get_save_path(slot)
	var temp_path := final_path + TEMP_EXT
	var backup_path := get_backup_path(slot)

	var write_err := _write_text_file(temp_path, json_string)
	if write_err != OK:
		_remove_file_if_exists(temp_path)
		return _emit_save_failure(slot, "Failed to write temp save file: %s." % _describe_error_code(write_err))

	if FileAccess.file_exists(final_path):
		var backup_err := _rotate_primary_to_backup(final_path, backup_path)
		if backup_err != OK:
			_remove_file_if_exists(temp_path)
			return _emit_save_failure(slot, "Failed to rotate existing save into backup: %s." % _describe_error_code(backup_err))

	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		_remove_file_if_exists(temp_path)
		var restored := _restore_primary_from_backup(final_path, backup_path)
		var error_msg := "Failed to promote temp save into slot %d: %s." % [slot, _describe_error_code(rename_err)]
		if restored:
			error_msg += " Restored the previous backup."
		return _emit_save_failure(slot, error_msg)

	EventBus.emit_checked(&"save_completed", [slot], {"slot": slot}, true)
	return true


## Load persistent game state from a slot. Falls back to backup if primary is invalid.
func load_game(slot: int = 0) -> bool:
	if slot < 0:
		return _emit_load_failure(slot, "Invalid save slot %d." % slot)

	var path := get_save_path(slot)
	var backup_path := get_backup_path(slot)

	var primary_attempt := _try_apply_save_file(path)
	if primary_attempt.get("success", false):
		EventBus.emit_checked(&"load_completed", [slot], {"slot": slot}, true)
		return true

	var backup_attempt := _try_apply_save_file(backup_path)
	if backup_attempt.get("success", false):
		var restored_primary := _restore_primary_from_backup(path, backup_path)
		var payload := {"slot": slot, "from_backup": true}
		if int(primary_attempt.get("code", ERR_FILE_NOT_FOUND)) != ERR_FILE_NOT_FOUND:
			payload["primary_error"] = str(primary_attempt.get("reason", "unknown error"))
		if restored_primary:
			payload["restored_primary"] = true
		EventBus.emit_checked(&"load_completed", [slot], payload, true)
		return true

	var error_msg := "Failed to load save data for slot %d. Primary: %s Backup: %s" % [
		slot,
		str(primary_attempt.get("reason", "not attempted")),
		str(backup_attempt.get("reason", "not attempted")),
	]
	return _emit_load_failure(slot, error_msg)


## Load save metadata for slot preview without applying to GameState.
func load_save_metadata(slot: int) -> Dictionary:
	if slot < 0:
		return {"exists": false}

	var path := get_save_path(slot)
	var primary_meta := _load_metadata_from_path(path)
	if primary_meta.get("exists", false):
		return primary_meta

	var backup_meta := _load_metadata_from_path(get_backup_path(slot))
	if backup_meta.get("exists", false):
		backup_meta["from_backup"] = true
		return backup_meta

	return {"exists": false}


## Check if a save file or recoverable backup exists for a slot.
func has_save(slot: int = 0) -> bool:
	if slot < 0:
		return false
	return FileAccess.file_exists(get_save_path(slot)) or FileAccess.file_exists(get_backup_path(slot))


## Delete a save file for a slot.
func delete_save(slot: int = 0) -> void:
	var path := get_save_path(slot)
	_remove_file_if_exists(path)
	_remove_file_if_exists(get_backup_path(slot))
	_remove_file_if_exists(path + TEMP_EXT)


## Get the file path for a save slot.
func get_save_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXT


func get_backup_path(slot: int) -> String:
	return get_save_path(slot) + BACKUP_EXT


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _emit_save_failure(slot: int, error_msg: String) -> bool:
	push_error(error_msg)
	EventBus.emit_checked(&"save_failed", [slot, error_msg], {"slot": slot, "error": error_msg}, true)
	return false


func _emit_load_failure(slot: int, error_msg: String) -> bool:
	push_error(error_msg)
	EventBus.emit_checked(&"load_failed", [slot, error_msg], {"slot": slot, "error": error_msg}, true)
	return false


func _write_text_file(path: String, contents: String) -> int:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	file.close()
	return OK


func _rotate_primary_to_backup(primary_path: String, backup_path: String) -> int:
	if FileAccess.file_exists(backup_path):
		var remove_err := DirAccess.remove_absolute(backup_path)
		if remove_err != OK:
			return remove_err
	return DirAccess.rename_absolute(primary_path, backup_path)


func _restore_primary_from_backup(primary_path: String, backup_path: String) -> bool:
	if not FileAccess.file_exists(backup_path):
		return false
	var file := FileAccess.open(backup_path, FileAccess.READ)
	if file == null:
		return false
	var contents := file.get_as_text()
	file.close()
	return _write_text_file(primary_path, contents) == OK


func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _load_metadata_from_path(path: String) -> Dictionary:
	var result := _try_load_file(path)
	if result != OK:
		return {"exists": false}
	var metadata := GameState.get_save_metadata(_last_parsed_data)
	if not metadata.get("exists", false):
		return {"exists": false}
	return metadata


func _try_apply_save_file(path: String) -> Dictionary:
	var result := _try_load_file(path)
	if result != OK:
		return {
			"success": false,
			"code": result,
			"reason": _last_load_error if not _last_load_error.is_empty() else _describe_error_code(result),
		}
	if not GameState.deserialize_persistent(_last_parsed_data):
		return {
			"success": false,
			"code": ERR_INVALID_DATA,
			"reason": "schema validation rejected the save payload",
		}
	return {"success": true, "code": OK}


## Try to read and parse a JSON save file. Returns OK on success.
## Stores parsed data in _last_parsed_data.
func _try_load_file(path: String) -> int:
	_last_parsed_data = {}
	_last_load_error = ""

	if not FileAccess.file_exists(path):
		_last_load_error = "file not found"
		return ERR_FILE_NOT_FOUND

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_load_error = "open failed: %s" % _describe_error_code(FileAccess.get_open_error())
		return ERR_FILE_CANT_OPEN

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(json_string)
	if parse_err != OK:
		_last_load_error = "JSON parse error on line %d: %s" % [json.get_error_line(), json.get_error_message()]
		return ERR_PARSE_ERROR
	if not json.data is Dictionary:
		_last_load_error = "save root is not a JSON object"
		return ERR_INVALID_DATA

	_last_parsed_data = (json.data as Dictionary).duplicate(true)
	return OK


func _describe_error_code(code: int) -> String:
	match code:
		OK:
			return "OK"
		ERR_FILE_NOT_FOUND:
			return "file not found"
		ERR_FILE_CANT_OPEN:
			return "cannot open file"
		ERR_PARSE_ERROR:
			return "parse error"
		ERR_INVALID_DATA:
			return "invalid data"
		_:
			return str(code)
