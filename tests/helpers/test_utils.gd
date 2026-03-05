## Test utility helpers for parameterized tests and common test patterns.
class_name TestUtils
extends RefCounted


## Run a callable for each set of parameters. Returns array of failure messages.
static func parameterized_test(
	test_cases: Array[Dictionary],
	test_func: Callable
) -> Array[String]:
	var failures: Array[String] = []
	for i: int in test_cases.size():
		var tc: Dictionary = test_cases[i]
		var label: String = tc.get("label", "Case %d" % i)
		var result: String = test_func.call(tc)
		if result != "":
			failures.append("%s: %s" % [label, result])
	return failures


## Create a mock character stats dictionary for testing.
static func make_character_stats(
	strength: int = 5,
	defense: int = 5,
	agility: int = 5,
	magic: int = 5,
	hp: float = 100.0
) -> Dictionary:
	return {
		"strength": strength,
		"defense": defense,
		"agility": agility,
		"magic": magic,
		"hp": hp,
	}


## Create a mock encounter definition for testing.
static func make_encounter_def(
	num_waves: int = 2,
	enemies_per_wave: int = 3,
	enemy_types: Array[StringName] = [&"rusher"]
) -> Dictionary:
	var waves: Array[Dictionary] = []
	for _i: int in num_waves:
		waves.append({
			"enemy_types": enemy_types,
			"count_range": [enemies_per_wave, enemies_per_wave],
		})
	return {"waves": waves}


## Assert that a float is within a percentage tolerance of expected.
static func assert_within_percent(actual: float, expected: float, percent: float) -> String:
	var tolerance: float = expected * (percent / 100.0)
	if absf(actual - expected) > tolerance:
		return "Expected %.2f ± %.1f%%, got %.2f" % [expected, percent, actual]
	return ""
