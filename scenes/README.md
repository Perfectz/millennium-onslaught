# scenes/

## Purpose
Contains all Godot scene trees (`.tscn`) and any scene-local scripts used to compose runtime gameplay.

## Subfolders
- `characters/`: playable character scenes.
- `enemies/`: enemy scenes.
- `bosses/`: boss scenes.
- `projectiles/`: projectile scenes.
- `dungeon/`: dungeon flow scenes.
- `dungeon/rooms/`: individual room scenes.
- `overworld/`: overworld scenes.
- `town/`: town/hub scenes.
- `ui/`: HUD and menu scenes.
- `vfx/`: particle/effect scenes.
- `cutscene/`: cutscene/story scenes.

## AI Coding Guidance
- Keep scene composition local; avoid hardcoded cross-scene node dependencies.
- Put reusable gameplay behavior in `scripts/`, then attach those scripts to scenes.
- Update the matching subfolder README when folder conventions change.

## Notes
Each subfolder contains its own `README.md` with folder-specific conventions.
