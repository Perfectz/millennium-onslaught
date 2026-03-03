# scripts/ai/enemy_states/

## Purpose
Enemy state machine states. Each file implements one state for `EnemyController`'s `StateMachine`. Behaviors vary by `EnemyDef.behavior` type — not all states are used by all enemy types.

## States

| State | File | Used By | Notes |
|-------|------|---------|-------|
| Idle | `enemy_state_idle.gd` | All | Perception delay before chasing |
| Chase | `enemy_state_chase.gd` | All | Approach player; branches by behavior type |
| Attack | `enemy_state_attack.gd` | rusher, shield, boss | 3-phase: windup → active → recovery |
| Hurt | `enemy_state_hurt.gd` | All | Knockback, juggle-aware |
| Dead | `enemy_state_dead.gd` | All | Shrink animation, cleanup |
| Retreat | `enemy_state_retreat.gd` | ranged | Back away when player is close |
| Shoot | `enemy_state_shoot.gd` | ranged | Fire projectile |
| Block | `enemy_state_block.gd` | shield | Slow advance while blocking |
| Stagger | `enemy_state_stagger.gd` | shield | Guard-broken vulnerability window |
| BossPhaseCheck | `enemy_state_boss_phase_check.gd` | boss | Phase transition at 50% HP |

## Adding a New Enemy State
1. Create `enemy_state_*.gd` extending `State` (RefCounted)
2. Implement `enter()`, `physics_update()`, and optionally `exit()`
3. Register in `EnemyController._ready()` via `state_machine.add_state()`
4. Wire transitions in relevant states
5. Update INDEX.md Enemy States table
