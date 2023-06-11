$root = "$env:USERPROFILE\winconf"
$power_shell_dir = "$root\powershell"
$ENV:STARSHIP_CONFIG = "$power_shell_dir\starship.toml"
$ENV:SPACESHIP_PROMPT_ADD_NEWLINE = $false
$ENV:SPACESHIP_PROMPT_SEPARATE_LINE = $false
$ENV:SPACESHIP_RPROMPT_ADD_NEWLINE = $true

. $root\functions.ps1
. $power_shell_dir\remove-aliases.ps1
. $power_shell_dir\shortcuts.ps1

Import-Module PSReadLine

. $power_shell_dir\starship.ps1
