# Fix broken Windows Terminal symlink caused by directory reorganization
Write-Host "=== Fixing Broken Terminal Symlink ===" -ForegroundColor Yellow

# Import functions
. "$env:userprofile\winconf\functions.ps1"

# Find Windows Terminal config directory
$terminal_conf_dir = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $terminal_conf_dir) {
    Write-Host "✗ Windows Terminal config directory not found" -ForegroundColor Red
    Write-Host "Please install Windows Terminal from Microsoft Store" -ForegroundColor Yellow
    exit 1
}

$settingsFile = "$terminal_conf_dir\settings.json"
$configPath = "$env:userprofile\winconf\terminal\profiles.json"

Write-Host "Terminal config directory: $terminal_conf_dir" -ForegroundColor Green
Write-Host "Settings file: $settingsFile" -ForegroundColor Green
Write-Host "Config path: $configPath" -ForegroundColor Green

# Check if config file exists
if (-not (Test-Path $configPath)) {
    Write-Host "✗ Config file missing: $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Config file exists" -ForegroundColor Green

# Remove existing broken symlink/file
if (Test-Path $settingsFile) {
    Write-Host "Removing existing settings file..." -ForegroundColor Yellow
    Remove-Item $settingsFile -Force -ErrorAction SilentlyContinue
}

# Set permissions
Write-Host "Setting permissions..." -ForegroundColor Yellow
SetPermissions $terminal_conf_dir

# Create new symlink
Write-Host "Creating new symlink..." -ForegroundColor Yellow
try {
    CreateSymLink $settingsFile $configPath
    Write-Host "✓ Symlink created successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Error creating symlink: $_" -ForegroundColor Red
    Write-Host "Please run as Administrator" -ForegroundColor Yellow
    exit 1
}

# Verify the symlink
if (Test-Path $settingsFile) {
    $item = Get-Item $settingsFile
    if ($item.LinkType -eq "SymbolicLink") {
        Write-Host "✓ Symlink verified successfully" -ForegroundColor Green
        Write-Host "Target: $($item.Target)" -ForegroundColor Green
    } else {
        Write-Host "✗ File exists but is not a symlink" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Settings file was not created" -ForegroundColor Red
}

Write-Host "=== Fix Complete ===" -ForegroundColor Yellow
Write-Host "Please restart Windows Terminal to apply the changes." -ForegroundColor Green