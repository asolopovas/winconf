# Github
function gs { git status }
function ga { git add $args }
function gb { git branch $args }
function gc { git add -A; git commit -m $args }
function gd { git diff $args }
function gk { git checkout $args }
function gp { git push }
function gl { git pull }
function gw {
    git add -A
    $commitMessage = Read-Host "Enter commit message"
    if (-not [string]::IsNullOrWhiteSpace($commitMessage)) {
        git commit -m "$commitMessage"
    }
    else {
        Write-Warning "Commit cancelled due to empty commit message."
    }
}
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

function CD1 { Set-Location .. }
function CD2 { Set-Location ../.. }
function CD3 { Set-Location ../../.. }
function CD4 { Set-Location ../../../.. }
function CD5 { Set-Location ../../../../.. }

New-Alias -Name '..' -Value CD1
New-Alias -Name '..2' -Value CD2
New-Alias -Name '..3' -Value CD3
New-Alias -Name '..4' -Value CD4
New-Alias -Name '..5' -Value CD5


