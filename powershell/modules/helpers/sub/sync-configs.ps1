function Sync-Configs {

    # Disable windows hotkeys
    $explorerPolicies="registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-Not(Test-RegistryValue -Path $explorerPolicies -Value "NoWinKeys")) {
        New-ItemProperty -Path $explorerPolicies -Name "NoWinKeys" -PropertyType DWord -Value 1 | Out-Null
    }

    # Sync Configurations
    $scriptDirectory = "$env:USERPROFILE\winconf\powershell"
    Import-Module -DisableNameChecking "$scriptDirectory\modules\helpers\helpers.psm1" -WarningAction SilentlyContinue
    & "$scriptDirectory\configs\Autohotkey-Boot.ps1"
    & "$scriptDirectory\configs\Sync-NvimConfig.ps1"
    & "$scriptDirectory\configs\Sync-Mirc-Config.ps1"
    & "$scriptDirectory\configs\Sync-Rainmeter.ps1"
    & "$scriptDirectory\configs\Sync-SublimeText-Config.ps1"
    & "$scriptDirectory\configs\Sync-WindowsTerminal.ps1"
    & "$scriptDirectory\configs\Sync-PowerShell-Config.ps1"
    & "$scriptDirectory\configs\Set-Environment-Paths.ps1"

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
    & "$scriptDirectory\configs\Set-Environment-Paths.ps1"
}

Export-ModuleMember -Function Sync-Configs
