$root = "$env:USERPROFILE\winconf"
$power_shell_dir = "$root\powershell"
$ENV:STARSHIP_CONFIG = "$power_shell_dir\starship.toml"

. $root\functions.ps1
. $power_shell_dir\completions\git-cli.ps1
. $power_shell_dir\remove-aliases.ps1
. $power_shell_dir\shortcuts.ps1

$moduleName = "PSReadLine"

if (-not (Get-Module -Name $moduleName)) {
    Import-Module $moduleName
}

. $power_shell_dir\starship.ps1

