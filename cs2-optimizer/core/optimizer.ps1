# =============================================================================
# CS2 Performance Optimizer - Windows Optimization Module
# =============================================================================
# Usage:
#   . .\core\optimizer.ps1          # Import as module
#   Invoke-CS2Optimizer             # Run full optimization
#   Invoke-CS2Optimizer -Silent     # Run without any output
# Returns exit code 0 on success, 1 on partial failure, 2 on critical failure
# =============================================================================
#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$DryRun
)

# Load main config
$configPath = Join-Path $PSScriptRoot "main-config.ps1"
if (Test-Path $configPath) { . $configPath }

# --- Helper: Write progress without spamming the console ---
function Write-Step {
    param([string]$Activity, [string]$Status, [int]$PercentComplete)
    if (-not $Silent) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
}

# --- Helper: Backup a registry key before modification ---
function Backup-RegistryKey {
    param([string]$KeyPath)
    if ($DryRun) { return }
    try {
        $backupDir  = Split-Path $Config_Reg_BackupPath -Parent
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        $stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = $Config_Reg_BackupPath -replace "\.reg$", "-$stamp.reg"
        $regPath    = $KeyPath -replace "HKLM:\\", "HKLM\" -replace "HKCU:\\", "HKCU\"
        reg export $regPath $backupFile /y 2>$null | Out-Null
    } catch { <# Non-fatal #> }
}

# --- Network Optimization ---
function Optimize-Network {
    Write-Step "CS2 Optimizer" "Optimizing network stack..." 20
    try {
        if (-not $DryRun) {
            # Disable TCP auto-tuning for consistent low latency
            netsh int tcp set global autotuninglevel=disabled 2>$null | Out-Null
            # Disable RSS (Receive-Side Scaling) scaling heuristics
            netsh int tcp set global rss=enabled 2>$null | Out-Null
            # Disable network throttling index for games
            $throttlePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            if (Test-Path $throttlePath) {
                Set-ItemProperty -Path $throttlePath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $throttlePath -Name "SystemResponsiveness" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
        }
        return $true
    } catch {
        return $false
    }
}

# --- RAM Optimization for 8-16 GB Systems ---
function Optimize-RAM {
    Write-Step "CS2 Optimizer" "Optimizing RAM usage..." 40
    try {
        if (-not $DryRun) {
            # Clear standby list (requires admin) - releases cached pages back to available
            $code = @"
using System;
using System.Runtime.InteropServices;
public class MemoryHelper {
    [DllImport("ntdll.dll")] public static extern int NtSetSystemInformation(int InfoClass, IntPtr Info, int Length);
    public static void ClearStandbyList() {
        var val = 4; // SystemMemoryListInformation - purge standby list
        var ptr = Marshal.AllocHGlobal(Marshal.SizeOf(val));
        Marshal.WriteInt32(ptr, val);
        NtSetSystemInformation(80, ptr, Marshal.SizeOf(val));
        Marshal.FreeHGlobal(ptr);
    }
}
"@
            try {
                Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
                [MemoryHelper]::ClearStandbyList()
            } catch { <# Non-fatal if not admin #> }

            # Set CS2 process priority if running
            $cs2 = Get-Process -Name "cs2" -ErrorAction SilentlyContinue
            if ($cs2 -and $Config_CPU_PriorityCS2) {
                $cs2.PriorityClass = $Config_CPU_PriorityCS2
            }
        }
        return $true
    } catch {
        return $false
    }
}

# --- Input Lag Reduction ---
function Optimize-InputLag {
    Write-Step "CS2 Optimizer" "Reducing input lag..." 60
    try {
        if (-not $DryRun) {
            $mousePath = "HKCU:\Control Panel\Mouse"
            Backup-RegistryKey $mousePath
            # Disable mouse acceleration (enhance pointer precision)
            Set-ItemProperty -Path $mousePath -Name "MouseSpeed"  -Value "0" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0" -ErrorAction SilentlyContinue
            # Disable SmoothMouseXCurve / SmoothMouseYCurve
            $noCurveX = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
            $noCurveY = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xA8,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xE0,0x00,0x00,0x00,0x00,0x00)
            Set-ItemProperty -Path $mousePath -Name "SmoothMouseXCurve" -Value $noCurveX -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $mousePath -Name "SmoothMouseYCurve" -Value $noCurveY -ErrorAction SilentlyContinue
        }
        return $true
    } catch {
        return $false
    }
}

# --- Crypto Miner Detection ---
function Test-CryptoMiners {
    Write-Step "CS2 Optimizer" "Scanning for crypto miners..." 80
    $found = @()
    foreach ($minerName in $Config_Sec_MinerProcessNames) {
        $proc = Get-Process -Name $minerName -ErrorAction SilentlyContinue
        if ($proc) { $found += $proc.Name }
    }
    if ($found.Count -gt 0 -and -not $Silent) {
        Write-Warning "Potential crypto miners detected: $($found -join ', ')"
    }
    return $found
}

# --- Main Entry Point ---
function Invoke-CS2Optimizer {
    [CmdletBinding()]
    param([switch]$Silent, [switch]$DryRun)

    $results = @{
        Network  = Optimize-Network
        RAM      = Optimize-RAM
        InputLag = Optimize-InputLag
        Miners   = Test-CryptoMiners
    }

    Write-Step "CS2 Optimizer" "Done." 100
    Write-Progress -Activity "CS2 Optimizer" -Completed

    $exitCode = 0
    if (-not $results.Network -or -not $results.RAM -or -not $results.InputLag) { $exitCode = 1 }
    if ($results.Miners.Count -gt 0) { $exitCode = [Math]::Max($exitCode, 1) }

    return $exitCode
}

# Run directly if not dot-sourced
if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-CS2Optimizer -Silent:$Silent -DryRun:$DryRun)
}
