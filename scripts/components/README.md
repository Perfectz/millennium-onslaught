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
| ScoreTracker | `score_tracker.gd` | 14 | Kill/time/combo/damage tracking + score formula |
| TPTracker | `tp_tracker.gd` | 14 | Technique points pool — regen, spend, gain |
| InputIntentBuffer | `input_intent_buffer.gd` | 21 | Unified action input buffer — survives hitstop, category-windowed |

## Conventions
- All components extend `RefCounted` (not Node)
- Components emit their own signals; controllers bridge them to EventBus
- Every component has a matching test suite in `tests/unit/components/`
- No autoload or scene tree references allowed — keeps them testable in isolation
- New components follow TDD: write test first, then implement
