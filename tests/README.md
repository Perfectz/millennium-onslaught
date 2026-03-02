# tests/

## Purpose
Contains automated tests, primarily GdUnit4 suites.

## Structure
- `unit/`: unit-level tests by domain.
- `unit/components/`: pure component tests.
- `unit/systems/`: pure/system logic tests.
- `unit/data/`: data/resource contract tests.
- `unit/utils/`: utility/helper tests.
- `integration/`: cross-system behavior tests.

## AI Coding Guidance
- Add or update tests whenever gameplay logic contracts change.
- Keep tests focused and name them by behavior (`test_<behavior>()`).
- Mirror source domains to keep navigation predictable.
- Update the matching subfolder README when folder conventions change.

## Run
- Editor: GdUnit4 panel -> Run All Tests.
- CLI: `godot --headless -s addons/gdUnit4/runtest.sh --add tests/`
