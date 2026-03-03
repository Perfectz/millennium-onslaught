# TechniqueDef Schema

> Defines a character technique (special move). Techniques cost TP, deal elemental damage, and can apply status effects.

**Class:** `TechniqueDef` (extends `Resource`)
**Source:** `resources/techniques/technique_def.gd`
**Location:** `resources/techniques/*.tres`

---

## Fields

| Field | Type | Default | Constraints | Description |
|-------|------|---------|-------------|-------------|
| `technique_id` | `StringName` | `&""` | Unique per technique | Identifier for events and logging |
| `display_name` | `String` | `""` | — | Name shown in UI and HUD |
| `description` | `String` | `""` | — | Description for menus |
| `tp_cost` | `float` | `25.0` | > 0 | TP consumed on use |
| `base_damage` | `float` | `20.0` | >= 0 | Damage before stat scaling |
| `element_type` | `StringName` | `&""` | `fire`, `ice`, `lightning`, `dark`, or `""` | Elemental affinity. Empty = neutral |
| `status_effect_chance` | `float` | `0.3` | 0.0–1.0 | Probability of applying element's status effect |
| `status_effect_duration` | `float` | `3.0` | >= 0 | Status effect duration in seconds |
| `knockback_force` | `float` | `10.0` | >= 0 | Knockback impulse on hit |
| `is_projectile` | `bool` | `true` | — | Whether technique spawns a projectile |
| `projectile_speed` | `float` | `18.0` | > 0 (if is_projectile) | Projectile travel speed |
| `aoe_radius` | `float` | `0.0` | >= 0 | Area of effect. 0 = single target |
| `animation_name` | `StringName` | `&"attack_heavy"` | Valid animation name | Animation played during technique |
| `particle_color` | `Color` | `(0.3, 0.85, 1.0)` | — | VFX particle color |
| `unlock_level` | `int` | `1` | >= 1 | Character level required to learn |
| `scales_with_magic` | `bool` | `true` | — | true = magic scaling, false = strength scaling |

---

## Element → Status Effect Mapping

| Element | Status Effect | Gameplay Effect |
|---------|--------------|-----------------|
| `fire` | Burn | DOT (damage over time) |
| `ice` | Freeze | Speed reduction |
| `lightning` | Shock | (Reserved for future) |
| `dark` | Bleed | Increased damage taken |

Status effect application: on hit, rolls `status_effect_chance`. If successful, applies the element's status effect for `status_effect_duration` seconds. Uses `ElementCalculator.get_status_effect()` for mapping.

---

## Example: vortex.tres

```tres
technique_id = &"vortex"
display_name = "Vortex"
description = "A spinning fire slash that burns enemies."
tp_cost = 25.0
base_damage = 22.0
element_type = &"fire"
status_effect_chance = 0.4
status_effect_duration = 3.0
knockback_force = 10.0
is_projectile = true
projectile_speed = 18.0
aoe_radius = 0.0
animation_name = &"attack_heavy"
particle_color = Color(1.0, 0.5, 0.2)
unlock_level = 1
scales_with_magic = false
```

---

## Usage

- `player_state_technique.gd` reads the active TechniqueDef from `PlayerController.get_active_technique()`.
- Builds an `AttackDef` from technique fields (base_damage, knockback_force, element_type, status_effect_chance).
- `PlayerController.cycle_technique()` rotates through learned techniques (Tab/Y input).
- `DamageCalculator.calculate_full()` uses magic or strength scaling based on `scales_with_magic`.
- `CombatSystem.apply_status_if_applicable()` rolls status effect chance on hit.

## Current Data Files

| File | ID | Element | TP Cost | Damage | Character |
|------|----|---------|---------|--------|-----------|
| `vortex.tres` | vortex | fire | 25 | 22 | Alys |
| `shadow_blade.tres` | shadow_blade | dark | 30 | 25 | Alys |
| `rayblade.tres` | rayblade | lightning | 25 | 20 | Chaz |
| `astral.tres` | astral | ice | 30 | 24 | Chaz |
| `flaeli.tres` | flaeli | fire | 35 | 28 | Rune (AoE) |
| `hewn.tres` | hewn | ice | 25 | 22 | Rune |
| `tandle.tres` | tandle | lightning | 30 | 26 | Rune |
| `burst_rocket.tres` | burst_rocket | fire | 20 | 18 | Wren |
| `spark.tres` | spark | lightning | 25 | 20 | Wren |
