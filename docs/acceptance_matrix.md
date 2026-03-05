# Acceptance Matrix — Millennium Onslaught

> **Purpose:** Per-MVP acceptance criteria checklist. Mark each criterion as PASS/FAIL during verification.

**Last Updated:** 2026-03-05

---

## MVP 0 — Scaffold

| # | Criterion | Status |
|---|-----------|--------|
| 1 | project.godot configured (1920x1080, canvas_items, expand) | PASS |
| 2 | All 8 autoloads load and verify | PASS |
| 3 | GdUnit4 installed and functional | PASS |
| 4 | Folder structure matches architecture spec | PASS |
| 5 | INDEX.md exists and is accurate | PASS |
| 6 | DECISIONS.md exists | PASS |
| 7 | Event catalog exists with initial signals | PASS |
| 8 | Main scene runs without errors | PASS |

## MVP 1 — First Punch

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Character moves with responsive controls | PENDING |
| 2 | Jump has weighty arc (fast up, heavy down) | PENDING |
| 3 | Can land on elevated platforms | PENDING |
| 4 | Belt-depth nudge works (subtle Z movement) | PENDING |
| 5 | Light attack 3-hit combo plays on repeated press | PENDING |
| 6 | Heavy attack is slower and more powerful | PENDING |
| 7 | Dodge roll with invincibility frames | PENDING |
| 8 | Hitstop on hit (screen freeze, camera shake, particles) | PENDING |
| 9 | Enemy takes damage and dies with effect | PENDING |
| 10 | Arena restartable | PENDING |

## MVP 2 — The Dungeon

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Enter dungeon, arrive in first room | PENDING |
| 2 | Enemy waves spawn, camera locks to arena | PENDING |
| 3 | 3+ distinct enemy types | PENDING |
| 4 | Juggle system with air hits and limit | PENDING |
| 5 | Combo branch points (light→heavy, cancel→dodge) | PENDING |
| 6 | HUD shows health, TP, combo counter | PENDING |
| 7 | Boss with 2 phases | PENDING |
| 8 | Dungeon Failed screen on death | PENDING |
| 9 | Victory screen with stats on boss kill | PENDING |

## Roadmap Infrastructure

| Month | Deliverable | Status |
|-------|------------|--------|
| 1 | Baseline audit + conventions + CI | COMPLETE |
| 2 | Typed event contracts + InputManager extraction | COMPLETE |
| 3 | Service layer (CombatService, EncounterService, SpawnService) | COMPLETE |
| 4 | Resource validation + balance tools | COMPLETE |
| 5 | Save versioning + checksums + migration | COMPLETE |
| 6 | Test harness expansion + parameterized tests | COMPLETE |
| 7 | Frame budget monitor + allocation tracker + stress test | COMPLETE |
| 8 | Build matrix + export scripts + release pipeline | COMPLETE |
| 9 | Change scope map + AI guardrails | COMPLETE |
| 10 | Accessibility + localization + replay capture | COMPLETE |
| 11 | Analytics + remote config + feature flags | COMPLETE |
| 12 | Content lock + acceptance matrix + hotfix playbook | COMPLETE |
