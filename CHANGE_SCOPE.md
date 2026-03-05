# Change Scope Map — Millennium Onslaught

> **Purpose:** Maps feature areas to their affected files/systems. AI agents and developers use this to scope changes and prevent unintended side effects.

**Last Updated:** 2026-03-05

---

## How to Use

Before making changes:
1. Identify which feature area(s) your change affects
2. Look up the affected files below
3. Only modify files within those scopes
4. If your change touches files outside the listed scope, document why in the commit message

---

## Feature Area → File Scope

### Core / State Machine
```
scripts/core/state_machine.gd
scripts/core/state.gd
tests/unit/test_state_machine.gd
```

### Event System
```
autoloads/event_bus.gd
scripts/core/event_contracts.gd
tests/unit/test_event_contracts.gd
docs/events/event_catalog.md
```

### Input System
```
autoloads/input_manager.gd
scripts/core/input_action_set.gd
tests/unit/test_input_manager.gd
```

### Combat / Damage
```
scripts/systems/combat_system.gd
scripts/systems/combat_service.gd
scripts/systems/damage_flow.gd
scripts/components/health_component.gd
scripts/components/hitbox_component.gd
scripts/components/hurtbox_component.gd
scripts/components/combo_tracker.gd
autoloads/constants.gd (combat section only)
tests/unit/test_health_component.gd
tests/unit/test_combo_tracker.gd
tests/unit/test_combat_service.gd
tests/unit/test_damage_formulas.gd
```

### Enemy AI
```
scripts/ai/enemy_ai_base.gd
scripts/ai/rusher_ai.gd
autoloads/constants.gd (enemy AI section only)
```

### Dungeon / Stage
```
scripts/dungeon/stage_runner.gd
scripts/dungeon/dungeon_manager.gd
scripts/systems/wave_system.gd
scripts/systems/encounter_service.gd
scripts/systems/spawn_service.gd
tests/unit/test_encounter_service.gd
tests/unit/test_spawn_service.gd
tests/integration/test_dungeon_flow.gd
```

### Camera
```
scripts/systems/camera_follow.gd
autoloads/constants.gd (camera section only)
```

### VFX
```
scripts/systems/vfx_system.gd
scripts/ui/damage_number.gd
autoloads/constants.gd (VFX section only)
```

### UI / HUD
```
scripts/ui/hud.gd
scripts/ui/damage_number.gd
scenes/ui/
```

### Movement / Physics
```
scripts/components/movement_component.gd
autoloads/constants.gd (movement, dodge, physics sections)
```

### Save / Load
```
autoloads/save_manager.gd
autoloads/game_state.gd
scripts/utils/save_migration.gd
tests/unit/test_save_manager.gd
tests/unit/test_save_migration.gd
tests/unit/test_game_state.gd
```

### Resource Validation
```
scripts/utils/resource_validator.gd
tests/unit/test_resource_validator.gd
docs/schemas/
```

### Performance Tooling
```
scripts/utils/frame_budget_monitor.gd
scripts/utils/allocation_tracker.gd
tools/stress_test.gd
docs/performance_baseline.md
autoloads/constants.gd (performance, frame budget sections)
```

### Build / CI
```
.github/workflows/ci.yml
.github/workflows/build.yml
tools/export_all.sh
tools/smoke_test.sh
docs/release_process.md
```

### Game State / RPG
```
autoloads/game_state.gd
autoloads/constants.gd (RPG section)
tests/unit/test_game_state.gd
```

### Audio
```
autoloads/audio_manager.gd
```

### Object Pool
```
autoloads/object_pool.gd
```

### Accessibility
```
scripts/systems/accessibility_manager.gd
tests/unit/test_accessibility.gd
```

### Localization
```
scripts/systems/localization_manager.gd
resources/localization/
tests/unit/test_localization.gd
```

### Analytics / Feature Flags
```
scripts/systems/analytics_service.gd
scripts/systems/remote_config.gd
scripts/systems/feature_flags.gd
tests/unit/test_feature_flags.gd
tests/unit/test_analytics.gd
```

---

## Cross-Cutting Concerns

These files may be affected by changes in ANY feature area:
- `INDEX.md` — System index updates
- `DECISIONS.md` — Architectural decision logging
- `ROADMAP_EXECUTION_STATE.md` — Progress tracking
- `docs/events/event_catalog.md` — New signals
- `autoloads/constants.gd` — New tunable values
