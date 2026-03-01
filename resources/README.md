# resources/ — Custom Resource Data Files

All gameplay-tunable data lives here as `.tres` resource files. Adding new content (characters, enemies, attacks, equipment) means creating new resources here — not modifying system logic.

## Subfolders

| Folder | Resource Type | MVP |
|--------|--------------|-----|
| `characters/` | CharacterDef | 1 |
| `enemies/` | EnemyDef | 2 |
| `attacks/` | AttackDef | 1 |
| `equipment/` | EquipmentDef | 4 |
| `encounters/` | EncounterDef | 2 |
| `dungeons/` | DungeonDef | 2 |
| `towns/` | TownDef | 3 |
| `story/` | StoryDef | 3 |
| `skills/` | SkillTreeDef | 4 |

## Naming Convention

- Files: `snake_case.tres` matching what they define
- Examples: `chaz_character.tres`, `sand_worm_enemy.tres`, `fire_slash_attack.tres`

## Rule

Resources are pure data. They never contain logic beyond validation. All resource types follow a common pattern: define fields, expose getters, validate on load. Schema docs live in `docs/schemas/`.
