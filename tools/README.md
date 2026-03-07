# tools/

## Purpose
Project tooling outside runtime game scripts (debug and editor extensions).

## Current Contents Snapshot
Status: 6 files, 2 subfolders.
- [file] `README.md`
- [file] `build_kaykit_academy_stage.py`
- [file] `sanity_check.ps1`
- [file] `smoke_test.sh`
- [file] `validate_event_catalog.py`
- [file] `validate_stage_layouts.gd`
- [dir] `debug/`
- [dir] `editor_plugins/`

## Notable Tools
- `build_kaykit_academy_stage.py`
  Rebuilds the Piata academy room scenes from the KayKit Dungeon Remastered pack and central layout data.
- `validate_stage_layouts.gd`
  Headless Godot validator for StageDef resources and generated stage layout contracts.

## AI Coding Guidance
- Keep non-runtime tooling isolated from core gameplay code.
- Document expected usage and scope in each tool script.

## Maintenance
- Update this README when folder role or conventions change.
