# Encounter System Schemas

> Three resource types compose the encounter system: `SpawnEntry` → `WaveDef` → `EncounterDef`. Together they define what enemies spawn, in what waves, with what arena constraints.

---

## SpawnEntry

> A single spawn instruction — how many of which enemy, from which side.

**Class:** `SpawnEntry` (extends `Resource`)  
**Source:** `resources/encounters/spawn_entry.gd`

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `enemy_def` | `EnemyDef` | `null` | Required | Which enemy type to spawn |
| `count` | `int` | `1` | >= 1 | How many to spawn |
| `spawn_side` | `StringName` | `&"both"` | `left`, `right`, `both` | Edge of arena to spawn from |

---

## WaveDef

> A group of spawn entries that arrive together as one wave.

**Class:** `WaveDef` (extends `Resource`)  
**Source:** `resources/encounters/wave_def.gd`

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `spawn_entries` | `Array[SpawnEntry]` | `[]` | >= 1 entry | Enemies in this wave |
| `delay_before_spawn` | `float` | `1.0` | >= 0 | Seconds to wait before spawning (after previous wave cleared) |

---

## EncounterDef

> A complete fight sequence — one or more waves with arena camera constraints.

**Class:** `EncounterDef` (extends `Resource`)  
**Source:** `resources/encounters/encounter_def.gd`

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `encounter_id` | `StringName` | `&""` | Unique per encounter | Identifier for tracking |
| `waves` | `Array[WaveDef]` | `[]` | >= 1 wave | Ordered wave sequence |
| `arena_lock` | `bool` | `true` | — | Whether camera arena-locks during this encounter |
| `arena_min_x` | `float` | `-10.0` | < arena_max_x | Left camera/player bound |
| `arena_max_x` | `float` | `10.0` | > arena_min_x | Right camera/player bound |

---

## Composition Diagram

```
EncounterDef
├── waves[0]: WaveDef
│   ├── spawn_entries[0]: SpawnEntry { rusher_def, count=2, both }
│   └── spawn_entries[1]: SpawnEntry { ranged_def, count=1, right }
├── waves[1]: WaveDef
│   ├── spawn_entries[0]: SpawnEntry { shield_def, count=1, left }
│   └── spawn_entries[1]: SpawnEntry { rusher_def, count=3, both }
├── arena_lock = true
├── arena_min_x = -8.0
└── arena_max_x = 8.0
```

---

## Example: encounter_room1.tres

```
Encounter: 2 waves
  Wave 1 (delay 1.0s): 2 rushers from both sides
  Wave 2 (delay 1.0s): 1 rusher + 1 ranged
Arena lock: true, bounds [-8, 8]
```

---

## Usage

- `DungeonDef.room_encounters` holds one `EncounterDef` per room.
- `WaveSystem.start_encounter(encounter_def)` reads waves and spawns enemies sequentially.
- `CameraFollow` receives arena bounds (X + Z) via `encounter_arena_locked` signal.
- When all enemies in a wave die, `WaveSystem` advances to the next wave or emits `enemy_wave_cleared`.

## Current Data Files

| File | Waves | Enemy Composition |
|------|-------|-------------------|
| `encounter_room1.tres` | 2 | W1: 2 rushers → W2: 1 rusher + 1 ranged |
| `encounter_room2.tres` | 2 | W1: 2 ranged + 1 shield → W2: 3 rushers |
| `encounter_room3.tres` | 3 | W1: 3 rushers → W2: 2 ranged + 1 shield → W3: 2 rushers + 2 shields + 1 ranged |
| `encounter_boss.tres` | 1 | W1: 1 boss (Warden) |
