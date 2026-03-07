# scenes/dungeon/rooms/

## Purpose
Room-scale dungeon scenes and room-local dev/test content.

## Current Contents Snapshot
Status: 9 files, 0 subfolders.
- [file] `academy_b1_entry.tscn`
- [file] `academy_b1_corridors.tscn`
- [file] `academy_b2_library.tscn`
- [file] `academy_b2_storage.tscn`
- [file] `academy_b3_gauntlet.tscn`
- [file] `academy_b3_boss.tscn`
- [file] `test_arena.gd`
- [file] `test_arena.gd.uid`
- [file] `test_arena.tscn`

Legacy `room_01` / `room_02` / `room_03` / `room_boss` scenes were removed after the project moved to stage-based Piata content.

## Generated Content
- `academy_b1_entry.tscn`
- `academy_b1_corridors.tscn`
- `academy_b2_storage.tscn`
- `academy_b2_library.tscn`
- `academy_b3_gauntlet.tscn`
- `academy_b3_boss.tscn`

These KayKit-based academy rooms are generated from `tools/build_kaykit_academy_stage.py`. Regenerate them after changing layout data in that script instead of hand-editing the scene files.

## AI Coding Guidance
- Keep scene composition local; avoid tight cross-scene node-path coupling.
- Attach behavior scripts from `scripts/` where practical and keep paths explicit.

## Maintenance
- Update this README when folder role or conventions change.
