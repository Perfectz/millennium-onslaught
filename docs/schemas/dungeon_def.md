# DungeonDef Schema

> Defines a complete dungeon — its room sequence, encounters per room, and boss fight.

**Class:** `DungeonDef` (extends `Resource`)  
**Source:** `resources/dungeons/dungeon_def.gd`  
**Location:** `resources/dungeons/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `dungeon_id` | `StringName` | `&""` | Required, unique | Identifier for save/story systems |
| `dungeon_name` | `String` | `""` | Required | Display name |
| `room_scenes` | `Array[String]` | `[]` | >= 1 path, last is boss room | Ordered scene paths (`res://scenes/dungeon/rooms/*.tscn`) |
| `room_encounters` | `Array[EncounterDef]` | `[]` | Length = `room_scenes.size() - 1` | One encounter per non-boss room |
| `boss_encounter` | `EncounterDef` | `null` | Required | Encounter for the final (boss) room |
| `requires_story_flag` | `StringName` | `&""` | Empty = always unlocked | Story flag that must be set to enter (MVP 3) |

---

## Room Flow

```
room_scenes[0] → room_encounters[0]
room_scenes[1] → room_encounters[1]
room_scenes[2] → room_encounters[2]
room_scenes[3] → boss_encounter     (final room)
```

`DungeonManager` advances through rooms linearly. Each room loads its scene and starts its encounter. After all enemies in all waves are cleared, the player transitions to the next room. The final room uses `boss_encounter`.

---

## Example: dungeon_1.tres ("Piata Basement")

```tres
dungeon_id = &"dungeon_1"
dungeon_name = "Piata Basement"
room_scenes = [
    "res://scenes/dungeon/rooms/room_01.tscn",
    "res://scenes/dungeon/rooms/room_02.tscn",
    "res://scenes/dungeon/rooms/room_03.tscn",
    "res://scenes/dungeon/rooms/room_boss.tscn"
]
room_encounters = [encounter_room1, encounter_room2, encounter_room3]
boss_encounter = encounter_boss
requires_story_flag = &""
```

---

## Usage

- `DungeonRun` loads a `DungeonDef` and passes it to `DungeonManager`.
- `DungeonManager` uses `room_scenes` to load room geometry and `room_encounters`/`boss_encounter` to start encounters.
- On dungeon completion, `GameState.bank_dungeon_rewards()` is called and `dungeon_completed` signal is emitted.
- On dungeon failure, `GameState.reset_dungeon()` clears transient state.

## Adding a New Dungeon

1. Create room scenes in `scenes/dungeon/rooms/`
2. Create encounter .tres files in `resources/encounters/`
3. Create a new `DungeonDef` .tres in `resources/dungeons/`
4. Reference all room scenes and encounters
5. Set `requires_story_flag` if gated by progression
