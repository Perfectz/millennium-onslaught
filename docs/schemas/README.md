# docs/schemas/ — Data Schema Documentation

Each resource type used in the project is documented here with all fields, valid ranges, and examples.

## Contents

*No schemas documented yet — created starting MVP 1 when data resources are introduced.*

## Planned Schemas (MVP order)

| Schema | MVP | Description |
|--------|-----|-------------|
| CharacterDef | 1 | Playable character definition |
| AttackDef | 1 | Single attack or combo step definition |
| EnemyDef | 2 | Enemy type definition |
| EncounterDef | 2 | Wave of enemies configuration |
| DungeonDef | 2 | Complete dungeon definition |
| TownDef | 3 | Town with shop, inn, NPCs |
| StoryDef | 3 | Dialogue and cutscene scripts |
| EquipmentDef | 4 | Weapon, armor, accessory definitions |
| SkillTreeDef | 4 | Per-character passive upgrade tree |

## Format Convention

Each schema doc should include:
1. Resource type name and class
2. Purpose (one line)
3. All fields with types and valid ranges
4. At least one complete example
5. Notes on how to create new instances
