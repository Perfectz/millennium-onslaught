# autoloads/ — Singleton Services

All files in this folder are registered as autoloads in `project.godot`. They initialize automatically when the game starts and persist for the entire application lifetime.

## Contents

| File | Class | Role |
|------|-------|------|
| `constants.gd` | ConstantsSingleton | Every tunable gameplay number |
| `event_bus.gd` | EventBusSingleton | Global signal hub for cross-system communication |
| `game_state.gd` | GameStateSingleton | Single source of truth for all game data |
| `game_manager.gd` | GameManagerSingleton | Game phase transitions and scene lifecycle |
| `object_pool.gd` | ObjectPoolSingleton | Pre-instantiation pool for spawned objects |
| `audio_manager.gd` | AudioManagerSingleton | SFX pool + music with crossfade |
| `save_manager.gd` | SaveManagerSingleton | Atomic file-based save/load |
| `input_manager.gd` | InputManagerSingleton | Device-to-player mapping, context switching |

## Naming Convention

- Files: `snake_case.gd`
- Classes: `PascalCaseSingleton`
- Autoload names in project.godot: `PascalCase` (e.g., `Constants`, `EventBus`)

## Rules

- Each autoload has exactly one responsibility
- Autoloads communicate via EventBus signals, never by directly calling each other
- `Constants` is the only exception — other autoloads may read from it directly
- All autoloads set `process_mode = PROCESS_MODE_ALWAYS` if they need to run during pause
