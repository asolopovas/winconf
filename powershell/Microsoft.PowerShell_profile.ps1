if( Get-Module -ListAvailable -Name WebAdministration ) {
  Import-Module WebAdministration
}
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

if ($host.Name -eq 'ConsoleHost')
{
    Import-Module PSReadLine
}

Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
Import-Module $PSScriptRoot\modules\helpers\helpers.psm1 -WarningAction SilentlyContinue
. $PSScriptRoot\Settings.ps1
. $PSScriptRoot\Aliases.ps1

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Ctrl + t and Ctrl + r for fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
