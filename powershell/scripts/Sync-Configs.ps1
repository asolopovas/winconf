# Disable windows hotkeys
New-ItemProperty -Path registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ -Name "NoWinKeys" -PropertyType DWord -Value 1 | Out-Null

# Sync Configurations
Import-Module -DisableNameChecking ..\modules\helpers\helpers.psm1 -WarningAction SilentlyContinue
& "$PSScriptRoot/configs/Autohotkey-Boot.ps1"
& "$PSScriptRoot/configs/Sync-Keypirinha-Config.ps1"
& "$PSScriptRoot/configs/Sync-NvimConfig.ps1"
& "$PSScriptRoot/configs/Sync-Mirc-Config.ps1"
& "$PSScriptRoot/configs/Sync-Rainmeter.ps1"
& "$PSScriptRoot/configs/Sync-SublimeText-Config.ps1"
& "$PSScriptRoot/configs/Sync-Con-Emu.ps1"
& "$PSScriptRoot/configs/Sync-WindowsTerminal.ps1"
& "$PSScriptRoot/configs/Sync-PowerShell-Config.ps1"

$keys = @(
    "registry::HKEY_CLASSES_ROOT\Directory\shell\git_gui",
    "registry::HKEY_CLASSES_ROOT\Directory\shell\git_shell",
    "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_gui",
    "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_shel"
)


foreach($key in $keys) {
 if (Test-Path $key) {
     Remove-Item $key | Out-Null
  }
}
