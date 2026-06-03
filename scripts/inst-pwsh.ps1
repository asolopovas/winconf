$root = Join-Path $env:USERPROFILE "winconf"
. (Join-Path $root "functions.ps1")

$documents = [Environment]::GetFolderPath("MyDocuments")
$modulePath = Join-Path $root "powershell\modules"
$profileSource = Join-Path $root "powershell\Microsoft.PowerShell_profile.ps1"
$currentPath = [Environment]::GetEnvironmentVariable("PSModulePath", "User")
$paths = @($currentPath -split ";" | Where-Object { $_ -and $_.TrimEnd("\") -ine $modulePath.TrimEnd("\") })
[Environment]::SetEnvironmentVariable("PSModulePath", (@($paths) + $modulePath) -join ";", "User")

foreach ($dir in @((Join-Path $documents "WindowsPowerShell"), (Join-Path $documents "PowerShell"))) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    CreateSymLink (Join-Path $dir "Microsoft.PowerShell_profile.ps1") $profileSource | Out-Null
    CreateSymLink (Join-Path $dir "Microsoft.VSCode_profile.ps1") $profileSource | Out-Null
    CreateSymLink (Join-Path $dir "Profile.ps1") $profileSource | Out-Null
}
