# docs/schemas/ - Data Schema Documentation

Schema docs in this folder describe fields, ranges, and examples for each resource type.

## Current Status (2026-03-02)

| Schema | File | Resource Class |
|--------|------|---------------|
| AttackDef | `attack_def.md` | `resources/attacks/attack_def.gd` |
| EnemyDef | `enemy_def.md` | `resources/enemies/enemy_def.gd` |
| Encounter System | `encounter_def.md` | `SpawnEntry`, `WaveDef`, `EncounterDef` |
| DungeonDef | `dungeon_def.md` | `resources/dungeons/dungeon_def.gd` |
| CharacterDef | `character_def.md` | `resources/characters/character_def.gd` |
| TechniqueDef | `technique_def.md` | `resources/techniques/technique_def.gd` |
| SkillTreeDef / SkillNodeDef | `skill_tree_def.md` | `resources/skills/skill_tree_def.gd`, `skill_node_def.gd` |

## Schema Doc Format

1. Resource class and purpose
2. Field table (name, type, default, constraints)
3. Minimal valid example
4. Authoring notes (how to create/edit in Godot)
5. Validation and runtime usage notes
