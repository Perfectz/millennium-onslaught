## Maps a character's learned techniques onto the three spell buttons (heal / single / area),
## so every hero casts their own PSIV techniques as they learn them. Pure logic.
class_name SpellSlotResolver
extends RefCounted


enum Slot { HEAL, SINGLE, AREA }


## Level a technique is learned at, honouring a per-character learnset override.
static func learn_level(t: TechniqueDef, levels: Dictionary = {}) -> int:
	return int(levels.get(t.technique_id, t.unlock_level))


## Techniques unlocked at or below `level`.
static func learned(techniques: Array[TechniqueDef], level: int, levels: Dictionary = {}) -> Array[TechniqueDef]:
	var out: Array[TechniqueDef] = []
	for t in techniques:
		if t != null and learn_level(t, levels) <= level:
			out.append(t)
	return out


## Techniques unlocked by going from `old_level` to `new_level`.
static func newly_learned(techniques: Array[TechniqueDef], old_level: int, new_level: int, levels: Dictionary = {}) -> Array[TechniqueDef]:
	var out: Array[TechniqueDef] = []
	for t in techniques:
		if t == null:
			continue
		var lv := learn_level(t, levels)
		if lv > old_level and lv <= new_level:
			out.append(t)
	return out


## Strongest learned technique (not skill) for a spell button, or null if none fits.
static func best(techniques: Array[TechniqueDef], level: int, slot: Slot, levels: Dictionary = {}) -> TechniqueDef:
	var pick: TechniqueDef = null
	var pick_power := -INF
	for t in learned(techniques, level, levels):
		if t.is_skill:
			continue
		if not _fits(t, slot):
			continue
		var power := t.heal_amount if slot == Slot.HEAL else t.base_damage
		if power > pick_power:
			pick = t
			pick_power = power
	return pick


static func _fits(t: TechniqueDef, slot: Slot) -> bool:
	match slot:
		Slot.HEAL:
			return t.spell_type == TechniqueDef.SpellType.HEAL
		Slot.SINGLE:
			return t.spell_type == TechniqueDef.SpellType.PROJECTILE and t.aoe_radius <= 0.0
		Slot.AREA:
			return t.spell_type == TechniqueDef.SpellType.AOE_BURST or (t.spell_type == TechniqueDef.SpellType.PROJECTILE and t.aoe_radius > 0.0)
	return false
