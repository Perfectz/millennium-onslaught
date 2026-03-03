# PROJECT PLAN — Godot 4 Belt-Scroller Beat-'Em-Up

> **Purpose:** Primary steering document for AI-driven development. Every AI agent working on this project reads this file first. It defines WHAT to build, WHY, and what constraints to follow — never HOW to code it. The AI decides implementation; this document constrains its decisions.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Multi-MVP Roadmap](#2-multi-mvp-roadmap)
3. [Architecture](#3-architecture)
4. [Lessons Learned](#4-lessons-learned)
5. [Definition of Done](#5-definition-of-done)
6. [Backlog](#6-backlog)
7. [Tooling & Workflow](#7-tooling--workflow)

---

## Three Foundational Principles

These principles are not optional. They are a lens applied to every decision, every MVP, every system.

### Principle 1 — Test-Driven Development (TDD)

Every feature begins with a failing test. The AI writes the test first (describing what should happen), then writes the minimum code to make it pass, then refactors. This cycle is mandatory for all pure logic: components, state machines, save/load serialization, data validation, encounter generation, score calculation, stat formulas.

**What is testable:** Anything that can run without Godot's scene tree — pure logic components (health, stats, equipment, combos), state machine transitions, data integrity checks, serialization round-trips, math utilities.

**What is play-verified only:** Rendering, physics feel, camera behavior, audio, input responsiveness, visual effects. These are verified through the MVP gate protocol (build, run, play, visual check, Android check) rather than automated tests.

Per-MVP acceptance criteria must map to test cases wherever the behavior is testable. "Damage formula applies correctly" is a test. "The hit feels crunchy" is a play-verify.

### Principle 2 — APIE (Abstraction, Polymorphism, Inheritance, Encapsulation)

The architecture enforces clean object-oriented design:

- **Abstraction:** Systems expose clear interfaces describing what they do, not how. The combat system works with "an entity that can attack and take damage" — it does not care whether that entity is a player or enemy. Data resources hide internal structure behind purpose-named methods.
- **Polymorphism:** Adding a new enemy type, character type, or attack type means creating a new data resource and plugging it in — not modifying existing system logic. Different types share a common interface but behave differently.
- **Inheritance:** Used sparingly and shallowly. Maximum two levels deep. A boss is an enemy with added phase logic. A technique is an attack with a TP cost. If inheritance goes deeper than two levels, the design is wrong — use composition instead.
- **Encapsulation:** Components own their data and expose only what outsiders need. The health component manages HP internally and announces "I died" — nothing else sets HP to zero directly. The inventory does not let outsiders rearrange its slots.

### Principle 3 — AI-Navigable Documentation & Indexing

The project must be self-documenting so any AI agent can drop in cold and orient itself immediately:

- **INDEX.md at project root:** Master index of every system — where it lives, what it does, what it depends on. Updated after every MVP.
- **Per-folder README.md:** Every folder with more than three files gets a README explaining contents, naming conventions, and how to add new things to that folder.
- **Inline doc comments:** Every public class and public method gets a one-line description. Not verbose — just enough for an AI to grep and understand purpose.
- **Event catalog:** A maintained document listing all event bus signals — name, payload description, who emits it, who listens. This is the nervous system of the project.
- **Data schema docs:** Each resource type (character definitions, enemy definitions, attack definitions, etc.) documented with all fields, valid ranges, and at least one example.
- **DECISIONS.md:** Running log of architectural decisions — date, what was decided, why, what alternatives were considered. When a future AI agent asks "why is it done this way?", the answer lives here.

Documentation is a **deliverable of every MVP**, not an afterthought.

---

## 1. Executive Summary

### Game Pillars

1. **Crunchy Combat Feel** — Every attack has impact. Screen freezes on contact. Camera shakes on heavy hits. Particles burst on kills. Audio punches on every connection. No hit ever feels empty.

2. **Deep Combo Mastery** — Characters have multi-step combo chains with branch points. Light attack chains into heavy. Launchers send enemies airborne for juggle combos. Cancel windows let skilled players flow between offense and defense. Easy to mash, rewarding to master.

3. **JRPG Soul** — A node-based overworld map connects towns and dungeons. Towns offer shops, inns, and NPC dialogue. Story progression unlocks new areas. The game has a beginning, middle, and end — with characters, narrative, and a sense of journey.

4. **Roguelike Dungeon Tension** — Every dungeon entry carries risk. Enemy encounters randomize each time. Die and you restart the dungeon, losing temporary buffs and dungeon-only drops while keeping all permanent RPG progress. Each run through a dungeon feels different even though the room layouts are familiar.

5. **Couch Co-op Chaos** — Up to four players share one screen. Team combos, revive mechanics, proximity buffs. The game is fun solo, but built to be better with friends on a couch.

### Core Loop (Player Experience)

You open the overworld map and choose where to go. Visit a town to buy equipment, rest at the inn, hear rumors from NPCs. Enter a dungeon. Fight through a series of rooms — platforming across ledges, brawling through waves of enemies, finding temporary power-ups. Reach the boss. Beat it — or die trying and get kicked back to the overworld, still stronger than when you went in. Complete the dungeon to unlock the next leg of the journey. Repeat with harder dungeons, better gear, deeper combo mastery, and new characters joining the party.

### Display & Resolution

- **Base Resolution:** 1920x1080 (Full HD). This is the design resolution — all UI layout and game camera framing targets this.
- **Stretch Mode:** `canvas_items` — the 2D UI layer scales cleanly across screen sizes while the 3D viewport renders at the device's native resolution for maximum visual quality.
- **Aspect Mode:** `expand` — the game fills the screen on wider or taller displays without letterboxing, expanding the visible area instead.
- **Anti-Aliasing:** MSAA 2x for the 3D viewport. Crisp edges on geometry without excessive GPU cost.
- **Android Rendering:** ETC2/ASTC texture compression enabled. The game should look sharp and modern on Android — not a scaled-down afterthought. Touch UI elements are sized for the full 1080p canvas.

### Platform Targets

- **PC:** Buttery 60fps at 1920x1080 or higher. Keyboard and controller support. The primary development platform.
- **Android:** Smooth 30fps with touch controls at native device resolution. Virtual joystick and action buttons sized for real fingers on a 1080p+ screen. Must be easy to build and test throughout development — not an afterthought bolted on at the end.

### What "Done" Looks Like

The complete game has: 5–8 playable characters with distinct movesets, 4+ dungeons with unique themes and bosses, 3+ towns with shops and story, a complete narrative arc from start to finish, 4-player local co-op, an Android APK, full RPG progression that feels meaningful after 10+ hours, and roguelike dungeon variety that keeps runs feeling fresh.

---

## 2. Multi-MVP Roadmap

### MVP 1 — "First Punch"

**Goal:** One character can move around a test arena, jump on platforms, and punch one enemy type to death. The hit feels good.

**Acceptance Criteria (observable in a running build):**
- I press a direction and the character runs. It feels responsive and immediate.
- I press jump and the character arcs into the air. It feels weighty — fast on the way up, heavy on the way down.
- I can land on elevated platforms and walk along them.
- I can nudge forward and backward into the screen slightly for tactical positioning (belt-depth). This is subtle, not a lane system.
- I press the attack button and the character swings. A three-hit combo plays if I keep pressing.
- I press heavy attack and a slower, more powerful swing plays.
- I press dodge and the character rolls with a burst of speed and brief invincibility.
- When my attack connects with the enemy, the screen freezes for a split second, the camera shakes, and a particle burst appears at the contact point. The hit has CRUNCH.
- The enemy takes damage. After enough hits, the enemy dies with a death effect.
- I can restart the arena.

**Systems Needed:** Player movement with platforming physics, belt-depth nudge movement, basic combo chain (three light attacks), heavy attack, dodge roll with invincibility frames, hitbox/hurtbox collision detection, hitstop (brief engine freeze on hit), camera shake, basic particle effects, one enemy type that walks toward the player and swings.

**Content:** All placeholder models (capsules, boxes, colored shapes). One flat arena with three platforms at different heights. One enemy type (simple melee rusher).

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| 2.5D depth sorting looks wrong | Using full 3D scene with real 3D renderer — depth sorting is automatic |
| Jump feel is floaty or stiff | Tune coyote time, jump buffering, and gravity curves early — this is the most important feel element |
| Hitstop implementation breaks animations or timers | Research Godot's process mode groups before implementing — allow exclusions |

**Demo Checklist:** Run the build. Move around. Jump on platforms. Punch the enemy until it dies. Confirm every hit feels impactful. Restart and do it again.

**TDD Targets:** Health component (take damage, die at zero), combo step transitions (light 1 → light 2 → light 3), state machine transitions (idle → run → jump → fall → land), damage calculation.

**Documentation Deliverable:** Initial INDEX.md, initial DECISIONS.md with rendering approach rationale, event catalog with first events.

---

### MVP 2 — "The Dungeon"

**Goal:** A complete dungeon run exists — enter, fight through multiple rooms with different enemy types, face a boss, die or win.

**Acceptance Criteria:**
- I enter a dungeon and arrive in the first room.
- Enemy waves spawn in each room. The camera locks to the arena until all enemies in the wave are defeated.
- There are at least three visually and behaviorally distinct enemy types: one that rushes and melees, one that attacks from range, and one that blocks or has a shield.
- I can launch enemies into the air and juggle them with attacks. There is a juggle limit — after enough air hits, they get knocked down hard.
- My combo chain has branch points: during certain moments I can switch from light to heavy, or cancel into a dodge, or use a technique.
- A HUD shows my health, my technique points, and a combo hit counter.
- After clearing all rooms, I fight a boss with at least two distinct phases (behavior change at half health).
- If I die, I see a "Dungeon Failed" screen and return to a restart point.
- If I beat the boss, I see a victory screen showing kills, time, and score.

**Systems Needed:** Multiple enemy types with distinct AI behaviors, wave/encounter spawning with arena-lock camera, juggle system with airborne state and juggle counter limit, combo cancel windows defined in attack data, technique points gauge, HUD overlay, dungeon room sequencing (progress through rooms linearly), boss with phase transitions, death and victory flows.

**Content:** Placeholder models still fine. Four rooms with varied platform layouts. Three enemy types. One boss. HUD elements can be simple UI.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Enemy AI feels unfair (frame-perfect reactions) | Add reaction delays. Use token system so only a few enemies attack at once — others circle and wait |
| Juggle combo loops feel infinite and cheesy | Enforce juggle limit from day one. Ground bounce after limit reached. |
| Camera arena-lock transitions feel jarring | Smooth transition into and out of arena lock — ease the bounds, do not snap |

**Demo Checklist:** Enter dungeon. Fight through four rooms. See different enemy behaviors. Juggle an enemy in the air. Get hit and see health drop on HUD. Reach boss. Die to boss (or beat it). See end screen. Also test: what happens if you die in room 2 — does it restart cleanly?

**TDD Targets:** Enemy spawn validation (encounter data produces correct enemy counts), juggle counter logic (increment, limit, reset on ground), combo cancel window logic (accept input only during defined frames), score calculation.

**Documentation Deliverable:** Update INDEX.md with all new systems. Document all new event bus signals. Document enemy definition schema and attack definition schema.

---

### MVP 3 — "The World"

**Goal:** The JRPG wrapper exists — overworld map, at least one town, and the dungeon is entered from the overworld. Story progression gates access.

**Acceptance Criteria:**
- I see a node-based overworld map. Nodes are connected by paths. I can navigate between connected nodes.
- One node is a town. When I select it, a menu appears with options: Shop, Inn, NPCs, Leave.
- The shop shows equipment I can buy with gold. I can buy an item and it appears in my inventory.
- The inn restores my party's health to full for a gold cost.
- NPCs display dialogue that hints at the story and where to go next.
- One node is a dungeon. When I select it, I enter the dungeon from MVP 2.
- Enemies in the dungeon drop gold.
- When I complete the dungeon (beat the boss), I return to the overworld map and a new node (next dungeon or next town) becomes accessible.
- A story flag system controls which nodes are locked and unlocked.
- I can save my game from the overworld. Loading restores me to the overworld with all my gold, inventory, and story progress intact.

**Systems Needed:** Node-based overworld map with navigation, story flag system (simple key-value store of completed events), menu-based town (shop, inn, NPC dialogue), gold currency earned from dungeon enemies, inventory for purchased equipment, save/load that persists all RPG state, scene transitions between overworld, town, and dungeon.

**Content:** Overworld map with 3–4 nodes (1 town, 1 dungeon, 1 locked town, 1 locked dungeon). Town with 5–6 shop items. Basic NPC dialogue (3–4 lines each for 2–3 NPCs). All visuals can be simple/placeholder.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Save file corruption from mid-write crash | Write to temporary file first, then atomic rename to final path |
| Overworld map navigation feels clunky on controller | Design input for controller-first (D-pad between nodes, confirm to enter) — keyboard mirrors it |
| Scene transition leaks memory (nodes not freed from previous scene) | Audit node cleanup on every scene change. Use the event bus to signal "scene is closing — clean up." |

**Demo Checklist:** Boot game. See overworld. Navigate to town. Buy something from shop. Rest at inn. Read NPC dialogue. Navigate to dungeon. Enter dungeon, fight, beat boss. Return to overworld. See new node unlocked. Save game. Quit. Reload. Verify everything persisted. Also test on Android: does touch navigation work on the overworld map?

**TDD Targets:** Save/load serialization round-trip (save state, load state, verify identical), shop transaction logic (buy reduces gold, adds item; cannot buy without enough gold; sell increases gold, removes item), story flag logic (set flag, check flag, flag gates node access), gold accumulation from kills.

**Documentation Deliverable:** Update INDEX.md. Document town definition schema, dungeon definition schema. Document save file format. Add all overworld/town events to event catalog.

---

### MVP 4 — "RPG Depth"

**Goal:** The RPG systems are layered in — leveling, stat allocation, equipment effects, multiple characters with unique movesets, techniques, and a skill tree.

**Acceptance Criteria:**
- Killing enemies awards XP. When I earn enough XP, my character levels up.
- On level up, I allocate points into stats: Strength, Magic, Defense, Agility. These visibly affect gameplay — more Strength means more damage, more Agility means faster attacks.
- I can equip weapons, armor, and accessories. Each piece changes my stats. Accessories can grant passive effects (critical hit chance, HP regeneration, elemental resistance).
- There are 3–4 playable characters, each with a unique combo chain and unique techniques.
- I can switch between characters in my party (during dungeon or from a menu).
- Techniques are special moves that cost TP. Each character has different techniques with different elements (fire, ice, lightning, dark). Elements have effects on enemies (burn, freeze, shock, bleed).
- A skill tree lets me spend points on permanent passive upgrades per character.
- Enemy drops include equipment, not just gold.
- The shop inventories in towns vary — later towns sell better gear.

**Systems Needed:** XP and leveling with stat allocation UI, equipment system with stat modifiers and passive effects, accessory passive system (read passives each frame, apply to stats), 3–4 character definitions with unique combo data and technique lists, party system (roster, active party selection, character switching in dungeon), technique system (TP cost, elemental damage, status effects), skill tree (permanent passive nodes with prerequisite chains), drop tables (enemies drop equipment based on rarity tiers), varied shop inventories per town.

**Content:** 3–4 character definitions with stats, combos, and techniques. 20–30 equipment items across weapon, armor, and accessory categories. Skill tree layout per character (10–15 nodes each). Drop tables for existing enemies. Shop inventories for 2+ towns.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Stat system makes some characters useless at high levels | Define stat scaling curves in data and test with automated balance simulations |
| Passive accessories stack into broken combos | Cap passive values in the stat component — no passive can exceed defined maximums |
| Too many RPG screens bog down pacing | Keep every RPG menu snappy — enter, make choice, exit in seconds. No nested sub-menus deeper than one level |

**Demo Checklist:** Kill enemies, level up, allocate stats, see damage increase. Equip a weapon, see attack change. Equip an accessory with crit chance, see occasional critical hits. Switch between characters mid-dungeon. Use a technique, see TP drain and elemental effect on enemy. Open skill tree, unlock a node, see its effect apply. Buy better gear at a later town.

**TDD Targets:** XP accumulation and level threshold logic, stat allocation (points available, apply, verify stat changes), equipment stat modification (equip item, verify derived stats change correctly), passive effect calculation (stack multiple accessories, verify correct totals with caps), technique TP cost and availability logic, skill tree prerequisite validation, drop table probability distributions.

**Documentation Deliverable:** Update INDEX.md. Document character definition schema (full with combos and techniques), equipment definition schema (with passives), skill tree definition schema. Update event catalog with all RPG events.

---

### MVP 5 — "The Stage"

**Goal:** Replace discrete room-by-room dungeon transitions with continuous, flowing stages. Players walk seamlessly from entrance to boss through connected encounter zones and traversal segments — no loading screens, no fade-to-black. The dungeon feels like one continuous journey inspired by Castle Crashers' "beads on a string" model.

**Acceptance Criteria:**
- I enter a dungeon and experience a continuous stage — no fade-to-black room transitions. I walk forward from the entrance and the stage unfolds ahead of me.
- The stage is composed of modular chunks that tile seamlessly along the X axis. I never see a seam or gap between chunks.
- Encounter zones ("beads") trigger when I enter them. Enemies spawn and the camera frames the fight area. A soft barrier (enemy pressure + camera leading) discourages me from running past, but there are no invisible walls.
- Between encounters, traversal segments ("string") provide walking space with light platforming, environmental props, and visual breathing room. I can see the next area approaching.
- Environmental interactables exist: I can pick up barrels and crates and throw them at enemies for damage. Hazard zones (spike pits, fire columns) damage anyone who enters them — enemies included.
- The pacing follows a clear rhythm: encounters escalate in intensity with breathers between peaks. The stage builds toward the boss.
- The boss encounter is a purpose-built wider area at the end of the stage with no forward exit until the boss is defeated.
- Camera movement is continuous: it follows me through traversal, widens during encounters, and never hard-cuts between areas.
- Chunks load ahead of the player and unload behind, keeping memory use bounded.
- The Piata Basement (dungeon_1) is rebuilt as a continuous stage with 8–10 chunks.
- The existing room-based test arena still works unchanged.

**Systems Needed:** Stage chunk system (modular Node3D chunks that tile along X with standardized connection points), StageDef resource (ordered chunk sequence with encounter triggers, interactable placements, hazard positions, and pacing metadata), encounter trigger zones (Area3D activation replacing room-enter triggers, multiple triggers per chunk), soft gating (camera leading + forward enemy spawn pressure during active encounters, no invisible walls), environmental interactables (pickup/throw system for barrels/crates, hazard damage zones with VFX), chunk streaming manager (sliding window around player X, load ahead, unload behind), stage-aware DungeonManager (detect StageDef vs legacy DungeonDef, delegate appropriately), continuous camera mode (smooth follow in traversal, soft framing in encounters).

**Content:** Piata Basement rebuilt as continuous stage (8–10 chunks: 2 traversal intro, 3 escalating encounter zones, 2 traversal breathers, 1 boss arena, 1 post-boss). 3 throwable prop types (barrel, crate, rock). 2 hazard types (spike pit, fire column). StageDef resource for dungeon_1.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Memory pressure from many simultaneous chunks | Stream chunks in a 3-chunk window (current ± 1). Profile on Android. Keep chunks lightweight. |
| Visible seams between chunks | Standardize connection points (matching floor height + edge alignment). Use fog or particles to mask distant transitions. |
| Soft gating feels too loose — players run past encounters | Camera leading + forward enemy spawns create natural pressure. If player runs too far ahead, spawn a pursuit wave. |
| Environmental interactables break combat balance | Throwables deal moderate fixed damage. Hazards damage enemies too. Hazards are avoidable. |
| Backwards compatibility with existing room-based dungeons | DungeonDef room-based flow remains unchanged. StageDef is a parallel path, not a replacement. DungeonRun checks which type. |
| Chunk authoring is tedious | Create a chunk template scene with connection point markers and standard floor. Document authoring conventions in README. |

**Demo Checklist:** Enter the Piata Basement. Walk forward — see the stage unfold continuously. Reach the first encounter zone — enemies spawn, camera frames the fight. Defeat them. Walk forward through a traversal segment — platforms, props. Enter a harder encounter. Pick up a barrel and throw it at an enemy. Walk through a hazard zone — dodge spikes. Reach the boss area. Fight the boss. Win. See victory screen. Also: open the test arena — verify old room-based system still works.

**TDD Targets:** Chunk window calculation (which chunks to load given player X position), encounter trigger activation logic (enter zone → start, all dead → complete), StageDef validation (chunks connected, encounters reference valid defs), interactable damage calculation (throwable impact, hazard tick), soft gating offset calculation (camera lead amount based on encounter distance).

**Documentation Deliverable:** Update INDEX.md with stage chunk system, encounter trigger system, interactable system. Document StageDef schema in docs/schemas/. Document chunk authoring conventions in scenes/dungeon/chunks/README.md. Add stage-related events to event catalog. Update DECISIONS.md with "Continuous Stage Design" rationale.

---

### MVP 6 — "Together"

**Goal:** Four players can play on one screen. Android build works with touch controls. Settings and save system are production-ready.

**Acceptance Criteria:**
- Player 1 uses keyboard. Players 2–4 use controllers. All four can move, fight, and use techniques independently.
- The camera smoothly follows all four players. If players spread out, the camera zooms out to contain everyone. If a player reaches the edge, they feel a soft push back toward center.
- When a player is knocked out in a dungeon, another player can stand near them and hold a button to revive them.
- Co-op synergy exists: when two specific characters use techniques near each other, a combination attack triggers.
- The Android APK installs and runs. Touch controls appear: virtual joystick on the left, action buttons on the right. The game is playable through a full dungeon run with touch alone.
- A settings menu lets me adjust audio volume, rebind controls, and toggle fullscreen.
- Control remapping works for keyboard and controller.
- Save and load is robust — saving during any game state produces a valid file, loading from any save point restores correctly.

**Systems Needed:** Multi-device input management (map device index to player index), per-player HUD elements, shared camera with dynamic zoom and containment logic, revive mechanic, combination attack system (detect proximity + technique pair), Android export pipeline, touch input layer (virtual joystick and buttons), settings UI with audio/display/controls, control remapping with persistence, hardened save system.

**Content:** Touch control layout for Android. Settings menu design. Combination attack definitions for 2–3 character pairs. Revive animation/effect.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Shared camera with 4 players becomes chaotic | Define clear zoom limits — minimum and maximum zoom. Soft-push players at screen edge. Test with 4 moving in opposite directions |
| Android performance drops below 30fps with 4 players + many enemies | Profile early. Reduce particle counts on Android. Pool aggressively. Limit simultaneous enemies on mobile |
| Touch controls feel imprecise | Make virtual joystick dead zone generous. Make attack buttons large. Test with actual fingers on a real phone, not emulator |
| Controller hot-plug crashes or confuses player assignment | Handle connect/disconnect events gracefully. Show "Controller disconnected" prompt. Reassign on reconnect |

**Demo Checklist:** Four controllers plugged in. All four players in a dungeon. Fight through rooms together. One player dies, another revives them. Two specific characters trigger a combination attack. Open settings, change volume, remap a button. Save and quit. Reload — all four characters restored correctly. Then: install APK on Android phone. Play a full dungeon with touch controls. Verify 30fps.

**TDD Targets:** Input mapping logic (device to player assignment, remap persistence), save/load with multi-character party state, combination attack detection logic (correct character pair + proximity + technique match), revive proximity and timing logic.

**Documentation Deliverable:** Update INDEX.md. Document input mapping system, touch control layout, Android build process, combination attack schema. Update event catalog with co-op events.

---

### MVP 7 — "Ship It"

**Goal:** The game is complete and polished. Full content, full audio, full visual effects, accessibility, and a finished narrative arc.

**Acceptance Criteria:**
- 5–8 playable characters, each feeling mechanically distinct.
- 12+ enemy types spread across dungeon themes (desert, ice, tech, dark, etc.).
- 4+ dungeons, each with unique visual themes, platform layouts, and a unique boss.
- 3+ towns, each with different shop inventories and NPC dialogue relevant to the story.
- The story has a beginning (character introduced, threat established), middle (journey across regions, allies join), and end (final confrontation, resolution).
- Audio exists for every interaction: hits, kills, pickups, menu navigation, footsteps, ambient dungeon sounds. Music changes per context (overworld, town, combat, boss, victory, defeat).
- Visual effects feel complete: attack trails, elemental effects, death bursts, level-up fanfare, screen transitions.
- Daily challenge mode: a date-seeded dungeon run with fixed parameters. Leaderboard (local only).
- Accessibility: colorblind mode, difficulty options (enemy damage, player health, continues), input assist (auto-combo option).
- The game runs start to finish without crashes across a full playthrough on both PC and Android.

**Systems Needed:** Full audio system with SFX for every event and music state transitions, visual effect polish pass (attack trails, elemental particles, screen transitions, UI juice), daily challenge mode with seeded randomization, local leaderboard, difficulty settings, accessibility options, full story scripting system.

**Content:** 5–8 complete character definitions, 12+ enemy definitions, 4+ dungeon definitions, 3+ town definitions, full story script, all audio assets (AI-generated), all visual effect definitions. This is the content-heavy MVP.

**Risks & Mitigations:**
| Risk | Mitigation |
|------|------------|
| Content creation bottleneck (solo dev) | Use AI tools aggressively for asset generation. Establish asset pipelines early. Batch similar content (all enemy models at once, all music tracks at once) |
| Scope creep on "polish" | Define a fixed polish list before starting. When the list is done, ship. No infinite polishing |
| Story feels tacked on | Write the story outline during MVP 3 (when overworld is built). Let it influence dungeon themes and town placement from the start |
| Balance across 8 characters is impossible solo | Automated balance testing: simulate 1000 combats per character matchup using stat formulas. Flag outliers. Tune data resources, not code |

**Demo Checklist:** Play the full game from start to finish. Visit every town. Complete every dungeon. Use every character. Hear music in every context. See VFX on every attack type. Try daily challenge. Check accessibility options. Full playthrough on Android.

**TDD Targets:** Daily challenge seed consistency (same date = same dungeon layout), leaderboard sorting and persistence, difficulty modifier application to damage formulas, all character data completeness validation (every character has full combo chain, techniques, skill tree), all enemy data completeness validation.

**Documentation Deliverable:** Final INDEX.md covering the full project. All schemas documented. Complete event catalog. DECISIONS.md up to date. Per-folder READMEs complete. The project is fully navigable by any AI agent.

---

## 3. Architecture

### Folder Structure

```
res://
├── project.godot
├── INDEX.md                         # Master system index (AI reads this first)
├── DECISIONS.md                     # Architectural decision log
│
├── addons/                          # Third-party addons (test framework, input remapping)
│
├── autoloads/                       # Singleton services (registered in project.godot)
│   ├── README.md
│   ├── event_bus                    # Global signal hub — all cross-system communication
│   ├── game_state                   # Centralized state: persistent RPG + transient dungeon
│   ├── game_manager                 # Lifecycle orchestrator: phase transitions, pause, restart
│   ├── constants                    # Every tunable number lives here. Zero hardcoded values.
│   ├── object_pool                  # Pre-instantiation pool for frequently spawned objects
│   ├── audio_manager                # SFX pool + music player with crossfade
│   ├── save_manager                 # File-based save/load with atomic writes
│   └── input_manager                # Device-to-player mapping, context switching, remapping
│
├── scenes/                          # Everything that gets instantiated as a scene tree
│   ├── README.md
│   ├── characters/                  # Playable character scenes
│   ├── enemies/                     # Enemy type scenes
│   ├── bosses/                      # Boss scenes
│   ├── projectiles/                 # Technique projectile scenes
│   ├── dungeon/                     # Dungeon container + room scenes
│   │   ├── rooms/                   # Individual room layouts (fixed geometry)
│   │   └── dungeon_manager          # Room sequencing + encounter roller
│   ├── overworld/                   # Node-based map scene
│   ├── town/                        # Town menu scene
│   ├── ui/                          # All UI screens (HUD, pause, settings, menus, shop, etc.)
│   ├── vfx/                         # Particle and effect scenes
│   └── cutscene/                    # Story dialogue scenes
│
├── scripts/                         # All game logic
│   ├── README.md
│   ├── core/                        # Base abstractions (entity base, state machine, hitbox/hurtbox)
│   ├── components/                  # Pure logic components (NO scene tree dependency — testable)
│   ├── systems/                     # Game systems (combat, combo, wave, camera, VFX, drops, etc.)
│   ├── ai/                          # Enemy AI controllers and behavior definitions
│   ├── dungeon/                     # Dungeon-specific logic (room loading, encounter rolling)
│   ├── overworld/                   # Overworld map navigation logic
│   ├── town/                        # Town menu logic (shop transactions, inn, NPC dialogue)
│   ├── ui/                          # UI widget scripts
│   └── utils/                       # Math helpers, debug utilities
│
├── resources/                       # Custom Resource data files (.tres)
│   ├── README.md
│   ├── characters/                  # CharacterDef resources
│   ├── enemies/                     # EnemyDef resources
│   ├── attacks/                     # AttackDef resources (combo steps, techniques)
│   ├── equipment/                   # EquipmentDef resources
│   ├── encounters/                  # EncounterDef resources (wave configurations)
│   ├── dungeons/                    # DungeonDef resources (room list, encounter pool, boss)
│   ├── towns/                       # TownDef resources (shop inventory, NPCs, services)
│   ├── story/                       # StoryDef resources (dialogue scripts, flag triggers)
│   └── skills/                      # SkillTreeDef resources
│
├── assets/                          # Raw assets
│   ├── models/
│   ├── textures/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   ├── fonts/
│   └── shaders/
│
├── docs/                            # AI-navigable documentation
│   ├── schemas/                     # Data schema docs per resource type
│   └── events/                      # Event catalog
│
├── tools/                           # Debug and editor tooling
│   ├── debug/                       # Debug overlay scripts
│   └── editor_plugins/              # Custom Godot editor tools
│
├── tests/                           # GdUnit4 test files (mirrors scripts/ structure)
│   ├── unit/
│   │   ├── components/
│   │   ├── systems/
│   │   ├── utils/
│   │   └── data/
│   └── integration/
│
└── export/                          # Export configurations
    ├── android/
    └── pc/
```

### Composition Rules

**When to make a Scene (.tscn):** If it gets instantiated at runtime as a standalone thing — a character, an enemy, a room, a UI screen, a particle effect, a projectile. Scenes encapsulate their entire internal structure (Encapsulation). Nothing outside the scene should need to know what nodes are inside it.

**When to make a Node:** If it is a building block that lives inside a scene — a hitbox area, a hurtbox area, a state machine controller, an AI brain, an animation player. Nodes are the internal organs of scenes.

**When to make a Resource (.tres):** If it is pure data with no presence in the scene tree — character stats, attack definitions, equipment properties, encounter configurations, dungeon layouts, town inventories, story dialogue. Resources are the data layer. They are edited in the Godot inspector or via text, never by modifying logic scripts. All resource types share a common pattern (Abstraction): define fields, expose getters, validate on load.

**When to make an Autoload:** If exactly one instance should exist for the entire game and all systems need access — event bus, game state, constants, audio, saves, input, pooling, game management. Autoloads are the global services layer. Each one has a clearly defined role (Abstraction) and never does two things.

### Singleton Roles

| Singleton | Role |
|-----------|------|
| **Event Bus** | The only way systems communicate across boundaries. Typed signals with documented payloads. No system directly references another system. Signal names follow `domain_action` convention: `combat_hit_landed`, `dungeon_room_cleared`, `overworld_node_selected`, `rpg_level_up`. |
| **Game State** | Single source of truth for all game data. Split into persistent state (RPG: party roster, levels, stats, gold, inventory, equipment, story flags, skill trees) and transient state (dungeon-only: current room index, temp buffs, dungeon drops). `reset_dungeon()` clears transient state on death. `save()` and `load()` handle persistent state only. |
| **Game Manager** | Orchestrates game phase transitions: main menu, overworld, town, dungeon, cutscene, pause, game over. Manages scene loading and cleanup. Handles pause (freeze scene tree). The one place that knows "what phase are we in." |
| **Constants** | Every tunable number: movement speeds, gravity, jump velocities, attack frame timings, damage multipliers, camera shake intensities, UI animation durations. Zero hardcoded values in gameplay scripts. When someone wants to tune a feel parameter, they edit Constants, not logic. |
| **Object Pool** | Pre-instantiates and recycles frequently spawned objects: enemies, projectiles, VFX particles, damage numbers. Systems request objects from the pool instead of instantiating. Systems return objects to the pool instead of freeing. Prevents per-frame memory allocation. |
| **Audio Manager** | Maintains a pool of SFX players (8+ concurrent). Music player with crossfade between tracks. Listens to event bus signals and plays corresponding sounds. Manages mute state. Context-aware music states (overworld, town, dungeon, boss, victory). |
| **Save Manager** | Reads and writes save files. Uses atomic write (write to temp file, rename to final path). Handles save slots if needed. Serializes from and deserializes to Game State. Never touches game logic — just reads/writes data. |
| **Input Manager** | Maps physical devices (keyboard, controllers, touch) to player indices. Switches input context (combat, menu, overworld) to change what buttons do. Handles remapping with persistence. Detects controller connect/disconnect. Touch layer for Android. |

### Data-Driven Design Rules

All gameplay-tunable values live in Resource data files. The AI can add new characters, enemies, attacks, equipment, dungeons, and towns by creating new data resources — without modifying any system logic (Polymorphism).

**Resource types and their purpose:**

| Resource | Defines | Key Fields (document fully in docs/schemas/) |
|----------|---------|----------------------------------------------|
| CharacterDef | A playable character | Name, base stats, combo chain reference, technique list, model/texture reference, portrait |
| EnemyDef | An enemy type | Name, stats, AI behavior type, attack list, drop table reference, biome tag |
| AttackDef | A single attack or combo step | Damage multiplier, knockback direction and force, hitstop duration, active frame window, cancel window start/end, element, status effect |
| EquipmentDef | A piece of equipment | Name, slot (weapon/armor/accessory), stat modifiers, passive effects list, rarity, shop price |
| EncounterDef | A wave of enemies in a room | Enemy types and counts, spawn positions, trigger type (position/time/kill-count) |
| DungeonDef | A complete dungeon (legacy rooms) | Room sequence, encounter pool (randomized per entry), boss reference, biome theme, music reference |
| StageDef | A continuous stage (MVP 5+) | Ordered chunk sequence, encounter triggers with positions, interactable placements, hazard positions, pacing density metadata, boss reference |
| TownDef | A town on the overworld | Name, shop inventory references, inn cost, NPC list with dialogue references, services available |
| StoryDef | A dialogue or cutscene script | Speaker, portrait, lines, trigger flag, next scene |
| SkillTreeDef | A character's passive upgrade tree | Nodes with stat bonuses, prerequisite connections, point costs |

### Game State Rules

**Persistent (survives dungeon death, saved to file):**
- Party roster (which characters have been recruited)
- Per-character: level, XP, allocated stats, equipped items, learned techniques, skill tree progress
- Inventory (all owned equipment and items)
- Gold
- Story flags (which events have occurred, which nodes are unlocked)

**Transient (lost on dungeon death, never saved):**
- Current dungeon room index
- Dungeon-only buffs (temporary power-ups found in dungeon rooms)
- Dungeon-only item drops (not yet banked)
- Current encounter state (which enemies are alive)

**Banking:** When a dungeon is completed (boss defeated), all transient drops and rewards are moved to persistent state. This is the moment things become permanent. Dying before this moment means those rewards are lost.

### Movement Rules

**Heavy Platforming (primary axis — Y):** The game has real platforms, real ledges, real gravity. Jumping feels deliberate and weighty — quick launch, heavy fall. The character should feel grounded and physical, not floaty. Coyote time (a few frames of grace after walking off a ledge where jump still works) and jump buffering (pressing jump slightly before landing still registers) are mandatory for responsive feel. Variable jump height — tap for short hop, hold for full jump. Landing on a platform should feel definitive with a subtle impact effect.

**Light Belt-Depth (secondary axis — Z):** The player can nudge into and out of the screen for tactical positioning — sidestep a projectile, flank an enemy, align with a target. This is NOT a discrete lane system. It is continuous, subtle, and shallow (small range). Attacks connect based on Z-proximity tolerance — if the attacker and target are within a defined Z-distance of each other, the hit connects. The 3D renderer handles depth sorting naturally.

### Combat Rules

**Hit Feedback:** Every attack that connects must produce simultaneous: a brief screen freeze (hitstop), a camera shake proportional to attack strength, a particle burst at the contact point, a sound effect. No hit should ever feel like nothing happened. Heavy attacks have more hitstop and more shake than light attacks. Kills have an additional death burst effect.

**Combo System:** Each character has a unique combo chain defined in data. A combo chain is a sequence of attacks with branch points. At specific frame windows within an attack animation, the player can input the next action: press light to continue the chain, press heavy to branch into a powerful finisher, press dodge to cancel into a roll, press technique to cancel into a special move. These cancel windows are defined per-attack in the AttackDef resource. The system starts simple (light-light-light chain with heavy branch) and scales by adding more branch points and longer chains per character.

**Juggle System:** Certain attacks (launchers) send enemies airborne. While an enemy is airborne, further hits count as juggle hits. Each entity has a juggle counter. When the counter reaches the juggle limit, the enemy is forced into a hard knockdown (slammed to the ground, long recovery). This prevents infinite air combos while rewarding skillful juggle play.

**Block and Parry:** Holding the block button reduces incoming damage to chip damage only. Pressing block within a tight timing window (roughly 100-150 milliseconds) before an attack connects triggers a perfect parry — the attack is deflected, the attacker is stunned briefly, and the defender gets a free counterattack window. Parry timing should feel demanding but fair.

**Dodge:** Dodge roll gives a burst of movement speed and brief invincibility frames. Pressing attack during a dodge transitions into a dash attack. Dodge has a short cooldown to prevent spam.

**Techniques:** Special moves that cost TP (technique points). TP regenerates slowly over time and in bursts from certain actions (landing combo finishers, parrying). Each technique has an element (fire, ice, lightning, dark) that applies a status effect on hit (burn deals damage over time, freeze slows movement, shock chains to nearby enemies, bleed increases damage taken). Techniques are defined per-character in data.

**Damage Formula:** Base attack power multiplied by the attack's damage multiplier, modified by the attacker's relevant stat, modified by critical hit multiplier (if a crit rolled), modified by elemental effectiveness, minus the target's defense. All values come from data resources and Constants — nothing hardcoded in the formula logic.

### Enemy AI Rules

**Fairness First:** Enemies must feel challenging but fair, never cheap. Only a small number of enemies should actively attack at any given time — the rest circle, pace, or posture menacingly. This is controlled by a token system: a limited number of "attack tokens" exist per encounter, and enemies must hold a token to attack. After attacking, they release the token and enter a cooldown. The number of tokens scales with the number of players (more players = slightly more aggressive enemies).

**Behavior Types:** Enemy AI behaviors are defined in data, not hardcoded per enemy. Behavior types include: melee rusher (charges in, swings, retreats), ranged attacker (maintains distance, fires projectiles), shield bearer (blocks from the front, vulnerable from behind or during attack animation), flying enemy (moves on a different Y plane, dives to attack), support enemy (buffs or heals other enemies). New enemy types are created by combining a behavior type with stats and attacks in an EnemyDef resource (Polymorphism).

**Reaction Time:** Enemies do not react instantly. There is a built-in perception delay between when something happens (player enters range, player attacks) and when the enemy responds. This delay varies by enemy type (elite enemies react faster) and is defined in data.

### Dungeon Rules

**Stage Layout (MVP 5+):** Production dungeons use continuous stages — modular chunks tiled along X that the player walks through seamlessly. Chunks define geometry (floor, platforms, walls), connection points (matching edges), and content markers (spawn points, interactable positions). Chunk geometry is hand-authored. The level design IS authored content. Players experience one continuous journey from entrance to boss.

**Beads on a String:** Stages follow a "beads on a string" pacing model. Encounter zones ("beads") are connected by traversal segments ("string"). Encounter zones contain enemy spawns and soft gating. Traversal segments contain light platforming, environmental props, and breathing room. The pacing builds in intensity with a density curve: low → medium → high → release → escalation → boss.

**60-90 Second Rule:** Something meaningful must change every 60-90 seconds — a new encounter starts, the environment shifts, a hazard appears, a traversal challenge begins. Dead time kills momentum.

**Soft Gating:** During encounters, players are encouraged to stay and fight through camera leading and enemy spawn pressure, not invisible walls. The camera moves ahead slightly, enemies spawn from the forward edge if the player pushes past. When the encounter is complete, soft gating releases naturally.

**Environmental Interactables:** Stages contain throwable objects (barrels, crates, rocks) and hazards (spike pits, fire columns). Throwables can be picked up and thrown at enemies for damage. Hazards damage any entity — player and enemy alike. These add tactical variety to encounters.

**Legacy Room System:** The room-based DungeonDef system (discrete rooms with fade-to-black transitions) remains functional for prototyping and testing but is not used for production dungeons.

**Encounter Randomization:** The encounter roller selects enemy waves for each encounter zone from the dungeon's encounter pool. The stage geometry is familiar but the fights differ each run.

**Death:** Dying in a dungeon means: transient state is wiped (dungeon-only buffs and drops lost), player returns to the overworld map, all persistent state is retained (levels, gold, equipment, story flags). The dungeon can be re-entered immediately with fresh randomized encounters.

**Completion:** Beating the boss means: all transient rewards are banked to persistent state, a story flag is set (dungeon completed), the player returns to the overworld, and new nodes may unlock.

### Overworld Rules

**Node-Based Map:** The overworld is a map of connected nodes, not a free-roam area. Each node is a location: town, dungeon, story event, or point of interest. Nodes are connected by paths. The player selects nodes and travels between them. Navigation is clean and immediate — select, confirm, arrive.

**Story Gating:** Story flags control which nodes are visible and accessible. Completing a dungeon sets a flag. That flag may unlock the next dungeon, a new town, or a story event node. The player always knows where to go next because the newly unlocked node is visually distinct.

**Visual Clarity:** Completed nodes look different from available nodes, which look different from locked nodes. The current position is always obvious. Connections between nodes are clear.

### Town Rules

**Menu-Based:** Towns are not walkable areas. They are menu screens. When you enter a town, you see options: Shop, Inn, NPCs, Leave. Each option opens a sub-panel. This is efficient to build and fast for the player.

**Shop:** Buy and sell equipment. Inventory shows item stats and comparison to currently equipped gear. Each town has a different inventory defined in its TownDef resource. Later towns sell better equipment.

**Inn:** Fully heals the party for a gold cost. The cost is defined per town.

**NPCs:** Each town has 2–4 NPCs. Selecting an NPC shows their dialogue — story hints, world flavor, quest-related information. NPC dialogue changes based on story flags.

### Camera Rules

**Dungeon Follow:** The camera follows the active player's X position (or the centroid of all players in co-op). Y follows with a deadzone — small vertical movements do not move the camera, but jumping to a high platform smoothly scrolls up.

**Arena Lock:** When an encounter triggers, the camera locks to defined bounds for that arena. Invisible barriers prevent players from leaving. When all enemies are defeated, the lock releases smoothly (ease out, not snap).

**Co-op Containment:** In co-op, the camera frames all alive players. If players spread apart, the camera zooms out (up to a defined maximum). If a player reaches the screen edge, they feel a soft resistance pushing them back toward center. Players cannot walk off-screen.

**Impact Effects:** Heavy hits trigger camera shake. Boss phase transitions trigger larger shakes. Screen flash on critical hits. These are proportional and defined in Constants.

### Input Rules

**Context-Sensitive:** Input behavior changes based on game phase. In dungeons: movement, attacks, dodge, block, techniques, character switch. On the overworld: cursor movement, confirm, cancel. In towns/menus: cursor navigation, confirm, cancel, page through options. The input manager switches context when the game manager changes phase.

**Device Mapping:** Player 1 defaults to keyboard. Players 2–4 default to controllers. All mappings are remappable and persisted to a config file. The game detects when controllers connect and disconnect and handles it gracefully.

**Android Touch:** A virtual joystick on the left side of the screen for movement. An action button cluster on the right side for attack, heavy, technique, dodge, and jump. Buttons are large enough for real fingers. The layout is fixed but may have a size adjustment option.

### Audio Rules

**Event-Driven:** The audio manager listens to event bus signals and plays corresponding sounds. Every significant gameplay event has an audio cue: attack swing, hit connection, enemy death, pickup collection, level up, menu navigation click, footsteps, jump, land. Silence is a bug.

**Music States:** Music transitions by context: overworld theme, town theme (varies per town), dungeon ambient (varies per biome), combat intensity (when encounter triggers), boss music, victory fanfare, defeat sting. Transitions use crossfade, not hard cuts.

**Mute:** M key toggles mute. Mute state persists in settings config file. A visual mute indicator appears on the HUD.

### Performance Rules

**Object Pooling:** Any object type that gets created and destroyed frequently (enemies, projectiles, VFX particles, damage numbers, pickup items) must use the object pool. Direct instantiation of these types is not allowed in production code.

**No Per-Frame Allocation:** No new object creation inside per-frame update functions. Pre-allocate working variables as class members. Reuse containers.

**Delta Cap:** All movement and physics calculations must cap the delta time value to prevent physics explosions after lag spikes or window focus loss.

**Collision Optimization:** Use separate collision layers for each interaction type (player hitbox vs enemy hurtbox, enemy hitbox vs player hurtbox, entity vs platform, entity vs trigger). This minimizes unnecessary collision checks.

**Android Profiling:** Every MVP must be profiled on an Android device or emulator. Target: sustained 30fps with no frame drops below 25fps during combat with maximum expected enemy count. If performance fails, reduce particle counts and maximum simultaneous enemies on mobile before trying other optimizations.

---

## 4. Lessons Learned

These are constraints learned from real-world game development. The AI must treat each prevention rule as a hard requirement.

### Lesson 1 — The Hardcoded Values Trap

**Symptom:** Tuning game feel requires editing dozens of script files to change numbers scattered everywhere.
**Root Cause:** Magic numbers hardcoded directly in gameplay logic instead of centralized.
**Prevention Rule:** Every tunable number lives in Constants. Zero hardcoded values in logic scripts.
**Guideline:** The architecture requires a Constants singleton. When an AI agent writes gameplay logic, every number (speed, timing, damage, duration, distance) must reference Constants.

### Lesson 2 — The Spaghetti Coupling Problem

**Symptom:** Changing one system breaks three others. Adding a feature requires modifying files across the entire project.
**Root Cause:** Systems directly reference and call each other, creating invisible dependency chains.
**Prevention Rule:** All cross-system communication goes through the event bus. No system imports or references another system directly.
**Guideline:** The event bus is the nervous system. Every interaction between systems (combat hit → VFX spark, enemy kill → score update → drop spawn) is a signal, not a function call.

### Lesson 3 — The Scattered State Bug Factory

**Symptom:** Save/load produces corrupt or inconsistent state. Game state gets out of sync between systems.
**Root Cause:** Game state is stored in multiple places across different nodes and scripts.
**Prevention Rule:** Game State singleton is the single source of truth. Systems read from it. Events trigger mutations to it.
**Guideline:** No system stores authoritative state locally. If a system needs to know the player's HP, it reads from Game State, not from a local variable.

### Lesson 4 — The Hitstop Animation Break

**Symptom:** Hitstop (screen freeze on hit) breaks ongoing animations, tweens, and timers, causing visual glitches.
**Root Cause:** Naive implementation freezes everything including systems that should keep running (UI animations, particle lifetimes).
**Prevention Rule:** Hitstop must use a mechanism that allows exclusions — certain nodes opt out of the freeze.
**Guideline:** Research Godot's process mode system before implementing hitstop. Plan for UI elements and certain effects to be immune to the global time scale change.

### Lesson 5 — The One-Way Platform Nightmare

**Symptom:** Players clip through one-way platforms, get stuck inside them, or cannot drop through them reliably.
**Root Cause:** Simple collision toggling conflicts with fast-moving characters and edge cases.
**Prevention Rule:** One-way platform implementation must handle: high-speed fall-through, intentional drop-through (down+jump), landing from below, and walking off edges cleanly.
**Guideline:** Allocate extra time for platform feel in MVP 1. Test extensively with fast falling speeds and edge transitions.

### Lesson 6 — The Infinite Combo Exploit

**Symptom:** Players find a combo loop that stunlocks enemies indefinitely, trivializing all content.
**Root Cause:** No juggle limit or stun decay. Combo windows allow repeating the same chain forever.
**Prevention Rule:** Enforce juggle limit from MVP 2. After N hits in the air, enemies get forced knockdown. Stun duration decreases with consecutive stuns on the same target.
**Guideline:** The juggle limit is in the architecture from the start, not patched in later.

### Lesson 7 — The Unfair AI Problem

**Symptom:** Players feel like enemies "cheat" — reacting instantly, never making mistakes, attacking in overwhelming groups.
**Root Cause:** AI with zero reaction delay and no attack throttling.
**Prevention Rule:** All enemies have a perception delay. Only N enemies attack simultaneously (token system). Both values are defined in data and tunable.
**Guideline:** Token system and reaction delays are part of the AI architecture from MVP 2, not added during polish.

### Lesson 8 — The Manual Depth Sorting Disaster

**Symptom:** In a 2.5D game using 2D rendering, sprites constantly render in wrong depth order, especially during Z-movement.
**Root Cause:** Manual depth sorting based on Y or Z position is fragile and fails at edge cases.
**Prevention Rule:** Use a full 3D renderer so depth sorting is handled automatically by the Z-buffer.
**Guideline:** The architecture mandates full 3D scene (not 2D with manual sorting). This is why the rendering decision was made.

### Lesson 9 — The Memory Leak Death Spiral

**Symptom:** Frame rate degrades over time. After 10 minutes of play, the game stutters. On Android, it crashes.
**Root Cause:** Spawned objects (enemies, projectiles, effects) are created with instantiate() but never properly freed, accumulating as orphaned nodes.
**Prevention Rule:** All frequently spawned objects use the object pool. Every MVP includes a node count audit.
**Guideline:** Object pool is an autoload from MVP 1. Creating a spawnable object without the pool is a code review failure.

### Lesson 10 — The Android Input Lag Curse

**Symptom:** Touch controls feel sluggish and unresponsive on Android despite adequate frame rate.
**Root Cause:** Input processed in the wrong callback, adding a frame or more of latency.
**Prevention Rule:** Process input in the earliest available callback. Do not poll input state in per-frame update if an event-driven approach is available.
**Guideline:** Input manager design must account for touch latency from the start. Test on real hardware, not just emulator.

### Lesson 11 — The Save Corruption Catastrophe

**Symptom:** Player loses all progress. Save file is empty or contains garbage data.
**Root Cause:** Game crashed or was killed mid-write, producing a partial file.
**Prevention Rule:** All save writes go to a temporary file first, then atomic rename to the final path. The previous save file is kept as a backup until the new one is confirmed.
**Guideline:** Save manager implements atomic writes from day one (MVP 3).

### Lesson 12 — The Co-op Camera Chaos

**Symptom:** With multiple players, the camera jerks wildly, zooms in and out rapidly, or leaves players off-screen.
**Root Cause:** Camera directly follows the average position without smoothing, deadzone, or zoom limits.
**Prevention Rule:** Co-op camera must use smooth interpolation, a deadzone, defined zoom limits (min and max), and soft containment (push players at edges, do not hard-clip).
**Guideline:** Camera system is designed for co-op from the start (MVP 2 camera architecture), even if co-op is not playable until MVP 6.

### Lesson 13 — The Samey Runs Problem

**Symptom:** After 3–4 dungeon runs, players feel like they are doing the same thing every time.
**Root Cause:** Too few encounter combinations, no in-dungeon events or variation beyond enemy spawns.
**Prevention Rule:** Each dungeon's encounter pool must be large enough that most runs feel different. In-dungeon events (traps, treasure, mini-challenges) add non-combat variety.
**Guideline:** Encounter pool size is a content metric tracked per dungeon. Minimum pool size defined in the DungeonDef schema.

### Lesson 14 — The RPG Scope Avalanche

**Symptom:** Development stalls because RPG systems (leveling, equipment, skills, passives, shops) are all being built simultaneously.
**Root Cause:** Trying to implement everything at once instead of layering.
**Prevention Rule:** Combat feel comes first (MVP 1–2). RPG systems layer in after combat is fun (MVP 4). Do not build shop UI before enemies feel good to fight.
**Guideline:** The MVP order is intentional: combat → dungeon → overworld → RPG → stage design → co-op → polish. Do not reorder.

### Lesson 15 — The Invisible Progress Problem

**Symptom:** The game "works" with placeholder art, but it is impossible to judge if combat feels good because there is no sensory feedback.
**Root Cause:** Placeholder art with no VFX, audio, or screen effects makes every interaction feel empty.
**Prevention Rule:** Hitstop, camera shake, particle effects, and at minimum placeholder sound effects must be present from MVP 1. Placeholder models are fine; placeholder feedback is not.
**Guideline:** MVP 1 acceptance criteria explicitly require impact effects. If the hit does not feel crunchy with capsule models, the MVP is not done.

### Lesson 16 — The Undocumented Event Nightmare

**Symptom:** An AI agent adding a new feature does not know what events exist, emits a duplicate signal with a different name, or listens to a signal that was renamed.
**Root Cause:** Event bus signals are not documented, leading to drift and duplication.
**Prevention Rule:** Every event bus signal is registered in the event catalog document. Adding a new signal without updating the catalog is a deliverable failure.
**Guideline:** Documentation is a mandatory MVP deliverable, not optional polish.

### Lesson 17 — The Stop-Start Room Problem

**Symptom:** Dungeon runs feel repetitive and mechanical. Each room is a discrete box. Fade to black, load new room, fight, repeat. No sense of journey or continuous progression through a place.
**Root Cause:** Room-based dungeon design with hard scene transitions creates a stop-start rhythm that breaks immersion and limits pacing control.
**Prevention Rule:** Production dungeons must use continuous stage design — "beads on a string" model where encounter zones are connected by traversal segments. No loading screens or fade-to-black between combat areas.
**Guideline:** MVP 5 introduces continuous stages. The pacing follows a density curve (low → medium → high → release) with the 60-90 second rule: something meaningful changes every minute. Room-based design remains as a legacy/prototyping tool but production dungeons use StageDef.

---

## 5. Definition of Done

### Global Definition of Done

The game is done when ALL of the following are true:

- The game runs from start to finish on PC without crashes
- The game runs from start to finish on Android without crashes
- All automated tests pass (TDD test suite green)
- All 5–8 playable characters have complete, distinct movesets
- All dungeons are completable with fair difficulty
- All towns are functional (shop, inn, NPCs)
- The story is complete: beginning, middle, end
- 4-player local co-op works on PC
- Touch controls work on Android
- Save/load preserves all persistent state correctly
- Audio exists for every significant gameplay event
- Music transitions between all contexts without hard cuts
- No hardcoded gameplay values exist outside Constants
- INDEX.md accurately describes the full project
- Event catalog is complete and matches actual signals
- DECISIONS.md has entries for all architectural choices

### Per-MVP Definition of Done

Every individual MVP is done when:

1. All acceptance criteria from the roadmap are met (observable in a running build)
2. All verification gates pass (build, runtime, gameplay, visual, Android where applicable)
3. All new pure logic has passing TDD tests
4. INDEX.md is updated with all new systems and their locations
5. Event catalog is updated with all new signals
6. Any new architectural decisions are logged in DECISIONS.md
7. New data resource types have schema documentation in docs/schemas/
8. New folders with 3+ files have a README.md

---

## 6. Backlog

### MVP 1 — "First Punch"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 1 | Project scaffold | Godot 4 project with folder structure, autoload registrations, INDEX.md, DECISIONS.md | Core |
| 2 | Constants singleton | Centralized tunable values for movement, combat, and physics | Core |
| 3 | Event bus singleton | Global signal hub with initial combat and lifecycle events | Core |
| 4 | Game state singleton | Minimal state: player HP, current phase | Core |
| 5 | Player movement | Run, jump, fall, land on platforms with coyote time and jump buffering | Core |
| 6 | Belt-depth nudge | Light Z-axis movement for tactical repositioning | Core |
| 7 | State machine | Generic finite state machine usable by player, enemies, and other systems | Core |
| 8 | Hitbox/hurtbox system | Collision detection for attacks with enable/disable tied to animation frames | Combat |
| 9 | Three-hit light combo | Basic combo chain: light 1 → light 2 → light 3 | Combat |
| 10 | Heavy attack | Single slow powerful attack with enhanced hitstop | Combat |
| 11 | Dodge roll | Movement burst with invincibility frames and cooldown | Combat |
| 12 | Hitstop system | Brief engine freeze on hit contact, proportional to attack strength | Combat |
| 13 | Camera shake | Screen shake on hit, proportional to attack force | Combat |
| 14 | Basic VFX | Particle burst on hit contact and enemy death | Combat |
| 15 | Basic enemy | Melee rusher that walks toward player and swings | Combat |
| 16 | Test arena | Flat room with three platforms at different heights | Content |
| 17 | Object pool | Pre-instantiation pool for enemies and VFX — used from day one | Core |

### MVP 2 — "The Dungeon"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 18 | Ranged enemy | Enemy that maintains distance and fires projectiles | Combat |
| 19 | Shield enemy | Enemy that blocks frontal attacks, vulnerable from behind | Combat |
| 20 | Flying enemy | Airborne enemy that dives to attack | Combat |
| 21 | Wave/encounter system | Spawns enemy waves from encounter data, triggers arena lock | Dungeon |
| 22 | Arena-lock camera | Camera bounds lock during encounters with smooth transitions | Dungeon |
| 23 | Launcher attack | Attack that sends enemies airborne | Combat |
| 24 | Juggle system | Airborne hit counter with juggle limit and forced knockdown | Combat |
| 25 | Combo cancel windows | Branch points in combo chains defined per-attack in data | Combat |
| 26 | HUD overlay | Health bar, TP gauge, combo counter for active player | UI |
| 27 | Dungeon room sequence | Load rooms in order from dungeon definition, transition between them | Dungeon |
| 28 | Encounter roller | Randomize enemy wave selection from pool on each dungeon entry | Dungeon |
| 29 | Boss with phases | Boss enemy that changes behavior at health thresholds | Combat |
| 30 | Death and restart flow | Player death → dungeon failed screen → restart dungeon | Core |
| 31 | Victory flow | Boss defeated → victory screen with stats → return to restart | Core |

### MVP 3 — "The World"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 32 | Overworld map | Node-based map with selectable connected nodes | Overworld |
| 33 | Story flag system | Key-value store of completed events, gates node access | Overworld |
| 34 | Town menu | Menu-based town interface: shop, inn, NPCs, leave | Town |
| 35 | Shop system | Buy and sell equipment with gold, show stat comparisons | Town |
| 36 | Inn system | Full party heal for a gold cost | Town |
| 37 | NPC dialogue | Display dialogue lines from story data, change based on flags | Town |
| 38 | Gold drops | Enemies drop gold currency during dungeon encounters | RPG |
| 39 | Save/load system | Persist all RPG state to file with atomic writes | Core |
| 40 | Scene transitions | Smooth fade transitions between overworld, town, and dungeon | Core |
| 41 | Game manager phase handling | Orchestrate transitions between all game phases cleanly | Core |

### MVP 4 — "RPG Depth"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 42 | XP and leveling | Earn XP from kills, level up at thresholds | RPG |
| 43 | Stat allocation | On level up, distribute points to STR/MAG/DEF/AGI, see effects | RPG |
| 44 | Equipment system | Equip weapons, armor, accessories with stat modifiers | RPG |
| 45 | Accessory passives | Accessories grant passive effects (crit chance, regen, resistance) with caps | RPG |
| 46 | Second playable character | New character with unique combo chain and techniques | Content |
| 47 | Third playable character | Another unique character | Content |
| 48 | Fourth playable character | Another unique character | Content |
| 49 | Party management | Select active party from roster, switch characters in dungeon | RPG |
| 50 | Technique system | Special moves costing TP with elemental effects and status application | Combat |
| 51 | Skill tree | Permanent passive upgrades per character with prerequisite chains | RPG |
| 52 | Drop tables | Enemies drop equipment based on rarity tier definitions | RPG |
| 53 | Varied shop inventories | Each town sells different equipment appropriate to progression point | Town |

### MVP 5 — "The Stage"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 54 | Stage chunk system | Modular Node3D chunks that tile along X with standardized connection points | Stage |
| 55 | StageDef resource | Data definition for continuous stage: chunk sequence, triggers, interactables, pacing | Stage |
| 56 | Chunk streaming manager | Load/unload chunks in sliding window around player X position | Stage |
| 57 | Encounter trigger zones | Area3D-based encounter activation replacing room-enter triggers | Stage |
| 58 | Soft gating system | Camera-leading + enemy pressure during encounters, no invisible walls | Stage |
| 59 | Environmental throwables | Pick up and throw barrels/crates at enemies for damage | Stage |
| 60 | Environmental hazards | Spike pits, fire columns that damage any entity in their zone | Stage |
| 61 | Continuous camera mode | Smooth follow in traversal, soft framing in encounters, no hard cuts | Stage |
| 62 | Stage-aware DungeonManager | Detect StageDef vs DungeonDef and delegate to appropriate system | Stage |
| 63 | Piata Basement stage rebuild | Dungeon_1 rebuilt as 8–10 continuous chunks with encounters and interactables | Content |

### MVP 6 — "Together"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 64 | Multi-device input | Map keyboard + up to 3 controllers to player indices | Co-op |
| 65 | Per-player HUD | Health/TP bars for all active players on screen | UI |
| 66 | Co-op camera | Shared camera with dynamic zoom and player containment | Co-op |
| 67 | Revive mechanic | Downed player revived by ally standing near and holding button | Co-op |
| 68 | Combination attacks | Two specific characters trigger a special team attack when near each other | Co-op |
| 69 | Android export | Working APK with touch controls, virtual joystick and action buttons | Android |
| 70 | Settings menu | Audio volume, display options, control remapping | UI |
| 71 | Control remapping | Rebind keyboard and controller inputs, persist to config | UI |
| 72 | Save system hardening | Test save/load across all game states, handle edge cases | Core |

### MVP 7 — "Ship It"

| # | Item | Description | Category |
|---|------|-------------|----------|
| 73 | Characters 5 through 8 | Remaining roster with unique movesets and techniques | Content |
| 74 | Full enemy variety | 12+ enemy types across biome themes | Content |
| 75 | Dungeon 2 | New continuous stage with unique theme, encounters, and boss | Content |
| 76 | Dungeon 3 | Another unique continuous stage | Content |
| 77 | Dungeon 4 | Another unique continuous stage | Content |
| 78 | Town 2 | New town with unique shop inventory and NPCs | Content |
| 79 | Town 3 | Another unique town | Content |
| 80 | Full story script | Complete narrative arc with dialogue for all story beats | Content |
| 81 | Full audio SFX | Sound effects for every gameplay event | Audio |
| 82 | Music per context | Unique tracks for overworld, each town, each biome, boss fights | Audio |
| 83 | VFX polish | Attack trails, elemental particles, screen transitions, UI juice | Polish |
| 84 | Daily challenge mode | Date-seeded dungeon run with fixed parameters and local leaderboard | Content |
| 85 | Accessibility options | Colorblind mode, difficulty settings, input assist (auto-combo) | Polish |
| 86 | Final balance pass | Automated stat simulations to flag outlier characters/equipment | Polish |

---

## 7. Tooling & Workflow

### Git Strategy

- **main** branch: Stable, buildable, playable. Tagged at each MVP completion (v0.1 through v0.7).
- **develop** branch: Integration branch. Features merge here first. Must build and pass tests.
- **feature/** branches: One branch per backlog item or small group of related items. Named descriptively: `feature/juggle-system`, `feature/town-shop-ui`. Merged to develop via pull request or merge commit.

### Naming Conventions

- **Files and folders:** snake_case. Always. No exceptions.
- **Classes and resource types:** PascalCase. CharacterDef, EnemyDef, AttackDef.
- **Variables and functions:** snake_case. player_speed, calculate_damage().
- **Constants:** UPPER_SNAKE_CASE. MAX_JUGGLE_COUNT, BASE_GRAVITY.
- **Event bus signals:** snake_case with domain prefix. combat_hit_landed, dungeon_room_cleared, rpg_level_up.
- **Resource files (.tres):** snake_case matching the thing they define. alys_character.tres, sand_worm_enemy.tres, fire_slash_attack.tres.

### Debug Overlays

Toggled by keyboard shortcuts. All disabled by default. Each overlay visualizes a different system:

| Key | Overlay | Shows |
|-----|---------|-------|
| F1 | Hitbox/Hurtbox | Colored wireframes for all active hitboxes (red) and hurtboxes (green) |
| F2 | Depth/Z display | Numeric Z-position label above each entity, depth tolerance visualization |
| F3 | AI state | Text label above each enemy showing current AI state (idle, chase, attack, stun, etc.) |
| F4 | Performance | FPS counter, draw call count, physics body count, node count, memory usage |
| F5 | Input display | Per-player panel showing all current input states (which buttons pressed, stick direction) |
| F6 | State dump | Full game state serialized to console as JSON — for crash repro and AI agent inspection |

### Logging Philosophy

**What to log:** System initialization, scene transitions, event bus signal emissions (optional verbose mode), errors and warnings, save/load operations, encounter generation results.

**What not to log:** Per-frame position updates, every physics tick, every input event in normal play. These create noise.

**Implementation:** A logging utility with system tags (COMBAT, AI, DUNGEON, SAVE, UI, AUDIO, etc.). Logs can be filtered by tag. Verbose mode toggleable. In production builds, only warnings and errors.

### Crash Reproduction Checklist

When a crash or bug is reported:

1. Check the log output for errors and warnings leading up to the crash.
2. Check the event bus ring buffer (last 100 events) to see what happened before the crash.
3. Use F6 state dump if reproducible to capture full game state at the moment of failure.
4. Record: what MVP, what phase (dungeon/overworld/town), what action was being performed, how many players, how many enemies on screen.
5. Write a test case that reproduces the logic failure if the bug is in testable code.
6. If the bug is in scene-coupled code, write a reproduction sequence in the demo checklist.

### TDD Workflow

**Framework:** GdUnit4 (or Godot's built-in test runner if GdUnit4 is unavailable).

**Test file location:** Mirror the scripts/ structure under tests/unit/. A component at scripts/components/health_component lives with its tests at tests/unit/components/test_health_component.

**What gets tested:** All pure logic components, all state machine transitions, all data validation, all formulas, all serialization round-trips, all encounter generation output validity.

**What does not get tested with TDD:** Scene rendering, physics feel, camera behavior, audio playback, visual effects. These are play-verified.

**Cycle:** For every new piece of pure logic: write a failing test describing the expected behavior, write the minimum code to pass it, refactor to clean up, run the full test suite to confirm nothing broke. This is not optional.

### Documentation Workflow

**INDEX.md:** Updated at the end of every MVP. Lists every system by name, file location, one-line purpose, and dependencies. An AI agent reads this first to orient itself.

**DECISIONS.md:** Updated whenever an architectural choice is made. Format: date, decision title, what was decided, why, what alternatives were considered. This prevents future AI agents from "improving" something that was deliberately designed a certain way.

**Event catalog (docs/events/):** Updated whenever a new event bus signal is added. Format: signal name, payload type description, who emits it, who listens to it. This is the API documentation for the project's nervous system.

**Schema docs (docs/schemas/):** Updated whenever a new resource type is created. Format: resource type name, purpose, all fields with types and valid ranges, at least one example. This lets an AI agent create valid data resources without reading source code.

**Per-folder READMEs:** Created when a folder exceeds three files. Brief: what is in this folder, naming convention, how to add a new file of this type.

### AI Onboarding Protocol

When a new AI agent session begins on this project, it should read files in this order:

1. **This document** (PROJECT_PLAN_GODOT4_BELTSCROLLER.md) — for overall vision and constraints
2. **INDEX.md** — for current project state and system locations
3. **DECISIONS.md** — for understanding why things are the way they are
4. **The relevant folder's README.md** — for the specific area being worked on
5. **The event catalog** — for understanding what signals exist
6. **Then source code** — now with full context

### Android Build & Test Checklist

Run this checklist at every MVP that claims Android support:

1. Export templates installed for current Godot version
2. Keystore configured (debug keystore for development)
3. Minimum SDK version set (24 or higher)
4. APK exported without errors
5. APK installs on a real Android device (not just emulator)
6. Game boots to expected screen without crash
7. Touch controls appear and respond (virtual joystick + buttons)
8. Gameplay is playable with touch alone (no keyboard/controller needed)
9. Frame rate holds at or above 30fps during combat with typical enemy count
10. Save/load works on Android storage
11. APK size is under 100MB (target, not hard limit)
12. No Android-specific permission warnings that would alarm users
