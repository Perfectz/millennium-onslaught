# Cross-platform-friendly sanity check entrypoint for Windows shells.
# Usage: pwsh .\tools\sanity_check.ps1 [-GodotPath godot] [-PythonPath python]

param(
    [string]$GodotPath = "godot",
    [string]$PythonPath = ""
)

$projectPath = Split-Path -Parent $PSScriptRoot

function Resolve-Python {
    param([string]$Requested)
    if ($Requested -ne "") {
        return $Requested
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return "python"
    }
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return "py -3"
    }
    throw "Python interpreter not found. Pass -PythonPath explicitly."
}

function Test-ParseOutput {
    param([string[]]$Lines)
    $failurePatterns = @(
        "SCRIPT ERROR:",
        "Parse Error:",
        "Failed to load script",
        "Failed to create an autoload"
    )
    foreach ($pattern in $failurePatterns) {
        if ($Lines | Select-String -SimpleMatch $pattern) {
            throw "Parse check failed due to '$pattern'."
        }
    }
}

$resolvedPython = Resolve-Python -Requested $PythonPath

Write-Host "=== Millennium Onslaught Sanity Check ==="
Write-Host "Project: $projectPath"
Write-Host "Godot:   $GodotPath"
Write-Host "Python:  $resolvedPython"
Write-Host ""

Write-Host "[1/4] Parse check (headless editor load)..."
$parseOutput = & $GodotPath --path $projectPath --editor --headless --quit 2>&1
$parseOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw "Godot parse check exited with code $LASTEXITCODE."
}
Test-ParseOutput -Lines $parseOutput
Write-Host "PASS: Parse check OK."
Write-Host ""

Write-Host "[2/4] Validate EventBus catalog..."
if ($resolvedPython -eq "py -3") {
    & py -3 "$PSScriptRoot\validate_event_catalog.py"
} else {
    & $resolvedPython "$PSScriptRoot\validate_event_catalog.py"
}
if ($LASTEXITCODE -ne 0) {
    throw "Event catalog validation failed."
}
Write-Host ""

Write-Host "[3/4] Validate stage layouts..."
& $GodotPath --path $projectPath --headless `
    -s res://tools/validate_stage_layouts.gd
if ($LASTEXITCODE -ne 0) {
    throw "Stage layout validation failed with code $LASTEXITCODE."
}
Write-Host ""

Write-Host "[4/4] Run GdUnit4 unit tests..."
& $GodotPath --path $projectPath --headless `
    -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd `
    --ignoreHeadlessMode `
    --add tests/unit/
if ($LASTEXITCODE -ne 0) {
    throw "Unit tests exited with code $LASTEXITCODE."
}

Write-Host ""
Write-Host "=== Sanity check passed ==="
