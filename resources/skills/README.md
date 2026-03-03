# resources/skills/

## Purpose
SkillTreeDef and SkillNodeDef resources defining per-character skill trees — stat bonuses, passive effects, prerequisites, and tier layout.

## Schema
See `docs/schemas/skill_tree_def.md` for full field documentation.

## Current Contents

| File | Description |
|------|-------------|
| `skill_node_def.gd` | SkillNodeDef class definition (single skill node) |
| `skill_tree_def.gd` | SkillTreeDef class definition (collection of nodes) |

**Note:** Skill tree .tres data files (alys_tree.tres, chaz_tree.tres, rune_tree.tres, wren_tree.tres) are planned. Currently, skill trees are defined inline via SkillTreeManager tests. Full .tres files will be authored when the skill tree UI is complete.

## Tier System
- **Tier 0 (Root):** Starting nodes, no prerequisites, cost 1 point
- **Tier 1 (Mid):** Intermediate, require 1+ root, cost 1-2 points
- **Tier 2 (Capstone):** Powerful endgame, require 1+ mid, cost 2-3 points

## Design Notes
- `CharacterDef.skill_tree_id` links to a SkillTreeDef.tree_id.
- `SkillTreeDef.to_manager_format()` converts to Dictionary format for SkillTreeManager.
- `SkillTreeManager` handles unlock validation, prerequisite checking, and bonus aggregation.
- `StatCalculator.calculate_derived()` accepts skill bonuses as input.
- UI color coding: green = unlocked, yellow = available, gray = locked.

## AI Coding Guidance
- Keep files data-centric; runtime behavior belongs in `scripts/`.
- Each tree should have 8-10 nodes across 3 tiers.
- Ensure prerequisites reference valid skill_ids within the same tree.

## Maintenance
- Update this README when adding skill tree data files or changing the tier structure.
