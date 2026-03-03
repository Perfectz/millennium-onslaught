# Stage Resources

Continuous stage definitions for the "beads on a string" belt-scroller model.

## Files

| File | Purpose |
|------|---------|
| `stage_def.gd` | StageDef resource — chunk list, encounters, pacing metadata |
| `stage_encounter_entry.gd` | StageEncounterEntry — encounter placement (trigger_x, arena bounds) |
| `piata_basement.tres` | Piata Basement stage — 6 chunks, 3 encounters |

## Architecture

StageDef references an ordered list of chunk scene paths and encounter entries.
StageRunner (scripts/dungeon/stage_runner.gd) loads chunks at runtime, tiles them
along X, and creates EncounterTrigger Area3D zones at defined positions.

## Validation

Call `stage_def.validate()` to check data integrity, or use StageValidator for
runtime checks including scene loadability and encounter spacing.
