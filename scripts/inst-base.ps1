$conf = "$env:USERPROFILE\winconf"
$scripts = "$conf\scripts"
$modules = "$conf\powershell\modules"

$explorerPolicies = "registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-Not(Test-RegistryValue -Path $explorerPolicies -Value "NoWinKeys")) {
    New-ItemProperty -Path $explorerPolicies -Name "NoWinKeys" -PropertyType DWord -Value 1 | Out-Null
}

Import-Module -DisableNameChecking "$modules\helpers\helpers.psm1" -WarningAction SilentlyContinue

. "$scripts\inst-pwsh.ps1"
. "$scripts\inst-paths.ps1"
. "$scripts\wsl-exclusions.ps1"

Write-Host "Do you want to install apps? (y/n)" -ForegroundColor Green
$answer = Read-Host
if ($answer -eq "y") {
    & "$scripts\inst-software.ps1"
}

. "$scripts\inst-ahk.ps1"
. "$scripts\inst-terminal.ps1"
. "$scripts\inst-fonts.ps1"
