# docs/change_scope/

## Purpose
AI-facing edit boundaries for core systems.

## Format
- `Entry Points`: where to start reading for the subsystem.
- `Safe Files`: low-risk files for focused edits.
- `Risky Boundaries`: files or seams where broad changes ripple quickly.
- `Required Validation`: tests and scripts that must run after edits.

## Guidance
- Prefer the narrowest file set that can satisfy a change.
- When a request crosses a risky boundary, update docs/tests in the same patch.
- Keep this folder concrete. Avoid roadmap prose and vague ownership notes.
