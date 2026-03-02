# Millennium Onslaught - Project README

## Purpose
This repository is a Godot 4 belt-scroller project. Folder READMEs are structured for fast AI and human navigation.

## First Stop Docs
- `INDEX.md`: implementation snapshot.
- `DECISIONS.md`: architecture and design decisions.
- `PROJECT_PLAN_GODOT4_BELTSCROLLER.md`: roadmap and scope plan.
- `CLAUDE.md`: project collaboration instructions.

## Folder Map
- `autoloads/`: global singleton services.
- `scenes/`: runtime scene trees.
- `scripts/`: gameplay/runtime logic.
- `resources/`: data resources.
- `tests/`: automated tests.
- `docs/`: event/schema and architecture docs.
- `assets/`: source art/audio/content.
- `tools/`: local debug/editor tooling.
- `addons/`: external plugin code.
- `export/`: platform export outputs/configs.
- `reports/`: generated test reports.
- `humandropbox/`: human-curated staging/reference assets.

## AI Coding Workflow
1. Read the target folder `README.md` before editing files in that folder.
2. Update related folder README/docs when behavior or structure changes.
3. Keep runtime logic in `scripts/`, data in `resources/`, and tests in `tests/`.
