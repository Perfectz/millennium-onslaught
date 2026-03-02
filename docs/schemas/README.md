# docs/schemas/ - Data Schema Documentation

Schema docs in this folder should describe fields, ranges, and examples for each resource type.

## Current Status (2026-03-01)

Per-schema markdown files have not been written yet.
Resource classes currently implemented in code:

- `AttackDef` (`resources/attacks/attack_def.gd`)
- `EnemyDef` (`resources/enemies/enemy_def.gd`)
- `SpawnEntry` (`resources/encounters/spawn_entry.gd`)
- `WaveDef` (`resources/encounters/wave_def.gd`)
- `EncounterDef` (`resources/encounters/encounter_def.gd`)
- `DungeonDef` (`resources/dungeons/dungeon_def.gd`)

## Recommended Schema Doc Format

1. Resource class and purpose
2. Field table (name, type, default, constraints)
3. Minimal valid example
4. Authoring notes (how to create/edit in Godot)
5. Validation and runtime usage notes
