. $env:userprofile\winconf\functions.ps1

$src = "$env:APPDATA\GPSoftware\Directory Opus"
$target = "$env:USERPROFILE\gdrive\configs\Directory Opus"

if (Test-Path $src -PathType Container) {
    Remove-Item -Force $src -Recurse
}

CreateSymLink $src $target
