# scenes/ — All Instantiated Scene Files

Everything that gets instantiated as a scene tree node lives here.

## Subfolders

| Folder | Contains |
|--------|----------|
| `characters/` | Playable character scenes |
| `enemies/` | Enemy type scenes |
| `bosses/` | Boss scenes |
| `projectiles/` | Technique projectile scenes |
| `dungeon/` | Dungeon container + room scenes |
| `dungeon/rooms/` | Individual room layout scenes |
| `overworld/` | Node-based overworld map scene |
| `town/` | Town menu scene |
| `ui/` | All UI screens (HUD, pause, settings, menus) |
| `vfx/` | Particle and effect scenes |
| `cutscene/` | Story dialogue scenes |

## Naming Convention

- Files: `snake_case.tscn` and `snake_case.gd`
- Scene root node: PascalCase matching the filename
- Example: `player_character.tscn` has root node `PlayerCharacter`

## Composition Rule

A scene encapsulates its entire internal structure. Nothing outside the scene should need to know what nodes are inside it. Scenes communicate via the EventBus, not by reaching into each other's node trees.
