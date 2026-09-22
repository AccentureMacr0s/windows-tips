# =============================================================================
# CS2 Quality Handler - Network Quality Check
# =============================================================================
# Called from CS2 console via: exec quality_check
# Or run directly from PowerShell for a standalone network quality check.
# =============================================================================
#Requires -Version 5.1

$configPath = Join-Path $PSScriptRoot "..\core\main-config.ps1"
if (Test-Path $configPath) { . $configPath }

function Get-NetworkQuality {
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $targets = @("8.8.8.8", "1.1.1.1", "208.67.222.222")
    $ping    = [System.Net.NetworkInformation.Ping]::new()

    foreach ($target in $targets) {
        $latencies = @()
        $sent   = 5
        $failed = 0
        for ($i = 0; $i -lt $sent; $i++) {
            try {
                $r = $ping.Send($target, 1000)
                if ($r.Status -eq "Success") {
                    $latencies += $r.RoundtripTime
                } else {
                    $failed++
                }
            } catch { $failed++ }
            Start-Sleep -Milliseconds 100
        }
        $loss    = if ($sent -gt 0) { [math]::Round($failed / $sent, 2) } else { 0 }
        $avgLat  = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Average).Average, 1) } else { -1 }
        $jitter  = if ($latencies.Count -gt 1) {
            $diffs = for ($i = 1; $i -lt $latencies.Count; $i++) { [math]::Abs($latencies[$i] - $latencies[$i-1]) }
            [math]::Round(($diffs | Measure-Object -Average).Average, 1)
        } else { 0 }

        $results.Add([PSCustomObject]@{
            Target   = $target
            Avg_ms   = $avgLat
            Loss_Pct = $loss * 100
            Jitter_ms = $jitter
        })
    }
    $ping.Dispose()
    return $results
}

function Get-QualityRecommendations {
    param([array]$Results)
    $recs = [System.Collections.Generic.List[string]]::new()

    foreach ($r in $Results) {
        if ($r.Avg_ms -gt $Config_Perf_LatencyWarningMs) {
            $recs.Add("High latency to $($r.Target): $($r.Avg_ms) ms - try a closer game server")
        }
        if ($r.Loss_Pct -gt ($Config_Perf_PacketLossMax * 100)) {
            $recs.Add("Packet loss to $($r.Target): $($r.Loss_Pct)% - check cable/router")
        }
        if ($r.Jitter_ms -gt 10) {
            $recs.Add("High jitter to $($r.Target): $($r.Jitter_ms) ms - unstable connection")
        }
    }

    if ($recs.Count -eq 0) { $recs.Add("Network quality looks good.") }
    return $recs
}

# Run check
$qResults = Get-NetworkQuality
$recs     = Get-QualityRecommendations -Results $qResults

# Log to performance log
$logDir = Split-Path $Config_Path_PerfLog -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$entry = [PSCustomObject]@{
    Timestamp       = [datetime]::UtcNow.ToString("o")
    Type            = "quality_check"
    NetworkResults  = $qResults
    Recommendations = $recs
}
Add-Content -Path $Config_Path_PerfLog -Value ($entry | ConvertTo-Json -Compress -Depth 5) -Encoding UTF8

# Display results
Write-Host "=== CS2 Network Quality Check ===" -ForegroundColor Cyan
foreach ($r in $qResults) {
    $color = if ($r.Avg_ms -gt $Config_Perf_LatencyWarningMs -or $r.Loss_Pct -gt 0) { "Yellow" } else { "Green" }
    Write-Host ("[{0}] Latency: {1} ms | Loss: {2}% | Jitter: {3} ms" -f $r.Target, $r.Avg_ms, $r.Loss_Pct, $r.Jitter_ms) -ForegroundColor $color
}
Write-Host "`nRecommendations:" -ForegroundColor White
$recs | ForEach-Object { Write-Host "  - $_" }
Write-Host "`nResults saved to log." -ForegroundColor Green
