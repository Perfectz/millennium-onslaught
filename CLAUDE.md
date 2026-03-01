# CLAUDE.md — Collaborative Developer Guide

> **Purpose:** This file orients Claude Code as a collaborative developer on **Millennium Onslaught** — a Godot 4 belt-scroller beat-'em-up inspired by Phantasy Star IV (plot), Guardian Heroes / Dead Cells (gameplay), and classic brawlers / roguelikes. Read this first, then follow the AI Onboarding Protocol.

---

## Project Identity

- **Engine:** Godot 4.6.1 (GDScript)
- **Genre:** 2.5D belt-scroller beat-'em-up with JRPG progression and roguelike dungeon tension
- **Platforms:** PC (60fps) and Android (30fps)
- **Rendering:** Full 3D (not 2D with manual sorting) — depth sorting is automatic via Z-buffer
- **Resolution:** 1920x1080 base, stretch mode `canvas_items`, aspect `expand`
- **Test Framework:** GdUnit4
- **Current MVP:** MVP 0 (Project scaffold and tooling setup)

## Onboarding Protocol

When starting a new session, read files in this order:
1. `PROJECT_PLAN_GODOT4_BELTSCROLLER.md` — vision, constraints, and MVP roadmap
2. `INDEX.md` — current project state and system locations
3. `DECISIONS.md` — why things are the way they are
4. Relevant folder's `README.md` — specific area context
5. `docs/events/event_catalog.md` — existing signals
6. Then source code

## Three Foundational Principles (Non-Negotiable)

1. **TDD** — Every pure logic feature starts with a failing test. Write test → write minimum code → refactor. No exceptions for testable logic.
2. **APIE** — Abstraction, Polymorphism, Inheritance (max 2 levels), Encapsulation. Clean OOP. Composition over deep inheritance.
3. **AI-Navigable Documentation** — INDEX.md, per-folder READMEs, inline doc comments, event catalog, schema docs, DECISIONS.md. Documentation is a deliverable of every MVP.

## Architecture Quick Reference

### Folder Structure
```
res://
├── project.godot
├── INDEX.md / DECISIONS.md
├── addons/           # GdUnit4, third-party
├── autoloads/        # Singletons (event_bus, game_state, game_manager, constants, object_pool, audio_manager, save_manager, input_manager)
├── scenes/           # .tscn files (characters, enemies, bosses, dungeon, overworld, town, ui, vfx)
├── scripts/          # All logic (core, components, systems, ai, dungeon, overworld, town, ui, utils)
├── resources/        # .tres data files (characters, enemies, attacks, equipment, encounters, dungeons, towns, story, skills)
├── assets/           # Raw assets (models, textures, audio, fonts, shaders)
├── docs/             # schemas/, events/
├── tools/            # debug/, editor_plugins/
├── tests/            # unit/, integration/ (mirrors scripts/ structure)
└── export/           # android/, pc/
```

### Singleton Roles
| Singleton | Role |
|-----------|------|
| **EventBus** | All cross-system communication via typed signals. No direct system references. |
| **GameState** | Single source of truth. Persistent (RPG) + Transient (dungeon-only) state. |
| **GameManager** | Phase transitions: menu, overworld, town, dungeon, cutscene, pause, game_over. |
| **Constants** | Every tunable number. Zero hardcoded values in gameplay scripts. |
| **ObjectPool** | Pre-instantiate and recycle enemies, projectiles, VFX, damage numbers. |
| **AudioManager** | SFX pool (8+) + music with crossfade. Event-driven. |
| **SaveManager** | Atomic writes (temp file → rename). Save slots. |
| **InputManager** | Device-to-player mapping, context switching, remapping, touch layer. |

### Composition Rules
- **Scene (.tscn):** Standalone instantiated things (character, enemy, room, UI screen, VFX)
- **Node:** Internal building blocks inside scenes (hitbox, hurtbox, state machine, AI brain)
- **Resource (.tres):** Pure data with no scene presence (stats, attacks, equipment, encounters)
- **Autoload:** Exactly-one global service (event bus, state, constants, etc.)

## Coding Standards

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Files/folders | snake_case | `health_component.gd` |
| Classes/resources | PascalCase | `CharacterDef`, `EnemyDef` |
| Variables/functions | snake_case | `player_speed`, `calculate_damage()` |
| Constants | UPPER_SNAKE_CASE | `MAX_JUGGLE_COUNT`, `BASE_GRAVITY` |
| Signals | snake_case with domain prefix | `combat_hit_landed`, `rpg_level_up` |
| Resource files | snake_case | `chaz_character.tres` |

### Hard Rules
- **Zero hardcoded values** in gameplay logic — all numbers go in Constants
- **Event bus for cross-system communication** — no system imports another system
- **GameState is single source of truth** — no local authoritative state
- **Object pool for frequently spawned objects** — no direct instantiate() in production
- **Atomic save writes** — temp file then rename
- **Inheritance max 2 levels deep** — use composition beyond that
- **No per-frame allocation** — pre-allocate working variables as class members
- **Delta time cap** — prevent physics explosions on lag spikes

### GDScript Style
- One class per file
- One-line doc comments on every public class and public method
- `@export` for inspector-editable values that come from Constants
- `@onready` for node references
- Type hints on all function signatures and member variables
- Signal declarations at top of file, below class_name

## Git Workflow

- **main:** Stable, tagged at MVP completion (v0.0 through v0.6)
- **develop:** Integration branch. Must build and pass tests.
- **feature/\*:** One per backlog item. Named descriptively: `feature/juggle-system`
- Commit messages: imperative mood, concise. Reference backlog item number when applicable.

## MVP Roadmap (Current Focus)

| MVP | Name | Goal |
|-----|------|------|
| **0** | **Scaffold** | Project structure, autoload stubs, git, GdUnit4, docs skeleton |
| 1 | First Punch | Movement, jumping, combo, dodge, hitstop, one enemy |
| 2 | The Dungeon | Multi-room dungeon, 3+ enemy types, boss, HUD, juggle system |
| 3 | The World | Overworld map, towns, shops, save/load, gold |
| 4 | RPG Depth | Leveling, stats, equipment, 4 characters, techniques, skill tree |
| 5 | Together | 4-player co-op, Android build, settings, control remapping |
| 6 | Ship It | Full content, audio, VFX polish, daily challenge, accessibility |

## Definition of Done (Per MVP)

1. All acceptance criteria met (observable in running build)
2. All verification gates pass (build, runtime, gameplay, visual, Android)
3. All new pure logic has passing TDD tests
4. INDEX.md updated with new systems
5. Event catalog updated with new signals
6. DECISIONS.md updated with architectural choices
7. New resource types have schema docs
8. New folders with 3+ files have README.md

## Debug Overlays

| Key | Shows |
|-----|-------|
| F1 | Hitbox (red) / Hurtbox (green) wireframes |
| F2 | Z-position labels and depth tolerance |
| F3 | Enemy AI state labels |
| F4 | FPS, draw calls, node count, memory |
| F5 | Per-player input states |
| F6 | Full game state JSON dump to console |

## Performance Targets

- **PC:** 60fps sustained
- **Android:** 30fps sustained, no drops below 25fps in combat
- Object pooling for all frequently spawned types
- No per-frame allocations
- Separate collision layers per interaction type
- Profile on Android at every MVP claiming mobile support

## Key Decisions Record

When making architectural choices, always log them in DECISIONS.md with:
- Date, decision title, what was decided, why, alternatives considered

## Working With Me

- I follow TDD strictly for all pure logic
- I update documentation as I build, not after
- I ask before making destructive changes
- I reference Constants for all tunable values
- I use the event bus for all cross-system communication
- I keep inheritance shallow (max 2 levels)
- I use composition and data-driven design for extensibility
- I test on both PC and Android targets when applicable
- I write concise inline docs on public APIs
- I follow the backlog item numbers from the project plan
