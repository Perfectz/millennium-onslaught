## Pure item-use math: given an ItemDef and a character's vitals, compute the result.
class_name ItemEffectResolver
extends RefCounted


## Returns {hp, tp, hp_restored, tp_restored, cured: Array[StringName], revived: bool, useful: bool}.
static func resolve(item: ItemDef, hp: float, max_hp: float, tp: float, max_tp: float, statuses: Array) -> Dictionary:
	var result := {
		"hp": hp, "tp": tp, "hp_restored": 0.0, "tp_restored": 0.0,
		"cured": [] as Array[StringName], "revived": false, "useful": false,
	}
	var dead := hp <= 0.0
	if dead and not item.revive:
		return result
	var heal := item.heal_hp + item.heal_hp_ratio * max_hp
	# Revive items (Moon Dew) only act on KO'd characters.
	var can_heal := dead or (hp < max_hp and not item.revive)
	if heal > 0.0 and can_heal:
		var new_hp := minf(hp + heal, max_hp)
		result["hp"] = new_hp
		result["hp_restored"] = new_hp - hp
		result["useful"] = true
		result["revived"] = dead
	if item.heal_tp > 0.0 and tp < max_tp:
		var new_tp := minf(tp + item.heal_tp, max_tp)
		result["tp"] = new_tp
		result["tp_restored"] = new_tp - tp
		result["useful"] = true
	var cured: Array[StringName] = []
	for status in item.cures:
		if status in statuses:
			cured.append(status)
	if not cured.is_empty():
		result["cured"] = cured
		result["useful"] = true
	return result
