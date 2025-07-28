. $env:userprofile\winconf\functions.ps1

$src = "$HOME\AppData\Roaming\mIRC"
$target = "$HOME\gdrive\configs\mIRC"

CreateSymLink  $src $target
