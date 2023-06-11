. $env:userprofile\winconf\functions.ps1

$src = "$env:APPDATA\GPSoftware\Directory Opus"
$target = "$env:USERPROFILE\Insync\andrius.solopovas@gmail.com\Google Drive\configs\Directory Opus"

if (Test-Path $src -PathType Container) {
    Remove-Item -Force $src -Recurse
}

CreateSymLink $src $target
