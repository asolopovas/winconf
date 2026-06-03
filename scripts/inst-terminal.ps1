$root = Join-Path $env:USERPROFILE "winconf"
. (Join-Path $root "functions.ps1")

$terminalConfigDir = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState")
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState")
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $terminalConfigDir) { throw "Windows Terminal config directory not found" }

SetPermissions $terminalConfigDir
CreateSymLink (Join-Path $terminalConfigDir "settings.json") (Join-Path $root "terminal\profiles.json") | Out-Null
