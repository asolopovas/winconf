. $env:userprofile\winconf\functions.ps1

$winconf = "$env:USERPROFILE\winconf"


$mydocs = [Environment]::GetFolderPath("MyDocuments")
$target = "$winconf\powershell"
$src_1 = "$mydocs\WindowsPowerShell"
$src_2 = "$mydocs\PowerShell"

CreateSymLink $src_1 $target
CreateSymLink $src_2 $target
CreateSymLink "$winconf\powershell\Microsoft.VSCode_profile.ps1"  "$winconf\powershell\Microsoft.PowerShell_profile.ps1"
