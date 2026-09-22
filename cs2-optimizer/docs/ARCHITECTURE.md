# CS2 Optimizer - Architecture

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     CS2-Launcher.bat                        │
│  (entry point: runs optimizer → CS2 → monitor → analyzer)  │
└───────────┬─────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────┐     reads     ┌──────────────────────┐
│  core/optimizer   │◄──────────────│  core/main-config    │
│  (Windows tuning) │               │  (all variables)     │
└───────────────────┘               └──────────┬───────────┘
                                               │ reads / writes
            ▼                                  │
┌───────────────────┐  JSON logs    ┌──────────▼───────────┐
│  core/monitor     │──────────────►│  logs/performance.log│
│  (background job) │               └──────────┬───────────┘
└───────────────────┘                          │
                                               │ parses
            ▼                                  │
┌───────────────────┐               ┌──────────▼───────────┐
│  core/analyzer    │──────────────►│  logs/analysis.log   │
│  (bottleneck ID)  │   reports     └──────────────────────┘
└───────────────────┘
            │
            │ (optionally updates)
            ▼
┌───────────────────┐
│  core/main-config │
└───────────────────┘
```

## Component Interactions

| Component | Reads | Writes |
|-----------|-------|--------|
| `main-config.ps1` | — | — (source of truth) |
| `optimizer.ps1` | `main-config.ps1` | Windows registry |
| `monitor.ps1` | `main-config.ps1` | `logs/performance.log` |
| `analyzer.ps1` | `performance.log`, `main-config.ps1` | `logs/analysis.log`, `main-config.ps1` |
| `performance-handler.ps1` | `main-config.ps1` | `logs/performance.log` |
| `quality-handler.ps1` | `main-config.ps1` | `logs/performance.log` |

## Data Flow

```
main-config.ps1 (settings)
       │
       ▼
optimizer.ps1 ──► Windows registry changes (reversible)
       │
       ▼
CS2 launches ──► game runs
       │
       ▼
monitor.ps1 (background) ──► performance.log (JSONL)
       │
       ▼
analyzer.ps1 ──► analysis.log (JSON report)
       │
       └──► main-config.ps1 (auto-adjust if -AutoApply)
```

## Log File Formats

### `logs/performance.log` (JSONL — one JSON object per line)

```json
{"Timestamp":"2024-01-15T12:00:00.000Z","CPU_Pct":45.2,"RAM_UsedMB":7800,"RAM_FreeMB":500,"CS2_RAM_MB":3200,"Latency_ms":28}
{"Timestamp":"2024-01-15T12:00:02.000Z","Type":"snapshot","CPU_Pct":52.0,"RAM_FreeMB":490,"CS2_RAM_MB":3210,"Latency_ms":30}
{"Timestamp":"2024-01-15T12:05:00.000Z","Type":"quality_check","NetworkResults":[...],"Recommendations":[...]}
```

### `logs/analysis.log` (single JSON object)

```json
{
  "GeneratedAt": "2024-01-15T13:00:00.000Z",
  "SamplesAnalyzed": 900,
  "Bottlenecks": ["CPU bottleneck: avg 87.3% (>85%)"],
  "Recommendations": ["Lower fps_max in cs2-config.cfg; close background apps"],
  "Summary": "1 issue(s) found."
}
```

## Extension Points

- **Add a new metric** → edit `monitor.ps1`:`$script:MonitorScriptBlock` to include additional CIM queries
- **Add a new bottleneck rule** → edit `analyzer.ps1`:`Get-Bottlenecks`
- **Add a new optimization** → add a function to `optimizer.ps1` and call it from `Invoke-CS2Optimizer`
- **Add a new in-game handler** → create a new `.ps1` in `handlers/` and bind it in `autoexec.cfg`
