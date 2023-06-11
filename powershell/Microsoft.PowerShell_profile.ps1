$root = "$env:USERPROFILE\winconf"
$power_shell_dir = "$root\powershell"

. $root\functions.ps1

Import-Module PSReadLine

. $power_shell_dir\shortcuts.ps1

$coreAliases = @(
    'gc'
    'gp'
    'gl'
)

# Register-ArgumentCompleter -CommandName Module-Reload -ParameterName Name -ScriptBlock {
#     Get-Module -ListAvailable | Select-Object -ExpandProperty Name | ForEach-Object {
#         $Text = $_
#         Write-Output $Text
#         if ($Text -match '\s') { $Text = $Text -replace '^|$', '"' }

#         [System.Management.Automation.CompletionResult]::new(
#             $Text,
#             $_,
#             'ParameterValue',
#             "$_"
#         )
#     }
# }

foreach ($alias in $coreAliases) {
    Remove-Item -Force Alias:$alias
}

# . $power_shell_dir\completions\docker.ps1
# . $power_shell_dir\starship.ps1


