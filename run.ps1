# Run Millennium Onslaught
# Usage: .\run.ps1           — run the game
#        .\run.ps1 -editor   — open in Godot editor
#        .\run.ps1 -verbose  — run with console output visible

param(
    [switch]$editor,
    [switch]$verbose
)

$projectPath = $PSScriptRoot

if ($editor) {
    godot --editor --path "$projectPath"
} elseif ($verbose) {
    godot --path "$projectPath" --verbose
} else {
    godot --path "$projectPath"
}
