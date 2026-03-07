# ROADMAP_EXECUTION_STATE.md — Monthly Milestone Tracker

> **Purpose:** Tracks monthly roadmap milestones and completion evidence for the Year-Long Development Roadmap.

---

## Month 1 — Foundation Hardening and Safety for AI Work

**Status:** COMPLETE
**Start Date:** 2026-03-04
**Objective:** Make the codebase boringly deterministic and safe to modify.

### Deliverables

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | Baseline audit pass (P0/P1/P2) | DONE | 115 issues found: 12 P0, 36 P1, 67 P2. See `docs/audits/month1_baseline_audit.md` |
| 2 | ROADMAP_EXECUTION_STATE.md | DONE | This file |
| 3 | Code conventions guide | DONE | `CONVENTIONS.md` |
| 4 | Runtime guards in hot paths | DONE | StateMachine, CameraFollow, WaveSystem, ObjectPool, HazardZone hardened |
| 5 | Camera shake stack fix | DONE | Already consolidated in MVP 4.5 (DECISIONS.md 2026-03-02). No duplicate shake sources remain |
| 6 | Encounter progress deadlock fix | DONE | WaveSystem tracks spawned enemy IDs; only matching deaths decrement counter |
| 7 | Centralize attack payload format | DONE | HazardZone caches AttackDef; Constants added for pool deactivation coords |
| 8 | Smoke test runner script | DONE | `tools/smoke_test.sh` + `tools/sanity_check.ps1` — one-command parse, catalog validation, and headless tests |
| 9 | CI baseline job | DONE | `.github/workflows/ci.yml` — shared sanity workflow (parse check, catalog validation, headless tests) |
| 10 | Known-issue freeze list | DONE | Added to INDEX.md |
| 11 | Month-end review template | DONE | `docs/MONTH_END_REVIEW_TEMPLATE.md` |

### Exit Gate

- [x] No critical runtime deadlocks (encounter deadlock fixed, WaveSystem tracks enemy ownership)
- [x] No duplicate camera shake (consolidated to single trauma system in CameraFollow)
- [x] CI smoke test passes (GitHub Actions workflow created)

---

## Month 2 — API Contracts and Typed Event-First Communication

**Status:** IN PROGRESS
**Objective:** Replace fuzzy coupling with stable contracts so AI changes do not ripple unpredictably.

### Deliverables

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | Canonical event contracts | IN PROGRESS | `scripts/contracts/combat_hit_event.gd`, `scripts/contracts/combat_kill_event.gd`, `docs/events/combat_event_contracts.md` |
| 2 | Typed EventBus payloads | IN PROGRESS | `autoloads/event_bus.gd` canonical typed combat signals; listeners migrated in audio/VFX/HUD/dungeon systems |
| 3 | Event payload schema versions | IN PROGRESS | `CombatHitEvent.schema_version = 1`, `CombatKillEvent.schema_version = 1` |
| 4 | Event catalog source-of-truth | DONE | `docs/events/event_catalog.md` validated by `tools/validate_event_catalog.py` |
| 5 | Contract test suite | IN PROGRESS | `tests/unit/data/test_combat_event_contracts.gd` |
| 6 | InputManager command API extraction | PARTIAL | DungeonRun controls already moved through `InputManager`; wider extraction remains |
| 7 | InputIntent abstraction | — | |
| 8 | Unmatched event debug tooling | — | |
| 9 | Unknown signal name assertion | — | |
| 10 | Docs update automation checks | DONE | Catalog validation enforced in `tools/smoke_test.sh`, `tools/sanity_check.ps1`, and `.github/workflows/ci.yml` |

### Exit Gate

- [ ] New event can be added without touching two unrelated systems
- [ ] Event contracts pass tests

---

## Months 3–12

> Tracked in future updates as each month begins.
