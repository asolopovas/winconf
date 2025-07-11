# Check starship installation and fix PATH issues
Write-Host "=== Starship Configuration Check ===" -ForegroundColor Yellow

# Check if starship is in PATH
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Write-Host "✓ Starship found in PATH" -ForegroundColor Green
    $starshipPath = (Get-Command starship).Source
    Write-Host "  Location: $starshipPath" -ForegroundColor Green
    
    try {
        $version = starship --version
        Write-Host "  Version: $version" -ForegroundColor Green
    } catch {
        Write-Host "  Error getting version: $_" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Starship not found in PATH" -ForegroundColor Red
    
    # Check common installation locations
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\starship.exe",
        "$env:USERPROFILE\.cargo\bin\starship.exe",
        "C:\tools\starship\starship.exe",
        "$env:PROGRAMFILES\starship\starship.exe"
    )
    
    Write-Host "Checking common locations..." -ForegroundColor Yellow
    $foundPath = $null
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Host "✓ Found starship at: $path" -ForegroundColor Green
            $foundPath = $path
            break
        }
    }
    
    if ($foundPath) {
        $starshipDir = Split-Path $foundPath
        Write-Host "Adding to PATH: $starshipDir" -ForegroundColor Yellow
        
        # Add to current session PATH
        $env:PATH = "$starshipDir;$env:PATH"
        
        # Test again
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Write-Host "✓ Starship now available in PATH" -ForegroundColor Green
            
            # Test starship init
            try {
                $initCommand = starship init powershell
                Write-Host "✓ Starship init command works" -ForegroundColor Green
            } catch {
                Write-Host "✗ Error with starship init: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "✗ Still cannot find starship after adding to PATH" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Starship not found in any common location" -ForegroundColor Red
        Write-Host "Please install starship using: winget install starship" -ForegroundColor Yellow
    }
}

# Check starship config
$starshipConfig = "$env:USERPROFILE\winconf\powershell\configs\starship.toml"
if (Test-Path $starshipConfig) {
    Write-Host "✓ Starship config found: $starshipConfig" -ForegroundColor Green
    $env:STARSHIP_CONFIG = $starshipConfig
    Write-Host "  Config set: $env:STARSHIP_CONFIG" -ForegroundColor Green
} else {
    Write-Host "✗ Starship config not found: $starshipConfig" -ForegroundColor Red
}

Write-Host "=== PATH Analysis ===" -ForegroundColor Yellow
$pathEntries = $env:PATH.Split(';')
Write-Host "PATH entries containing 'starship':" -ForegroundColor Green
$pathEntries | Where-Object { $_ -like '*starship*' } | ForEach-Object { Write-Host "  $_" }

Write-Host "PATH entries containing 'winget':" -ForegroundColor Green
$pathEntries | Where-Object { $_ -like '*winget*' } | ForEach-Object { Write-Host "  $_" }

Write-Host "PATH entries containing 'Local':" -ForegroundColor Green
$pathEntries | Where-Object { $_ -like '*Local*' } | ForEach-Object { Write-Host "  $_" }