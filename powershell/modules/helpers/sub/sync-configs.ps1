function Sync-Configs {
    # Disable windows hotkeys
    $explorerPolicies="registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-Not(Test-RegistryValue -Path $explorerPolicies -Value "NoWinKeys")) {
        New-ItemProperty -Path $explorerPolicies -Name "NoWinKeys" -PropertyType DWord -Value 1 | Out-Null
    }
    # Sync Configurations
    $powershell = "$HOME\winconf\powershell"
    Import-Module -DisableNameChecking "$powershell\modules\helpers\helpers.psm1" -WarningAction SilentlyContinue
    Write-Output "Setting up Autohotkey-Boot"
    & "$powershell\configs\Autohotkey-Boot.ps1"
    Write-Output "Setting up Nvim"
    & "$powershell\configs\Sync-NvimConfig.ps1"
    Write-Output "Setting up Mirc"
    & "$powershell\configs\Sync-Mirc-Config.ps1"
    Write-Output "Setting up Rainmeter"
    & "$powershell\configs\Sync-Rainmeter.ps1"
    Write-Output "Setting up Sublime"
    & "$powershell\configs\Sync-SublimeText-Config.ps1"
    Write-Output "Setting up PhpStorm"
    & "$powershell\configs\Sync-PhpStorm.ps1"
    Write-Output "Setting up Windows Terminal"
    & "$powershell\configs\Sync-WindowsTerminal.ps1"
    Write-Output "Setting up Powershell"
    & "$powershell\configs\Sync-PowerShell-Config.ps1"
    Write-Output "Setting up Environment-Paths"
    & "$powershell\configs\Set-Environment-Paths.ps1"
    Write-Output "Setting Varios System Configurations"
    & "$powershell\configs\Sync-System-Settings.ps1"

    $keys = @(
        "registry::HKEY_CLASSES_ROOT\Directory\shell\git_gui",
        "registry::HKEY_CLASSES_ROOT\Directory\shell\git_shell",
        "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_gui",
        "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_shel"
    )

    foreach ($key in $keys) {
        if (Test-Path $key) {
            Remove-Item $key | Out-Null
        }
    }
}

Export-ModuleMember -Function Sync-Configs
