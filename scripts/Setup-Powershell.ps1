. $env:userprofile\winconf\functions.ps1

$winconf = "$env:USERPROFILE\winconf"

$mydocs = [Environment]::GetFolderPath("MyDocuments")
$dir_1 = "$mydocs\WindowsPowerShell"
$dir_2 = "$mydocs\PowerShell"
$profile_src = "$winconf\powershell\Microsoft.PowerShell_profile.ps1"

$currentPath = [System.Environment]::GetEnvironmentVariable("PSModulePath", "User")
[System.Environment]::SetEnvironmentVariable("PSModulePath", "$currentPath;$winconf\powershell\modules", "User")

if (-not (Test-Path $dir_1)) {
    New-Item -ItemType Directory -Path $dir_1
}

if (-not (Test-Path $dir_2)) {
    New-Item -ItemType Directory -Path $dir_2
}

CreateSymLink "$dir_1\Microsoft.PowerShell_profile.ps1" $profile_src
CreateSymLink "$dir_1\Microsoft.VSCode_profile.ps1" $profile_src
CreateSymLink "$dir_2\Profile.ps1" $profile_src
