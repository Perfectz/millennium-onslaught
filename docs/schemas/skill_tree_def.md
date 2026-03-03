# SkillTreeDef / SkillNodeDef Schema

> Defines a character's skill tree. Each tree contains nodes that grant stat bonuses and passive effects when unlocked with skill points.

**Classes:** `SkillTreeDef`, `SkillNodeDef` (both extend `Resource`)
**Source:** `resources/skills/skill_tree_def.gd`, `resources/skills/skill_node_def.gd`
**Location:** `resources/skills/*.tres`

---

## SkillTreeDef Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `tree_id` | `StringName` | `&""` | Matches CharacterDef.skill_tree_id | Unique tree identifier |
| `skills` | `Array[SkillNodeDef]` | `[]` | — | All skill nodes in this tree |

### Helper Method

`to_manager_format() -> Array[Dictionary]` — Converts the skills array to the Dictionary format used by `SkillTreeManager.load_tree()`.

---

## SkillNodeDef Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `skill_id` | `StringName` | `&""` | Unique within tree | Identifier for unlock tracking |
| `display_name` | `String` | `""` | — | Name shown in UI |
| `description` | `String` | `""` | — | Effect description for tooltip |
| `stat_bonuses` | `Dictionary` | `{}` | Keys: stat names | Stat increases when unlocked (e.g., `{"strength": 2}`) |
| `passive_effects` | `Dictionary` | `{}` | Keys: effect names | Passive effects (e.g., `{"crit_chance": 0.05}`) |
| `prerequisites` | `Array[StringName]` | `[]` | Valid skill_ids in same tree | Skills that must be unlocked first |
| `point_cost` | `int` | `1` | >= 1 | Skill points required to unlock |
| `tier` | `int` | `0` | 0, 1, or 2 | 0 = root, 1 = mid, 2 = capstone |
| `ui_position` | `Vector2` | `(0, 0)` | — | Position hint for visual layout |

---

## Tier System

| Tier | Name | Typical Cost | Description |
|------|------|-------------|-------------|
| 0 | Root | 1 | Starting nodes, no prerequisites |
| 1 | Mid | 1–2 | Intermediate nodes, require 1+ root |
| 2 | Capstone | 2–3 | Powerful endgame nodes, require 1+ mid |

---

## Example: alys_tree.tres

```tres
tree_id = &"alys_tree"
skills = [
  # Tier 0 (root)
  SkillNodeDef { skill_id: &"swift_strikes", stat_bonuses: {"agility": 2}, tier: 0 },
  SkillNodeDef { skill_id: &"hunters_eye", stat_bonuses: {"strength": 2}, tier: 0 },

  # Tier 1 (mid)
  SkillNodeDef { skill_id: &"vortex_mastery", passive_effects: {"fire_damage_bonus": 0.15},
                 prerequisites: [&"swift_strikes"], point_cost: 2, tier: 1 },

  # Tier 2 (capstone)
  SkillNodeDef { skill_id: &"shadow_dance", passive_effects: {"dodge_bonus": 0.1},
                 prerequisites: [&"vortex_mastery"], point_cost: 3, tier: 2 },
]
```

---

## Usage

- `SkillTreeManager.load_tree(tree_data)` ingests the Dictionary format from `to_manager_format()`.
- `SkillTreeManager.can_unlock(skill_id, available_points)` validates prerequisites and point cost.
- `SkillTreeManager.unlock_skill(skill_id)` marks a skill as unlocked.
- `SkillTreeManager.get_total_stat_bonuses()` aggregates all unlocked stat bonuses.
- `SkillTreeManager.get_total_passive_effects()` aggregates all unlocked passive effects.
- `StatCalculator.calculate_derived()` accepts skill bonuses as a parameter.
- UI color coding: green = unlocked, yellow = available, gray = locked.

## Current Data Files

| File | Tree ID | Character | Nodes |
|------|---------|-----------|-------|
| `alys_tree.tres` | alys_tree | Alys | 8 nodes (agility/fire focus) |
| `chaz_tree.tres` | chaz_tree | Chaz | 8 nodes (strength/lightning focus) |
| `rune_tree.tres` | rune_tree | Rune | 10 nodes (magic/multi-element focus) |
| `wren_tree.tres` | wren_tree | Wren | 8 nodes (defense/mechanical focus) |
