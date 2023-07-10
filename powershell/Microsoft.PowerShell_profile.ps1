$root = "$env:USERPROFILE\winconf"
$power_shell_dir = "$root\powershell"
$ENV:STARSHIP_CONFIG = "$power_shell_dir\starship.toml"

. $root\functions.ps1
. $power_shell_dir\completions\git-cli.ps1
. $power_shell_dir\remove-aliases.ps1
. $power_shell_dir\shortcuts.ps1

Import-Module PSReadLine

. $power_shell_dir\starship.ps1

If (Test-Path "$env:userprofile\miniconda3\Scripts\conda.exe") {
    (& "$env:userprofile\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
