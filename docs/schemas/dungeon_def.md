# DungeonDef Schema

> Defines a dungeon entry point. The project supports both legacy room-based dungeons and the current continuous-stage formats.

**Class:** `DungeonDef` (extends `Resource`)  
**Source:** `resources/dungeons/dungeon_def.gd`  
**Location:** `resources/dungeons/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `dungeon_id` | `StringName` | `&""` | Required, unique | Identifier for save/story systems |
| `dungeon_name` | `String` | `""` | Required | Display name |
| `room_scenes` | `Array[String]` | `[]` | Legacy mode only | Ordered room scene paths |
| `room_encounters` | `Array[EncounterDef]` | `[]` | Legacy mode only | One encounter per non-boss room |
| `boss_encounter` | `EncounterDef` | `null` | Legacy mode only | Encounter for the final legacy room |
| `requires_story_flag` | `StringName` | `&""` | Empty = always unlocked | Story gate checked before entry |
| `stage_def` | `StageDef` | `null` | Optional | Single continuous stage override |
| `stage_defs` | `Array[StageDef]` | `[]` | Optional | Sequential continuous stages |

---

## Supported Modes

### Legacy room mode

Uses `room_scenes`, `room_encounters`, and `boss_encounter`. This mode is still supported by `DungeonRun` and `DungeonManager`, but it is no longer the primary content path.

### Single-stage mode

Uses `stage_def` and runs one continuous `StageDef`.

### Multi-stage mode

Uses `stage_defs` and plays multiple `StageDef` resources in order. This is the current format for `dungeon_1.tres`.

---

## Example: dungeon_1.tres

```tres
dungeon_id = &"dungeon_1"
dungeon_name = "Piata Academy Basement - Three Floors"
requires_story_flag = &""
stage_defs = [academy_b1, academy_b2, academy_b3]
```

---

## Usage

- `DungeonRun` prefers `stage_defs` when present.
- If `stage_defs` is empty, `DungeonRun` falls back to `stage_def`.
- If no stage definitions are present, `DungeonRun` uses legacy `room_scenes` loading.
- `StageRunner` handles chunk loading, encounter triggers, and stage completion for stage-based dungeons.
- `DungeonManager` handles encounter progression for legacy room mode.

## Adding a New Dungeon

1. Prefer creating one or more `StageDef` resources in `resources/stages/`.
2. Create or reuse encounter resources in `resources/encounters/`.
3. Create a `DungeonDef` in `resources/dungeons/`.
4. Populate `stage_defs` for multi-stage content or `stage_def` for a single continuous stage.
5. Only use `room_scenes` / `room_encounters` / `boss_encounter` for explicit legacy content.
6. Set `requires_story_flag` if the dungeon is progression-gated.
