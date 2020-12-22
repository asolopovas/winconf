# Config
if (Test-Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -PathType leaf) {
  Remove-Item $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
}
Sym-Link $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json $env:userprofile\winconf\configs\winterminal\profiles.json
# Terminal Vars
$terminalPath = "C:\Users\Andrius\AppData\Local\Microsoft\WindowsApps\wt.exe"
# Powershell
$PowerShellPath = "C:\Windows\System32\\WindowsPowerShell\v1.0\powershell.exe"
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ -Name "WT-PowerShell" -Value "Open in PowerShell" | Out-Null
New-ItemProperty -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\WT-PowerShell -Name "Icon" -Value $PowerShellPath | Out-Null
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\WT-PowerShell -Name "command" -Value "$terminalPath -d `"%V`" -p PowerShell" | Out-Null
# Ubuntu
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ -Name "WT-Ubuntu" -Value "Open in Ubuntu" | Out-Null
New-ItemProperty -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\WT-Ubuntu -Name "Icon" -Value $terminalPath | Out-Null
New-Item -Path registry::HKEY_CLASSES_ROOT\Directory\Background\shell\WT-Ubuntu -Name "command" -Value "$terminalPath -d `"%V`" -p Ubuntu" | Out-Null
