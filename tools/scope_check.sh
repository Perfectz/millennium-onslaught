#!/usr/bin/env bash
# Scope check — validates that changed files match a declared scope.
# Usage: bash tools/scope_check.sh <scope_file>
# The scope file should contain one file path per line (from CHANGE_SCOPE.md).
# Compares against git diff to find out-of-scope changes.

set -euo pipefail

SCOPE_FILE="${1:-}"

if [ -z "$SCOPE_FILE" ]; then
    echo "Usage: bash tools/scope_check.sh <scope_file>"
    echo ""
    echo "The scope file should list one file path per line."
    echo "This tool compares git changes against the declared scope."
    exit 1
fi

if [ ! -f "$SCOPE_FILE" ]; then
    echo "ERROR: Scope file not found: $SCOPE_FILE"
    exit 1
fi

echo "=== Scope Check ==="
echo "Scope file: $SCOPE_FILE"
echo ""

# Get changed files from git.
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "")

if [ -z "$CHANGED_FILES" ]; then
    echo "No changed files detected."
    exit 0
fi

# Read scope file.
SCOPE_PATTERNS=$(grep -v '^#' "$SCOPE_FILE" | grep -v '^$' | sed 's/^ *//' | sed 's/ *$//')

IN_SCOPE=0
OUT_OF_SCOPE=0
OUT_OF_SCOPE_FILES=""

while IFS= read -r changed_file; do
    FOUND=false
    while IFS= read -r pattern; do
        if [[ "$changed_file" == $pattern ]] || [[ "$changed_file" == "$pattern" ]]; then
            FOUND=true
            break
        fi
    done <<< "$SCOPE_PATTERNS"

    if $FOUND; then
        echo "  IN SCOPE: $changed_file"
        ((IN_SCOPE++))
    else
        echo "  OUT OF SCOPE: $changed_file"
        OUT_OF_SCOPE_FILES="$OUT_OF_SCOPE_FILES\n  $changed_file"
        ((OUT_OF_SCOPE++))
    fi
done <<< "$CHANGED_FILES"

echo ""
echo "=== Results ==="
echo "  In scope: $IN_SCOPE"
echo "  Out of scope: $OUT_OF_SCOPE"

if [ "$OUT_OF_SCOPE" -gt 0 ]; then
    echo ""
    echo "WARNING: Out-of-scope changes detected:"
    echo -e "$OUT_OF_SCOPE_FILES"
    echo ""
    echo "Review these changes and add them to your scope declaration if intentional."
    exit 1
else
    echo ""
    echo "All changes are within declared scope."
    exit 0
fi
