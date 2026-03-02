# scripts/

## Purpose
Contains gameplay/runtime logic scripts used by scenes, systems, and UI.

## Subfolders
- `core/`: controllers, state machine base, combat collision primitives, player states.
- `ai/`: enemy controller and enemy states.
- `components/`: mostly pure logic components intended for unit testing.
- `systems/`: gameplay systems (combat, wave, camera, VFX, projectile handling).
- `dungeon/`: dungeon progression/run orchestration.
- `ui/`: UI behavior scripts.
- `tools/`: runtime/debug helper scripts.
- `overworld/`: overworld gameplay logic.
- `town/`: town gameplay logic.
- `utils/`: shared utility helpers.

## AI Coding Guidance
- Put behavior here, not in `resources/` or `assets/`.
- Prefer explicit APIs and event-driven communication over implicit node coupling.
- Keep `components/` deterministic and scene-tree independent when possible.
- Update the matching subfolder README when folder conventions change.

## Notes
Each subfolder contains its own `README.md` with local coding rules.
