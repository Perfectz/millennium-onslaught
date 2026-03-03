# resources/encounters/

## Purpose
Encounter data files defining enemy wave compositions for dungeon rooms. Three resource types compose the encounter pipeline: `SpawnEntry` → `WaveDef` → `EncounterDef`.

## Schema
See [docs/schemas/encounter_def.md](../../docs/schemas/encounter_def.md) for full field definitions of all three types.

## Resource Definitions

| File | Class | Purpose |
|------|-------|---------|
| `spawn_entry.gd` | SpawnEntry | Single spawn instruction (which enemy, how many, from where) |
| `wave_def.gd` | WaveDef | Group of spawn entries arriving together |
| `encounter_def.gd` | EncounterDef | Complete fight — ordered waves + arena bounds |

## Data Files

| File | Waves | Enemy Composition |
|------|-------|-------------------|
| `encounter_room1.tres` | 2 | W1: 2 rushers → W2: 1 rusher + 1 ranged |
| `encounter_room2.tres` | 2 | W1: 2 ranged + 1 shield → W2: 3 rushers |
| `encounter_room3.tres` | 3 | W1: 3 rushers → W2: 2 ranged + 1 shield → W3: 2 rushers + 2 shields + 1 ranged |
| `encounter_boss.tres` | 1 | W1: 1 boss (Warden) |

## Adding a New Encounter
1. Create `SpawnEntry` sub-resources inline or as separate `.tres`
2. Create `WaveDef` resources referencing the spawn entries
3. Create an `EncounterDef` with ordered waves and arena bounds
4. Reference from a `DungeonDef.room_encounters` or `boss_encounter`
