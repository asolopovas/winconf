# Comprehensive fix for issues after directory reorganization
param(
    [switch]$TestOnly,
    [switch]$RestartServices
)

Write-Host "=== Fixing PowerShell and AutoHotkey Issues ===" -ForegroundColor Yellow

# 1. Fix PowerShell profile and ensure proper loading
Write-Host "1. Checking PowerShell profile..." -ForegroundColor Green
$profilePath = $PROFILE.AllUsersAllHosts
$configPath = "$env:USERPROFILE\winconf\powershell\Microsoft.Powershell_profile.ps1"

if (Test-Path $configPath) {
    Write-Host "✓ Config file exists: $configPath" -ForegroundColor Green
    
    # Test if profile is properly symlinked
    if (Test-Path $profilePath) {
        $isSymlink = (Get-Item $profilePath).LinkType -eq "SymbolicLink"
        if ($isSymlink) {
            Write-Host "✓ Profile is properly symlinked" -ForegroundColor Green
        } else {
            Write-Host "⚠ Profile exists but is not a symlink" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ Profile does not exist at $profilePath" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Config file missing: $configPath" -ForegroundColor Red
}

# 2. Check and fix starship configuration
Write-Host "2. Checking Starship configuration..." -ForegroundColor Green
$starshipConfig = "$env:USERPROFILE\winconf\powershell\configs\starship.toml"

if (Test-Path $starshipConfig) {
    Write-Host "✓ Starship config exists: $starshipConfig" -ForegroundColor Green
    $env:STARSHIP_CONFIG = $starshipConfig
    
    # Test starship command
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host "✓ Starship command available" -ForegroundColor Green
        try {
            $starshipVersion = starship --version
            Write-Host "✓ Starship version: $starshipVersion" -ForegroundColor Green
        } catch {
            Write-Host "✗ Error running starship: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Starship command not found in PATH" -ForegroundColor Red
        Write-Host "  Checking common locations..." -ForegroundColor Yellow
        
        $possiblePaths = @(
            "$env:LOCALAPPDATA\Microsoft\WinGet\Links\starship.exe",
            "$env:USERPROFILE\.cargo\bin\starship.exe",
            "C:\tools\starship\starship.exe"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                Write-Host "  Found starship at: $path" -ForegroundColor Green
                Write-Host "  Consider adding to PATH: $(Split-Path $path)" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "✗ Starship config missing: $starshipConfig" -ForegroundColor Red
}

# 3. Check AutoHotkey configuration
Write-Host "3. Checking AutoHotkey configuration..." -ForegroundColor Green
$ahkMainScript = "$env:USERPROFILE\winconf\autohotkey\load.ahk"

if (Test-Path $ahkMainScript) {
    Write-Host "✓ AutoHotkey main script exists: $ahkMainScript" -ForegroundColor Green
    
    # Check if AutoHotkey is running
    $ahkProcess = Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue
    if ($ahkProcess) {
        Write-Host "✓ AutoHotkey is running" -ForegroundColor Green
        $ahkProcess | ForEach-Object { Write-Host "  Process: $($_.Name) - PID: $($_.Id)" }
    } else {
        Write-Host "✗ AutoHotkey is not running" -ForegroundColor Red
        
        if (-not $TestOnly) {
            Write-Host "  Attempting to start AutoHotkey..." -ForegroundColor Yellow
            try {
                $ahkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
                if (Test-Path $ahkExe) {
                    Start-Process -FilePath $ahkExe -ArgumentList $ahkMainScript -NoNewWindow
                    Write-Host "✓ AutoHotkey started" -ForegroundColor Green
                } else {
                    Write-Host "✗ AutoHotkey executable not found at $ahkExe" -ForegroundColor Red
                }
            } catch {
                Write-Host "✗ Error starting AutoHotkey: $_" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "✗ AutoHotkey main script missing: $ahkMainScript" -ForegroundColor Red
}

# 4. Check terminal configuration
Write-Host "4. Checking Windows Terminal configuration..." -ForegroundColor Green
$terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$terminalConfig = "$env:USERPROFILE\winconf\terminal\profiles.json"

if (Test-Path $terminalConfig) {
    Write-Host "✓ Terminal config exists: $terminalConfig" -ForegroundColor Green
    
    if (Test-Path $terminalSettings) {
        $isSymlink = (Get-Item $terminalSettings).LinkType -eq "SymbolicLink"
        if ($isSymlink) {
            Write-Host "✓ Terminal settings properly symlinked" -ForegroundColor Green
        } else {
            Write-Host "⚠ Terminal settings exist but not symlinked" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Terminal settings not found at $terminalSettings" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Terminal config missing: $terminalConfig" -ForegroundColor Red
}

# 5. Test Ubuntu availability
Write-Host "5. Checking Ubuntu availability..." -ForegroundColor Green
$ubuntu = Get-AppxPackage -Name "*Ubuntu*" -ErrorAction SilentlyContinue
if ($ubuntu) {
    Write-Host "✓ Ubuntu package found" -ForegroundColor Green
    $ubuntu | ForEach-Object { Write-Host "  $($_.Name) - $($_.PackageFullName)" }
} else {
    Write-Host "✗ Ubuntu package not found" -ForegroundColor Red
    Write-Host "  Install Ubuntu from Microsoft Store" -ForegroundColor Yellow
}

# 6. Summary and recommendations
Write-Host "=== Summary and Recommendations ===" -ForegroundColor Yellow

if ($RestartServices) {
    Write-Host "Restarting services..." -ForegroundColor Green
    
    # Restart Windows Terminal
    Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Restart AutoHotkey
    Get-Process -Name "AutoHotkey*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    
    $ahkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    if (Test-Path $ahkExe) {
        Start-Process -FilePath $ahkExe -ArgumentList $ahkMainScript -NoNewWindow
        Write-Host "✓ AutoHotkey restarted" -ForegroundColor Green
    }
}

Write-Host "Complete! Please restart PowerShell and Windows Terminal to apply changes." -ForegroundColor Green
Write-Host "Press Win+Enter to test Ubuntu terminal startup." -ForegroundColor Green