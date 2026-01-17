# Interactive Startup Manager Script
function Show-StartupManager {
    do {
        Clear-Host
        Write-Host "Removes Startup HKCU and HKLM Entries" -ForegroundColor Green
        Write-Host "================================" -ForegroundColor Green
      
        # Show all startup programs
        Write-Host "CURRENT STARTUP PROGRAMS:" -ForegroundColor Yellow
        $startupItems = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location
        $counter = 1
        
        foreach ($item in $startupItems) {
            $shortCommand = if ($item.Command.Length -gt 60) { 
                $item.Command.Substring(0, 60) + "..." 
            } else { 
                $item.Command 
            }
            Write-Host "$counter. $($item.Name)" -ForegroundColor Cyan
            Write-Host "   Path: $shortCommand" -ForegroundColor Gray
            Write-Host "   Location: $($item.Location)" -ForegroundColor Gray
            Write-Host ""
            $counter++
        }
        
        # Show registry startup items too
        Write-Host "REGISTRY STARTUP ITEMS:" -ForegroundColor Yellow
        $regStartup = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
        if ($regStartup) {
            $regStartup.PSObject.Properties | Where-Object {$_.Name -notmatch "PS"} | ForEach-Object {
                Write-Host "$counter. $($_.Name)" -ForegroundColor Cyan
                Write-Host "   Command: $($_.Value)" -ForegroundColor Gray
                Write-Host ""
                $counter++
            }
        }
        
        Write-Host "================================" -ForegroundColor Green
        Write-Host "OPTIONS:" -ForegroundColor White
        Write-Host " -Type service name to DISABLE it" -ForegroundColor Red
        Write-Host " -Type 'refresh' to reload list" -ForegroundColor Blue
        Write-Host " -Type 'exit' to quit" -ForegroundColor Yellow
        Write-Host ""
        
        $userInput = Read-Host "Enter service/program name"
        
        if ($userInput.ToLower() -eq "exit") {
            Write-Host "Goodbye!" -ForegroundColor Green
            break
        }
        elseif ($userInput.ToLower() -eq "refresh") {
            continue
        }
        elseif ($userInput.Trim() -ne "") {
            # Try to disable the startup item
            Write-Host "Searching for '$userInput'..." -ForegroundColor Yellow
            
            # Search in registry startup
            $found = $false
            $regItems = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
            if ($regItems) {
                $regItems.PSObject.Properties | Where-Object {
                    $_.Name -like "*$userInput*" -and $_.Name -notmatch "PS"
                } | ForEach-Object {
                    Write-Host "Found: $($_.Name)" -ForegroundColor Green
                    $confirm = Read-Host "Remove '$($_.Name)' from startup? (y/n)"
                    if ($confirm.ToLower() -eq "y") {
                        try {
                            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction Stop
                            Write-Host "Removed '$($_.Name)' from startup!" -ForegroundColor Green
                            $found = $true
                        }
                        catch {
                            Write-Host "Failed to remove: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
            
            # Also check HKLM
            $regItemsLM = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
            if ($regItemsLM) {
                $regItemsLM.PSObject.Properties | Where-Object {
                    $_.Name -like "*$userInput*" -and $_.Name -notmatch "PS"
                } | ForEach-Object {
                    Write-Host "Found (System): $($_.Name)" -ForegroundColor Green
                    $confirm = Read-Host "Remove '$($_.Name)' from system startup? (y/n) [Requires Admin]"
                    if ($confirm.ToLower() -eq "y") {
                        try {
                            Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction Stop
                            Write-Host "Removed '$($_.Name)' from system startup!" -ForegroundColor Green
                            $found = $true
                        }
                        catch {
                            Write-Host "Failed to remove (may need admin): $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
            
            if (-not $found) {
                Write-Host "No startup item found matching '$userInput'" -ForegroundColor Red
                Write-Host "Try partial names (e.g., 'Teams', 'OneDrive', 'Edge')" -ForegroundColor Blue
            }
            
            Read-Host "`nPress Enter to continue"
        }
        
    } while ($true)
}

# Run the interactive startup manager
Show-StartupManager