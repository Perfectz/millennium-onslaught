# AttackDef Schema

> Defines a single attack or combo step. Used by both player and enemy attack states.

**Class:** `AttackDef` (extends `Resource`)  
**Source:** `resources/attacks/attack_def.gd`  
**Location:** `resources/attacks/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `attack_name` | `StringName` | `&""` | Unique per attack | Identifier for logging and cancel system |
| `base_damage` | `float` | `10.0` | > 0 | Raw damage before multipliers |
| `damage_multiplier` | `float` | `1.0` | > 0 | Scales base_damage (stat/level modifier) |
| `knockback_force` | `float` | `3.0` | >= 0 | Knockback impulse magnitude |
| `knockback_direction` | `Vector3` | `(1, 0.2, 0)` | Normalized preferred | Direction of knockback (X=horizontal, Y=vertical) |
| `hitstop_duration` | `float` | `0.05` | >= 0 | Screen freeze duration on hit (seconds) |
| `windup_time` | `float` | `0.0` | >= 0 | Delay before hitbox activates |
| `active_time` | `float` | `0.1` | > 0 | Duration hitbox is active |
| `recovery_time` | `float` | `0.2` | >= 0 | Cooldown after active frames |
| `cancel_window_start` | `float` | `0.5` | 0.0–1.0 | Normalized time when cancel opens |
| `cancel_window_end` | `float` | `0.9` | 0.0–1.0, >= start | Normalized time when cancel closes |
| `cancel_into` | `Array[StringName]` | `[&"dodge"]` | Valid: `light`, `heavy`, `dodge`, `technique`, `jump`, `launcher` | Actions that can interrupt during window |
| `is_launcher` | `bool` | `false` | — | Whether this attack launches enemies airborne |
| `launch_velocity` | `float` | `0.0` | >= 0 (relevant only if is_launcher) | Upward velocity applied to launched target |

---

## Timing Model

Total attack duration = `windup_time + active_time + recovery_time`

Cancel window is normalized (0.0–1.0) across this total duration. For example, with windup=0.0, active=0.1, recovery=0.15 (total=0.25s), a cancel_window_start of 0.4 opens at 0.1s into the attack.

```
|---windup---|---active---|---recovery---|
0.0                                    1.0
             ^cancel_start  ^cancel_end
```

---

## Example: light_attack_1.tres

```tres
attack_name = &"light_1"
base_damage = 10.0
damage_multiplier = 1.0
knockback_force = 7.0
knockback_direction = Vector3(1, 0.2, 0)
hitstop_duration = 0.07
windup_time = 0.0
active_time = 0.1
recovery_time = 0.15
cancel_window_start = 0.4
cancel_window_end = 0.9
cancel_into = [&"dodge", &"heavy", &"launcher"]
```

---

## Usage

- Player attack states load AttackDefs via preload and use them to configure hitbox damage, timing, and cancel rules.
- Enemy attacks are referenced via `EnemyDef.attack` or `boss_attack_override`.
- `ComboCancelChecker` reads `cancel_window_start`, `cancel_window_end`, and `cancel_into` to validate cancel inputs.
- `DamageCalculator` reads `base_damage` and `damage_multiplier`.

## Current Data Files

| File | Name | Damage | Cancel Into |
|------|------|--------|-------------|
| `light_attack_1.tres` | light_1 | 10 | dodge, heavy, launcher |
| `light_attack_2.tres` | light_2 | 10 | dodge, heavy, launcher |
| `light_attack_3.tres` | light_3 | 15 | dodge |
| `heavy_attack.tres` | heavy | 25 | dodge |
| `launcher_attack.tres` | launcher | 12 | dodge, jump |
| `projectile_attack.tres` | projectile | 20 | — |
| `enemy_rusher_attack.tres` | rusher_swing | 8 | — |
| `enemy_ranged_attack.tres` | ranged_shot | 8 | — |
| `enemy_shield_attack.tres` | shield_bash | 10 | — |
| `boss_attack_1.tres` | boss_slam | 20 | — |
| `boss_attack_2.tres` | boss_slam_enraged | 26 | — |
