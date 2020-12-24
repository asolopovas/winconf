Remove-Alias gs
Remove-Alias ga
Remove-Alias gb
Remove-Alias gc
Remove-Alias gd
Remove-Alias gp
Remove-Alias gl
Remove-Alias go

# Github
function gs { git status }
function ga { git add $args }
function gb { git branch $args }
function gc { git add -A; git commit -m $args }
function gd { git diff $args }
function gch { git checkout $args }
function gp { git push }
function gl { git pull }
function gw { git add -A; git commit -m 'save'}

function nah { git reset --hard }

# Choco
function choco-installed-list { choco list --local-only }

# Tools
function hosts-edit {
  nvim.exe "C:\Windows\System32\drivers\etc\hosts"
}

function log($value) {
  Write-Output $value
}

function Module-List {
  [CmdletBinding()]
  param()
  (Get-Module -ListAvailable | Select-Object -ExpandProperty Name)
}

function Update-Dev-Conf() {
  yarn remove dev-conf
  yarn add https://github.com/asolopovas/dev-conf.git
}



function Module-Reload($Name) {
  Import-Module $name -Force -WarningAction SilentlyContinue
}

Register-ArgumentCompleter -CommandName Module-Reload -ParameterName Name -ScriptBlock {
  Get-Module -ListAvailable | Select-Object -ExpandProperty Name | ForEach-Object {
      $Text = $_
      log $Text
      if ($Text -match '\s') { $Text = $Text -replace '^|$','"' }

      [System.Management.Automation.CompletionResult]::new(
          $Text,
          $_,
          'ParameterValue',
          "$_"
      )
  }
}



$winconf = "$env:USERPROFILE\winconf"

# Various
Set-Alias -Name which  -Value Get-Command
Set-Alias -Name get    -Value File-Get
Set-Alias -Name tail   -Value Tail-Content
Set-Alias -Name touch  -Value Touch-File
Set-Alias -Name ln     -Value Sym-Link
Set-Alias -Name grep   -Value Select-String
Set-Alias -Name toUnix -Value convertUnixEnding
Set-Alias -Name impmod -Value Import-Module
Set-Alias -Name vim    -Value C:\tools\neovim\Neovim\bin\nvim.exe
# Docker Aliases
Set-Alias -Name dc -Value docker-compose.exe
Set-Alias -Name dk -Value docker.exe
