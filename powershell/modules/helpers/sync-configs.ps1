function Sync-Configs {
    $conf = "$env:USERPROFILE\winconf"
    $scripts = "$conf\scripts"
    $modules = "$conf\powershell\modules"

    $explorerPolicies="registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-Not(Test-RegistryValue -Path $explorerPolicies -Value "NoWinKeys")) {
        New-ItemProperty -Path $explorerPolicies -Name "NoWinKeys" -PropertyType DWord -Value 1 | Out-Null
    }

    Import-Module -DisableNameChecking "$modules\helpers\helpers.psm1" -WarningAction SilentlyContinue

    & "$scripts\Sync-PowerShell.ps1"
    & "$scripts\Set-Environment-Paths.ps1"
    & "$scripts\excludeWSL.ps1"

    Write-Host "Do you want to install apps? (y/n)" -ForegroundColor Green
    $answer = Read-Host
    if ($answer -eq "y") {
        & "$scripts\Install-Software.ps1"
    }

    & "$scripts\Sync-Autohotkey.ps1"
    & "$scripts\Sync-Mirc.ps1"
    & "$scripts\Sync-Terminal.ps1"
    & "$scripts\Sync-Rainmeter.ps1"

    $keys = @(
        'Registry::HKEY_CLASSES_ROOT\Directory\shell\git_gui',
        'Registry::HKEY_CLASSES_ROOT\Directory\shell\git_shell',
        'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_gui',
        'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\git_shell'
    )

    foreach ($key in $keys) {
        if (Test-Path $key) {
            Remove-Item $key -Recurse -Force
        }
    }
}
