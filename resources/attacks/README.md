# resources/attacks/

## Purpose
AttackDef `.tres` data files defining individual attacks and combo steps. Used by both player and enemy attack states.

## Schema
See [docs/schemas/attack_def.md](../../docs/schemas/attack_def.md) for full field definitions.

## Current Files

| File | Name | User | Damage | Launcher |
|------|------|------|--------|----------|
| `light_attack_1.tres` | light_1 | Player | 10 | No |
| `light_attack_2.tres` | light_2 | Player | 10 | No |
| `light_attack_3.tres` | light_3 | Player | 15 | No |
| `heavy_attack.tres` | heavy | Player | 25 | No |
| `launcher_attack.tres` | launcher | Player | 12 | Yes |
| `projectile_attack.tres` | projectile | Player | 20 | No |
| `enemy_rusher_attack.tres` | rusher_swing | Rusher | 8 | No |
| `enemy_ranged_attack.tres` | ranged_shot | Ranger | 8 | No |
| `enemy_shield_attack.tres` | shield_bash | Guardian | 10 | No |
| `boss_attack_1.tres` | boss_slam | Boss (Phase 1) | 20 | No |
| `boss_attack_2.tres` | boss_slam_enraged | Boss (Phase 2) | 26 | No |

## Adding a New Attack
1. Duplicate an existing `.tres` file in Godot inspector or text editor
2. Set `attack_name` to something unique
3. Tune damage, timing, knockback, and cancel window fields
4. Reference from a player state or `EnemyDef.attack`
