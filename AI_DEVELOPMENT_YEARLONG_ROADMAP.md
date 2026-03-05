# AI-Optimized Year-Long Development Roadmap (12 Months)

**Scope:** Millennium Onslaught (Godot 4)  
**Goal:** Build a production-ready game architecture that is reliable for shipping and fast to update with AI agents (Claude Code / GPT 5.3) when user requests change.

## How to use this list

1. Execute in order.  
2. Each month has clear entry dependencies from the previous month.  
3. Every month ends with a green gate before moving on.  
4. Every functional change must update docs and tests (or include explicit test gaps).  
5. Treat this as a living backlog; if risk changes, reorder within a month only when needed.

## Month 1 — Foundation hardening and safety for AI work

**Objective:** Make the codebase boringly deterministic and safe to modify.

1. Baseline audit pass with severity tags (P0/P1/P2) for existing script/runtime issues.
2. Add a repo-level architecture map (new `ROADMAP_EXECUTION_STATE.md`) that tracks monthly milestones and completion evidence.
3. Standardize code conventions from existing files into one enforced guide:
   - naming, file layout, script header docs, signal naming, signal payload names
4. Add/standardize runtime guards in hot paths:
   - object pool return sanity checks
   - nil checks for autoload/service access
   - defensive scene-node type checks before casts
5. Fix camera shake stack corruption risk (single additive trauma source only).
6. Fix encounter progress deadlock (waves that can generate zero enemies).
7. Centralize attack payload format (single AttackEvent/AttackData type) and replace ad-hoc dictionaries where possible.
8. Add automated smoke test runner script and a one-command project sanity check.
9. Add CI baseline job:
   - parse-only project load check
   - headless test execution
10. Add a “known-issue freeze” list in DECISIONS/INDEX so no unresolved risk is silently buried.
11. Create a strict month-end review with reproducible bug list and evidence logs.

**Exit gate:** No critical runtime deadlocks, no duplicate camera shake, CI smoke test passes.

## Month 2 — API contracts and typed event-first communication

**Objective:** Replace fuzzy coupling with stable contracts so AI changes do not ripple unpredictably.

1. Design and document canonical event contracts (payload schema + emitter/listener ownership) for EventBus.
2. Convert all EventBus payloads from anonymous dictionaries to typed objects/resources where feasible.
3. Add schema version tags to event payloads for backward compatibility.
4. Add event catalog as a source-of-truth page and enforce it through lint/check step.
5. Introduce a small “Contract Test” suite:
   - emit/listen compatibility checks
   - required fields checks
6. Extract all controller/scene direct `Input` calls into InputManager command APIs.
7. Introduce a minimal InputIntent abstraction (`intent -> action -> effect`) used by all gameplay systems.
8. Add debug tooling to print unmatched events at runtime.
9. Add “no unknown signal names” runtime assertion in development builds.
10. Add docs update automation checks for new/changed events and resources.

**Exit gate:** New event can be added without touching two unrelated systems; event contracts pass tests.

## Month 3 — Domain/service decomposition for AI ergonomics

**Objective:** Separate orchestration from rules, physics, and effects.

1. Split high-complexity scripts into:
   - Domain services (pure rules, deterministic outputs)
   - Scene orchestrators (node wiring only)
2. Move attack resolution into a shared CombatService:
   - damage resolution
   - hitstop/damage numbers trigger policy
   - knockback and status handling
3. Move encounter/wave selection into EncounterService with deterministic seed support.
4. Move object lifecycle to SpawnService:
   - instantiate/activate/deactivate policy
   - object pool telemetry
5. Introduce a `DamageFlow` service pipeline:
   - validate
   - calculate
   - clamp
   - apply
   - feedback
6. Add unit tests for each service boundary and contract tests for invalid payloads.
7. Create integration tests for end-to-end combat event chain (hit -> feedback -> state updates).
8. Add service-level profiling markers (`CombatService`, `EncounterService`, `SpawnService`).
9. Update folder READMEs for service ownership and ownership boundaries.
10. Add feature toggles for enabling/disabling optional gameplay services while iterating.

**Exit gate:** Game logic can be understood and changed in service modules with minimal scene edits.

## Month 4 — Data layer, content pipeline, and modifiable behavior

**Objective:** Make behavior content-editable and reduce code edits for balance/content changes.

1. Complete typed resource schemas for every gameplay domain file already in use.
2. Add validator pass for `.tres` resources at load time:
   - required keys
   - range validation
   - soft warnings for deprecated keys
3. Add migration scripts for resource schema changes.
4. Add live-content preview command for loading resources and outputting derived stats.
5. Centralize all gameplay tunables in resource-driven config profiles:
 - combat tuning, AI tuning, encounter tuning
6. Introduce content packs:
   - dev pack
   - staging pack
   - release pack
7. Add automated content lint:
   - empty pools
   - unreachable encounter states
   - duplicate identifiers
8. Add a deterministic simulation tool for enemy/encounter balance preview.
9. Add balance test fixtures for typical run seeds (first 100 waves).
10. Add changelog format linking content changes to resource file diffs.

**Exit gate:** Designers can rebalance attacks and encounters without touching script logic.

## Month 5 — Save/load hardening and progression reliability

**Objective:** Ensure player progress is durable and robust across updates.

1. Add strict schema versioning to save format with migration table.
2. Implement safe deserialize with strict validation and rollback behavior.
3. Add crash-safe write with checksum/transaction log.
4. Add save compatibility tests for all major milestones (new installs, old saves, corrupt saves).
5. Add telemetry event for save failures and recovery path.
6. Add automated backup cleanup and retention policy (last N saves + one golden backup).
7. Introduce “playtest reset” and “safe recovery” modes in debug builds.
8. Add per-player data integrity checks and deterministic audit IDs.
9. Add analytics for gold/xp/lv progression monotonicity anomalies.
10. Document save migration path in DECISIONS + INDEX with example migration recipes.

**Exit gate:** Corrupt or old saves recover gracefully without blocking progression.

## Month 6 — Testing architecture expansion and AI verification

**Objective:** Make tests fast to author and easy to run for every AI patch.

1. Add test harness for scene-agnostic gameplay flows (unit + integration tiers).
2. Add fake scene/event adapters for services to run in command-line tests.
3. Add parameterized tests for critical combat branches and edge cases.
4. Add mutation-style negative tests for malformed event payloads and invalid state transitions.
5. Add per-module test coverage targets and thresholds.
6. Add test scaffolding templates in repo for quick AI-generated tests.
7. Add bug repro templates (repro steps + expected state + fixture seed).
8. Add performance regression tests for per-frame allocations in critical loops.
9. Add automatic test report publishing with pass/fail trend.
10. Update CI to fail on dropped coverage and on new TODOs in critical modules.

**Exit gate:** New feature can be added with 3 test files: unit, service, and integration.

## Month 7 — Gameplay loop optimization and performance budget discipline

**Objective:** Hit shipping performance targets consistently on PC/Android.

1. Establish frame budgets per subsystem (combat, dungeon, UI, VFX).
2. Add periodic allocation snapshots and report spikes.
3. Introduce node/object lifecycle accounting:
   - spawn count
   - pool hit/miss
   - object aging
4. Add CPU/GPU hotspots pass in dungeon loops and combat events.
5. Convert remaining per-frame allocations to cached structures.
6. Profile and optimize input/event throughput under 4-player concurrency.
7. Add low-memory mode toggles for Android profile tests.
8. Add content streaming checks for stage/chunk systems.
9. Add automated 30-minute stress run with memory growth assertion.
10. Create performance scorecard document updated monthly.

**Exit gate:** 60 FPS desktop / 30 FPS Android sustained in representative builds.

## Month 8 — Cross-platform build and release engineering

**Objective:** Reduce release risk and make patch deployment routine.

1. Standardize build matrix:
   - Windows debug/release
   - Android debug/release
2. Add reproducible export scripts with pinned version settings.
3. Add asset checksum verification step in release pipeline.
4. Add automated packaging and artifact naming with version tags.
5. Add staged environments (local -> staging -> release).
6. Implement changelog automation from commit message parsing + feature tags.
7. Add release smoke checklist:
   - save migration
   - settings persistence
   - input remap persistence
8. Add rollback strategy for bad releases with one-command revert.
9. Add post-build validation script (launch check, scene load check, startup telemetry).
10. Document release owner process and emergency fix process.

**Exit gate:** A broken release can be safely replaced in one controlled rollback step.

## Month 9 — AI update workflow and prompt-to-change protocol

**Objective:** Optimize for frequent user-driven changes via AI coding agents.

1. Create a machine-readable change request format (`.md` or JSON ticket template).
2. Add a change triage pipeline:
   - request -> impact map -> estimated touchpoints -> implementation steps
3. Create a `CHANGE_SCOPE` map for each core system:
   - safe files
   - forbidden boundaries
   - test expectations
4. Add an AI-friendly code map index with:
   - entry point per subsystem
   - “do not touch” notes
   - example call chains
5. Add semantic search index files for common refactor targets.
6. Add generated prompts for common tasks:
   - balance pass
   - bug fix from repro
   - new attack data creation
7. Add patch-size policy (small, reversible, validated).
8. Add auto-generated summary reports after AI edits:
   - changed symbols
   - tests run
   - docs updated
9. Add guardrails for AI changes (disallow broad search/replace in autoload/singletons).
10. Run a simulation: five end-user change requests implemented in batch and verify end-to-end.

**Exit gate:** 80%+ of user requests can be scoped and implemented without manual architecture discussion.

## Month 10 — Player experience consistency, accessibility, and user trust

**Objective:** Ship a game that feels polished and trustworthy for retail users.

1. Improve tutorial/onboarding for first-run and new feature introduction.
2. Add accessibility profile presets:
   - high contrast
   - reduced motion
   - color-blind filters
3. Add input latency feedback and calibration utilities.
4. Add localization-ready string tables and text extraction pipeline.
5. Add in-game support for controller remap reset and conflict detection.
6. Add help overlay keyed to current phase (overworld/town/dungeon/ui).
7. Add clear error messaging for save/load failures.
8. Add deterministic replay capture for bug and support cases.
9. Add user-facing privacy-safe bug-reporting template with diagnostic bundle creation.
10. Add support contact path and issue tagging by system.

**Exit gate:** Support reports include reproducible diagnostic bundle and are easy for players to trigger.

## Month 11 — Monetization readiness, analytics, and live ops hooks

**Objective:** Prepare for sustainable commercial operations and fast updates.

1. Add analytics schema for:
   - retention cohorts
   - crash sources
   - feature adoption
2. Add in-game event funnels (dungeon start->clear, shop conversion, upgrade usage).
3. Add server-safe offline-safe analytics buffer for mobile/network-limited sessions.
4. Add remote config for balanced variables (drop rates, enemy multipliers, VFX toggles).
5. Add feature flags for staged rollouts and A/B testing.
6. Add anti-cheat sanity checks for suspicious progression jumps.
7. Add user session/session-loss recovery path.
8. Add release health dashboard inputs (crash rate, perf regressions, top events).
9. Add retention-focused retention metrics and weekly tuning windows.
10. Add legal/privacy checklist (third-party libs, ad/data collection docs, policy alignment).

**Exit gate:** Every update can change tuning through approved config channels without code edits.

## Month 12 — Pre-launch stabilization and commercial hardening

**Objective:** Finalize a shippable baseline and make patching predictable.

1. Full content lock review and content diff audit for balancing integrity.
2. Execute full gameplay acceptance matrix across PC + Android.
3. Run crash, save, and performance stress sweeps at maximum content density.
4. Finalize long-tail onboarding and docs quality pass.
5. Perform architecture freeze review against roadmap objectives:
   - AI-editability
   - reliability
   - update velocity
6. Add ship-mode feature flags and remove non-essential debug paths.
7. Create post-launch hotfix playbook (severity ladder + response SLAs).
8. Finalize support queue workflow and triage labels:
   - crash
   - balance
   - UX
   - content request
9. Add customer feedback ingestion flow:
   - import -> reproduce -> backlog -> release note
10. Capture final baseline metrics and set Year-2 roadmap draft based on gaps.

**Exit gate:** Release build is support-ready and architecture can support weekly AI-driven updates.

---

## Delivery rhythm (every month)

1. Week 1: Plan and dependency mapping.
2. Week 2: Core implementation.
3. Week 3: Hardening, tests, docs.
4. Week 4: Validation and next-month plan adjustment.

## Ongoing risk controls (year-round)

- Keep a technical debt lane with limits: max 1 high-risk debt item per sprint.
- Never merge large refactors without contract tests and a rollback plan.
- Every subsystem change must include:
  - functional description
  - affected tests
  - updated docs references
- Require two evidence artifacts before major merge:
  - passing tests
  - one gameplay smoke video or log bundle.
