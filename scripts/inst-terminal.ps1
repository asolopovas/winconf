. "$env:userprofile\winconf\functions.ps1"

$terminal_conf_dir = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $terminal_conf_dir) {
    Write-Host "Windows Terminal config directory not found" -ForegroundColor Red
    exit 1
}

$settingsFile = "$terminal_conf_dir\settings.json"
Remove-Item $settingsFile -Force -ErrorAction SilentlyContinue

SetPermissions $terminal_conf_dir
CreateSymLink $settingsFile "$env:userprofile\winconf\terminal\profiles.json"
