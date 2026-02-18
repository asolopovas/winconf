. $env:userprofile\winconf\functions.ps1

$winconf = "$env:USERPROFILE\winconf"
$mydocs = [Environment]::GetFolderPath("MyDocuments")
$modulePath = "$winconf\powershell\modules"
$profile_src = "$winconf\powershell\Microsoft.PowerShell_profile.ps1"

$currentPath = [System.Environment]::GetEnvironmentVariable("PSModulePath", "User")
$cleanPaths = ($currentPath -split ";" | Where-Object { $_ -and $_ -ne $modulePath }) -join ";"
$newPath = if ($cleanPaths) { "$cleanPaths;$modulePath" } else { $modulePath }
[System.Environment]::SetEnvironmentVariable("PSModulePath", $newPath, "User")

$profileDirs = @(
    "$mydocs\WindowsPowerShell"
    "$mydocs\PowerShell"
)

foreach ($dir in $profileDirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir }
    CreateSymLink "$dir\Microsoft.PowerShell_profile.ps1" $profile_src
    CreateSymLink "$dir\Microsoft.VSCode_profile.ps1" $profile_src
    CreateSymLink "$dir\Profile.ps1" $profile_src
}
