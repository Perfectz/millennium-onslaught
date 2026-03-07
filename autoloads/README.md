# autoloads/ - Singleton Services

All files in this folder are registered as autoloads in `project.godot`.
They boot at startup and stay alive for the full app lifetime.

## Current Autoloads

| File | Class | Autoload Name | Role |
|---|---|---|---|
| `constants.gd` | `ConstantsSingleton` | `Constants` | Tunable gameplay constants |
| `event_bus.gd` | `EventBusSingleton` | `EventBus` | Global signal/event hub with canonical typed combat contracts |
| `game_state.gd` | `GameStateSingleton` | `GameState` | Persistent profile/save state |
| `runtime_state.gd` | `RuntimeStateSingleton` | `RuntimeState` | Transient session/dungeon state |
| `game_manager.gd` | `GameManagerSingleton` | `GameManager` | Game phase and scene lifecycle |
| `object_pool.gd` | `ObjectPoolSingleton` | `ObjectPool` | Reusable object pooling |
| `audio_manager.gd` | `AudioManagerSingleton` | `AudioManager` | Audio playback and mute state |
| `save_manager.gd` | `SaveManagerSingleton` | `SaveManager` | Save/load orchestration |
| `input_manager.gd` | `InputManagerSingleton` | `InputManager` | Input context/device mapping, remapping, and auxiliary debug/photo action registration |

## Conventions

- Files use `snake_case.gd`.
- Classes use `PascalCaseSingleton`.
- Autoload names use `PascalCase`.

## Usage Rules

- Prefer EventBus signals for cross-system notifications.
- Prefer `EventBus.emit_checked()` for new signal emissions so recent event logs and unmatched-listener diagnostics stay complete.
- Put persistent profile/save data in `GameState` and active run/session data in `RuntimeState`.
- Direct reads/writes to shared singletons are allowed for core state flows (for example `GameManager <-> RuntimeState`).
- Keep each autoload focused on one responsibility.
