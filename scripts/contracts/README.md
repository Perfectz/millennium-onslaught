# scripts/contracts/

## Purpose
Typed runtime event payloads and other code-level contracts shared across systems.

## Current Contents Snapshot
Status: 2 files, 0 subfolders.
- [file] `combat_hit_event.gd`
- [file] `combat_kill_event.gd`

## AI Coding Guidance
- Prefer adding canonical typed payloads here before expanding EventBus signals with positional arguments.
- Keep contracts small, explicit, and versioned.
- Use additive migration: introduce canonical payload signals first, then retire legacy signals after listeners are moved.

## Maintenance
- Update this README when the contract surface changes.
