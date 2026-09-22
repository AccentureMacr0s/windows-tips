# =============================================================================
# CS2 Optimizer - Build EXE from PS scripts using PS2EXE
# =============================================================================
# Usage: .\bin\build-exe.ps1
# Requires PS2EXE module (installed automatically if missing).
# =============================================================================
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$rootDir    = Split-Path $PSScriptRoot -Parent
$outputDir  = Join-Path $rootDir "bin"
$outputExe  = Join-Path $outputDir "CS2-Optimizer.exe"
$launcherPs = Join-Path $rootDir "bin\launcher-entry.ps1"

# Ensure PS2EXE is available
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "Installing PS2EXE module..." -ForegroundColor Yellow
    Install-Module -Name ps2exe -Scope CurrentUser -Force -ErrorAction Stop
}
Import-Module ps2exe

# Generate a temporary entry-point that wraps the launcher logic
$entryScript = @'
#Requires -Version 5.1
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$root      = Split-Path $ScriptDir -Parent

. "$root\core\main-config.ps1"
. "$root\core\optimizer.ps1"
. "$root\core\monitor.ps1"

Invoke-CS2Optimizer -Silent
$job = Start-CS2Monitor

Start-Process "steam://rungameid/730"

# Wait for CS2 to exit
do { Start-Sleep -Seconds 5 }
until (-not (Get-Process cs2 -ErrorAction SilentlyContinue))

Stop-CS2Monitor

. "$root\core\analyzer.ps1"
$report = Invoke-CS2Analyzer
Write-Host $report.Summary
'@

Set-Content -Path $launcherPs -Value $entryScript -Encoding UTF8

Write-Host "Compiling CS2-Optimizer.exe..." -ForegroundColor Cyan
Invoke-ps2exe -InputFile $launcherPs -OutputFile $outputExe `
    -NoConsole:$false `
    -Title "CS2 Optimizer" `
    -Version "1.0.0" `
    -Description "CS2 Performance Optimizer Launcher" `
    -ErrorAction Stop

Remove-Item $launcherPs -ErrorAction SilentlyContinue

Write-Host "Build complete: $outputExe" -ForegroundColor Green
