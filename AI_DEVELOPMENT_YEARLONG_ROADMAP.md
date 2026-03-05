# AI Development Year-Long Roadmap — Millennium Onslaught

> **Purpose:** 12-month infrastructure and quality roadmap layered on top of the MVP game development plan. Each month adds engineering discipline, tooling, and architectural hardening to support sustainable development.

**Created:** 2026-03-01
**Last Updated:** 2026-03-05

---

## Month 1 — Baseline Audit & Stabilization (COMPLETE)

**Goal:** Establish the quality baseline. Audit existing code, fix critical bugs, create tracking infrastructure.

### Deliverables:
- [x] Baseline audit of MVP 0 scaffold (115 issues: 12 P0, 36 P1, 67 P2)
- [x] Fix all P0 issues (StateMachine null guard, WaveSystem ownership, CameraFollow validity, ObjectPool constants, HazardZone cached AttackDef, title screen button, level-up elif, touch opacity, spawn padding)
- [x] Create ROADMAP_EXECUTION_STATE.md
- [x] Create CONVENTIONS.md
- [x] Create CI pipeline (.github/workflows/ci.yml)
- [x] Create smoke test (tools/smoke_test.sh)
- [x] Create audit report (docs/audits/month1_baseline_audit.md)
- [x] Establish known-issue freeze list (14 items in INDEX.md)

---

## Month 2 — Typed Event Contracts & InputManager Extraction

**Goal:** Replace loose signal parameters with typed payload contracts. Extract InputManager action mappings into data-driven action sets.

### Deliverables:
- [ ] `scripts/core/event_contracts.gd` — Typed RefCounted classes for all event payloads (HitEvent, KillEvent, SpawnEvent, DamageEvent, PhaseChangeEvent, etc.)
- [ ] Refactor EventBus signals to accept typed contract objects
- [ ] `scripts/core/input_action_set.gd` — Data-driven action set definitions per InputContext
- [ ] `tests/unit/test_event_contracts.gd` — Contract validation: required fields present, correct types
- [ ] `tests/unit/test_input_manager.gd` — Context switching, device assignment, action set loading
- [ ] Update event_catalog.md with contract types
- [ ] DECISIONS.md entry: "Why typed event contracts"

### Acceptance Criteria:
- All event emissions use typed contract objects
- Contract tests catch missing required fields
- InputManager loads action definitions from data, not hardcoded mappings

---

## Month 3 — Service Layer Architecture

**Goal:** Extract game logic into stateless service classes. Establish clean separation between scene-tree-dependent code and pure logic.

### Deliverables:
- [ ] `scripts/systems/combat_service.gd` — Stateless damage calculation (base damage, stat modifiers, crit, element, defense)
- [ ] `scripts/systems/encounter_service.gd` — Generate encounters from definitions (enemy types, counts, positions)
- [ ] `scripts/systems/spawn_service.gd` — Request enemy spawn from ObjectPool with position validation
- [ ] `scripts/systems/damage_flow.gd` — Pipeline orchestrator: hit detection → calc → apply → VFX → audio → HUD
- [ ] `tests/unit/test_combat_service.gd` — Damage formula coverage (all modifier combinations)
- [ ] `tests/unit/test_encounter_service.gd` — Encounter generation validity
- [ ] `tests/unit/test_spawn_service.gd` — Spawn position validation
- [ ] DECISIONS.md entry: "Service layer vs monolithic systems"

### Acceptance Criteria:
- All services are stateless (no member variables that persist between calls)
- All services testable without scene tree
- DamageFlow pipeline is event-driven end-to-end

---

## Month 4 — Resource Validation & Content Tools

**Goal:** Build validation tooling to catch data errors before runtime. Create balance simulation tools.

### Deliverables:
- [ ] `scripts/utils/resource_validator.gd` — Validate .tres files: required fields, value ranges, reference integrity
- [ ] `docs/schemas/character_def.md` — CharacterDef schema documentation
- [ ] `docs/schemas/enemy_def.md` — EnemyDef schema documentation
- [ ] `docs/schemas/attack_def.md` — AttackDef schema documentation
- [ ] `tools/editor_plugins/content_validator.gd` — Run validation on all resources from editor
- [ ] `tools/balance_calculator.gd` — Simulate N combat encounters, report stat distributions
- [ ] `tests/unit/test_resource_validator.gd` — Validator catches known-bad data

### Acceptance Criteria:
- Resource validator catches all missing required fields
- Balance calculator produces human-readable reports
- All existing resources pass validation

---

## Month 5 — Save System Hardening

**Goal:** Make saves robust against version changes and corruption.

### Deliverables:
- [ ] Add `save_version` field to SaveManager serialization
- [ ] `scripts/utils/save_migration.gd` — Version-aware migration pipeline (v1→v2→...→vN)
- [ ] Add CRC32 checksum to save files, verify on load
- [ ] `tests/unit/test_save_migration.gd` — Migration chain tests, corruption detection, round-trip integrity
- [ ] DECISIONS.md entry: "Save versioning strategy"

### Acceptance Criteria:
- Old saves migrate forward through version chain
- Corrupted saves detected and reported (not silently loaded)
- All save operations include checksum

---

## Month 6 — Test Harness Expansion

**Goal:** Reach comprehensive test coverage with parameterized tests and integration tests.

### Deliverables:
- [ ] `tests/helpers/test_utils.gd` — Parameterized test helpers for GdUnit4
- [ ] `tests/unit/test_damage_formulas.gd` — Parameterized: all element × all defense × crit/non-crit
- [ ] `tests/unit/test_encounter_generation.gd` — Parameterized: encounters across difficulty/seed ranges
- [ ] `tests/integration/test_dungeon_flow.gd` — Full dungeon lifecycle: enter → rooms → boss → exit
- [ ] Coverage tracking in ROADMAP_EXECUTION_STATE.md

### Acceptance Criteria:
- Damage formulas tested across 50+ parameter combinations
- Integration test exercises full dungeon flow
- Coverage map shows all testable systems covered

---

## Month 7 — Performance Infrastructure

**Goal:** Establish performance monitoring and profiling tools to enforce frame budgets.

### Deliverables:
- [ ] `scripts/utils/frame_budget_monitor.gd` — Per-system frame time tracking, budget warnings
- [ ] `scripts/utils/allocation_tracker.gd` — Detect per-frame Dictionary/Array allocations in debug
- [ ] `tools/stress_test.gd` — Spawn configurable enemy counts, measure FPS over N frames
- [ ] Performance constants in Constants: frame budgets, pool warm sizes
- [ ] `docs/performance_baseline.md` — Baseline metrics for PC and Android targets

### Acceptance Criteria:
- Frame budget monitor logs warnings when any system exceeds 4ms/frame
- Stress test produces reproducible metrics report
- No per-frame allocations in hot paths

---

## Month 8 — Build Matrix & Release Pipeline

**Goal:** Automated builds for all target platforms with versioned release artifacts.

### Deliverables:
- [ ] `.github/workflows/build.yml` — Build matrix: Linux, Windows, Android debug/release
- [ ] `tools/export_all.sh` — Local export script for all platforms
- [ ] Export presets configuration
- [ ] Version tagging convention added to CONVENTIONS.md
- [ ] `docs/release_process.md` — Step-by-step release checklist

### Acceptance Criteria:
- CI produces build artifacts for all platforms on tag push
- Export script runs locally without manual intervention
- Release process documented end-to-end

---

## Month 9 — AI Development Guardrails

**Goal:** Structured change request process to prevent scope creep and unintended side effects during AI-assisted development.

### Deliverables:
- [ ] `CHANGE_SCOPE.md` — Maps feature areas to affected files/systems
- [ ] `docs/change_request_format.md` — Template for AI change requests
- [ ] `tools/scope_check.sh` — Validate changed files against declared scope
- [ ] Update CLAUDE.md with change request workflow section

### Acceptance Criteria:
- Every feature area has a defined file scope
- Scope check catches out-of-scope modifications
- CLAUDE.md includes change request protocol

---

## Month 10 — Accessibility & Localization

**Goal:** First-class accessibility features and localization infrastructure.

### Deliverables:
- [ ] `scripts/systems/accessibility_manager.gd` — Colorblind filter, difficulty scaling, input assists
- [ ] `scripts/systems/localization_manager.gd` — String table loading, language switching
- [ ] `resources/localization/en.tres` — English string table
- [ ] `scripts/utils/replay_capture.gd` — Input recording/playback for bug reproduction
- [ ] `tests/unit/test_accessibility.gd` — Difficulty modifier application tests
- [ ] `tests/unit/test_localization.gd` — String lookup, missing key handling

### Acceptance Criteria:
- Colorblind mode modifiable at runtime
- All UI strings loaded from string table (no hardcoded user-facing text)
- Replay capture records and replays inputs frame-accurately

---

## Month 11 — Analytics & Feature Flags

**Goal:** Local analytics and feature flag system for controlled rollouts and A/B testing.

### Deliverables:
- [ ] `scripts/systems/analytics_service.gd` — Session stats collection (play time, deaths, kills, gold earned)
- [ ] `scripts/systems/remote_config.gd` — JSON config loader (local file, extensible to remote)
- [ ] `scripts/systems/feature_flags.gd` — Boolean/variant flags from config
- [ ] `tests/unit/test_feature_flags.gd` — Enable/disable, default values, config parsing
- [ ] `tests/unit/test_analytics.gd` — Event recording, session lifecycle

### Acceptance Criteria:
- Analytics records complete session data
- Feature flags gate code paths at runtime
- Config loads from local JSON with fallback defaults

---

## Month 12 — Content Lock & Ship Prep

**Goal:** Freeze content, validate completeness, prepare hotfix infrastructure.

### Deliverables:
- [ ] `docs/acceptance_matrix.md` — Per-MVP acceptance criteria pass/fail matrix
- [ ] `docs/hotfix_playbook.md` — Emergency fix process (triage, fix, test, release)
- [ ] Content validation pass (all .tres files pass resource validator)
- [ ] Final INDEX.md update with complete system listing
- [ ] Final ROADMAP_EXECUTION_STATE.md with all months marked complete
- [ ] Git tag: `v0.1-roadmap-complete`

### Acceptance Criteria:
- All acceptance criteria in matrix marked pass
- Hotfix playbook covers 5+ common failure scenarios
- All resources pass validation
- INDEX.md covers every system in the project
