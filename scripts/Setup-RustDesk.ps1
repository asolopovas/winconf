. $env:USERPROFILE\winconf\functions.ps1

$src = "$env:USERPROFILE\gdrive\configs\RustDeskPeers"
$target = "$env:USERPROFILE\AppData\Roaming\RustDesk\config\peers"
if (Test-Path $target) {
    Remove-Item $target -Recurse
}

CreateSymLink $target $src
