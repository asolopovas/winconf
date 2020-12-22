$customScriptsPath = "$PSScriptRoot\..\..\."
$document = [environment]::getfolderpath("mydocuments")
$confSrc1 = "$document\WindowsPowerShell"
# $confSrc2 = "$document\PowerShell"
$confTarget = $customScriptsPath

Sync-Config $confSrc1 $confTarget
# Sync-Config $confSrc2 $confTarget

