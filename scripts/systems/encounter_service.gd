## Generates encounter data from encounter definitions.
## Stateless — all generation uses passed parameters and optional seed.
class_name EncounterService
extends RefCounted


## Generate wave definitions from an encounter definition dictionary.
## Encounter def format: { "waves": [{ "enemy_types": [...], "count_range": [min, max] }] }
static func generate_encounter(encounter_def: Dictionary, seed_value: int = -1) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var waves: Array[Dictionary] = []
	var wave_defs: Array = encounter_def.get("waves", [])
	for wave_def: Dictionary in wave_defs:
		var wave: Dictionary = _generate_wave(wave_def, rng)
		waves.append(wave)
	return waves


## Generate spawn positions for a wave within room bounds.
static func generate_spawn_positions(
	enemy_count: int,
	room_min: Vector3,
	room_max: Vector3,
	min_spacing: float = 2.0,
	seed_value: int = -1
) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var positions: Array[Vector3] = []
	var attempts: int = 0
	var max_attempts: int = enemy_count * 10
	while positions.size() < enemy_count and attempts < max_attempts:
		var pos := Vector3(
			rng.randf_range(room_min.x, room_max.x),
			room_min.y,
			rng.randf_range(room_min.z, room_max.z)
		)
		if _is_position_valid(pos, positions, min_spacing):
			positions.append(pos)
		attempts += 1
	return positions


## Validate an encounter definition has required fields.
static func validate_encounter_def(encounter_def: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if "waves" not in encounter_def:
		errors.append("Missing 'waves' field")
		return errors
	var waves: Array = encounter_def["waves"]
	if waves.is_empty():
		errors.append("'waves' array is empty")
	for i: int in waves.size():
		var wave: Dictionary = waves[i]
		if "enemy_types" not in wave:
			errors.append("Wave %d: missing 'enemy_types'" % i)
		elif wave["enemy_types"].is_empty():
			errors.append("Wave %d: 'enemy_types' is empty" % i)
		if "count_range" not in wave:
			errors.append("Wave %d: missing 'count_range'" % i)
		elif wave["count_range"].size() != 2:
			errors.append("Wave %d: 'count_range' must have [min, max]" % i)
	return errors


static func _generate_wave(wave_def: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var enemy_types: Array = wave_def.get("enemy_types", [])
	var count_range: Array = wave_def.get("count_range", [1, 3])
	var count_min: int = count_range[0] if count_range.size() > 0 else 1
	var count_max: int = count_range[1] if count_range.size() > 1 else count_min
	var count: int = rng.randi_range(count_min, count_max)
	var enemies: Array[Dictionary] = []
	for i: int in count:
		var type_index: int = rng.randi_range(0, enemy_types.size() - 1)
		enemies.append({
			"type": enemy_types[type_index],
			"index": i,
		})
	return {
		"enemies": enemies,
		"count": count,
	}


static func _is_position_valid(pos: Vector3, existing: Array[Vector3], min_spacing: float) -> bool:
	for other: Vector3 in existing:
		if pos.distance_to(other) < min_spacing:
			return false
	return true
