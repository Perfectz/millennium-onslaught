#!/usr/bin/env bash
# Smoke test — verifies project structure and basic integrity.
# Run from project root: bash tools/smoke_test.sh

set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN: $1"; WARN=$((WARN + 1)); }

echo "=== Millennium Onslaught Smoke Test ==="
echo ""

# --- Project Structure ---
echo "--- Project Structure ---"
[ -f "project.godot" ] && pass "project.godot exists" || fail "project.godot missing"
[ -f "INDEX.md" ] && pass "INDEX.md exists" || fail "INDEX.md missing"
[ -f "DECISIONS.md" ] && pass "DECISIONS.md exists" || fail "DECISIONS.md missing"
[ -f "CLAUDE.md" ] && pass "CLAUDE.md exists" || fail "CLAUDE.md missing"
[ -f "CONVENTIONS.md" ] && pass "CONVENTIONS.md exists" || fail "CONVENTIONS.md missing"
[ -f "AI_DEVELOPMENT_YEARLONG_ROADMAP.md" ] && pass "Roadmap exists" || fail "Roadmap missing"
[ -f "ROADMAP_EXECUTION_STATE.md" ] && pass "Execution state exists" || fail "Execution state missing"

# --- Autoloads ---
echo ""
echo "--- Autoloads ---"
for autoload in event_bus game_state game_manager constants object_pool audio_manager save_manager input_manager; do
    [ -f "autoloads/${autoload}.gd" ] && pass "autoloads/${autoload}.gd" || fail "autoloads/${autoload}.gd missing"
done

# --- Required Folders ---
echo ""
echo "--- Folder Structure ---"
for dir in scenes scripts resources assets docs tools tests addons autoloads; do
    [ -d "$dir" ] && pass "$dir/" || fail "$dir/ missing"
done

# --- Script Conventions ---
echo ""
echo "--- Script Conventions ---"
if find scripts/ -name "*.gd" 2>/dev/null | head -1 | grep -q "."; then
    # Check for hardcoded values
    HARDCODED=$(find scripts/ -name "*.gd" -exec grep -l '= [0-9]\+\.[0-9]' {} \; 2>/dev/null | grep -v "test_" | wc -l || echo "0")
    [ "$HARDCODED" -eq 0 ] && pass "No hardcoded values in scripts" || warn "$HARDCODED files may have hardcoded values"

    # Check for type hints on function signatures
    MISSING_TYPES=$(find scripts/ -name "*.gd" -exec grep -l 'func [a-z].*):$' {} \; 2>/dev/null | wc -l || echo "0")
    [ "$MISSING_TYPES" -eq 0 ] && pass "All functions have return type hints" || warn "$MISSING_TYPES files may be missing return types"
else
    warn "No scripts found in scripts/ (expected at MVP 0)"
fi

# --- Tests ---
echo ""
echo "--- Tests ---"
TEST_COUNT=$(find tests/ -name "test_*.gd" 2>/dev/null | wc -l || echo "0")
echo "  INFO: $TEST_COUNT test files found"

# --- Summary ---
echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "SMOKE TEST FAILED ($FAIL failures)"
    exit 1
else
    echo "SMOKE TEST PASSED"
    exit 0
fi
