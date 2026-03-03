# scripts/ui/

## Purpose
UI behavior scripts for HUD/screens/widgets.

## Current Contents Snapshot
Status: 22 files, 0 subfolders.
- [file] `controller_settings.gd` — Dual keyboard + joypad remapping screen
- [file] `defeat_screen.gd`
- [file] `hud.gd`
- [file] `main_menu.gd`
- [file] `pause_menu.gd` — Single-column: Resume, Save, Party, Settings, God Mode, Title, Quit
- [file] `save_load_menu.gd` — 3-slot save/load with metadata preview
- [file] `settings_menu.gd` — Unified settings (Audio / Display / Controls tabs)
- [file] `title_screen.gd`
- [file] `touch_controls.gd` — Virtual joystick + action buttons for Android
- [file] `ui_style.gd` — Shared glass-morphism helpers
- [file] `victory_screen.gd`

## AI Coding Guidance
- Gameplay/runtime logic belongs here, not in resources or assets.
- Favor explicit interfaces and event-driven communication between systems.

## Maintenance
- Update this README when folder role or conventions change.
