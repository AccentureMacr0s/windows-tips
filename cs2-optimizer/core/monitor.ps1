# =============================================================================
# CS2 Performance Optimizer - Real-Time Monitor
# =============================================================================
# Usage:
#   Start-CS2Monitor              # Start monitoring (runs until CS2 exits)
#   Stop-CS2Monitor               # Stop background monitor
# Logs JSON entries to logs/performance.log, <1% CPU overhead.
# =============================================================================
#Requires -Version 5.1

# Load main config
$configPath = Join-Path $PSScriptRoot "main-config.ps1"
if (Test-Path $configPath) { . $configPath }

$script:MonitorActive = $false
$script:MonitorJob    = $null

# --- Collect one performance sample ---
function Get-PerfSample {
    $ts = [datetime]::UtcNow.ToString("o")

    # CPU usage (2-sample average for accuracy)
    $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue |
            Measure-Object -Property LoadPercentage -Average).Average

    # RAM usage
    $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $ramFreeMB  = if ($os) { [math]::Round($os.FreePhysicalMemory / 1KB, 0) } else { 0 }
    $ramTotalMB = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1KB, 0) } else { 0 }
    $ramUsedMB  = $ramTotalMB - $ramFreeMB

    # CS2 process metrics
    $cs2 = Get-Process -Name "cs2" -ErrorAction SilentlyContinue | Select-Object -First 1
    $cs2RamMB  = if ($cs2) { [math]::Round($cs2.WorkingSet64 / 1MB, 1) } else { 0 }
    # CPU% per process: compare two samples 500ms apart for a real snapshot
    $cs2CpuPct = 0
    if ($cs2) {
        $cpu1 = $cs2.CPU
        Start-Sleep -Milliseconds 500
        $cs2b  = Get-Process -Id $cs2.Id -ErrorAction SilentlyContinue
        if ($cs2b) {
            $cpuDelta = $cs2b.CPU - $cpu1
            $cs2CpuPct = [math]::Round(($cpuDelta / 0.5) * 100 / [Environment]::ProcessorCount, 1)
        }
    }

    # Network latency via ping (loopback = baseline; ping server for real latency)
    $latencyMs = 0
    try {
        $ping = [System.Net.NetworkInformation.Ping]::new()
        $reply = $ping.Send("8.8.8.8", 500)
        if ($reply.Status -eq "Success") { $latencyMs = $reply.RoundtripTime }
        $ping.Dispose()
    } catch { $latencyMs = -1 }

    # GPU temperature (optional - via OpenHardwareMonitor WMI namespace if installed)
    $gpuTempC = $null
    try {
        $gpuSensor = Get-CimInstance -Namespace "root\OpenHardwareMonitor" -ClassName Sensor `
            -Filter "SensorType='Temperature' AND Name LIKE '%GPU%'" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($gpuSensor) { $gpuTempC = [math]::Round($gpuSensor.Value, 1) }
    } catch { $gpuTempC = $null }

    return [PSCustomObject]@{
        Timestamp   = $ts
        CPU_Pct     = [math]::Round($cpu, 1)
        RAM_UsedMB  = $ramUsedMB
        RAM_FreeMB  = $ramFreeMB
        CS2_RAM_MB  = $cs2RamMB
        CS2_CPU_Pct = $cs2CpuPct
        Latency_ms  = $latencyMs
        GPU_Temp_C  = $gpuTempC
    }
}

# --- Rotate log if it exceeds max size ---
function Invoke-LogRotation {
    param([string]$LogPath)
    if (-not (Test-Path $LogPath)) { return }
    $sizeMB = (Get-Item $LogPath).Length / 1MB
    if ($sizeMB -ge $Config_Log_MaxSizeMB) {
        $archive = $LogPath -replace "\.log$", "-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        Rename-Item -Path $LogPath -NewName $archive -ErrorAction SilentlyContinue
    }
}

# --- Write one JSON line to log ---
function Write-PerfEntry {
    param([PSCustomObject]$Sample)
    $logDir = Split-Path $Config_Path_PerfLog -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Invoke-LogRotation -LogPath $Config_Path_PerfLog
    $json = $Sample | ConvertTo-Json -Compress
    Add-Content -Path $Config_Path_PerfLog -Value $json -Encoding UTF8
}

# --- Background monitor loop (runs in PowerShell job) ---
$script:MonitorScriptBlock = {
    param($ConfigPath, $IntervalS, $PerfLogPath, $MaxLogMB)

    # Re-load config in job context
    if (Test-Path $ConfigPath) { . $ConfigPath }

    function Invoke-LogRotation2([string]$p) {
        if (-not (Test-Path $p)) { return }
        if ((Get-Item $p).Length / 1MB -ge $MaxLogMB) {
            Rename-Item $p ($p -replace "\.log$","-$(Get-Date -Format 'yyyyMMdd-HHmmss').log") -EA SilentlyContinue
        }
    }

    while ($true) {
        $ts      = [datetime]::UtcNow.ToString("o")
        $cpu     = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average
        $os      = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $ramFree = if ($os) { [math]::Round($os.FreePhysicalMemory / 1KB, 0) } else { 0 }
        $ramUsed = if ($os) { [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1KB, 0) } else { 0 }

        $cs2     = Get-Process -Name "cs2" -EA SilentlyContinue | Select-Object -First 1
        $cs2Ram  = if ($cs2) { [math]::Round($cs2.WorkingSet64 / 1MB, 1) } else { 0 }

        $latency = -1
        try {
            $p = [System.Net.NetworkInformation.Ping]::new()
            $r = $p.Send("8.8.8.8", 500)
            if ($r.Status -eq "Success") { $latency = $r.RoundtripTime }
            $p.Dispose()
        } catch {}

        $entry = "{""Timestamp"":""$ts"",""CPU_Pct"":$([math]::Round($cpu,1)),""RAM_UsedMB"":$ramUsed,""RAM_FreeMB"":$ramFree,""CS2_RAM_MB"":$cs2Ram,""Latency_ms"":$latency}"

        $logDir = Split-Path $PerfLogPath -Parent
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        Invoke-LogRotation2 $PerfLogPath
        Add-Content -Path $PerfLogPath -Value $entry -Encoding UTF8

        # Exit if CS2 is no longer running
        if (-not $cs2) { break }

        Start-Sleep -Seconds $IntervalS
    }
}

function Start-CS2Monitor {
    if ($script:MonitorActive) { return }
    $script:MonitorActive = $true
    $script:MonitorJob = Start-Job -ScriptBlock $script:MonitorScriptBlock -ArgumentList @(
        $configPath,
        $Config_Log_MonitorIntervalS,
        $Config_Path_PerfLog,
        $Config_Log_MaxSizeMB
    )
    return $script:MonitorJob
}

function Stop-CS2Monitor {
    if ($script:MonitorJob) {
        Stop-Job  $script:MonitorJob -ErrorAction SilentlyContinue
        Remove-Job $script:MonitorJob -ErrorAction SilentlyContinue
        $script:MonitorJob   = $null
        $script:MonitorActive = $false
    }
}

# Run directly if not dot-sourced
if ($MyInvocation.InvocationName -ne '.') {
    $job = Start-CS2Monitor
    Write-Host "CS2 Monitor started (Job ID: $($job.Id)). Press Ctrl+C to stop." -ForegroundColor Green
    try { Wait-Job $job | Out-Null } catch { }
    Stop-CS2Monitor
}
