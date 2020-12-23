# Config
$wtConfig = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtConfig -PathType leaf) {
    Remove-Item $wtConfig
}
Sym-Link $wtConfig $env:userprofile\winconf\configs\winterminal\profiles.json
# Windows Terminal Path
$wt = (Get-Command wt.exe).Source
# PowerShell Path
$ps =(Get-Command powershell.exe).Source
# Ubuntu Path
$ubuntu = (Get-Command ubuntu.exe).Source

$shellPath = "registry::HKEY_CLASSES_ROOT\Directory\Background\shell"
# Powershell
if (-Not (Test-Path "$shellPath\WT-PowerShell")) {
    New-Item -Path $shellPath -Name "WT-PowerShell" -Value "Open in PowerShell" | Out-Null
    New-ItemProperty -Path "$shellPath\WT-PowerShell" -Name "Icon" -Value $ps | Out-Null
    New-Item -Path "$shellPath\WT-PowerShell" -Name "command" -Value "$wt -d `"%V`" -p PowerShell" | Out-Null
}
# Ubuntu
if (-Not (Test-Path "$shellPath\WT-Ubuntu")) {
    New-Item -Path $shellPath -Name "WT-Ubuntu" -Value "Open in Ubuntu" | Out-Null
    New-ItemProperty -Path "$shellPath\WT-Ubuntu" -Name "Icon" -Value $ubuntu | Out-Null
    New-Item -Path "$shellPath\WT-Ubuntu" -Name "command" -Value "$wt -d `"%V`" -p Ubuntu" | Out-Null
}
