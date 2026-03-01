# tests/ — GdUnit4 Test Files

All automated tests live here, mirroring the `scripts/` folder structure.

## Structure

```
tests/
├── unit/
│   ├── components/    # Tests for scripts/components/ (pure logic)
│   ├── systems/       # Tests for scripts/systems/
│   ├── utils/         # Tests for scripts/utils/
│   └── data/          # Tests for data validation
└── integration/       # Cross-system integration tests
```

## Naming Convention

- Test files: `test_<source_file_name>.gd`
- Example: `scripts/components/health_component.gd` → `tests/unit/components/test_health_component.gd`
- Test functions: `test_<behavior_being_tested>()`

## Running Tests

From Godot editor: GdUnit4 panel → Run All Tests
From command line: `godot --headless -s addons/gdUnit4/runtest.sh --add tests/`

## TDD Cycle

1. Write a failing test describing expected behavior
2. Write minimum code to pass it
3. Refactor to clean up
4. Run full test suite to confirm nothing broke
