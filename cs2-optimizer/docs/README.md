# CS2 Performance Optimizer

A comprehensive Windows optimization and real-time monitoring system for Counter-Strike 2, designed for low-spec PCs (8–16 GB RAM).

## Features

- **One-click launcher** – optimizes Windows, starts CS2, monitors performance, then generates a report
- **Network optimization** – disables TCP auto-tuning and throttling for consistent low latency
- **RAM optimization** – clears standby memory before launch on 8–16 GB systems
- **Input lag reduction** – disables mouse acceleration via registry
- **Real-time monitoring** – logs CPU, RAM, latency every 2 seconds to `logs/performance.log` (JSON)
- **Log analyzer** – identifies CPU/RAM/network bottlenecks and generates recommendations
- **In-game handlers** – press F9 (performance snapshot) or F10 (network quality) during gameplay
- **Crypto miner detection** – scans for known miner processes at startup
- **Configurable** – all settings in one file: `core/main-config.ps1`

## System Requirements

| Component | Minimum |
|-----------|---------|
| OS        | Windows 10 / 11 |
| PowerShell | 5.1 (built-in) |
| RAM       | 8 GB |
| Game      | Counter-Strike 2 (Steam) |

## Quick Start

1. Copy the `cs2-optimizer/` folder anywhere on your PC.
2. Copy `configs/cs2-config.cfg` and `configs/autoexec.cfg` to your CS2 `cfg/` directory.
3. Double-click `bin/CS2-Launcher.bat` — it will:
   - Run Windows optimizations
   - Start the background monitor
   - Launch CS2 via Steam
   - After you exit CS2, run the analyzer and show a summary

## Installation

### Config Files
```
%ProgramFiles(x86)%\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\
```
Copy both `cs2-config.cfg` and `autoexec.cfg` there.

### CS2 Launch Options (Steam)
Add to CS2 launch options in Steam:
```
+exec autoexec
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Steam not found" | Set `$Config_Path_Steam` in `core/main-config.ps1` |
| Monitor job not starting | Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| No GPU temperature shown | Install OpenHardwareMonitor (optional) |
| Registry backup not created | Run launcher as Administrator |
