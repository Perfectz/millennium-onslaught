## Data definition for a character's complete skill tree.
class_name SkillTreeDef
extends Resource


## Unique tree identifier (matches CharacterDef.skill_tree_id).
@export var tree_id: StringName = &""

## All skill nodes in this tree.
@export var skills: Array[SkillNodeDef] = []


## Convert skills array to the Dictionary format used by SkillTreeManager.load_tree().
func to_manager_format() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node: SkillNodeDef in skills:
		result.append({
			"skill_id": node.skill_id,
			"prerequisites": node.prerequisites.duplicate(),
			"point_cost": node.point_cost,
			"stat_bonuses": node.stat_bonuses.duplicate(),
			"passive_effects": node.passive_effects.duplicate(),
			"display_name": node.display_name,
			"description": node.description,
			"tier": node.tier,
			"ui_position": node.ui_position,
		})
	return result
