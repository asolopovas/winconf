# Test AutoHotkey configuration
Write-Host "=== AutoHotkey Configuration Test ===" -ForegroundColor Yellow

$ahkFiles = @(
    "$env:USERPROFILE\winconf\hotkeys.ahk",
    "$env:USERPROFILE\winconf\hotkey-desktop-switcher.ahk",
    "$env:USERPROFILE\winconf\autohotkey\load.ahk",
    "$env:USERPROFILE\winconf\autohotkey\desktop-switcher\init.ahk"
)

foreach ($file in $ahkFiles) {
    if (Test-Path $file) {
        Write-Host "✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $file" -ForegroundColor Red
    }
}

# Check if AutoHotkey is running
$ahkProcess = Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue
if ($ahkProcess) {
    Write-Host "✓ AutoHotkey is running:" -ForegroundColor Green
    $ahkProcess | ForEach-Object { Write-Host "  Process: $($_.Name) - $($_.Path)" }
} else {
    Write-Host "✗ AutoHotkey is not running" -ForegroundColor Red
}

# Check terminal profiles
Write-Host "=== Terminal Profile Test ===" -ForegroundColor Yellow
$terminalProfiles = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $terminalProfiles) {
    Write-Host "✓ Terminal profiles found" -ForegroundColor Green
} else {
    Write-Host "✗ Terminal profiles not found" -ForegroundColor Red
}

# Check if Ubuntu is available
$ubuntu = Get-AppxPackage -Name "*Ubuntu*" -ErrorAction SilentlyContinue
if ($ubuntu) {
    Write-Host "✓ Ubuntu package found:" -ForegroundColor Green
    $ubuntu | ForEach-Object { Write-Host "  $($_.Name) - $($_.PackageFullName)" }
} else {
    Write-Host "✗ Ubuntu package not found" -ForegroundColor Red
}