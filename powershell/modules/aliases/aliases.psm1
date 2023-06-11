# Github
function gs { git status }
function ga { git add $args }
function gb { git branch $args }
function gc { git add -A; git commit -m $args }
function gd { git diff $args }
function gk { git checkout $args }
function gp { git push }
function gl { git pull }
function gw { git add -A; git commit -m 'save' }
# Docker
function nah { git reset --hard; git clean -fd }

# Choco
function lsChoco { choco list --local-only }

function Log($value) {
    Write-Output $value
}

# List Loded Module Names
function lsModules {
    [CmdletBinding()]
    param()
  (Get-Module -ListAvailable | Select-Object -ExpandProperty Name)
}

New-Alias -Name which   -Scope Global -Value Get-Command
New-Alias -Name l       -Scope Global -Value Get-ChildItem
New-Alias -Name grep    -Scope Global -Value Select-String
New-Alias -Name dk      -Scope Global -Value docker.exe


