# CS2 Optimizer - Usage Guide

## First-Time Setup

1. **Copy config files** to CS2 cfg directory:
   ```
   %ProgramFiles(x86)%\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg\
   ```
   Files to copy: `configs/cs2-config.cfg` and `configs/autoexec.cfg`

2. **Set CS2 launch options** in Steam (right-click CS2 → Properties → General):
   ```
   +exec autoexec
   ```

3. **Run the launcher** (right-click → Run as Administrator for full optimization):
   ```
   bin\CS2-Launcher.bat
   ```

## Customizing `core/main-config.ps1`

Open `core/main-config.ps1` in Notepad or VS Code and adjust the variables at the top:

| Variable | Default | Description |
|----------|---------|-------------|
| `$Config_Perf_FPSTarget` | 144 | Target FPS cap in cs2-config.cfg |
| `$Config_Net_Rate` | 786432 | Max bandwidth (bytes/sec) |
| `$Config_Net_UpdateRate` | 128 | Server update rate |
| `$Config_RAM_MinFreeMB` | 2048 | Min free RAM to keep (MB) |
| `$Config_Sec_EnableMinerDetect` | `$true` | Scan for crypto miners |
| `$Config_Path_Steam` | auto | Override Steam install path |

After changing `$Config_Net_UpdateRate`, also update `cl_updaterate` in `configs/cs2-config.cfg` to match.

## Understanding Logs

### `logs/performance.log`
Contains one JSON entry per line recorded every 2 seconds while CS2 runs.  
Key fields: `CPU_Pct`, `RAM_UsedMB`, `RAM_FreeMB`, `CS2_RAM_MB`, `Latency_ms`

### `logs/analysis.log`
Generated after each CS2 session. Contains:
- `SamplesAnalyzed` — number of monitor readings
- `Bottlenecks` — list of detected issues
- `Recommendations` — suggested fixes

## Using In-Game Handlers (F9 / F10)

While in CS2 (requires `autoexec.cfg` loaded):

| Key | Action |
|-----|--------|
| **F9** | Takes a performance snapshot (CPU, RAM, latency) and saves to log |
| **F10** | Runs a 5-ping network quality test and shows recommendations |

Results appear in the CS2 console and are saved to `logs/performance.log`.

> **Note:** The `exec performance_check` and `exec quality_check` binds require matching `.cfg` files in your CS2 `cfg/` directory. The provided `autoexec.cfg` already uses these bind names; the handlers are intended to be triggered externally (e.g., via a companion tool or custom `.cfg` that calls a shell command). For a simpler setup, you can run `handlers/performance-handler.ps1` and `handlers/quality-handler.ps1` directly from a PowerShell window at any time.

## Reading Analysis Reports

After each session, open `logs/analysis.log`:
```json
{
  "Summary": "1 issue(s) found.",
  "Bottlenecks": ["CPU bottleneck: avg 87.3% (>85%)"],
  "Recommendations": ["Lower fps_max; close background apps"]
}
```

## Manual Optimization Tips

- **Close browser tabs** before launching CS2 — each tab uses ~50-150 MB RAM
- **Disable Game Bar** in Windows Settings → Gaming → Xbox Game Bar
- **Set power plan** to High Performance in Control Panel → Power Options
- **Update GPU drivers** monthly for the latest CS2 optimizations
- **Use wired Ethernet** — Wi-Fi adds 5-30 ms jitter
- **Disable Discord overlay** in Discord Settings → Overlay — saves ~100 MB RAM
