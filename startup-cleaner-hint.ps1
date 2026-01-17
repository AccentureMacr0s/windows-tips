# Created by: DS-Macros
# Purpose: Disable unwanted startup applications like OneDrive, Chime, Teams, and Edge
# See what's currently in startup before removing
Write-Host "Current startup programs:" -ForegroundColor Yellow
Get-CimInstance Win32_StartupCommand | Where-Object {$_.Name -match "OneDrive|Chime|Teams|Edge"} | Select-Object Name, Command, Location

# Disable OneDrive startup via registry
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value $null -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue

# Also disable via Task Scheduler if present
Disable-ScheduledTask -TaskName "OneDrive*" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "*Chime*" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "*Chime*" -ErrorAction SilentlyContinue

# Remove Teams from startup
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "*Teams*" -ErrorAction SilentlyContinue

# Disable Teams auto-start through its own setting
$teamsConfig = "$env:APPDATA\Microsoft\Teams\desktop-config.json"
if (Test-Path $teamsConfig) {
    $config = Get-Content $teamsConfig | ConvertFrom-Json
    $config.appPreferenceSettings.openAtLogin = $false
    $config | ConvertTo-Json -Depth 10 | Set-Content $teamsConfig
}

# Disable all Edge auto-launch entries
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | 
    Get-Member -MemberType NoteProperty | 
    Where-Object {$_.Name -like "*Edge*"} | 
    ForEach-Object {Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction SilentlyContinue}

# Disable Edge startup boost
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0 -Force -ErrorAction SilentlyContinue


