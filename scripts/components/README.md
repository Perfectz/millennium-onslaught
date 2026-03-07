# scripts/components/

## Purpose
Pure logic components with no scene tree dependency. All are `RefCounted` and fully unit-testable without Godot's runtime. Components are owned by controllers (PlayerController, EnemyController) and their signals are bridged to EventBus by the owning controller.

## Components

| Component | File | Tests | Purpose |
|-----------|------|-------|---------|
| HealthComponent | `health_component.gd` | 17 | HP tracking, damage, healing, death signal |
| ComboTracker | `combo_tracker.gd` | 11 | Combo step tracking with input window timer |
| DamageCalculator | `damage_calculator.gd` | 7 | Damage formula evaluation |
| ComboCancelChecker | `combo_cancel_checker.gd` | 10 | Cancel window timing and type validation |
| JuggleTracker | `juggle_tracker.gd` | 15 | Airborne hit counter with limit enforcement |
| ScoreTracker | `score_tracker.gd` | 14 | Kill/time/combo/damage tracking plus score formula |
| TPTracker | `tp_tracker.gd` | 14 | Technique points pool: regen, spend, gain |
| InputIntentBuffer | `input_intent_buffer.gd` | 21 | Unified action input buffer that survives hitstop |
| RuntimeBoundsPolicy | `runtime_bounds_policy.gd` | 4 | Pure active-bounds clamp, pushback, and edge-knockback policy |
| PlayerLockOnPolicy | `player_lock_on_policy.gd` | 4 | Lock-on candidate filtering, nearest-target selection, and cycle-target selection |
| PlayerProfilePolicy | `player_profile_policy.gd` | 4 | Character selection, restore snapshots, runtime sync payloads, and level-up growth records |
| PlayerStatsPolicy | `player_stats_policy.gd` | 4 | Base stat resolution, derived stat composition, and HP scaling helpers |
| PlayerHitPolicy | `player_hit_policy.gd` | 4 | Parry/block hit resolution, damage context, and knockback helpers |

## Conventions
- All components extend `RefCounted` (not Node)
- Components emit their own signals; controllers bridge them to EventBus
- Every component has a matching test suite in `tests/unit/components/`
- No autoload or scene tree references allowed; keep them testable in isolation
- New components follow TDD: write test first, then implement
