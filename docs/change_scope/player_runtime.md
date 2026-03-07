# Player Runtime

## Entry Points
- `scripts/core/player_controller.gd`
- `autoloads/input_manager.gd`
- `scripts/systems/camera_follow.gd`
- `scripts/ui/debug_overlay.gd`
- `scripts/tools/debug_bundle_capture.gd`

## Safe Files
- Input defaults and debug actions in `autoloads/input_manager.gd`
- Debug capture and overlays in `scripts/ui/debug_overlay.gd` and `scripts/tools/debug_bundle_capture.gd`
- Isolated player regression tests under `tests/unit/systems/`

## Risky Boundaries
- `scripts/core/player_controller.gd` state machine wiring and combat callbacks
- `scripts/systems/camera_follow.gd` player visibility and movement framing
- Any direct edits that bypass `InputManager`

## Required Validation
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_input_remapping.gd`
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_player_controller_runtime.gd`
- `godot --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --add tests/unit/systems/test_debug_bundle_capture.gd`

## Notes
- New debug/runtime tooling should prefer JSON-safe snapshots over ad hoc print spam.
- Raw `Input.is_action_*` calls outside `InputManager` are a regression unless there is a strong reason.
