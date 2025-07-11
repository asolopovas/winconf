# Comprehensive fix for issues caused by directory reorganization
Write-Host "=== Comprehensive Fix for Directory Reorganization Issues ===" -ForegroundColor Yellow

# Import functions
. "$env:userprofile\winconf\functions.ps1"

$fixedIssues = @()
$errors = @()

# 1. Fix Windows Terminal symlink
Write-Host "1. Fixing Windows Terminal symlink..." -ForegroundColor Green
try {
    $terminal_conf_dir = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($terminal_conf_dir) {
        $settingsFile = "$terminal_conf_dir\settings.json"
        $configPath = "$env:userprofile\winconf\terminal\profiles.json"
        
        # Remove existing file/symlink
        if (Test-Path $settingsFile) {
            Remove-Item $settingsFile -Force -ErrorAction SilentlyContinue
        }
        
        # Create new symlink
        SetPermissions $terminal_conf_dir
        CreateSymLink $settingsFile $configPath
        
        $fixedIssues += "Windows Terminal symlink"
        Write-Host "✓ Windows Terminal symlink fixed" -ForegroundColor Green
    } else {
        $errors += "Windows Terminal not found"
        Write-Host "✗ Windows Terminal not found" -ForegroundColor Red
    }
} catch {
    $errors += "Windows Terminal symlink: $_"
    Write-Host "✗ Error fixing Windows Terminal symlink: $_" -ForegroundColor Red
}

# 2. Fix AutoHotkey scheduled task
Write-Host "2. Checking AutoHotkey scheduled task..." -ForegroundColor Green
try {
    $taskNames = @("Autohotkey-$env:UserName", "Autohotkey-$($env:UserName)v2")
    
    foreach ($taskName in $taskNames) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            $action = $task.Actions[0]
            if ($action.WorkingDirectory -like "*configs\autohotkey*") {
                Write-Host "Found task with old path: $taskName" -ForegroundColor Yellow
                Write-Host "Old working directory: $($action.WorkingDirectory)" -ForegroundColor Yellow
                
                # Unregister old task
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                
                # Create new task with correct path
                $autohotkeyPath = "$env:USERPROFILE\winconf\autohotkey"
                $autohotkeyExec = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
                $domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
                
                $A = New-ScheduledTaskAction -Execute $autohotkeyExec -WorkingDirectory $autohotkeyPath -Argument "$autohotkeyPath\load.ahk"
                $T = New-ScheduledTaskTrigger -AtLogon -User "$domain\$env:UserName"
                $P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
                $S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
                $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
                Register-ScheduledTask -TaskName $taskName -InputObject $D
                
                $fixedIssues += "AutoHotkey scheduled task: $taskName"
                Write-Host "✓ AutoHotkey scheduled task fixed: $taskName" -ForegroundColor Green
            } else {
                Write-Host "✓ AutoHotkey task already has correct path: $taskName" -ForegroundColor Green
            }
        }
    }
} catch {
    $errors += "AutoHotkey scheduled task: $_"
    Write-Host "✗ Error fixing AutoHotkey scheduled task: $_" -ForegroundColor Red
}

# 3. Restart AutoHotkey with new path
Write-Host "3. Restarting AutoHotkey..." -ForegroundColor Green
try {
    # Stop any running AutoHotkey processes
    Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    
    # Start AutoHotkey with new path
    $autohotkeyPath = "$env:USERPROFILE\winconf\autohotkey"
    $autohotkeyExec = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    $scriptPath = "$autohotkeyPath\load.ahk"
    
    if (Test-Path $autohotkeyExec -and (Test-Path $scriptPath)) {
        Start-Process -FilePath $autohotkeyExec -ArgumentList $scriptPath -WorkingDirectory $autohotkeyPath -NoNewWindow
        $fixedIssues += "AutoHotkey restart"
        Write-Host "✓ AutoHotkey restarted with new path" -ForegroundColor Green
    } else {
        $errors += "AutoHotkey executable or script not found"
        Write-Host "✗ AutoHotkey executable or script not found" -ForegroundColor Red
    }
} catch {
    $errors += "AutoHotkey restart: $_"
    Write-Host "✗ Error restarting AutoHotkey: $_" -ForegroundColor Red
}

# 4. Start AutoHotkey scheduled task
Write-Host "4. Starting AutoHotkey scheduled task..." -ForegroundColor Green
try {
    $taskNames = @("Autohotkey-$env:UserName", "Autohotkey-$($env:UserName)v2")
    
    foreach ($taskName in $taskNames) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Start-ScheduledTask -TaskName $taskName
            Write-Host "✓ Started scheduled task: $taskName" -ForegroundColor Green
            break
        }
    }
} catch {
    $errors += "Starting AutoHotkey scheduled task: $_"
    Write-Host "✗ Error starting AutoHotkey scheduled task: $_" -ForegroundColor Red
}

# Summary
Write-Host "=== Fix Summary ===" -ForegroundColor Yellow
if ($fixedIssues.Count -gt 0) {
    Write-Host "✓ Fixed issues:" -ForegroundColor Green
    $fixedIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
}

if ($errors.Count -gt 0) {
    Write-Host "✗ Errors encountered:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

Write-Host "=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Restart Windows Terminal to apply settings" -ForegroundColor Green
Write-Host "2. Test Win+Enter hotkey for Ubuntu terminal" -ForegroundColor Green
Write-Host "3. Check PowerShell colors and prompt" -ForegroundColor Green

if ($fixedIssues.Count -gt 0) {
    Write-Host "✓ Directory reorganization issues have been fixed!" -ForegroundColor Green
}