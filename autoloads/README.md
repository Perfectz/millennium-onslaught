# autoloads/ - Singleton Services

All files in this folder are registered as autoloads in `project.godot`.
They boot at startup and stay alive for the full app lifetime.

## Current Autoloads

| File | Class | Autoload Name | Role |
|---|---|---|---|
| `constants.gd` | `ConstantsSingleton` | `Constants` | Tunable gameplay constants |
| `event_bus.gd` | `EventBusSingleton` | `EventBus` | Global signal/event hub |
| `game_state.gd` | `GameStateSingleton` | `GameState` | Runtime + persistent state |
| `game_manager.gd` | `GameManagerSingleton` | `GameManager` | Game phase and scene lifecycle |
| `object_pool.gd` | `ObjectPoolSingleton` | `ObjectPool` | Reusable object pooling |
| `audio_manager.gd` | `AudioManagerSingleton` | `AudioManager` | Audio playback and mute state |
| `save_manager.gd` | `SaveManagerSingleton` | `SaveManager` | Save/load orchestration |
| `input_manager.gd` | `InputManagerSingleton` | `InputManager` | Input context/device mapping |

## Conventions

- Files use `snake_case.gd`.
- Classes use `PascalCaseSingleton`.
- Autoload names use `PascalCase`.

## Usage Rules

- Prefer EventBus signals for cross-system notifications.
- Direct reads/writes to shared singletons are allowed for core state flows (for example `GameManager <-> GameState`).
- Keep each autoload focused on one responsibility.
