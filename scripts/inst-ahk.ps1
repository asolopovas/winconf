param (
    [int]$version = 2
)

. $env:userprofile\winconf\functions.ps1

$domain = (Get-CimInstance -ClassName Win32_ComputerSystem  | Select-Object Name,Domain).name

function UpdateOrCreateRegKey($path, $name, $value, $type = 'DWord') {
    if (Test-RegistryValue -Path $path -Value $name) {
        Set-ItemProperty -Path $path -Name $name -Value $value | Out-Null
    } else {
        New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type | Out-Null
    }
}

$autohotkeyPath = if ($version -eq 1) { "$env:USERPROFILE\winconf\configs\autohotkey" } else { "$env:USERPROFILE\winconf" }
$autohotkeyExec = if ($version -eq 1) { "C:\Program Files\AutoHotkey\AutoHotkey.exe" } else { "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" }

$oldTaskNames = @("Autohotkey-$env:UserName", "Autohotkey-$env:UserName" + "v2")
foreach ($oldTask in $oldTaskNames) {
    if (Test-ScheduledTask $oldTask) {
        Write-Host "Removing old task: $oldTask" -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $oldTask -Confirm:$false
    }
}

$taskName = "AutoHotkey-Init-$env:UserName"
if ($version -eq 2) {
    $taskName += "-v2"
}

if (!(Test-ScheduledTask $taskName)) {
    $A = New-ScheduledTaskAction -Execute $autohotkeyExec -WorkingDirectory $autohotkeyPath -Argument "$autohotkeyPath\init-autohotkey.ahk"
    $T = New-ScheduledTaskTrigger -AtLogon -User "$domain\$env:UserName"
    $P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    $S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
    Register-ScheduledTask -TaskName $taskName -InputObject $D
    Start-ScheduledTask -TaskName $taskName
}

$policies_path = "registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System"
New-Item -Path $policies_path -ErrorAction SilentlyContinue | Out-Null
UpdateOrCreateRegKey $policies_path "DisableLockWorkstation" 1

$windows_hotkeys = "registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$windows_hotkeys_1 = "registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

New-Item -Path $windows_hotkeys -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $windows_hotkeys_1 -ErrorAction SilentlyContinue | Out-Null

UpdateOrCreateRegKey $windows_hotkeys "DisabledHotkeys" "K" "String"
UpdateOrCreateRegKey $windows_hotkeys_1 "NoWinKeys" 1
