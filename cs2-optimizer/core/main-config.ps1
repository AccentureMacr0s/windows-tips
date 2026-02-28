# =============================================================================
# CS2 Performance Optimizer - Main Configuration
# =============================================================================
# All settings are defined here. Edit this file to customize behavior.
# =============================================================================

# --- System Resource Limits ---
$Config_RAM_MaxUsageMB       = 14336   # Max RAM usage to target (14 GB of 16 GB)
$Config_RAM_MinFreeMB        = 2048    # Minimum free RAM to maintain (MB)
$Config_CPU_AffinityCS2      = $null   # CPU affinity mask for CS2 (null = all cores)
$Config_CPU_PriorityCS2      = "High"  # Process priority: Normal, AboveNormal, High

# --- Network Settings (synced with cs2-config.cfg) ---
$Config_Net_Rate             = 786432  # cl_cmdrate / rate (bytes/sec) 786432 = 768 KB/s
$Config_Net_CmdRate          = 128     # cl_cmdrate (commands per second)
$Config_Net_UpdateRate       = 128     # cl_updaterate (updates per second)
$Config_Net_InterpRatio      = 1       # cl_interp_ratio
$Config_Net_Interp           = 0       # cl_interp (0 = auto-calculate)

# --- Performance Thresholds ---
$Config_Perf_FPSTarget       = 144     # Target FPS cap (balanced for GPU load on low-spec builds)
$Config_Perf_FPSWarning      = 60      # FPS below this triggers warning in logs
$Config_Perf_InputLagMaxMs   = 5       # Max acceptable input lag (ms)
$Config_Perf_FrameTimeMaxMs  = 20      # Max frame time before stutter is logged (ms)
$Config_Perf_LatencyWarningMs = 80     # Network latency warning threshold (ms)
$Config_Perf_PacketLossMax   = 0.02    # Max acceptable packet loss (2%)

# --- Security Settings ---
$Config_Sec_EnableMinerDetect = $true  # Enable crypto miner detection
$Config_Sec_MinerProcessNames = @(     # Known miner process names
    "xmrig", "xmr-stak", "nicehash", "ethminer",
    "phoenixminer", "claymore", "nbminer", "teamredminer",
    "lolminer", "gminer", "miniZ", "trex"
)
$Config_Sec_ProcessWhitelist  = @(     # Allowed high-CPU processes
    "cs2", "steam", "steamwebhelper", "steamservice",
    "audiodg", "dwm", "csrss", "svchost"
)

# --- Paths ---
$Config_Path_Steam           = "$env:ProgramFiles(x86)\Steam"
$Config_Path_CS2             = "$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive"
$Config_Path_CS2_CFG         = "$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
$Config_Path_Logs            = "$PSScriptRoot\..\logs"
$Config_Path_PerfLog         = "$Config_Path_Logs\performance.log"
$Config_Path_AnalysisLog     = "$Config_Path_Logs\analysis.log"

# --- Logging Settings ---
$Config_Log_MaxSizeMB        = 10      # Max log file size per session (MB)
$Config_Log_MonitorIntervalS = 2       # Monitor polling interval (seconds)

# --- Registry Backup ---
$Config_Reg_BackupPath       = "$Config_Path_Logs\registry-backup.reg"
