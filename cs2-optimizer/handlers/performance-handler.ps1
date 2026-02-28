# =============================================================================
# CS2 Performance Handler - Quick Performance Snapshot
# =============================================================================
# Called from CS2 console via: exec performance_check
# Or run directly from PowerShell for a standalone snapshot.
# =============================================================================
#Requires -Version 5.1

# Load monitor functions
$monitorPath = Join-Path $PSScriptRoot "..\core\monitor.ps1"
if (Test-Path $monitorPath) { . $monitorPath }

$configPath = Join-Path $PSScriptRoot "..\core\main-config.ps1"
if (Test-Path $configPath) { . $configPath }

function Get-PerformanceSnapshot {
    $ts  = [datetime]::UtcNow.ToString("o")
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue |
            Measure-Object -Property LoadPercentage -Average).Average
    $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $ramFreeMB = if ($os) { [math]::Round($os.FreePhysicalMemory / 1KB, 0) } else { 0 }

    $cs2 = Get-Process -Name "cs2" -ErrorAction SilentlyContinue | Select-Object -First 1
    $cs2RamMB = if ($cs2) { [math]::Round($cs2.WorkingSet64 / 1MB, 1) } else { 0 }

    $latencyMs = -1
    try {
        $ping = [System.Net.NetworkInformation.Ping]::new()
        $reply = $ping.Send("8.8.8.8", 500)
        if ($reply.Status -eq "Success") { $latencyMs = $reply.RoundtripTime }
        $ping.Dispose()
    } catch { }

    $snapshot = [PSCustomObject]@{
        Timestamp  = $ts
        Type       = "snapshot"
        CPU_Pct    = [math]::Round($cpu, 1)
        RAM_FreeMB = $ramFreeMB
        CS2_RAM_MB = $cs2RamMB
        Latency_ms = $latencyMs
    }

    # Append snapshot to performance log
    $logDir = Split-Path $Config_Path_PerfLog -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path $Config_Path_PerfLog -Value ($snapshot | ConvertTo-Json -Compress) -Encoding UTF8

    return $snapshot
}

$snap = Get-PerformanceSnapshot
Write-Host "=== CS2 Performance Snapshot ===" -ForegroundColor Cyan
Write-Host ("CPU     : {0}%" -f $snap.CPU_Pct)
Write-Host ("RAM Free: {0} MB" -f $snap.RAM_FreeMB)
Write-Host ("CS2 RAM : {0} MB" -f $snap.CS2_RAM_MB)
Write-Host ("Latency : {0} ms" -f $(if ($snap.Latency_ms -lt 0) { "N/A" } else { $snap.Latency_ms }))
Write-Host "Snapshot saved to log." -ForegroundColor Green
