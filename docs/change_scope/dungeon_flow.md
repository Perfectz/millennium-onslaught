# Dungeon Flow

## Entry Points
- `scripts/dungeon/dungeon_run.gd`
- `scripts/dungeon/stage_runner.gd`
- `scripts/systems/wave_system.gd`
- `resources/dungeons/dungeon_1.tres`
- `resources/stages/academy_b1.tres`
- `resources/stages/academy_b2.tres`
- `resources/stages/academy_b3.tres`

## Safe Files
- Stage resource `.tres` files for encounter ordering and chunk selection
- `scripts/tools/stage_validator.gd`
- `tools/build_kaykit_academy_stage.py`
- `tests/unit/dungeon/test_academy_stage_content.gd`
- `tests/unit/dungeon/test_stage_validator.gd`

## Risky Boundaries
- `scripts/dungeon/dungeon_run.gd` scene orchestration and phase transitions
- `scripts/dungeon/stage_runner.gd` chunk seams, exits, and encounter triggers
- `scripts/systems/wave_system.gd` encounter completion and enemy recovery logic
- Generated academy room scenes under `scenes/dungeon/rooms/`

## Required Validation
- `godot --path . --headless -s res://tools/validate_stage_layouts.gd`
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/dungeon/`
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_wave_system.gd`

## Notes
- Do not hand-edit generated academy layouts unless the generator cannot express the change.
- Exit/pathing bugs should be fixed in shared stage logic or generator rules first.
