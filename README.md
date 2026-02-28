# Windows Tips & CS2 Performance Toolkit

A collection of Windows optimization scripts and a full CS2 performance toolkit for low-spec PCs (8–16 GB RAM).

---

## Repository Structure

```
windows-tips/
├── cs2-config.cfg              # Standalone CS2 config (copy to CS2 cfg/ folder)
├── cs2-optimizer/              # Full CS2 optimizer suite
│   ├── bin/
│   │   ├── CS2-Launcher.bat    # One-click launcher (entry point)
│   │   └── build-exe.ps1       # Compiles scripts into a standalone EXE
│   ├── configs/
│   │   ├── autoexec.cfg        # CS2 autoexec (loads config + binds F9/F10)
│   │   └── cs2-config.cfg      # Optimized CS2 settings for low-spec PCs
│   ├── core/
│   │   ├── main-config.ps1     # All configurable variables (edit this first)
│   │   ├── optimizer.ps1       # Windows tweaks: network, RAM, input lag
│   │   ├── monitor.ps1         # Background performance logger (JSONL)
│   │   └── analyzer.ps1        # Post-session bottleneck analyzer
│   ├── handlers/
│   │   ├── performance-handler.ps1  # F9 in-game snapshot
│   │   └── quality-handler.ps1      # F10 network quality check
│   └── logs/                   # Auto-created; holds performance.log & analysis.log
├── remove-startup-apps.ps1     # Remove startup entries interactively
├── startup-cleaner-hint.ps1    # Quick one-shot startup cleaner
└── validator.ps1               # Disk-usage report for a user profile
```

---

## CS2 Config (Standalone)

The root-level `cs2-config.cfg` is a self-contained CS2 configuration file with tuned mouse, crosshair, network, HUD, audio, FPS, and bind settings.

### Installation

Copy the file to your CS2 `cfg` directory:

```
%ProgramFiles(x86)%\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\
```

Then add to **CS2 Launch Options** in Steam (right-click CS2 → Properties → General):

```
+exec cs2-config
```

### Key Settings

| Category | Setting | Value | Purpose |
|----------|---------|-------|---------|
| Mouse | `m_rawinput` | `1` | Raw input (bypasses Windows accel) |
| Network | `rate` | `786432` | ~6 Mbit – Valve recommended max |
| Network | `cl_updaterate` | `128` | 128-tick server updates |
| Crosshair | `cl_crosshairstyle` | `4` | Static crosshair |
| FPS | `fps_max` | `400` | Uncapped for high-refresh monitors |

---

## CS2 Optimizer Suite

### Quick Start

1. Copy the `cs2-optimizer/` folder anywhere on your PC.
2. Copy `cs2-optimizer/configs/cs2-config.cfg` and `cs2-optimizer/configs/autoexec.cfg` to:
   ```
   %ProgramFiles(x86)%\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\
   ```
3. Add to CS2 launch options in Steam:
   ```
   +exec autoexec
   ```
4. Double-click `bin/CS2-Launcher.bat` (or right-click → **Run as Administrator** for full effect).

---

### `bin/CS2-Launcher.bat` — One-Click Launcher

Runs the optimizer, starts the background monitor, launches CS2 via Steam, and runs the analyzer when you exit.

**Execution example:**
```bat
REM Double-click or run from Command Prompt:
bin\CS2-Launcher.bat
```

Expected output:
```
[CS2 Launcher] Running optimizer...
[CS2 Launcher] Starting background monitor...
[CS2 Launcher] Launching CS2 via Steam...
[CS2 Launcher] CS2 is running. Waiting for exit...
[CS2 Launcher] CS2 exited. Stopping monitor...
[CS2 Launcher] Running analyzer...
[CS2 Launcher] Done. Check logs\ for performance report.
```

---

### `bin/build-exe.ps1` — Build Standalone EXE

Compiles all optimizer scripts into a single `CS2-Optimizer.exe` using the [PS2EXE](https://github.com/MScholtes/PS2EXE) module (auto-installed if missing).

**Execution example:**
```powershell
# Run from the cs2-optimizer/ directory
.\bin\build-exe.ps1
```

Expected output:
```
Installing PS2EXE module...   # only on first run
Compiling CS2-Optimizer.exe...
Build complete: C:\...\cs2-optimizer\bin\CS2-Optimizer.exe
```

---

### `core/optimizer.ps1` — Windows Optimization Module

Applies three optimizations and scans for crypto miners:

| Step | What it does |
|------|-------------|
| Network | Disables TCP auto-tuning; disables network throttling |
| RAM | Clears standby memory; sets CS2 process priority to High |
| Input lag | Disables mouse acceleration via registry |
| Miner scan | Warns if known miner processes are detected |

**Execution examples:**
```powershell
# Run full optimization (shows progress bar)
.\core\optimizer.ps1

# Run silently (no console output) — used by the launcher
.\core\optimizer.ps1 -Silent

# Dry run — shows what would change without applying anything
.\core\optimizer.ps1 -DryRun

# Dot-source and call the function directly
. .\core\optimizer.ps1
Invoke-CS2Optimizer
Invoke-CS2Optimizer -Silent
Invoke-CS2Optimizer -DryRun
```

Exit codes: `0` = success, `1` = partial failure / miner found, `2` = critical failure.

---

### `core/monitor.ps1` — Real-Time Performance Monitor

Logs CPU, RAM, CS2 RAM, and network latency to `logs/performance.log` (one JSON line every 2 seconds) while CS2 is running.

**Execution examples:**
```powershell
# Start the monitor directly (blocks until CS2 exits or Ctrl+C)
.\core\monitor.ps1

# Dot-source and start/stop manually
. .\core\monitor.ps1
$job = Start-CS2Monitor
# ... CS2 session ...
Stop-CS2Monitor
```

Sample log entry written to `logs/performance.log`:
```json
{"Timestamp":"2024-06-01T18:00:00.000Z","CPU_Pct":45.2,"RAM_UsedMB":7800,"RAM_FreeMB":512,"CS2_RAM_MB":3200,"CS2_CPU_Pct":22.5,"Latency_ms":28,"GPU_Temp_C":null}
```

---

### `core/analyzer.ps1` — Log Analyzer

Parses `logs/performance.log`, identifies CPU / RAM / network bottlenecks, generates recommendations, and writes `logs/analysis.log`.

**Execution examples:**
```powershell
# Analyze the last session
.\core\analyzer.ps1

# Analyze and auto-apply fixes to core/main-config.ps1
.\core\analyzer.ps1 -AutoApply

# Dot-source and call the function directly
. .\core\analyzer.ps1
$report = Invoke-CS2Analyzer
$report = Invoke-CS2Analyzer -AutoApply
Write-Host $report.Summary
```

Sample console output:
```
=== CS2 Analysis Report ===
Samples : 900
Summary : 1 issue(s) found.

Bottlenecks:
  - CPU bottleneck: avg 87.3% (>85%)

Recommendations:
  - Lower fps_max in cs2-config.cfg; close background apps

Full report saved to: logs\analysis.log
```

Sample `logs/analysis.log`:
```json
{
  "GeneratedAt": "2024-06-01T19:00:00.000Z",
  "SamplesAnalyzed": 900,
  "Bottlenecks": ["CPU bottleneck: avg 87.3% (>85%)"],
  "Recommendations": ["Lower fps_max in cs2-config.cfg; close background apps"],
  "Summary": "1 issue(s) found."
}
```

---

### `handlers/performance-handler.ps1` — F9 Performance Snapshot

Takes an instant CPU / RAM / latency snapshot and appends it to `logs/performance.log`.

**Execution examples:**
```powershell
# Run directly for a standalone snapshot
.\handlers\performance-handler.ps1
```

Expected output:
```
=== CS2 Performance Snapshot ===
CPU     : 52.1%
RAM Free: 3840 MB
CS2 RAM : 3215.4 MB
Latency : 31 ms
Snapshot saved to log.
```

In-game (requires `autoexec.cfg` loaded):
```
F9   →  exec performance_check  →  triggers this handler
```

---

### `handlers/quality-handler.ps1` — F10 Network Quality Check

Sends 5 pings to three DNS servers (8.8.8.8, 1.1.1.1, 208.67.222.222), measures latency, packet loss, and jitter, then logs and displays recommendations.

**Execution examples:**
```powershell
# Run directly for a standalone network quality check
.\handlers\quality-handler.ps1
```

Expected output:
```
=== CS2 Network Quality Check ===
[8.8.8.8]         Latency: 18.2 ms  | Loss: 0%  | Jitter: 1.4 ms
[1.1.1.1]         Latency: 17.8 ms  | Loss: 0%  | Jitter: 1.1 ms
[208.67.222.222]  Latency: 22.0 ms  | Loss: 0%  | Jitter: 2.0 ms

Recommendations:
  - Network quality looks good.

Results saved to log.
```

In-game (requires `autoexec.cfg` loaded):
```
F10  →  exec quality_check  →  triggers this handler
```

---

### `core/main-config.ps1` — Configuration Reference

All tunable variables live here. Edit before running any script.

| Variable | Default | Description |
|----------|---------|-------------|
| `$Config_RAM_MaxUsageMB` | `14336` | Max RAM target (14 GB of 16 GB) |
| `$Config_RAM_MinFreeMB` | `2048` | Minimum free RAM to maintain (MB) |
| `$Config_CPU_PriorityCS2` | `High` | CS2 process priority |
| `$Config_Net_Rate` | `786432` | Bandwidth cap (bytes/sec) |
| `$Config_Net_UpdateRate` | `128` | Server update rate |
| `$Config_Perf_FPSTarget` | `144` | FPS cap written to cs2-config.cfg |
| `$Config_Perf_LatencyWarningMs` | `80` | Latency warning threshold (ms) |
| `$Config_Sec_EnableMinerDetect` | `$true` | Scan for crypto miners on startup |
| `$Config_Path_Steam` | auto | Override Steam install path |

---

## Windows Startup Scripts

### `remove-startup-apps.ps1` — Interactive Startup Manager

Displays all startup programs (WMI + HKCU/HKLM registry) and lets you remove them by name.

**Execution example:**
```powershell
.\remove-startup-apps.ps1
```

Expected output:
```
Removes Startup HKCU and HKLM Entries
================================
CURRENT STARTUP PROGRAMS:
1. OneDrive
   Path: C:\Users\...\OneDrive.exe /background
   Location: HKU\...\Run

REGISTRY STARTUP ITEMS:
2. Teams
   Command: C:\Users\...\Teams.exe

================================
OPTIONS:
 -Type service name to DISABLE it
 -Type 'refresh' to reload list
 -Type 'exit' to quit

Enter service/program name: OneDrive
Found: OneDrive
Remove 'OneDrive' from startup? (y/n): y
Removed 'OneDrive' from startup!
```

---

### `startup-cleaner-hint.ps1` — Quick Startup Cleaner

Non-interactive one-shot script. Removes OneDrive, Chime, Teams, and Edge from startup entries in both HKCU and HKLM, disables Teams auto-start, and turns off Edge startup boost.

**Execution example:**
```powershell
# Run as Administrator for HKLM entries
.\startup-cleaner-hint.ps1
```

Expected output:
```
Current startup programs:
Name      Command                          Location
----      -------                          --------
OneDrive  C:\...\OneDrive.exe /background  HKU\...\Run
```

---

### `validator.ps1` — Disk Usage Report

Reports the size of each folder under a user profile, then drills into common directories.

**Execution example:**
```powershell
.\validator.ps1
```

Expected output:
```
Name        SizeGB SizeMB LastModified
----        ------ ------ ------------
AppData       8.43   8637 6/1/2024 10:22:05 AM
OneDrive      4.10   4201 5/30/2024 3:14:00 PM
Downloads     2.75   2816 6/1/2024 9:00:00 AM
...

AppData: 8637 MB (8.43 GB)
Documents: 512 MB (0.5 GB)
Downloads: 2816 MB (2.75 GB)
...
```

---

## System Requirements

| Component | Minimum |
|-----------|---------|
| OS | Windows 10 / 11 |
| PowerShell | 5.1 (built-in) |
| RAM | 8 GB |
| Game | Counter-Strike 2 (Steam) |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Steam not found" | Set `$Config_Path_Steam` in `core/main-config.ps1` |
| Monitor job not starting | Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| No GPU temperature shown | Install OpenHardwareMonitor (optional) |
| Registry backup not created | Run launcher / optimizer as Administrator |
| HKLM entries not removed | Run startup scripts as Administrator |
