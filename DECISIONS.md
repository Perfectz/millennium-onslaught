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

---

## 2026-03-01 — SceneTransitioner as GameManager Child

**Decision:** Scene transitions use a `SceneTransitioner` (CanvasLayer at layer 99) that is a child of `GameManager`. All scene changes go through `GameManager.go_to_overworld()`, `go_to_town()`, `go_to_dungeon()`, or `go_to_main_menu()`.

**Why:** Centralizing transitions in GameManager ensures phase changes and fade effects always happen together. The SceneTransitioner as a child of GameManager survives scene changes (autoloads persist). Layer 99 ensures the fade rect renders above everything.

**Alternatives Considered:**
- Per-scene transition logic: Duplicates fade code across every scene.
- Global signal with scene handling: More decoupled but harder to ensure phase/fade ordering.

---

## 2026-03-01 — Inline NPC Data in TownDef (Not Separate NPCDef)

**Decision:** NPC dialogue data is stored as inline `Array[Dictionary]` inside `TownDef.npcs` rather than as separate `NPCDef` Resource files.

**Why:** NPCs in MVP 3 are simple name/lines/flag data. Creating separate `.tres` files for each NPC adds file management overhead without benefit. The inline approach keeps town data self-contained. Can migrate to NPCDef resources in MVP 4 if NPCs gain complex behavior (quests, state machines).

**Alternatives Considered:**
- Separate NPCDef resources: Cleaner OOP but overkill for static dialogue-only NPCs.
- JSON files: Loses Godot resource referencing and inspector editing.

---

## 2026-03-01 — Pure RefCounted Components for MVP 3 Logic

**Decision:** `StoryFlagManager`, `ShopTransaction`, and `GoldTracker` are `extends RefCounted` with no autoload dependencies.

**Why:** Following the pattern established by `HealthComponent`, `ComboTracker`, etc. Pure logic components are fully testable without the scene tree. The town/shop UI scripts bridge these components to EventBus/GameState, keeping the logic layer clean.

---

## 2026-03-01 — JSON Typed Array Deserialization Workaround

**Decision:** `GameState.deserialize_persistent()` manually iterates and converts arrays from JSON (e.g., `Array` → `Array[StringName]`) instead of direct assignment.

**Why:** Godot's JSON parser returns untyped arrays. Direct assignment to typed arrays (e.g., `Array[StringName]`) throws a runtime type error. The manual conversion loop ensures type safety without changing the save format.

---

## 2026-03-01 — Auto-Save on Dungeon Completion and Town Exit

**Decision:** Game auto-saves to slot 0 when a dungeon is completed and when the player leaves a town.

**Why:** These are the two major state-changing moments in the game loop. Auto-saving here prevents progress loss without requiring the player to manually save. The overworld also offers a manual save menu via the Select button for explicit save management.

---

## 2026-03-02 — MVP 4.5 Juice & Polish Architecture

**Decision:** Added three new autoloads (JuiceManager, ToastSystem, DamageNumberSpawner), upgraded SceneTransitioner with shader-based wipes, upgraded CameraFollow to spring-damped with trauma shake, extended AudioManager with pitch variation and variant pools, added dissolve shader + helper, and added UI stagger/exit animation + button sound wiring in UIStyle.

**Why:** Professional game feel ("juice") requires tight integration between systems — a single hit triggers camera shake, screen flash, slow-mo, damage numbers, and sound simultaneously. Making JuiceManager an autoload lets it listen to EventBus signals and coordinate all effects without any gameplay system knowing about it. The trauma-based camera shake (squared intensity curve) gives exponential feel that's more natural than linear. Spring-damped follow eliminates the visual "mushiness" of lerp-based cameras. Shader-based wipes in SceneTransitioner are GPU-accelerated and extensible. Audio pitch variation prevents repetitive sound fatigue.

**Alternatives Considered:**
- Per-system juice (each system handles its own effects): Leads to scattered, inconsistent feel and tight coupling.
- Camera shake as separate system vs integrated into CameraFollow: Separate system adds complexity; trauma model integrates naturally with follow logic.
- Separate TransitionManager autoload vs upgrading SceneTransitioner: Upgrading preserves GameManager's existing API while adding capability.
- Pooled Label3D vs billboard sprites for damage numbers: Label3D is simpler, resolution-independent, and well-suited for 3D scenes.

---

## 2026-03-02 — Camera System Overhaul (Paper-Driven)

**Decision:** Consolidated CameraFollow and CameraShakeSystem into a single CameraFollow system with 8 new capabilities: velocity look-ahead, horizontal dead zone, Z-axis arena bounds, enemy centroid threat bias, dynamic FOV zoom, director cue system, velocity cap, and real-time trauma shake. Removed CameraShakeSystem entirely. Moved all hardcoded camera constants to Constants autoload.

**Why:** Analysis of theoretical camera paper against the codebase revealed 10 gaps. The paper's three design lineages (belt-scroller threat visibility, JRPG curated framing, platformer anticipation) directly map to the game's genre blend. Key improvements:

1. **Duplicate shake fix:** CameraShakeSystem (h_offset/v_offset) and CameraFollow's trauma shake ran simultaneously on every hit, causing double-shake that violated readability. Consolidated to single trauma-based system.
2. **Velocity look-ahead:** Camera now biases toward movement direction ("anticipation beats reaction"), preventing off-screen hits.
3. **X dead zone:** Minor horizontal corrections (dodge repositioning) no longer drag the camera, improving stability.
4. **Z-axis arena bounds:** Belt-depth movement now camera-constrained during encounters, matching the paper's depth-lane readability principle.
5. **Enemy centroid bias:** Camera pulls toward enemy group center during arena locks ("never hide an enemy who can hit you").
6. **Dynamic FOV zoom:** FOV widens with enemy count during encounters, keeping threats visible.
7. **Director cue system:** Event-driven camera cuts for boss intros/set-pieces via new EventBus signals.
8. **Velocity cap:** Prevents camera whip on teleport or lag spikes.
9. **Real-time trauma:** Shake now uses Time.get_ticks_usec() instead of physics delta, remaining active during hitstop.
10. **Constants compliance:** All camera tuning values pulled from Constants autoload (zero hardcoded values).

**Priority stack (when principles conflict):** arena bounds > threat visibility > look-ahead > dead zone > breathing.

**Alternatives Considered:**
- Keep CameraShakeSystem alongside CameraFollow: Causes double-shake, two systems managing the same camera.
- Per-enemy threat tracking vs group-based centroid: Group query is simpler and O(n) per frame, which is fine for belt-scroller enemy counts (<20).
- Camera state machine with explicit modes (FOLLOW, ARENA_LOCK, DIRECTOR, BOSS_FIGHT): Decided on two modes (FOLLOW, DIRECTOR) since arena lock is a constraint layer, not a separate mode.
- Co-op multi-target framing: Deferred to MVP 5 per project plan. Constants for zoom min/max are in place.

---

## 2026-03-02 — Unified InputIntentBuffer for Input Responsiveness

**Decision:** Replace per-state `Input.is_action_just_pressed()` polling with a centralized `InputIntentBuffer` (RefCounted component) that records all action inputs in real time and lets states consume buffered intents.

**Why:** Multiple responsiveness problems existed:
1. **Hitstop ate inputs:** `Engine.time_scale = 0` stops `_physics_process`, so all `is_action_just_pressed` polls were missed during hitstop freeze.
2. **Only jump had a buffer:** Attack, dodge, and technique inputs required frame-perfect timing.
3. **Landing dropped actions:** The land state only checked movement after recovery — attack/dodge/technique pressed during landing were silently lost.
4. **Cancel windows were instant-poll:** Missing a cancel (heavy, dodge, launcher) by one frame felt unresponsive.
5. **Hurt exit was always idle:** No way to mash dodge or attack during stun for immediate post-recovery action.

**Architecture:**
- `InputIntentBuffer` is a pure RefCounted component (TDD-testable, no scene tree dependency).
- Uses `Time.get_ticks_usec()` real-time timestamps (injectable clock for tests).
- Five categories: `attack_light`, `attack_heavy`, `attack_launcher`, `dodge`, `technique`.
- Last-intent-wins policy within each category.
- Category-specific buffer windows: `ACTION_BUFFER_WINDOW` (133ms for attacks), `DODGE_BUFFER_WINDOW` (133ms), `TECHNIQUE_BUFFER_WINDOW` (100ms).
- PlayerController samples inputs in `_process()` with `PROCESS_MODE_ALWAYS` — runs during hitstop.
- States consume via `intent_buffer.consume(&"category")` instead of `Input.is_action_just_pressed()`.
- `clear_all()` on hurt entry and death to prevent stale intents leaking across hard state changes.

**States Updated:** idle, run, land, attack_light (cancel window + combo chain), attack_heavy (dodge cancel), attack_launcher (dodge cancel added), technique (dodge cancel), dodge (post-dodge action buffer), hurt (post-stun action buffer), dead (clear on death).

**Alternatives Considered:**
- **Ring buffer / queue:** More complex, and last-intent-wins is the correct behavior for fighting games (later input supersedes earlier).
- **Delta-based buffer tick:** Would still be affected by time scale. Real-time ticks are immune to hitstop.
- **Per-state local buffers:** Would duplicate logic across 12 states. Centralized component follows existing project patterns (HealthComponent, ComboTracker, etc.).
- **Unreal-style input buffering in StateMachine:** Would couple the FSM to player-specific logic. Keeping it as a component maintains separation.

**Trade-off:** Slight indirection (consume call vs direct poll), but eliminates an entire class of "my input didn't register" frustration.

---

## 2026-03-02 — CharacterDef Resource for 4 Playable Characters

**Decision:** Each playable character (Alys, Chaz, Rune, Wren) is defined by a `CharacterDef` Resource containing base stats, combo chain (Array[AttackDef]), heavy/launcher attacks, techniques (Array[TechniqueDef]), model paths, and skill tree reference. `Constants.CHARACTER_DEFS` maps character IDs to resource paths.

**Why:** Mirrors the existing `EnemyDef` pattern. Data-driven design means adding a new character requires only a new `.tres` file — zero code changes. Attack states read from `player.character_def.combo_chain[]` with fallback to preloaded defaults for backward compatibility.

**Alternatives Considered:**
- Hardcoded per-character classes: Would require a class per character with near-identical logic.
- GDScript dictionaries: Less type safety, no editor preview.

---

## 2026-03-02 — Elemental System: Weakness/Resistance + Status Effects

**Decision:** Four elements (fire, ice, lightning, dark) each map to a status effect (burn, freeze, shock, bleed). `ElementCalculator` computes damage multipliers (1.5x weakness, 0.5x resistance) and rolls status effects. `StatusEffectTracker` manages active effects per entity with gameplay modifiers (burn=DOT, freeze=speed reduction, bleed=damage-taken multiplier).

**Why:** Pure RefCounted components with zero scene dependency — fully TDD-testable. Both `PlayerController` and `EnemyController` hold their own `StatusEffectTracker`. Effects tick in `_physics_process` alongside existing update logic.

**Alternatives Considered:**
- Node-based status effects: Would require scene tree, harder to test.
- Global status effect manager: Would couple entities to a singleton.

---

## 2026-03-02 — RPG Stat Integration via Backward-Compatible API Extension

**Decision:** `CombatSystem.process_hit()` extended with optional RPG params (defense, attacker_stat, stat_scale, element_multiplier, damage_taken_multiplier) that default to neutral values. `DamageCalculator.calculate_full()` added alongside existing `calculate()`. All existing callers work unchanged.

**Why:** Hundreds of existing combat interactions use the simple API. Breaking changes would cascade through every enemy and state. Default params preserve backward compatibility while enabling full RPG stats when available.

---

## 2026-03-02 — Character Switching in Dungeon (Q/E Keys)

**Decision:** During dungeon gameplay, Q/E (or LB/RB on controller) rotate the active party member. The current character's HP/TP is saved to `GameState.character_data`, then `PlayerController._load_character_from_game_state()` reloads with the new character's def, stats, and HP. Cooldown prevents rapid switching.

**Why:** Single `PlayerController` instance handles all characters — no scene swap needed. `_load_character_from_game_state()` already handles CharacterDef loading and stat restoration, so switching is just a data swap.

---

## 2026-03-02 — XP Awarded on Dungeon Completion (Not Per-Kill)

**Decision:** XP accumulates in `DungeonManager._dungeon_xp` during the run (summing `EnemyDef.xp_reward` per kill) and is banked to all `GameState.active_party` members on dungeon completion. XP is lost on dungeon failure (same as gold).

**Why:** Matches the roguelike dungeon tension design — dying means losing dungeon progress including XP. This creates risk/reward decisions about when to push deeper vs. retreating. Party-wide XP prevents inactive characters from falling behind.

**Alternatives Considered:**
- Per-kill immediate XP: Would allow mid-dungeon level-ups but reduce tension.
- Active-only XP: Would punish character switching.

---

## 2026-03-02 — UI Glass-Morphism Unification

**Decision:** Unified all UI screens to a glass-morphism visual language matching the title screen. `UIStyle.style_button()` now creates left-accent-only glass buttons (3px left border, ultra-transparent bg, accent glow shadows). `UIStyle.create_panel_style()` enforces transparency (alpha cap 0.55), thin 1px borders, and 6px max corner radius. New `create_glow_orb()` provides animated moving glow shader. `apply_screen_effects()` now layers glow orb + particles + vignette + scanlines.

**Why:** The title screen had a polished, award-winning look while all other screens used an older boxy style (4-border, opaque panels, 12px corners). By centralizing the glass-morphism in `UIStyle`'s existing public API (`style_button`, `create_panel_style`), all 10+ callers across every screen auto-upgraded without per-file style changes. Title screen refactored to use shared helpers (DRY). HUD panels use direct StyleBoxFlat overrides with higher alpha (0.6-0.7) for combat readability.

**Screens Updated:** splash, title, main menu, pause menu, save/load, overworld, town, party, defeat, victory, HUD.

**Alternatives Considered:**
- Per-screen custom styles: Would require maintaining 11+ unique style sets.
- Godot Theme resource (.tres): Would lose the code-driven animation capabilities (glow pulses, press feedback).

---

## 2026-03-02 — Continuous Stage System (Beads on a String)

**Decision:** Implemented continuous scrolling stages alongside the existing room-based dungeon system. DungeonDef gained an optional `stage_def: StageDef` field — when present, StageRunner loads tiled chunk scenes along the X axis and places EncounterTrigger Area3D zones that activate fights as the player walks forward. WaveSystem, CameraFollow, and PlayerController required zero changes — the existing arena lock + room bounds clamping handles both modes.

**Why:** Room-based dungeons created a stop-start rhythm (load -> fight -> fade -> load) that broke beat-'em-up flow. Continuous stages preserve forward momentum between encounters, matching classic belt-scrollers like Streets of Rage and Guardian Heroes.

**Alternatives Considered:**
1. Infinite procedural stage — Too complex for MVP, loses handcrafted pacing
2. Single giant scene — No modularity, can't reuse chunks across stages
3. Replace rooms entirely — Breaking change, loses existing content

**Key Files:** stage_def.gd, stage_runner.gd, encounter_trigger.gd, dungeon_run.gd, dungeon_manager.gd

---

## 2026-03-02 — PS4 Theming for Hub Screens

**Decision:** Replace all cyberpunk placeholder content in the Overworld and Town hub screens with Phantasy Star IV lore-accurate names, descriptions, and dialogue.

**Why:** The game's identity is rooted in Phantasy Star IV. The hub screens are the player's primary navigation interface and should reinforce the world-building. Cyberpunk placeholders ("Bangkok Night Market", "Equipment Synth", "Data Broker") broke thematic immersion. PS4 locations (Piata Academy, Birth Valley, Zema) and characters (Alys, Hahn, Rune) ground the player in the Algo star system.

**What Changed:**
- Overworld entries: Piata Academy (town), Piata Basement (dungeon), Birth Valley (dungeon), Zema (petrified town)
- Town entries: Hunter's Guild Office, Academy Weapons Shop, Piata Inn, Academy Library
- Dialogue speakers: Alys Brangwin, Hahn Mahlay, Shopkeeper, Innkeeper
- OverworldNodeDef descriptions updated to reference Bio-monsters, petrification, and the Great Collapse
- Added data-driven `dialogue_header` field to HubScreenData (overworld: "HUNTER COMMS", town: "TOWN TALK")
- UI refinements: entry transition fade animation, button sound wiring, stagger entrance, vignette + scanline overlays

**Alternatives Considered:**
1. Original Phantasy Star IV names only — Too literal, limits creative freedom for original story beats
2. Fully original names — Loses the PS4 identity the game is built around
3. Hybrid approach (chosen) — Use PS4 location names and characters, with original descriptions that hint at the game's unique plot

**Key Files:** overworld_hub_screen.tres, town_hub_screen.tres, split_hub_screen.gd, hub_screen_data.gd, node_*.tres, piata.tres

---

## 2026-03-03 — Save System Hardening with Version Gate and Backup Recovery

**Decision:** Added `SAVE_VERSION` to Constants, version gate in `deserialize_persistent()` (rejects future versions), per-field type-safe parsing with graceful fallback to defaults, `get_save_metadata()` static helper for slot previews, and backup file recovery in `SaveManager.load_game()`.

**Why:** Save files can be corrupted, manually edited, or come from future versions. Type-safe deserialization prevents crashes from malformed data. Backup recovery (primary → `.backup` fallback) prevents total progress loss. Metadata extraction enables rich slot previews (party names, gold, level) without loading the full game state.

**Alternatives Considered:**
- Schema migration system: Overkill for current save complexity; version gate is sufficient.
- No backup: Simpler but risks total progress loss on file corruption.
- In-memory metadata cache: Would add memory overhead; on-demand parsing from file is fast enough for 3 slots.

---

## 2026-03-03 — Dual Keyboard + Joypad Remapping in Single Screen

**Decision:** ControllerSettings shows both keyboard and joypad bindings per action in a two-column layout. Each column has its own Remap button. Keyboard remapping (`remap_action_keyboard`) only touches `InputEventKey` events; joypad remapping (`remap_action_joypad`) only touches `InputEventJoypadButton` events. Both persist separately via ConfigFile.

**Why:** Players may use keyboard on PC and controller on Android/PC. Showing both in one screen prevents the confusion of "where did my keyboard bindings go?" Selective event removal (only removing events of the same type) ensures remapping keyboard never destroys joypad bindings and vice versa.

**Alternatives Considered:**
- Separate keyboard and controller screens: More clicks, harder to compare bindings.
- Combined events per action: Would make it impossible to have different keyboard and joypad mappings for the same action.

---

## 2026-03-03 — Unified Settings Menu with Tab Sidebar

**Decision:** Created `SettingsMenu` as a code-only CanvasLayer with three tabs (Audio, Display, Controls). Audio tab consolidates Master/Music/SFX sliders + Mute from the old pause menu. Display tab adds Fullscreen and Scanlines toggles. Controls tab shows binding summary and opens ControllerSettings for remapping.

**Why:** Settings were scattered across pause menu (audio), controller settings (joypad only), and hardcoded (display). Unifying into one tabbed screen provides a standard game settings experience accessible from both pause menu and title screen.

**Alternatives Considered:**
- Keep settings in pause menu: Would require duplicating access from title screen.
- Separate Audio/Video/Controls screens: Three separate modals add navigation complexity.

---

## 2026-03-03 — Touch Controls via Input.parse_input_event()

**Decision:** Touch controls inject synthetic `InputEventAction` events via `Input.parse_input_event()` rather than using `InputManager.inject_touch_*()` tracker API.

**Why:** `PlayerController` reads input via global `Input.get_axis()` and `Input.is_action_just_pressed()`, not the per-player tracker API. Synthetic InputEventAction events are processed by the global Input system, ensuring compatibility with existing code paths. The joystick maps screen touch position to analog strength for movement actions. Buttons map 1:1 to combat actions.

**Alternatives Considered:**
- Refactor PlayerController to use per-player tracker API: Would touch many files and states for no PC-visible benefit.
- Custom input provider pattern: More abstraction than needed for single-player mobile.

---

## 2026-03-03 — Android Touch Auto-Detect with Controller Fallback

**Decision:** `InputManager.should_show_touch_controls()` returns true only on mobile platforms with no connected controller. On controller connect/disconnect, `input_touch_visibility_changed` signal toggles TouchControls visibility. GameManager spawns TouchControls only on mobile.

**Why:** Android supports both touch and controller play. Players who connect a controller don't want touch overlays cluttering the screen. Auto-detection via `Input.get_connected_joypads()` handles this without user configuration.

**Alternatives Considered:**
- Always show touch on Android: Would overlap with controller buttons.
- Manual toggle in settings: Extra step for users; auto-detect is more intuitive.
