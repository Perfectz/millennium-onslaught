# Year-Long Enhancement Spec

**Project:** Millennium Onslaught (Godot 4)  
**Planning baseline date:** 2026-03-07  
**Current repo snapshot:** `INDEX.md` reports MVP 6 "Together" in progress and roadmap Month 2 in progress.  
**Purpose:** Turn the current roadmap into a concrete 12-month enhancement spec that balances player-facing scope, runtime reliability, AI-editable architecture, and release readiness.

---

## 1. Current Baseline

As of 2026-03-07, the project already has a meaningful playable core:

- Real-time belt-scroller combat, player/enemy state machines, hitstop, camera shake, VFX, and boss flow.
- Overworld and town wrapper systems, save/load, shop/equipment/progression foundations, and a continuous stage pipeline.
- Typed combat contracts started, event catalog validation, CI sanity checks, and 449 automated test functions listed in `INDEX.md`.
- First production stage content for Piata/Academy is underway, with Android controls/settings/save hardening already in active development.

The biggest current gaps are not "can the game run?" gaps. They are "can the game scale cleanly?" gaps:

- Event and input contracts are only partially normalized.
- Some P0/P1 runtime risks from the baseline audit still need closure.
- Save/load, party runtime, and co-op assumptions are not fully hardened.
- Content authoring exists, but the pipeline is not yet safe enough for rapid AI-assisted expansion.
- The project does not yet have full Year-1 content breadth: additional dungeons, towns, bosses, roster depth, or release operations.

This roadmap assumes the codebase is moving from "strong prototype / early vertical slice" toward "content-rich beta that can credibly ship."

---

## 2. Year-End Target State

By the end of this 12-month roadmap, the project should reach all of the following:

- 4 production-quality continuous dungeons with distinct stage pacing, hazards, bosses, and encounter pools.
- 3 towns with differentiated shops, inn tuning, NPC dialogue sets, and clear story progression gates.
- 5-6 playable characters with distinct combo identity, techniques, and progression hooks.
- Stable couch co-op for up to 4 local players on PC.
- Android build that is playable through a full dungeon run at an acceptable performance floor.
- Hardened save/migration pipeline, release workflow, support diagnostics, and content validation tools.
- AI-friendly architecture where most content or balance requests can be implemented by changing resources, small services, or documented boundaries instead of broad scene rewrites.

This is not a "live service backend" plan. It is a Year-1 productization and content-completion plan.

---

## 3. Planning Rules

The roadmap is governed by these rules:

1. Every month must ship one player-visible improvement, one stability/tooling improvement, and one documentation update.
2. No month may close with unresolved P0 issues in active gameplay paths.
3. New content is blocked if the authoring pipeline for that content type is not validated.
4. Every new system boundary needs tests or an explicit note explaining why only play-verification is practical.
5. Architecture work must reduce future change cost; if it does not unlock content or stability, it is not worth the month.

---

## 4. Enhancement Lanes

| Lane | Purpose | Year-End Output |
|---|---|---|
| Runtime Reliability | Remove crash/desync risks and make game state deterministic | No known P0s in shipping paths, bounded P1 backlog |
| Contracts and AI Ergonomics | Make systems safer for AI edits and faster to scope | Typed event/data boundaries, change-scope docs, stable ownership |
| Player Systems | Deepen combat, party, progression, co-op, and accessibility | Polished combat loop plus durable progression and support features |
| Content Pipeline | Make stages, encounters, items, techniques, and towns fast to add safely | Resource validation, preview tools, content lint, reproducible authoring |
| Content Expansion | Build the actual game breadth | Multi-town, multi-dungeon, multi-boss playable campaign slice |
| Release and Ops | Reduce platform and launch risk | Export automation, smoke gates, rollback playbook, diagnostics |

---

## 5. Quarterly Outcomes

| Quarter | Focus | Outcome |
|---|---|---|
| Q1 (Months 1-3) | Stabilize contracts and hot-path runtime behavior | Safe base for rapid feature work |
| Q2 (Months 4-6) | Finish data pipeline and deepen progression/party systems | Systems can scale without brittle code edits |
| Q3 (Months 7-9) | Add major content breadth, co-op, and Android discipline | Broader game with real platform proof |
| Q4 (Months 10-12) | Complete content, support features, and release hardening | Beta-to-release candidate quality |

---

## 6. Month-by-Month Enhancement Spec

### Month 1 - Foundation Hardening and AI Safety

**Status:** COMPLETE  
**Primary goal:** Remove early deadlocks and establish a trustworthy execution/documentation baseline.

**Delivered focus:**

- Baseline audit with severity tags and visible known-issue tracking.
- CI sanity workflow and local smoke entrypoints.
- Core conventions and architecture tracking documents.
- Initial hardening on wave progression, state machine guards, and hot-path safety.

**Why it mattered:**

- It converted the repo from "playable but risky" to "inspectable and governable."
- It created the evidence layer the rest of the roadmap depends on.

**Exit gate:** Achieved. Month 1 evidence lives in `ROADMAP_EXECUTION_STATE.md`.

### Month 2 - Contracts, Input Intents, and Runtime Observability

**Status:** IN PROGRESS  
**Primary goal:** Finish the shift from ad-hoc coupling to explicit contracts.

**Player-facing enhancements:**

- More consistent combat feedback chain across HUD, audio, VFX, and dungeon systems.
- Fewer "ghost" interactions caused by anonymous dictionaries or raw input reads.

**Technical enhancements:**

- Complete typed combat event rollout in `EventBus` and finish migration of major listeners.
- Introduce `InputIntent` flow so raw device input is translated once, then consumed by gameplay systems.
- Add unmatched-event diagnostics and unknown-signal assertions in development flows.
- Close Month 2 known issues in the current freeze list where possible:
  - KI-03 spell state desync
  - KI-05 pooled VFX finished-signal leak
  - KI-06 overlapping zoom punch drift
  - KI-07 enemy re-entry on configure
  - KI-09 missing target validity checks
  - KI-10 missing runtime bounds enforcement

**Content/docs enhancements:**

- Treat `docs/events/event_catalog.md` as a gate, not a reference only.
- Update change-scope docs for combat, runtime state, and dungeon flow.

**Exit gate:**

- A new gameplay event can be added with one contract file, one catalog update, and minimal unrelated code churn.
- All major gameplay input paths use `InputManager` or an equivalent intent adapter.

### Month 3 - Service Decomposition and Deterministic Gameplay Rules

**Primary goal:** Separate pure rules from scene orchestration so balance and bug fixes stop requiring scene-level surgery.

**Player-facing enhancements:**

- Cleaner combat resolution, fewer edge-case failures during encounters, and more consistent enemy reactions.
- More reliable stage progression when multiple combat and encounter systems overlap.

**Technical enhancements:**

- Extract combat decision logic into a focused service layer:
  - damage calculation
  - hit reaction policy
  - knockback/status application
  - feedback triggers
- Extract encounter selection/spawn ownership into service modules with deterministic seed support.
- Normalize runtime ownership between `GameState`, `RuntimeState`, `DungeonRun`, and `StageRunner`.
- Add integration tests for the full hit pipeline: hit -> state change -> VFX/audio/HUD -> encounter bookkeeping.

**AI-editability enhancements:**

- Reduce high-complexity scripts by pushing rules into testable modules.
- Document "safe change" seams in `scripts/README.md` and matching folder READMEs.

**Exit gate:**

- The highest-risk combat and encounter logic can be changed through service files and tests without editing multiple scenes.
- Remaining P1 issues are no longer concentrated in a few oversized scripts.

### Month 4 - Data Validation and Authoring Pipeline

**Primary goal:** Make content additions safe, fast, and resource-driven.

**Player-facing enhancements:**

- Better balance consistency between attacks, enemies, towns, and stage encounters.
- Fewer broken runs caused by invalid content data.

**Technical enhancements:**

- Add or complete `validate()` behavior across resource definitions:
  - attacks
  - enemies
  - encounters
  - dungeons/stages
  - characters
  - techniques
  - towns
  - skill trees
- Enforce content lint in local sanity and CI:
  - duplicate IDs
  - empty encounter pools
  - impossible stage links
  - invalid stat/value ranges
- Add small authoring tools for previewing derived data and validating stage chunks before runtime.

**Content pipeline enhancements:**

- Finish conventions for chunk authoring, encounter placement, and hazard/interactable metadata.
- Establish reusable encounter templates and difficulty bands for future dungeons.

**Exit gate:**

- Designers or AI agents can safely add or rebalance most gameplay data through resources plus validation.
- Invalid content fails early in tools/tests instead of surfacing during playtest.

### Month 5 - Progression Reliability and Save Integrity

**Primary goal:** Make permanent progression trustworthy across refactors, content growth, and interrupted sessions.

**Player-facing enhancements:**

- Stable XP/gold/equipment/story persistence.
- Clearer recovery behavior when a save is old, damaged, or partially written.

**Technical enhancements:**

- Version the save schema explicitly and add migration hooks.
- Add strict deserialize validation, checksum or transaction safeguards, backup retention, and rollback behavior.
- Harden party roster, equipment, skill tree, and inventory serialization boundaries.
- Expand tests for:
  - new save
  - migrated save
  - corrupt save
  - mid-progression save
  - multi-character party state

**Product enhancements:**

- Ensure overworld, town, dungeon, and pause/save flows all round-trip correctly.
- Add clearer user-facing messaging for load recovery and save failures.

**Exit gate:**

- Save corruption cannot silently brick progression.
- Major progression systems survive round-trip save/load without manual repair steps.

### Month 6 - Party Depth, Character Identity, and Technique Polish

**Primary goal:** Turn the current progression foundation into a compelling multi-character RPG layer.

**Player-facing enhancements:**

- 4 production-ready playable characters with clearer role identity.
- Polished character switch behavior in dungeon runs.
- Stronger distinction between techniques, elemental/status effects, and build paths.
- More meaningful equipment and skill choices instead of flat stat upgrades only.

**Technical enhancements:**

- Finish integrating current player policy components into runtime flow:
  - profile
  - stats
  - hit policy
  - lock-on policy
  - runtime bounds
- Tighten technique definitions and effect application so balance changes remain data-driven.
- Add tests for character switch edge cases, technique state transitions, and party-derived stat calculations.

**Content enhancements:**

- Expand skill trees, baseline equipment tiers, and technique libraries for the main roster.
- Add clearer role tags for future UI/help surfaces: striker, caster, tank, support, mobility.

**Exit gate:**

- The party system feels intentional, not merely available.
- The main roster has enough mechanical differentiation to support replay and co-op planning.

### Month 7 - Content Expansion Wave 1

**Primary goal:** Build the first large jump in game breadth on top of the hardened pipeline.

**Player-facing enhancements:**

- Add the next major production dungeon and its town wrapper.
- Introduce a new biome, boss, enemy family, music profile, and stage gimmicks.
- Extend story progression past the first completed dungeon into a broader campaign loop.

**Content targets:**

- Dungeon 2 fully playable as a continuous stage.
- Town 2 fully functional with differentiated shop inventory, inn values, NPC dialogue, and unlock behavior.
- 2-3 new enemy archetypes and 1 boss tied to the new dungeon.
- New hazard and interactable set for biome identity.

**Technical enhancements:**

- Reuse the validated content pipeline to prove the team can add a full dungeon without architecture churn.
- Add content-completeness checks for stage packs and encounter coverage.

**Exit gate:**

- A player can progress from the current opening content into a second dungeon/town arc without placeholder-only progression gaps.

### Month 8 - Local Co-op Foundation

**Primary goal:** Make shared-screen multiplayer truly playable instead of a theoretical future branch.

**Player-facing enhancements:**

- 2-4 local players can join, play, and finish a dungeon together on PC.
- Revive flow works during combat.
- Shared camera and HUD scale to multiple players without unreadable clutter.
- First pass of combination/team mechanics lands.

**Technical enhancements:**

- Finalize multi-device input routing, per-player profile assignment, and join/drop handling.
- Expand camera rules to account for player spread, downed allies, and off-screen pressure.
- Extend save/runtime handling to support multi-character active sessions cleanly.

**Validation enhancements:**

- Add deterministic tests for device mapping, revive timing/proximity, and shared-party state rules.
- Add playtest checklist specifically for 2-player and 4-player dungeon runs.

**Exit gate:**

- A 4-player local run is stable on PC with no blocker-level camera, input, or save issues.

### Month 9 - Android Playability and Performance Discipline

**Primary goal:** Prove the game is not only a PC prototype and can sustain a full run on Android hardware targets.

**Player-facing enhancements:**

- Full touch-control dungeon playthrough.
- Improved menu readability and controller/touch parity.
- Reduced performance spikes in combat-heavy and effects-heavy scenarios.

**Technical enhancements:**

- Establish explicit frame and memory budgets for PC and Android.
- Audit object lifetime, per-frame allocation hotspots, and pooled effect usage.
- Add automated long-run stress checks and mobile-oriented smoke coverage where feasible.
- Standardize export settings, package naming, and post-build validation.

**Product enhancements:**

- Low-memory or reduced-effects profile for mobile.
- Safer touch UI sizing and fallback controls for dense encounters.

**Exit gate:**

- Representative Android hardware can complete a full dungeon run at the accepted minimum performance target.
- Export and smoke verification are reproducible, not ad hoc.

### Month 10 - Content Expansion Wave 2

**Primary goal:** Move from "strong slice" to "real game breadth."

**Player-facing enhancements:**

- Add at least one more town and one more dungeon.
- Expand roster depth beyond the core party baseline.
- Introduce midgame-to-endgame progression arcs, stronger shop variance, and larger enemy ecology.

**Content targets:**

- Dungeon 3 complete.
- Town 3 complete.
- Character 5 and possibly Character 6 integrated with at least baseline production readiness.
- 3-4 additional enemy types across newer biomes.
- Story beats that clearly bridge midgame progression.

**Technical enhancements:**

- Add completeness validators for character kits, boss data, and story progression chains.
- Expand content metrics in docs so gaps are visible:
  - encounter pool size
  - item tier coverage
  - technique coverage by character
  - boss mechanic checklist

**Exit gate:**

- The campaign breadth is no longer concentrated in one biome and one progression loop.

### Month 11 - Accessibility, Diagnostics, and Replayable Systems

**Primary goal:** Improve player trust, replay value, and supportability before the final stabilization push.

**Player-facing enhancements:**

- Accessibility presets:
  - reduced motion
  - high contrast
  - clearer HUD scaling and feedback tuning
- Better remap conflict recovery and settings transparency.
- Daily challenge or equivalent replayable seeded mode with local tracking.
- In-game diagnostic bundle or replay capture flow that support-minded players can trigger.

**Technical enhancements:**

- Expand debug bundle capture into a user-safe support workflow.
- Add deterministic replay or event trace support for issue reproduction where practical.
- Introduce light analytics or local telemetry summaries for progression anomalies, crash context, and feature usage if they remain offline-safe and optional.

**Operational enhancements:**

- Create a support issue template linked to debug bundles and severity tags.
- Add weekly balance review loops using captured seeds and content metrics.

**Exit gate:**

- Players can report issues with enough evidence to reproduce them.
- Accessibility and replay features are present before final lock, not deferred to post-launch.

### Month 12 - Release Candidate Hardening

**Primary goal:** Convert the expanded game into a release candidate that can survive shipping and hotfix cycles.

**Player-facing enhancements:**

- Final onboarding and UX clarity pass.
- Final balance and progression tuning pass across the full content path.
- Stable release flow across PC and Android targets.

**Technical enhancements:**

- Full acceptance matrix run for all critical game loops:
  - new game
  - save/load
  - overworld progression
  - town services
  - dungeon completion/failure
  - co-op session
  - Android touch flow
- Performance, crash, and save stress sweeps on content-complete builds.
- Ship-mode flags, debug path trimming, and post-launch hotfix playbook.

**Release enhancements:**

- Finalize changelog process, release ownership, rollback instructions, and emergency-fix rules.
- Draft Year-2 roadmap from actual post-beta gaps rather than speculation.

**Exit gate:**

- The project can produce a release candidate build with known issues clearly triaged, reproducible, and operationally manageable.

---

## 7. Year-End Metrics

Use these metrics to decide whether the roadmap succeeded:

| Area | Starting Point (2026-03-07) | Year-End Target |
|---|---|---|
| Known P0 issues | Baseline audit lists unresolved P0 items | 0 unresolved P0s in active shipping paths |
| Automated tests | 449 listed test functions | 650+ test functions with better integration coverage |
| Production dungeons | 1 active production stage path in progress | 4 complete dungeons |
| Towns | 1 current town baseline | 3 complete towns |
| Playable characters | 4 partially realized core characters | 5-6 production-ready characters |
| Enemy variety | Early multi-archetype baseline | 12+ enemies including bosses and biome variants |
| PC performance | Primary dev target | Stable 60 FPS on representative content |
| Android performance | Active support path, not yet proven | Full dungeon run at target floor |
| AI-editability | Partial contracts, partial change-scope docs | Most balance/content requests resolved inside documented seams |

---

## 8. Out of Scope for This Year

To keep the plan realistic, the following are explicitly out of scope unless the roadmap is re-baselined:

- Online multiplayer or rollback networking
- Live backend services or mandatory online analytics
- Procedural level geometry generation beyond seeded encounter/content variation
- Console certification work
- Full voice acting pipeline
- Large engine migration or renderer rewrite

---

## 9. Monthly Definition of Done

Each month is only complete when all of the following are true:

1. The planned player-visible enhancement is running in a build.
2. The matching docs (`INDEX.md`, event catalog, schema docs, or folder README) are updated.
3. New or changed contracts are covered by tests or explicitly marked play-verify only.
4. The month closes with evidence:
   - passing sanity run
   - updated execution tracker
   - short playtest log, bundle, or video note

If one of those is missing, the month is not done and the next month should not be declared active.
