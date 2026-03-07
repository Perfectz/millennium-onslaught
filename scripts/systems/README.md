# scripts/systems/

## Purpose
Game systems that orchestrate gameplay mechanics. Systems connect to EventBus for cross-system communication and operate on entities/components.

## Systems

| System | File | Purpose |
|--------|------|---------|
| CombatSystem | `combat_system.gd` | Applies hit results, emits combat events |
| CameraFollow | `camera_follow.gd` | Follow camera with arena lock/unlock, multi-sample wall-occlusion avoidance, and action-driven photo mode |
| CameraShakeSystem | `camera_shake_system.gd` | Camera shake feedback on hits |
| HitstopSystem | `hitstop_system.gd` | Time-scale freeze on hit (Engine.time_scale) |
| VFXSystem | `vfx_system.gd` | Hit/kill particle spawning via ObjectPool |
| SpawnPositionResolver | `spawn_position_resolver.gd` | Shared spawn clearance helper for players and enemies |
| EnemyProjectile | `enemy_projectile.gd` | Enemy projectile movement and collision |
| PlayerProjectile | `player_projectile.gd` | Player technique projectile behavior |
| EncounterRoller | `encounter_roller.gd` | Pure logic — randomized wave selection from pools |
| WaveSystem | `wave_system.gd` | Spawns enemy waves from EncounterDef, tracks alive count, and self-recovers stuck encounter state |

## Conventions
- Systems communicate via EventBus signals, not direct references
- Systems that need scene presence are Nodes attached to room/dungeon scenes
- Pure logic systems (EncounterRoller) are RefCounted and fully unit-testable
- Tunable values come from Constants, attack data comes from AttackDef resources
