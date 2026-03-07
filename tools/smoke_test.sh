#!/usr/bin/env bash
## One-command sanity check: parse check + event catalog validation + unit tests.
## Usage: bash tools/smoke_test.sh [godot_path] [python_path]
## Exit 0 = all clear, non-zero = failure.

set -euo pipefail

GODOT="${1:-godot}"
PYTHON="${2:-python3}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Millennium Onslaught Sanity Check ==="
echo "Project: $PROJECT_DIR"
echo "Godot:   $GODOT"
echo "Python:  $PYTHON"
echo ""

# --- Step 1: Parse check (loads project, registers scripts, exits) ---
echo "[1/4] Parse check (headless editor load)..."
PARSE_OUTPUT="$("$GODOT" --path "$PROJECT_DIR" --editor --headless --quit 2>&1 || true)"
printf '%s\n' "$PARSE_OUTPUT"
if printf '%s\n' "$PARSE_OUTPUT" | grep -Eq "SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to create an autoload"; then
    echo "FAIL: Parse errors detected."
    exit 1
fi
echo "PASS: Parse check OK."
echo ""

# --- Step 2: EventBus catalog validation ---
echo "[2/4] Validate EventBus catalog..."
"$PYTHON" "$PROJECT_DIR/tools/validate_event_catalog.py"
echo ""

# --- Step 3: Stage layout validation ---
echo "[3/4] Validate stage layouts..."
"$GODOT" --path "$PROJECT_DIR" --headless \
    -s res://tools/validate_stage_layouts.gd
echo ""

# --- Step 4: Headless unit tests via GdUnit4 ---
echo "[4/4] Running GdUnit4 headless tests..."
"$GODOT" --path "$PROJECT_DIR" --headless \
    -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
    --ignoreHeadlessMode \
    --add tests/unit/
TEST_EXIT=$?

if [ $TEST_EXIT -ne 0 ]; then
    echo "FAIL: Tests exited with code $TEST_EXIT."
    exit $TEST_EXIT
fi

echo ""
echo "=== All sanity checks passed ==="
exit 0
