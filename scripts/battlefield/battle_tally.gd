## KO counter, rank and reward math for a battlefield run.
class_name BattleTally
extends RefCounted


signal milestone_reached(ko_count: int)

var _ko_count: int = 0
var _officer_kos: int = 0
var _best_combo: int = 0


## Count a KO. Officers count toward the KO total too.
func register_ko(is_officer: bool) -> void:
	_ko_count += 1
	if is_officer:
		_officer_kos += 1
	if Constants.BATTLE_KO_MILESTONE > 0 and _ko_count % Constants.BATTLE_KO_MILESTONE == 0:
		milestone_reached.emit(_ko_count)


## Track the longest hit chain.
func register_combo(hits: int) -> void:
	_best_combo = maxi(_best_combo, hits)


## Total KOs.
func get_ko_count() -> int:
	return _ko_count


## Officer KOs.
func get_officer_ko_count() -> int:
	return _officer_kos


## Longest combo.
func get_best_combo() -> int:
	return _best_combo


## XP earned: every KO plus an officer bonus.
func get_xp_reward() -> int:
	return _ko_count * Constants.BATTLE_XP_PER_KO + _officer_kos * Constants.BATTLE_XP_PER_OFFICER


## Meseta earned: every KO plus an officer bonus.
func get_gold_reward() -> int:
	return _ko_count * Constants.BATTLE_GOLD_PER_KO + _officer_kos * Constants.BATTLE_GOLD_PER_OFFICER


## Battle rank letter for this run.
func get_rank() -> String:
	return rank_for_kos(_ko_count)


## Rank letter for a KO count (thresholds in Constants, highest first).
static func rank_for_kos(kos: int) -> String:
	var thresholds := Constants.BATTLE_RANK_KO_THRESHOLDS
	for i in thresholds.size():
		if kos >= thresholds[i]:
			return Constants.BATTLE_RANK_LETTERS[i]
	return Constants.BATTLE_RANK_LETTERS[Constants.BATTLE_RANK_LETTERS.size() - 1]
