#!/usr/bin/env bash
# Export all platforms locally.
# Usage: bash tools/export_all.sh [godot_path]
# Default godot_path: godot (assumes in PATH)

set -euo pipefail

GODOT="${1:-godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Millennium Onslaught — Export All ==="
echo "Godot: $GODOT"
echo "Project: $PROJECT_DIR"
echo ""

# Import project first.
echo "--- Importing project ---"
"$GODOT" --headless --path "$PROJECT_DIR" --import --quit-after 30 || true
echo ""

# Export Linux.
echo "--- Exporting Linux ---"
mkdir -p "$PROJECT_DIR/export/pc/linux"
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Linux" \
  "$PROJECT_DIR/export/pc/linux/millennium-onslaught.x86_64" 2>&1 || echo "Linux export failed (preset may not be configured)"
echo ""

# Export Windows.
echo "--- Exporting Windows ---"
mkdir -p "$PROJECT_DIR/export/pc/windows"
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Windows Desktop" \
  "$PROJECT_DIR/export/pc/windows/millennium-onslaught.exe" 2>&1 || echo "Windows export failed (preset may not be configured)"
echo ""

# Export Android Debug.
echo "--- Exporting Android (Debug) ---"
mkdir -p "$PROJECT_DIR/export/android"
"$GODOT" --headless --path "$PROJECT_DIR" --export-debug "Android" \
  "$PROJECT_DIR/export/android/millennium-onslaught-debug.apk" 2>&1 || echo "Android debug export failed (preset may not be configured)"
echo ""

# Export Android Release.
echo "--- Exporting Android (Release) ---"
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Android" \
  "$PROJECT_DIR/export/android/millennium-onslaught-release.apk" 2>&1 || echo "Android release export failed (preset may not be configured)"
echo ""

echo "=== Export Complete ==="
echo "Check export/ directory for build artifacts."
