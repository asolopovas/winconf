. $env:userprofile\winconf\functions.ps1

# Config
$dir_1 = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$dir_2 = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"

if (Test-Path $dir_1) {
    $terminal_conf_dir = $dir_1
} elseif (Test-Path $dir_2) {
    $terminal_conf_dir = $dir_2
} else {
    Write-Host "Windows Terminal config directory not found"
    Return 1
}

$settingsFile = "$terminal_conf_dir\settings.json"
Remove-Item $settingsFile -Force -ErrorAction SilentlyContinue

SetPermissions $terminal_conf_dir
CreateSymLink $settingsFile "$env:userprofile\winconf\configs\winterminal\profiles.json"
