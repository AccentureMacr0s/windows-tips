Get-ChildItem -Path "C:\Users\ds" -Directory -Force | ForEach-Object { 
     $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
     if ($size -eq $null) { $size = 0 }
     [PSCustomObject]@{
         Name = $_.Name
         SizeGB = [math]::Round($size / 1GB, 2)
         SizeMB = [math]::Round($size / 1MB, 2)
         LastModified = $_.LastWriteTime
     }
 } | Sort-Object SizeGB -Descending | Format-Table -AutoSize

 Write-Host "=== CHECKING LARGE DIRECTORIES ===" -ForegroundColor Yellow

# Check VirtualBox VMs
if (Test-Path "C:\Users\ds\VirtualBox VMs") {
    $vboxSize = (Get-ChildItem "C:\Users\ds\VirtualBox VMs" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host "VirtualBox VMs: $([math]::Round($vboxSize / 1GB, 2)) GB" -ForegroundColor Green
}

# Check .android
if (Test-Path "C:\Users\ds\.android") {
    $androidSize = (Get-ChildItem "C:\Users\ds\.android" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host ".android: $([math]::Round($androidSize / 1MB, 0)) MB" -ForegroundColor Green
}

# Check Downloads
if (Test-Path "C:\Users\ds\Downloads") {
    $downloadsSize = (Get-ChildItem "C:\Users\ds\Downloads" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host "Downloads: $([math]::Round($downloadsSize / 1MB, 0)) MB" -ForegroundColor Green
}

# Check AppData/Local/Temp
if (Test-Path "C:\Users\ds\AppData\Local\Temp") {
    $tempSize = (Get-ChildItem "C:\Users\ds\AppData\Local\Temp" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host "Temp files: $([math]::Round($tempSize / 1MB, 0)) MB" -ForegroundColor Green
}

# Perfect! Now I can see the major space consumers. Let me check what's in your .android directory specifically:
Write-Host "=== ANDROID DIRECTORY BREAKDOWN ===" -ForegroundColor Yellow
Get-ChildItem "C:\Users\ds\.android" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size -eq $null) { $size = 0 }
    Write-Host "$($_.Name): $([math]::Round($size / 1MB, 0)) MB" -ForegroundColor Cyan
}

Write-Host "`n=== DOWNLOADS BREAKDOWN ===" -ForegroundColor Yellow
Get-ChildItem "C:\Users\ds\Downloads" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size -eq $null) { $size = 0 }
    Write-Host "$($_.Name): $([math]::Round($size / 1MB, 0)) MB" -ForegroundColor Cyan
}