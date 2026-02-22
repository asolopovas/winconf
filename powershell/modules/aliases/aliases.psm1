. $PSScriptRoot/git-aliases.ps1
. $PSScriptRoot/package-managers.ps1

function lsChoco { choco list --local-only }

function lsModules {
    [CmdletBinding()]
    param()
  (Get-Module -ListAvailable | Select-Object -ExpandProperty Name)
}

New-Alias -Name which   -Scope Global -Value Get-Command
New-Alias -Name l       -Scope Global -Value Get-ChildItem
New-Alias -Name grep    -Scope Global -Value Select-String
New-Alias -Name dk      -Scope Global -Value docker.exe
New-Alias -Name pbpaste -Scope Global -Value Get-Clipboard
New-Alias -Name ppaste  -Scope Global -Value Get-Clipboard
New-Alias -Name pbcopy  -Scope Global -Value Set-Clipboard
New-Alias -Name pcopy   -Scope Global -Value Set-Clipboard

New-Alias -Name "pt" -Value poetry.exe

