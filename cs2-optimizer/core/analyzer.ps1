# =============================================================================
# CS2 Performance Optimizer - Log Analyzer
# =============================================================================
# Usage:
#   . .\core\analyzer.ps1
#   Invoke-CS2Analyzer              # Analyze latest performance.log
#   Invoke-CS2Analyzer -AutoApply   # Also update main-config.ps1 settings
# =============================================================================
#Requires -Version 5.1

[CmdletBinding()]
param([switch]$AutoApply)

# Load main config
$configPath = Join-Path $PSScriptRoot "main-config.ps1"
if (Test-Path $configPath) { . $configPath }

# --- Parse JSON log lines ---
function Get-PerfData {
    param([string]$LogPath)
    if (-not (Test-Path $LogPath)) {
        Write-Warning "Performance log not found: $LogPath"
        return @()
    }
    $lines = Get-Content $LogPath -Encoding UTF8 -ErrorAction SilentlyContinue
    $entries = foreach ($line in $lines) {
        try { $line | ConvertFrom-Json } catch { }
    }
    return @($entries)
}

# --- Identify bottlenecks from data ---
function Get-Bottlenecks {
    param([array]$Data)
    $issues = [System.Collections.Generic.List[string]]::new()

    if ($Data.Count -eq 0) { return $issues }

    $avgCpu     = ($Data | Measure-Object -Property CPU_Pct   -Average).Average
    $avgRamUsed = ($Data | Measure-Object -Property RAM_UsedMB -Average).Average
    $latData    = @($Data | Where-Object { $null -ne $_.Latency_ms -and $_.Latency_ms -ge 0 })
    $avgLatency = if ($latData.Count -gt 0) { ($latData | Measure-Object -Property Latency_ms -Average).Average } else { $null }
    $maxLatency = if ($latData.Count -gt 0) { ($latData | Measure-Object -Property Latency_ms -Maximum).Maximum } else { $null }

    if ($avgCpu -gt 85)  { $issues.Add("CPU bottleneck: avg $([math]::Round($avgCpu,1))% (>85%)") }
    if ($avgRamUsed -gt ($Config_RAM_MaxUsageMB * 0.90)) {
        $issues.Add("RAM pressure: avg used $([math]::Round($avgRamUsed,0)) MB (>90% of limit)")
    }
    if ($null -ne $avgLatency -and $avgLatency -gt $Config_Perf_LatencyWarningMs) {
        $issues.Add("Network latency: avg $([math]::Round($avgLatency,1)) ms (>$($Config_Perf_LatencyWarningMs) ms)")
    }
    if ($null -ne $maxLatency -and $maxLatency -gt ($Config_Perf_LatencyWarningMs * 3)) {
        $issues.Add("Latency spikes: max $maxLatency ms detected")
    }
    return $issues
}

# --- Generate recommendations ---
function Get-Recommendations {
    param([array]$Bottlenecks)
    $rec = [System.Collections.Generic.List[string]]::new()
    foreach ($b in $Bottlenecks) {
        switch -Wildcard ($b) {
            "CPU*"     { $rec.Add("Lower fps_max in cs2-config.cfg; close background apps") }
            "RAM*"     { $rec.Add("Reduce Config_RAM_MaxUsageMB; run optimizer before game") }
            "Network*" { $rec.Add("Switch to wired connection; reduce cl_updaterate to 64") }
            "Latency*" { $rec.Add("Investigate ISP route; consider different game server region") }
        }
    }
    return $rec
}

# --- Optionally patch main-config.ps1 ---
function Update-Config {
    param([array]$Bottlenecks)
    if (-not (Test-Path $configPath)) { return }
    $content = Get-Content $configPath -Raw

    foreach ($b in $Bottlenecks) {
        if ($b -like "Network*") {
            # Halve update rate to reduce bandwidth pressure
            $content = $content -replace '(\$Config_Net_UpdateRate\s*=\s*)\d+', '${1}64'
            $content = $content -replace '(\$Config_Net_CmdRate\s*=\s*)\d+', '${1}64'
        }
    }
    Set-Content -Path $configPath -Value $content -Encoding UTF8 -ErrorAction SilentlyContinue
}

# --- Write analysis report ---
function Write-AnalysisReport {
    param([array]$Data, [array]$Bottlenecks, [array]$Recommendations)

    $logDir = Split-Path $Config_Path_AnalysisLog -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    $report = [PSCustomObject]@{
        GeneratedAt     = [datetime]::UtcNow.ToString("o")
        SamplesAnalyzed = $Data.Count
        Bottlenecks     = $Bottlenecks
        Recommendations = $Recommendations
        Summary         = if ($Bottlenecks.Count -eq 0) { "No bottlenecks detected." } else { "$($Bottlenecks.Count) issue(s) found." }
    }

    $json = $report | ConvertTo-Json -Depth 5
    Set-Content -Path $Config_Path_AnalysisLog -Value $json -Encoding UTF8
    return $report
}

# --- Main Entry Point ---
function Invoke-CS2Analyzer {
    [CmdletBinding()]
    param([switch]$AutoApply)

    $data    = Get-PerfData -LogPath $Config_Path_PerfLog
    $issues  = Get-Bottlenecks -Data $data
    $recs    = Get-Recommendations -Bottlenecks $issues
    $report  = Write-AnalysisReport -Data $data -Bottlenecks $issues -Recommendations $recs

    if ($AutoApply -and $issues.Count -gt 0) {
        Update-Config -Bottlenecks $issues
    }

    return $report
}

# Run directly if not dot-sourced
if ($MyInvocation.InvocationName -ne '.') {
    $report = Invoke-CS2Analyzer -AutoApply:$AutoApply
    Write-Host "`n=== CS2 Analysis Report ===" -ForegroundColor Cyan
    Write-Host "Samples : $($report.SamplesAnalyzed)"
    Write-Host "Summary : $($report.Summary)"
    if ($report.Bottlenecks.Count -gt 0) {
        Write-Host "`nBottlenecks:" -ForegroundColor Yellow
        $report.Bottlenecks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host "`nRecommendations:" -ForegroundColor Green
        $report.Recommendations | ForEach-Object { Write-Host "  - $_" }
    }
    Write-Host "`nFull report saved to: $Config_Path_AnalysisLog" -ForegroundColor Gray
}
