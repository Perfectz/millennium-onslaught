# docs/events/

## Purpose
EventBus signal catalog and event contract docs.

## Current Contents Snapshot
Status: 2 files, 0 subfolders.
- [file] `event_catalog.md`
- [file] `combat_event_contracts.md`

## AI Coding Guidance
- Update docs when behavior, file layout, or interfaces change.
- Prefer concise, source-of-truth statements over roadmap speculation.
- Keep payload cells in `event_catalog.md` synchronized with `autoloads/event_bus.gd`.
- Prefer `EventBus.emit_checked()` (or `try_emit_checked()` in tests/tooling) for new emitters so the debug overlay captures recent events and flags unmatched signals.
- Run `python tools/validate_event_catalog.py` after changing EventBus signals or the catalog.

## Maintenance
- Update this README when folder role or conventions change.
