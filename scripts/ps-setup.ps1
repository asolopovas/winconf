. $env:userprofile\winconf\functions.ps1

$winconf = "$env:USERPROFILE\winconf"

$mydocs = [Environment]::GetFolderPath("MyDocuments")
$dir_1 = "$mydocs\WindowsPowerShell"
$dir_2 = "$mydocs\PowerShell"
$profile_src = "$winconf\powershell\Microsoft.PowerShell_profile.ps1"
$src_1 = $dir_1
$src_2 = $dir_2

if (-not (Test-Path $src_1)) {
    New-Item -ItemType Directory -Path $src_1
}

if (-not (Test-Path $src_2)) {
    New-Item -ItemType Directory -Path $src_2
}

CreateSymLink "$dir_1\Microsoft.Powershell_profile" $profile_src
CreateSymLink "$dir_2\Profile.ps1" $profile_src
