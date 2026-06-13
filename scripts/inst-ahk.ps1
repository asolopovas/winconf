$ErrorActionPreference = 'Stop'

$repo = "$env:USERPROFILE\winconf"
$ahkExe = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
$taskName = "AutoHotkey-Init-$env:UserName-v2"

if (-not (Test-Path -LiteralPath $ahkExe)) {
    Write-Warning "AutoHotkey v2 not found at $ahkExe - skipping task setup."
    return
}

foreach ($old in @("Autohotkey-$env:UserName", "Autohotkey-$($env:UserName)v2", "AutoHotkey-Init-$env:UserName")) {
    if (Get-ScheduledTask -TaskName $old -ErrorAction SilentlyContinue) {
        Write-Host "Removing legacy task: $old" -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $old -Confirm:$false
    }
}

# Re-registered every run so changes to exe path, arguments, or settings heal
# themselves; Stop+Start applies the current scripts (v2 #SingleInstance Force).
$task = New-ScheduledTask `
    -Action (New-ScheduledTaskAction -Execute $ahkExe -WorkingDirectory $repo -Argument "$repo\init-autohotkey.ahk") `
    -Trigger (New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:UserName") `
    -Principal (New-ScheduledTaskPrincipal -GroupId 'BUILTIN\Administrators' -RunLevel Highest) `
    -Settings (New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1))

Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Start-ScheduledTask -TaskName $taskName
Write-Host "Task '$taskName' registered and started." -ForegroundColor Green

$registryTweaks = @{
    'registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System'   = @{ DisableLockWorkstation = 1 }
    'registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' = @{ DisabledHotkeys = 'K' }
    'registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' = @{ NoWinKeys = 1 }
}
foreach ($key in $registryTweaks.Keys) {
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    foreach ($name in $registryTweaks[$key].Keys) {
        Set-ItemProperty -Path $key -Name $name -Value $registryTweaks[$key][$name]
    }
}
