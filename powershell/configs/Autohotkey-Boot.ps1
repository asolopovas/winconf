choco install autohotkey -y | Out-Null
if (!(Test-ScheduledTask Autohotkey)) {
  $autohotkeyPath = "$env:USERPROFILE\winconf\autohotkey"
  $A = New-ScheduledTaskAction -Execute "C:\Program Files\AutoHotkey\AutoHotkey.exe" -WorkingDirectory $autohotkeyPath -Argument "$autohotkeyPath\load.ahk"
  $T = new-scheduledtasktrigger -atlogon
  $P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
  $S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
  $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
  Register-ScheduledTask -TaskName Autohotkey -InputObject $D
  Start-ScheduledTask -TaskName Autohotkey
}
# Disable Lock Key
$reg_root = "registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion"
$policies_path = "$reg_root\Policies"
if (!(Test-Path "$policies_path\System")) {
  New-Item -Path $policies_path -Name "System" | Out-Null
  New-ItemProperty -Path "$policies_path\System" -Name "DisableLockWorkstation" -Value 1 | Out-Null
}
else {
  if (Test-RegistryValue -Path $policies_path -Value "DisableLockWorkstation") {
    Set-ItemProperty -Path "$policies_path\System" -Name "DisableLockWorkstation" -Value 1 | Out-Null
  } else {
    New-ItemProperty -Path "$policies_path\System" -Name "DisableLockWorkstation" -Value 1 | Out-Null
  }
}
# Disable Windows Hotkeys
$windows_hotkeys = "$reg_root\Explorer\Advanced"
$windows_hotkeys_1 = "$reg_root\Policies\Explorer"
if (!(Test-Path $windows_hotkeys)) { New-Item -Path $windows_hotkeys | Out-Null }
if (!(Test-Path $windows_hotkeys_1)) { New-Item -Path $windows_hotkeys_1 | Out-Null }

if (!(Test-RegistryValue -Path $windows_hotkeys -Value "DisabledHotKeys")) {
  New-ItemProperty -Path $windows_hotkeys -Name "DisabledHotkeys" -Value  "K" -PropertyType String | Out-Null
} else {
  Set-ItemProperty -Path $windows_hotkeys -Name "DisabledHotkeys" -Value "K" | Out-Null
}

if (!(Test-RegistryValue -Path $windows_hotkeys_1 -Value "NoWinKeys")) {
  New-ItemProperty -Path $windows_hotkeys_1 -Name "NoWinKeys" -Value 1 | Out-Null
} else {
  Set-ItemProperty -Path $windows_hotkeys_1 -Name "NoWinKeys" -Value 1 | Out-Null
}
