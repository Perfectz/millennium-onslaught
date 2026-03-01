# INDEX.md — Millennium Onslaught — Master System Index

> **Purpose:** AI reads this first after the project plan. Lists every system by name, file location, one-line purpose, and dependencies. Updated at every MVP.

**Current MVP:** 0 — Scaffold
**Last Updated:** 2026-03-01

---

## Autoloads (Singletons)

| System | File | Purpose | Dependencies |
|--------|------|---------|--------------|
| Constants | `autoloads/constants.gd` | Centralized tunable values for all gameplay numbers | None |
| EventBus | `autoloads/event_bus.gd` | Global signal hub for cross-system communication | None |
| GameState | `autoloads/game_state.gd` | Single source of truth for persistent and transient game data | Constants |
| GameManager | `autoloads/game_manager.gd` | Game phase transitions and scene lifecycle orchestration | EventBus, GameState |
| ObjectPool | `autoloads/object_pool.gd` | Pre-instantiation pool for frequently spawned objects | None |
| AudioManager | `autoloads/audio_manager.gd` | SFX pool and music player with crossfade | EventBus |
| SaveManager | `autoloads/save_manager.gd` | Atomic file-based save/load | EventBus, GameState |
| InputManager | `autoloads/input_manager.gd` | Device-to-player mapping and input context switching | EventBus |

## Scenes

| Scene | File | Purpose |
|-------|------|---------|
| Main | `scenes/main.tscn` | Entry point scene — placeholder for MVP 0 |

## Scripts

*No gameplay scripts yet — MVP 0 is scaffold only.*

## Resources

*No data resources yet — created starting MVP 1.*

## Tests

*Test framework (GdUnit4) installed — no test files yet.*

---

## Folder Map

```
res://
├── addons/           → Third-party addons (GdUnit4)
├── autoloads/        → 8 singleton services
├── scenes/           → Scene files (.tscn)
├── scripts/          → All game logic (.gd)
│   ├── core/         → Base abstractions (state machine, entity base)
│   ├── components/   → Pure logic components (testable, no scene dependency)
│   ├── systems/      → Game systems (combat, combo, wave, camera, VFX)
│   ├── ai/           → Enemy AI controllers
│   ├── dungeon/      → Dungeon-specific logic
│   ├── overworld/    → Overworld navigation logic
│   ├── town/         → Town menu logic
│   ├── ui/           → UI widget scripts
│   └── utils/        → Math helpers, debug utilities
├── resources/        → Custom Resource data files (.tres)
├── assets/           → Raw assets (models, textures, audio, fonts, shaders)
├── docs/             → AI-navigable documentation
│   ├── schemas/      → Data schema documentation
│   └── events/       → Event catalog
├── tools/            → Debug overlays and editor plugins
├── tests/            → GdUnit4 test files
└── export/           → Export configurations
```
