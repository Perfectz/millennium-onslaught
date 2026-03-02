## Randomizes enemy wave selection from encounter pools.
## Pure logic — no scene tree dependency. Fully testable.
class_name EncounterRoller
extends RefCounted


## Roll a single wave from a pool of possible entries.
## Each entry is a Dictionary with "enemy_type": StringName, "count": int.
## Returns an Array of selected entries (picks one from the pool).
func roll_wave(pool: Array[Dictionary]) -> Array[Dictionary]:
	if pool.is_empty():
		return []
	var index := randi_range(0, pool.size() - 1)
	return [pool[index]]


## Roll a complete encounter from a sequence of wave pools.
## Each element in waves is an Array[Dictionary] pool to roll from.
## Returns Array[Array[Dictionary]] — one rolled wave per pool.
func roll_encounter(waves: Array[Array]) -> Array[Array]:
	var result: Array[Array] = []
	for wave_pool in waves:
		result.append(roll_wave(wave_pool))
	return result


## Count total enemies across all entries in a wave.
func count_enemies_in_wave(wave: Array[Dictionary]) -> int:
	var total := 0
	for entry in wave:
		total += entry.get("count", 0)
	return total
