# EnemyDef Schema

> Defines an enemy type's stats, behavior, and visual properties. Used to configure `EnemyController` instances at spawn time.

**Class:** `EnemyDef` (extends `Resource`)  
**Source:** `resources/enemies/enemy_def.gd`  
**Location:** `resources/enemies/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `enemy_name` | `StringName` | `&""` | Required | Display name for UI/debug |
| `enemy_type` | `StringName` | `&""` | Required, unique per type | Identifier for encounter/score systems |
| `base_hp` | `float` | `50.0` | > 0 | Starting health points |
| `move_speed` | `float` | `4.0` | > 0 | Movement speed (units/sec) |
| `attack_range` | `float` | `1.5` | > 0 | Distance to trigger attack |
| `perception_delay` | `float` | `0.3` | >= 0 | Reaction time before noticing player (sec) |
| `attack_cooldown` | `float` | `1.5` | > 0 | Minimum time between attacks (sec) |
| `attack` | `AttackDef` | `null` | Required | Attack resource for this enemy type |
| `behavior` | `StringName` | `&"rusher"` | `rusher`, `ranged`, `shield`, `boss` | AI behavior type — determines state graph |
| `can_block` | `bool` | `false` | — | Whether enemy uses block/stagger states |
| `block_damage_reduction` | `float` | `0.0` | 0.0–1.0 | Damage absorbed while blocking (0.9 = 90%) |
| `projectile_scene` | `PackedScene` | `null` | Required for `ranged` behavior | Scene to instantiate for ranged attacks |
| `mesh_color` | `Color` | `Color.RED` | — | Placeholder mesh color for visual distinction |
| `xp_reward` | `int` | `10` | >= 0 | XP awarded on death (MVP 4) |

---

## Behavior Types

| Behavior | State Graph | Key Traits |
|----------|-------------|------------|
| `rusher` | idle → chase → attack → hurt/dead | Charges directly at player, melee only |
| `ranged` | idle → chase → retreat/shoot → hurt/dead | Maintains distance, fires projectiles, retreats when player is close |
| `shield` | idle → chase → block → attack/stagger → hurt/dead | Advances while blocking, vulnerable during stagger |
| `boss` | idle → chase → attack → boss_phase_check → hurt/dead | Same as rusher + phase transition at 50% HP |

---

## Example: rusher_def.tres

```tres
enemy_name = &"Rusher"
enemy_type = &"rusher"
base_hp = 50.0
move_speed = 4.0
attack_range = 1.5
perception_delay = 0.3
attack_cooldown = 1.5
attack = ExtResource("enemy_rusher_attack.tres")
behavior = &"rusher"
can_block = false
block_damage_reduction = 0.0
mesh_color = Color(0.9, 0.2, 0.15, 1)
xp_reward = 10
```

---

## Usage

- `WaveSystem` spawns enemies and calls `EnemyController.configure(enemy_def)` to apply all fields.
- `EnemyController._ready()` uses `enemy_def` to set HP, behavior, block rules, and mesh color.
- `EnemyController.get_move_speed()`, `get_attack_range()`, `get_attack_cooldown()` read from this resource with `Constants.ENEMY_RUSHER_*` as fallback defaults when no def is set.

## Current Data Files

| File | Name | HP | Speed | Behavior | Color |
|------|------|----|-------|----------|-------|
| `rusher_def.tres` | Rusher | 50 | 4.0 | rusher | Red |
| `ranged_def.tres` | Ranger | 35 | 3.0 | ranged | Green |
| `shield_def.tres` | Guardian | 70 | 3.0 | shield | Blue |
| `boss_def.tres` | Warden | 300 | 5.0 | boss | Purple |
