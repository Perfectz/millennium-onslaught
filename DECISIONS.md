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

## 2026-03-01 — Defensive Deserialization in GameState

**Decision:** `GameState.deserialize_persistent()` validates required fields before applying loaded data and returns `bool` success status.

**Why:** Save files can be corrupted, manually edited, or come from older versions with different schemas. Silently loading invalid data causes downstream crashes that are hard to trace. Validating on load catches problems immediately at the source.

**Alternatives Considered:**
- Trust all save data blindly: Simpler but fragile. A missing field causes a null reference later.
- Schema versioning with migration: Overkill for MVP 0, but noted for future consideration when save schema changes between MVPs.

---

## 2026-03-01 — RefCounted States with Node StateMachine

**Decision:** States are RefCounted (no scene tree dependency), StateMachine is a Node (processes _physics_process/_unhandled_input).

**Why:** States are pure logic objects that can be tested without a scene tree. The StateMachine as a Node allows it to participate in the Godot processing loop automatically. States access the entity via a `entity: CharacterBody3D` reference set when registered.

**Trade-off:** States can't use Node features (timers, signals) directly, but this keeps them lightweight and testable.

---

## 2026-03-01 — Hitstop via Engine.time_scale with Real-Time Countdown

**Decision:** Hitstop freezes the game by setting `Engine.time_scale = 0.0`. The HitstopSystem uses `process_mode = ALWAYS` and counts down using `Time.get_ticks_usec()` to measure real elapsed time.

**Why:** `Engine.time_scale = 0` cleanly freezes all INHERIT/PAUSABLE nodes. The real-time tick approach is immune to the fact that delta becomes 0 during the freeze — ensuring the hitstop always ends.

**Alternatives Considered:**
- Pause tree: Would need every node to opt into pause behavior. time_scale is simpler.
- SceneTree timer with `ignore_time_scale`: Works but doesn't handle overlapping hitstops cleanly.

---

## 2026-03-01 — Z-Tolerance Hit Detection for Belt-Depth

**Decision:** Hitbox-Hurtbox collision includes a Z-axis tolerance check (`Constants.Z_HIT_TOLERANCE = 1.0`). Hits only register if the attacker and target are within 1 unit of Z-depth.

**Why:** In a 2.5D belt-scroller, players and enemies move along the Z-axis (belt-depth). Without Z-tolerance, attacks could hit enemies visually far away in the depth axis. The tolerance ensures hits feel spatially correct.

---

## 2026-03-01 — Data-Driven Attacks via AttackDef Resources

**Decision:** All attack properties (damage, knockback, timing, hitstop) are stored in `.tres` Resource files (`AttackDef`), not hardcoded in state scripts.

**Why:** Allows tuning attacks by editing data files without touching code. New attacks can be added by creating new `.tres` files. States are parameterized by the loaded AttackDef.

---

## 2026-03-01 — ObjectPool Double-Return Guard

**Decision:** `ObjectPool.return_instance()` checks `pool_active` meta before returning, ignoring duplicate returns with a warning.

**Why:** In combat with many simultaneous deaths and effects, it's possible for a return call to happen twice (e.g., from both a death handler and a cleanup sweep). Without a guard, the same instance ends up in the pool twice, causing it to be handed out to two requesters who then fight over the same node.

**Alternatives Considered:**
- Assert and crash on double-return: Too aggressive for production gameplay.
- Track a separate `_active_instances` set: More memory overhead for a problem that a simple meta check solves.

---

## 2026-03-01 — WORLD_GRAVITY Separation from PLAYER_GRAVITY

**Decision:** Added `WORLD_GRAVITY` constant separate from `PLAYER_GRAVITY`. Enemy gravity uses `WORLD_GRAVITY` instead of `PLAYER_GRAVITY`.

**Why:** Enemies referenced `PLAYER_GRAVITY` for their own gravity, creating a semantic coupling — changing the player's gravity would unintentionally change enemy physics. `WORLD_GRAVITY` provides a shared baseline that either player or enemy can override independently via multipliers.

**Alternatives Considered:**
- Single GRAVITY constant: Simpler but prevents independent tuning of player/enemy fall feel.
- Per-enemy gravity in EnemyDef: Over-engineered for current needs; can be added later if needed.

---

## 2026-03-01 — Centralized Delta Cap in StateMachine

**Decision:** `StateMachine._physics_process()` caps delta via `minf(delta, Constants.DELTA_CAP)` before passing to states. Individual states no longer cap delta themselves.

**Why:** Every state was independently capping delta, creating 14+ duplicate lines. A single cap at the state machine level ensures consistency, reduces maintenance, and prevents missed caps in new states. States still receive a safe delta value.

**Alternatives Considered:**
- Keep per-state caps: Redundant but "safer" — rejected because the state machine is the single entry point for all state ticks.
- Cap in `_physics_process` of controllers: Would need to be done in both player and enemy controllers; the state machine is the better choke point.

---

## 2026-03-01 — Collision Layer Constants

**Decision:** Defined `LAYER_ENVIRONMENT`, `LAYER_PLAYER`, `LAYER_ENEMY`, `LAYER_PLAYER_HITBOX`, etc. as named constants in `Constants`.

**Why:** Hardcoded collision layer values (1, 2, 4, etc.) are cryptic and error-prone. Named constants make collision configuration self-documenting and prevent bugs when layers change.

**Alternatives Considered:**
- Relying on Godot's Project Settings layer names: Good for .tscn but unusable from GDScript at runtime.
- Enum: Would require casting to int frequently; constants are simpler.

---

## 2026-03-01 — VFX ObjectPool Integration

**Decision:** `VFXSystem` warms ObjectPool with hit/death particles at startup and recycles them via `get_instance()`/`return_instance()` instead of `instantiate()`/`queue_free()`.

**Why:** Hit particles spawn frequently in combat (every successful hit). Repeated instantiate/free cycles cause GC pressure and potential frame drops, especially on Android. Object pooling eliminates these allocations. A fallback to instantiate() is kept for pool exhaustion.

**Alternatives Considered:**
- Always instantiate: Simpler but violates the "no per-frame allocation" rule and harms Android performance.
- Pool only on Android: Branch complexity not worth it when pooling works everywhere.

---

## 2026-03-01 — EventBus Bridge Pattern for Component Signals

**Decision:** `PlayerController._bridge_eventbus_signals()` connects local component signals (health, combo) to corresponding EventBus signals, forwarding `player_index`.

**Why:** Components like `HealthComponent` are pure logic (RefCounted) and must not reference autoloads. The controller bridges the gap by listening to component signals and re-emitting them on EventBus with player context (index). This keeps components testable while enabling cross-system communication.

**Alternatives Considered:**
- Components emit on EventBus directly: Violates the "no autoload references in pure logic" rule and makes unit testing require mock autoloads.
- HUD polls components directly: Creates tight coupling between UI and gameplay objects.

---

## 2026-03-01 — Kenney FBX Model with Runtime Animation Merging

**Decision:** Replace the blue capsule placeholder with a Kenney Animated Characters 2 FBX model. The `CharacterModel` script loads `idle.fbx` as the base (mesh + skeleton + idle animation), then extracts animations from `run.fbx` and `jump.fbx` at runtime and merges them into a single `AnimationPlayer`. A fallback capsule mesh is created if FBX loading fails.

**Why:** Kenney packs distribute animations as separate FBX files, each containing the full model + skeleton + one animation. Runtime merging avoids needing manual import configuration in the Godot editor. Using `idle.fbx` as the base ensures the model has both mesh and a default animation immediately. The fallback capsule guarantees the game remains playable even if model files are missing.

**Alternatives Considered:**
- Single GLTF with all animations: Cleaner runtime but requires manual re-export from Blender, adding a tool dependency.
- Godot import presets (.import files): Fragile across machines and requires editor interaction.
- Animated sprite sheet approach: Loses the benefit of 3D depth sorting that was a founding architecture decision.

**Tuning:** Scale, offset, and rotation are in `Constants` (`PLAYER_MODEL_SCALE`, `PLAYER_MODEL_OFFSET`, `PLAYER_MODEL_ROTATION_Y`) for easy adjustment without touching scene files.
