#!/usr/bin/env bash
## One-command smoke test: parse check + headless unit tests.
## Usage: bash tools/smoke_test.sh [godot_path]
## Exit 0 = all clear, non-zero = failure.

set -euo pipefail

GODOT="${1:-godot}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Millennium Onslaught Smoke Test ==="
echo "Project: $PROJECT_DIR"
echo "Godot:   $GODOT"
echo ""

# --- Step 1: Parse check (loads project, registers scripts, exits) ---
echo "[1/2] Parse check (headless editor load)..."
if "$GODOT" --path "$PROJECT_DIR" --editor --headless --quit 2>&1 | tee /dev/stderr | grep -qi "error"; then
    echo "FAIL: Parse errors detected."
    exit 1
fi
echo "PASS: Parse check OK."
echo ""

# --- Step 2: Headless unit tests via GdUnit4 ---
echo "[2/2] Running GdUnit4 headless tests..."
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
echo "=== All smoke tests passed ==="
exit 0
