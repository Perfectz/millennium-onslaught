# DECISIONS.md — Architectural Decision Log

> **Purpose:** Running log of architectural decisions. When a future AI agent asks "why is it done this way?", the answer lives here.

---

## 2026-03-01 — Full 3D Renderer (Not 2D with Manual Sorting)

**Decision:** Use Godot's full 3D renderer (Forward+) for the 2.5D belt-scroller.

**Why:** The game has belt-depth (Z-axis) movement. In a 2D renderer, depth sorting sprites by Y/Z position is fragile and breaks at edge cases (Lesson 8 from project plan). A full 3D renderer handles depth sorting automatically via the Z-buffer. This eliminates an entire class of visual bugs.

**Alternatives Considered:**
- 2D renderer with Y-sort: Simpler initial setup but manual depth sorting is error-prone with Z-movement.
- 2D renderer with custom sort: More control but high maintenance burden, especially with platforming.

**Trade-off:** Slightly more complex initial scene setup (3D nodes vs 2D), but eliminates depth sorting bugs entirely.

---

## 2026-03-01 — Resolution: 1920x1080 with Canvas Items Stretch

**Decision:** Base viewport resolution of 1920x1080, stretch mode `canvas_items`, aspect `expand`.

**Why:** Targeting a mature Android game aesthetic requires high-resolution UI and clear text. 1920x1080 is the standard Full HD resolution that matches modern Android devices. `canvas_items` stretch mode scales the 2D UI layer cleanly while letting the 3D viewport render at native device resolution. `expand` aspect allows the game to fill wider/taller screens without letterboxing.

**Alternatives Considered:**
- 1280x720: Lower resolution, would look dated on modern phones and tablets.
- 2560x1440: Overkill for base resolution, higher GPU cost for no meaningful visual gain since 3D renders at native anyway.
- `viewport` stretch mode: Would force 3D to render at the base resolution, losing native resolution benefit on high-DPI devices.

---

## 2026-03-01 — GdUnit4 for TDD (Test Framework)

**Decision:** Use GdUnit4 as the testing framework.

**Why:** GdUnit4 is the most mature and actively maintained test framework for Godot 4. It supports unit tests for pure GDScript logic (components, state machines, formulas) without requiring the scene tree. This aligns with the TDD principle.

**Alternatives Considered:**
- Godot built-in test runner: Less feature-rich, limited assertion library.
- WAT (Weighted Average Testing): Less community support, fewer updates.

---

## 2026-03-01 — Event Bus Architecture (No Direct System References)

**Decision:** All cross-system communication goes through a global EventBus singleton using typed signals.

**Why:** Prevents spaghetti coupling (Lesson 2). Systems emit events and listen to events without knowing about each other. Adding a new system that reacts to combat hits (e.g., score tracker, VFX spawner, audio cue) requires zero changes to the combat system.

**Alternatives Considered:**
- Direct function calls between systems: Simpler initially but creates invisible dependency chains.
- Observer pattern per-system: More decoupled than direct calls but each system needs its own signal management.

**Trade-off:** Slight indirection cost (signals vs direct calls), but dramatically better maintainability and extensibility.

---

## 2026-03-01 — Collision Layer Strategy

**Decision:** Separate collision layers for each interaction type.

**Why:** Minimizes unnecessary collision checks (Performance Rules). Player hitbox only checks against enemy hurtbox. Enemy hitbox only checks against player hurtbox. Platform collisions are separate from combat collisions.

**Layer Assignment:**
| Layer | Name | Purpose |
|-------|------|---------|
| 1 | environment | Static world geometry |
| 2 | player | Player body collision |
| 3 | enemy | Enemy body collision |
| 4 | player_hitbox | Player attack areas |
| 5 | enemy_hitbox | Enemy attack areas |
| 6 | player_hurtbox | Player damageable areas |
| 7 | enemy_hurtbox | Enemy damageable areas |
| 8 | platform | One-way and solid platforms |
| 9 | trigger | Area triggers (room transitions, events) |
| 10 | pickup | Collectible items |
