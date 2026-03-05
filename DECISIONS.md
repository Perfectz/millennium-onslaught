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

---

## 2026-03-05 — Typed Event Contracts (Month 2)

**Decision:** Replace loose signal parameters with typed RefCounted payload classes (EventContracts.HitEvent, KillEvent, etc.).

**Why:** Loose parameters (attacker: Node, target: Node, damage: float, hit_position: Vector3) have no validation and are easy to misorder. Typed contracts enforce required fields, enable validation, and provide to_dict() for logging.

**Alternatives Considered:**
- Keep loose parameters: Simpler but no validation, easy to introduce bugs when signal signatures change.
- Dictionary payloads: Flexible but no type safety, keys are stringly-typed.

**Trade-off:** Slightly more boilerplate per event type, but catch errors at emit time rather than runtime crash.

---

## 2026-03-05 — Data-Driven Input Action Sets (Month 2)

**Decision:** Extract InputManager action mappings into InputActionSet data objects per InputContext.

**Why:** Hardcoded action mappings in InputManager make remapping difficult and testing impossible. Data-driven action sets can be swapped per context and are testable without the scene tree.

---

## 2026-03-05 — Stateless Service Layer (Month 3)

**Decision:** Game logic services (CombatService, EncounterService, SpawnService) are stateless — all calculations use passed parameters, no persistent member variables.

**Why:** Stateless services are trivially testable (no setup/teardown), thread-safe, and impossible to have stale state bugs. The DamageFlow orchestrator coordinates the pipeline without services knowing about each other.

**Alternatives Considered:**
- Stateful service singletons: Simpler API but harder to test and debug.
- Pure functions only: Too granular, loses encapsulation of related operations.

---

## 2026-03-05 — Save Versioning with CRC32 Checksums (Month 5)

**Decision:** Every save file includes a `save_version` integer and a CRC32 checksum. Loading verifies checksum and runs version migration chain.

**Why:** Save format will change as features are added. Without versioning, old saves break silently. Without checksums, corrupted saves load with garbage data causing hard-to-debug crashes.

**Migration Strategy:** Linear chain (v0 → v1 → v2 → ... → vN). Each migration adds missing fields with defaults. Old saves are upgraded transparently.

---

## 2026-03-05 — Video Background Z-Ordering Fix (Month 2)

**Decision:** StageRunner's video background uses CanvasLayer with layer=-1, placing it BEHIND the 3D viewport. 3D gameplay renders at the default layer (0). UI CanvasLayer at layer 10.

**Why:** Without explicit layer assignment, CanvasLayer defaults to layer 0, which renders ON TOP of 3D content, making players and enemies invisible behind the video. Negative layer values ensure the video is always behind 3D.

**Scene Tree:**
```
Stage (Node3D)
├── VideoBackground (CanvasLayer, layer = -1)  ← BEHIND 3D
│   └── VideoStreamPlayer
├── DungeonRoom (Node3D)                        ← 3D at default layer
└── UI (CanvasLayer, layer = 10)                ← On top
```

---

## 2026-03-05 — Feature Flags for Controlled Rollout (Month 11)

**Decision:** Boolean and variant feature flags loaded from JSON config (local file, extensible to remote). Flags gate code paths at runtime.

**Why:** Allows testing new features without branching, gradual rollout, and quick rollback by changing config rather than code.

**Pattern:**
```gdscript
if feature_flags.is_enabled("new_combat_system"):
    # New path
else:
    # Existing path
```
