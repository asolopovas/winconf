. "$env:USERPROFILE\winconf\functions.ps1"

Write-Host "Setting up Wezterm..." -ForegroundColor DarkCyan

# Create default .wezterm.lua config if it doesn't exist
$weztermConfigFile = "$env:USERPROFILE\winconf\configs\.wezterm.lua"
if (!(Test-Path -Path $weztermConfigFile)) {
    Write-Host "Wezterm config not found at $weztermConfigFile" -ForegroundColor Yellow
    Write-Host "Please ensure the config file exists in the winconf repository" -ForegroundColor Yellow
    return
}

# Create symlink for ~/.wezterm.lua
$targetPath = "$env:USERPROFILE\.wezterm.lua"
if (Test-Path -Path $targetPath) {
    Write-Host "Removing existing .wezterm.lua" -ForegroundColor Yellow
    Remove-Item -Path $targetPath -Force
}

CreateSymLink $targetPath $weztermConfigFile
Write-Host "Created symlink from $weztermConfigFile to $targetPath" -ForegroundColor Green

Write-Host "Wezterm setup complete!" -ForegroundColor Green