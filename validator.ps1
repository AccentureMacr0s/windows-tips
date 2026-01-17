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

 $directories = @("AppData", "Documents", "Downloads", "Desktop", "Pictures", "Videos", "Music", "OneDrive", ".android", "VirtualBox VMs", "PycharmProjects", "IdeaProjects", "Zotero", ".cache", ".vscode", ".nuget")
     foreach ($dir in $directories) {
    $path = "C:\Users\ds\$dir"
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($size -eq $null) { $size = 0 }
        Write-Host "$dir`: $([math]::Round($size / 1MB, 0)) MB ($([math]::Round($size / 1GB, 2)) GB)"     
    }
}