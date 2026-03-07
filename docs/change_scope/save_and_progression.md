# Save And Progression

## Entry Points
- `autoloads/game_state.gd`
- `autoloads/save_manager.gd`
- `scripts/core/player_controller.gd`
- `tests/unit/systems/test_save_serialization.gd`
- `tests/unit/systems/test_save_hardening.gd`

## Safe Files
- Serialization shape changes in `autoloads/game_state.gd`
- Save file safety logic in `autoloads/save_manager.gd`
- Focused regression tests in save/inventory test suites

## Risky Boundaries
- Any change that mutates `character_data`, `active_party`, or inventory schema
- Runtime stat sync paths in `scripts/core/player_controller.gd`
- Backward compatibility with existing save slots

## Required Validation
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_save_serialization.gd`
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_save_hardening.gd`
- Full `pwsh tools/sanity_check.ps1` when schema or runtime sync changes

## Notes
- Prefer additive schema changes and explicit defaulting/migration.
- Save bugs are always higher priority than balance or content polish.
