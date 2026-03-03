## Pure skill tree logic. No scene tree dependency — fully testable.
## Validates prerequisites, manages unlocks, and computes passive bonuses.
class_name SkillTreeManager
extends RefCounted


signal skill_unlocked(skill_id: StringName)

## Skill definitions keyed by skill_id.
var _skills: Dictionary = {}


## Load a tree from an array of skill dictionaries.
## Each entry: {skill_id, prerequisites, point_cost, stat_bonuses}
func load_tree(skills: Array) -> void:
	_skills.clear()
	for skill: Dictionary in skills:
		var sid: StringName = skill["skill_id"]
		_skills[sid] = skill.duplicate(true)


## Get the number of skills in the tree.
func get_skill_count() -> int:
	return _skills.size()


## Attempt to unlock a skill. Modifies unlocked dict in place. Returns true on success.
func unlock(skill_id: StringName, unlocked: Dictionary, available_points: int) -> bool:
	if skill_id not in _skills:
		return false
	if skill_id in unlocked:
		return false
	var skill: Dictionary = _skills[skill_id]
	if available_points < skill["point_cost"]:
		return false
	for prereq: StringName in skill["prerequisites"]:
		if prereq not in unlocked:
			return false
	unlocked[skill_id] = true
	skill_unlocked.emit(skill_id)
	return true


## Check if a skill can be unlocked (without actually unlocking it).
func can_unlock(skill_id: StringName, unlocked: Dictionary, available_points: int) -> bool:
	if skill_id not in _skills:
		return false
	if skill_id in unlocked:
		return false
	var skill: Dictionary = _skills[skill_id]
	if available_points < skill["point_cost"]:
		return false
	for prereq: StringName in skill["prerequisites"]:
		if prereq not in unlocked:
			return false
	return true


## Get total stat bonuses from all unlocked skills.
func get_total_bonuses(unlocked: Dictionary) -> Dictionary:
	var total: Dictionary = {}
	for sid: StringName in unlocked:
		if sid in _skills:
			var bonuses: Dictionary = _skills[sid]["stat_bonuses"]
			for key: String in bonuses:
				total[key] = total.get(key, 0) + bonuses[key]
	return total


## Get the point cost of a skill.
func get_skill_cost(skill_id: StringName) -> int:
	if skill_id not in _skills:
		return 0
	return _skills[skill_id]["point_cost"]


## Get the prerequisites of a skill.
func get_skill_prerequisites(skill_id: StringName) -> Array:
	if skill_id not in _skills:
		return []
	return _skills[skill_id]["prerequisites"]


## Get a skill's full data dict.
func get_skill_data(skill_id: StringName) -> Dictionary:
	return _skills.get(skill_id, {})
