$root = "$env:USERPROFILE\winconf"
$power_shell_dir = "$root\powershell"
$ENV:STARSHIP_CONFIG = "$power_shell_dir\starship.toml"

. $env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1
conda activate $env:USERPROFILE\miniconda3

. $root\functions.ps1
. $power_shell_dir\completions\git-cli.ps1
. $power_shell_dir\remove-aliases.ps1
. $power_shell_dir\shortcuts.ps1

$moduleName = "PSReadLine"

if (-not (Get-Module -Name $moduleName)) {
    Import-Module $moduleName
}

. $power_shell_dir\starship.ps1

# get powershell version and if its more than or equals to 7.4 execute the following
$ps_major = $PSVersionTable.PSVersion.Major
$ps_minor = $PSVersionTable.PSVersion.Minor

if ($ps_major -ge 7 -And $ps_minor -ge 4) {
    $power_toys_module = "$env:LOCALAPPDATA\PowerToys\WinGetCommandNotFound.psd1"
    # test if file exists import if it does
    if (Test-Path $power_toys_module) {
        Import-Module $power_toys_module
    }

}

fnm env --use-on-cd | Out-String | Invoke-Expression
