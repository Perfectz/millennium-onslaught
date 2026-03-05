## Simulates combat encounters to test balance.
## Run from editor or command line to generate balance reports.
class_name BalanceCalculator
extends RefCounted


## Result of a simulated combat encounter.
class SimResult extends RefCounted:
	var attacker_name: String = ""
	var defender_name: String = ""
	var hits_to_kill: int = 0
	var total_damage: float = 0.0
	var crit_count: int = 0
	var overkill: float = 0.0


## Simulate N combat encounters between attacker and defender stats.
static func simulate_encounters(
	attacker_stats: Dictionary,
	defender_stats: Dictionary,
	attack_damage: float,
	num_trials: int = 1000,
	seed_value: int = -1
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var results: Array[SimResult] = []
	var total_hits: int = 0
	var total_crits: int = 0
	var min_hits: int = 999999
	var max_hits: int = 0
	for _i: int in num_trials:
		var result := _simulate_single(
			attacker_stats, defender_stats, attack_damage, rng
		)
		results.append(result)
		total_hits += result.hits_to_kill
		total_crits += result.crit_count
		min_hits = mini(min_hits, result.hits_to_kill)
		max_hits = maxi(max_hits, result.hits_to_kill)
	var avg_hits: float = float(total_hits) / float(num_trials)
	var crit_rate: float = float(total_crits) / float(total_hits) if total_hits > 0 else 0.0
	return {
		"trials": num_trials,
		"avg_hits_to_kill": avg_hits,
		"min_hits": min_hits,
		"max_hits": max_hits,
		"crit_rate_observed": crit_rate,
		"attacker_strength": attacker_stats.get("strength", 5),
		"defender_defense": defender_stats.get("defense", 5),
		"defender_hp": defender_stats.get("hp", 100.0),
	}


## Generate a human-readable balance report.
static func generate_report(sim_results: Array[Dictionary]) -> String:
	var report: String = "=== Balance Report ===\n"
	report += "Generated: %s\n\n" % Time.get_datetime_string_from_system()
	for result: Dictionary in sim_results:
		report += "--- Matchup ---\n"
		report += "  STR %d vs DEF %d (HP: %.0f)\n" % [
			result["attacker_strength"],
			result["defender_defense"],
			result["defender_hp"]
		]
		report += "  Avg hits to kill: %.1f\n" % result["avg_hits_to_kill"]
		report += "  Range: %d – %d hits\n" % [result["min_hits"], result["max_hits"]]
		report += "  Observed crit rate: %.1f%%\n" % (result["crit_rate_observed"] * 100.0)
		report += "\n"
	return report


static func _simulate_single(
	attacker: Dictionary,
	defender: Dictionary,
	base_damage: float,
	rng: RandomNumberGenerator
) -> SimResult:
	var result := SimResult.new()
	var hp: float = defender.get("hp", 100.0)
	var atk_str: int = attacker.get("strength", 5)
	var def_def: int = defender.get("defense", 5)
	var atk_agi: int = attacker.get("agility", 5)
	var crit_chance: float = CombatService.calculate_crit_chance(atk_agi)
	while hp > 0.0:
		var is_crit: bool = rng.randf() < crit_chance
		var damage: float = CombatService.calculate_damage(
			base_damage, atk_str, def_def, &"physical", &"", is_crit
		)
		hp -= damage
		result.hits_to_kill += 1
		result.total_damage += damage
		if is_crit:
			result.crit_count += 1
	result.overkill = absf(hp)
	return result
