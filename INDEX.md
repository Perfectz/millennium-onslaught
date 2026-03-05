# INDEX.md — Millennium Onslaught — Master System Index

> **Purpose:** AI reads this first after the project plan. Lists every system by name, file location, one-line purpose, and dependencies. Updated at every MVP.

**Current MVP:** 0 — Scaffold (with Month 1-12 infrastructure complete)
**Last Updated:** 2026-03-05

---

## Autoloads (Singletons)

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| Constants | `autoloads/constants.gd` | Centralized tunable values for all gameplay numbers | None |
| EventBus | `autoloads/event_bus.gd` | Global signal hub for cross-system communication | None |
| GameState | `autoloads/game_state.gd` | Single source of truth for persistent and transient game data | Constants |
| GameManager | `autoloads/game_manager.gd` | Game phase transitions and scene lifecycle orchestration | EventBus, GameState |
| ObjectPool | `autoloads/object_pool.gd` | Pre-instantiation pool for frequently spawned objects | None |
| AudioManager | `autoloads/audio_manager.gd` | SFX pool and music player with crossfade | EventBus |
| SaveManager | `autoloads/save_manager.gd` | Atomic file-based save/load with versioning and checksums | EventBus, GameState, SaveMigration |
| InputManager | `autoloads/input_manager.gd` | Device-to-player mapping and input context switching | EventBus |

## Core Scripts

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| StateMachine | `scripts/core/state_machine.gd` | Generic FSM with enter/exit/process pattern | State, Constants |
| State | `scripts/core/state.gd` | Base state class for state machine | None |
| EventContracts | `scripts/core/event_contracts.gd` | Typed payload classes for EventBus signals | None |
| InputActionSet | `scripts/core/input_action_set.gd` | Data-driven action set definitions per context | None |

## Components

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| HealthComponent | `scripts/components/health_component.gd` | HP management, damage, healing, death detection | None |
| HitboxComponent | `scripts/components/hitbox_component.gd` | Attack collision area with Z-tolerance | HurtboxComponent, Constants |
| HurtboxComponent | `scripts/components/hurtbox_component.gd` | Damage receiving area with invincibility | HealthComponent |
| ComboTracker | `scripts/components/combo_tracker.gd` | Combo step tracking, input windows, drops | Constants |
| MovementComponent | `scripts/components/movement_component.gd` | Belt-scroller movement with gravity and jump | Constants |

## Systems

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| CombatSystem | `scripts/systems/combat_system.gd` | Hit registration, hitstop, event emission | EventBus, Constants |
| CombatService | `scripts/systems/combat_service.gd` | Stateless damage calculation (pure logic) | Constants |
| EncounterService | `scripts/systems/encounter_service.gd` | Encounter generation from definitions | None |
| SpawnService | `scripts/systems/spawn_service.gd` | Enemy spawning via ObjectPool | ObjectPool, EventBus |
| DamageFlow | `scripts/systems/damage_flow.gd` | Full damage pipeline orchestrator | CombatService, EventBus, EventContracts |
| CameraFollow | `scripts/systems/camera_follow.gd` | Player follow with shake and arena lock | EventBus, Constants |
| WaveSystem | `scripts/systems/wave_system.gd` | Wave spawning, tracking, clear detection | EventBus |
| VFXSystem | `scripts/systems/vfx_system.gd` | Particle spawning on combat events | ObjectPool, EventBus |
| AccessibilityManager | `scripts/systems/accessibility_manager.gd` | Colorblind mode, difficulty, input assists | EventBus |
| LocalizationManager | `scripts/systems/localization_manager.gd` | String table loading and language switching | EventBus |
| AnalyticsService | `scripts/systems/analytics_service.gd` | Session stats collection | EventBus |
| RemoteConfig | `scripts/systems/remote_config.gd` | JSON config loader (local/remote) | None |
| FeatureFlags | `scripts/systems/feature_flags.gd` | Runtime feature flag system | RemoteConfig |

## AI

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| EnemyAIBase | `scripts/ai/enemy_ai_base.gd` | Base enemy AI with perception and tokens | Constants |
| RusherAI | `scripts/ai/rusher_ai.gd` | Simple melee rusher behavior | EnemyAIBase |

## Dungeon

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| StageRunner | `scripts/dungeon/stage_runner.gd` | Room sequencing, video background (layer -1) | EventBus, GameState |
| DungeonManager | `scripts/dungeon/dungeon_manager.gd` | Dungeon entry/exit, fail/complete flow | EventBus, GameState, GameManager |

## UI

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| HUD | `scripts/ui/hud.gd` | Health bar, TP bar, combo counter | EventBus |
| DamageNumber | `scripts/ui/damage_number.gd` | Floating pooled damage numbers | ObjectPool, Constants |

## Utilities

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| ResourceValidator | `scripts/utils/resource_validator.gd` | Validates .tres data against schemas | None |
| SaveMigration | `scripts/utils/save_migration.gd` | Save version migration and checksum | None |
| FrameBudgetMonitor | `scripts/utils/frame_budget_monitor.gd` | Per-system frame time tracking | None |
| AllocationTracker | `scripts/utils/allocation_tracker.gd` | Per-frame allocation detection | None |
| ReplayCapture | `scripts/utils/replay_capture.gd` | Input recording/playback | None |

## Tools

| Tool | File | Purpose |
|------|------|---------|
| BalanceCalculator | `tools/balance_calculator.gd` | Combat balance simulation | CombatService |
| StressTest | `tools/stress_test.gd` | FPS measurement under load |
| SmokeTest | `tools/smoke_test.sh` | Project structure verification |
| ExportAll | `tools/export_all.sh` | Multi-platform export script |
| ScopeCheck | `tools/scope_check.sh` | Changed files vs scope validation |

## Tests

| Test | File | Covers |
|------|------|--------|
| test_health_component | `tests/unit/test_health_component.gd` | HealthComponent |
| test_combo_tracker | `tests/unit/test_combo_tracker.gd` | ComboTracker |
| test_state_machine | `tests/unit/test_state_machine.gd` | StateMachine |
| test_game_state | `tests/unit/test_game_state.gd` | GameState |
| test_save_manager | `tests/unit/test_save_manager.gd` | SaveManager |
| test_save_migration | `tests/unit/test_save_migration.gd` | SaveMigration |
| test_event_contracts | `tests/unit/test_event_contracts.gd` | EventContracts |
| test_input_manager | `tests/unit/test_input_manager.gd` | InputManager, InputActionSet |
| test_combat_service | `tests/unit/test_combat_service.gd` | CombatService |
| test_encounter_service | `tests/unit/test_encounter_service.gd` | EncounterService |
| test_spawn_service | `tests/unit/test_spawn_service.gd` | SpawnService |
| test_damage_formulas | `tests/unit/test_damage_formulas.gd` | CombatService (parameterized) |
| test_resource_validator | `tests/unit/test_resource_validator.gd` | ResourceValidator |
| test_accessibility | `tests/unit/test_accessibility.gd` | AccessibilityManager |
| test_localization | `tests/unit/test_localization.gd` | LocalizationManager |
| test_feature_flags | `tests/unit/test_feature_flags.gd` | FeatureFlags, RemoteConfig |
| test_analytics | `tests/unit/test_analytics.gd` | AnalyticsService |
| test_dungeon_flow | `tests/integration/test_dungeon_flow.gd` | Full dungeon lifecycle |

## Documentation

| Document | File | Purpose |
|----------|------|---------|
| Project Plan | `PROJECT_PLAN_GODOT4_BELTSCROLLER.md` | Vision, MVPs, backlog |
| CLAUDE.md | `CLAUDE.md` | AI onboarding and project rules |
| CONVENTIONS.md | `CONVENTIONS.md` | Enforced code conventions |
| DECISIONS.md | `DECISIONS.md` | Architectural decision log |
| Yearlong Roadmap | `AI_DEVELOPMENT_YEARLONG_ROADMAP.md` | 12-month infrastructure plan |
| Execution State | `ROADMAP_EXECUTION_STATE.md` | Progress tracking |
| Change Scope | `CHANGE_SCOPE.md` | Feature area → file mapping |
| Event Catalog | `docs/events/event_catalog.md` | All EventBus signals |
| CharacterDef Schema | `docs/schemas/character_def.md` | Character definition schema |
| EnemyDef Schema | `docs/schemas/enemy_def.md` | Enemy definition schema |
| AttackDef Schema | `docs/schemas/attack_def.md` | Attack definition schema |
| Performance Baseline | `docs/performance_baseline.md` | FPS targets and baselines |
| Release Process | `docs/release_process.md` | Release checklist |
| Change Request Format | `docs/change_request_format.md` | AI change request template |
| Acceptance Matrix | `docs/acceptance_matrix.md` | Per-MVP criteria checklist |
| Hotfix Playbook | `docs/hotfix_playbook.md` | Emergency fix process |
| Month 1 Audit | `docs/audits/month1_baseline_audit.md` | Baseline audit results |

---

## Folder Map

```
res://
├── addons/           → Third-party addons (GdUnit4)
├── autoloads/        → 8 singleton services
├── scenes/           → Scene files (.tscn)
├── scripts/          → All game logic (.gd)
│   ├── core/         → StateMachine, State, EventContracts, InputActionSet
│   ├── components/   → Health, Hitbox, Hurtbox, Combo, Movement
│   ├── systems/      → Combat, Camera, Wave, VFX, Accessibility, Localization, Analytics, FeatureFlags
│   ├── ai/           → EnemyAIBase, RusherAI
│   ├── dungeon/      → StageRunner, DungeonManager
│   ├── overworld/    → (MVP 3)
│   ├── town/         → (MVP 3)
│   ├── ui/           → HUD, DamageNumber
│   └── utils/        → ResourceValidator, SaveMigration, FrameBudgetMonitor, AllocationTracker, ReplayCapture
├── resources/        → Custom Resource data files (.tres)
├── assets/           → Raw assets (models, textures, audio, fonts, shaders)
├── docs/             → AI-navigable documentation
│   ├── schemas/      → CharacterDef, EnemyDef, AttackDef schemas
│   ├── events/       → Event catalog
│   └── audits/       → Monthly audit reports
├── tools/            → BalanceCalculator, StressTest, SmokeTest, ExportAll, ScopeCheck
├── tests/            → GdUnit4 test files (18 test files)
│   ├── unit/         → Unit tests
│   ├── integration/  → Integration tests
│   └── helpers/      → Test utilities
└── export/           → Export configurations
```

---

## Known Issues (Freeze List)

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | Video background Z-ordering | FIXED | StageRunner uses CanvasLayer(layer=-1) |
| 2 | No player/enemy scenes yet | OPEN | Needs MVP 1 scene creation |
| 3 | InputMap actions not configured in project.godot | OPEN | InputActionSet can apply at runtime |
| 4 | ObjectPool not warmed at startup | OPEN | Needs scene-specific warm calls |
