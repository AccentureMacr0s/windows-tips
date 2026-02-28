@echo off
setlocal EnableDelayedExpansion

:: ============================================================================
:: CS2 Optimizer Launcher
:: ============================================================================
:: Runs optimizer, starts background monitor, launches CS2, then runs analyzer.

:: Locate PowerShell
set PS=powershell.exe -NoProfile -ExecutionPolicy Bypass

:: Resolve script directory
set SCRIPT_DIR=%~dp0..

echo [CS2 Launcher] Running optimizer...
%PS% -File "%SCRIPT_DIR%\core\optimizer.ps1"
if errorlevel 2 (
    echo [CS2 Launcher] Critical optimizer failure. Aborting.
    pause
    exit /b 2
)

echo [CS2 Launcher] Starting background monitor...
%PS% -WindowStyle Hidden -File "%SCRIPT_DIR%\core\monitor.ps1" &
set MONITOR_PID=%ERRORLEVEL%

echo [CS2 Launcher] Launching CS2 via Steam...
start "" "steam://rungameid/730"

:: Wait for CS2 to start (up to 30 seconds)
set /a WAIT=0
:wait_cs2_start
timeout /t 2 /nobreak >nul
%PS% -Command "if (Get-Process cs2 -EA SilentlyContinue) { exit 0 } else { exit 1 }"
if not errorlevel 1 goto cs2_running
set /a WAIT+=2
if !WAIT! lss 30 goto wait_cs2_start
echo [CS2 Launcher] CS2 did not start within 30 seconds.
goto cleanup

:cs2_running
echo [CS2 Launcher] CS2 is running. Waiting for exit...
:wait_cs2_exit
timeout /t 5 /nobreak >nul
%PS% -Command "if (Get-Process cs2 -EA SilentlyContinue) { exit 0 } else { exit 1 }"
if not errorlevel 1 goto wait_cs2_exit

:cleanup
echo [CS2 Launcher] CS2 exited. Stopping monitor...
%PS% -Command "Get-Job | Stop-Job; Get-Job | Remove-Job" >nul 2>&1

echo [CS2 Launcher] Running analyzer...
%PS% -File "%SCRIPT_DIR%\core\analyzer.ps1"

echo [CS2 Launcher] Done. Check logs\ for performance report.
pause
endlocal
