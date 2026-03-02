# resources/

## Purpose
Contains gameplay data (`.tres`) and custom `Resource` scripts used to drive systems without hardcoding values.

## Subfolders
- `attacks/`: attack definitions and attack data assets.
- `enemies/`: enemy type definitions and enemy data assets.
- `encounters/`: encounter/wave/spawn data assets.
- `dungeons/`: dungeon definition assets.
- `characters/`: character data assets.
- `equipment/`: equipment data assets.
- `skills/`: skill data assets.
- `story/`: story/dialog data assets.
- `towns/`: town/shop/NPC data assets.

## AI Coding Guidance
- Keep this folder data-oriented; runtime logic belongs in `scripts/`.
- Prefer stable IDs/paths in resources because systems reference them directly.
- When adding a new resource type, add/update schema docs under `docs/schemas/`.
- Update the matching subfolder README when folder conventions change.

## Notes
Each subfolder contains its own `README.md` with folder-specific data expectations.
