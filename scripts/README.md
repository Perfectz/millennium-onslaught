# scripts/ — All Game Logic

All gameplay logic lives here, organized by domain. Scene files (`.tscn`) live in `scenes/` — scripts here are attached to those scenes or used as standalone logic.

## Subfolders

| Folder | Purpose | Scene Dependency |
|--------|---------|------------------|
| `core/` | Base abstractions — state machine, entity base, hitbox/hurtbox | Some require nodes |
| `components/` | Pure logic components — health, stats, combo, inventory | **No scene dependency (testable)** |
| `systems/` | Game systems — combat, combo, wave, camera, VFX, drops | Require scene tree |
| `ai/` | Enemy AI controllers and behavior definitions | Require scene tree |
| `dungeon/` | Dungeon-specific logic — room loading, encounter rolling | Require scene tree |
| `overworld/` | Overworld map navigation logic | Require scene tree |
| `town/` | Town menu logic — shop, inn, NPC dialogue | Require scene tree |
| `ui/` | UI widget scripts | Require CanvasLayer |
| `utils/` | Math helpers, debug utilities, logging | **No scene dependency (testable)** |

## Naming Convention

- Files: `snake_case.gd`
- Classes: `PascalCase`
- One class per file
- Test mirror: `scripts/components/health_component.gd` → `tests/unit/components/test_health_component.gd`

## Key Rule

Everything in `components/` and `utils/` must be **pure logic** with zero scene tree dependency. These are the TDD targets.
