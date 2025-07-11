# Debug script to check profile loading issues
Write-Host "=== PowerShell Profile Debug ===" -ForegroundColor Yellow

$root = Join-Path $env:USERPROFILE 'winconf'
$psdir = Join-Path $root 'powershell'

Write-Host "Root path: $root" -ForegroundColor Green
Write-Host "PowerShell dir: $psdir" -ForegroundColor Green

# Check if files exist
$files = @(
    "$root\functions.ps1",
    "$psdir\completions\git-cli.ps1",
    "$psdir\modules\aliases\remove-aliases.ps1",
    "$psdir\modules\helpers\shortcuts.ps1",
    "$psdir\configs\starship.toml"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✓ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing: $file" -ForegroundColor Red
    }
}

# Check starship config
$starshipConfig = Join-Path $psdir 'configs\starship.toml'
Write-Host "Starship config: $starshipConfig" -ForegroundColor Green
$env:STARSHIP_CONFIG = $starshipConfig

# Check if starship command exists
if (Test-CommandExists starship) {
    Write-Host "✓ Starship command found" -ForegroundColor Green
    try {
        Write-Host "Starship version:" -ForegroundColor Green
        starship --version
    } catch {
        Write-Host "✗ Error running starship: $_" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Starship command not found" -ForegroundColor Red
}

# Check environment variables
Write-Host "=== Environment Variables ===" -ForegroundColor Yellow
Write-Host "PATH entries containing 'starship':" -ForegroundColor Green
$env:PATH.Split(';') | Where-Object { $_ -like '*starship*' } | ForEach-Object { Write-Host "  $_" }

Write-Host "PATH entries containing 'winget':" -ForegroundColor Green
$env:PATH.Split(';') | Where-Object { $_ -like '*winget*' } | ForEach-Object { Write-Host "  $_" }

Write-Host "PATH entries containing 'Local':" -ForegroundColor Green
$env:PATH.Split(';') | Where-Object { $_ -like '*Local*' } | ForEach-Object { Write-Host "  $_" }