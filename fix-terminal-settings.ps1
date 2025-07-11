# Fix Windows Terminal settings symlink and JSON validation
Write-Host "=== Windows Terminal Settings Fix ===" -ForegroundColor Yellow

$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$configPath = "$env:USERPROFILE\winconf\terminal\profiles.json"

Write-Host "1. Checking terminal configuration..." -ForegroundColor Green
if (Test-Path $configPath) {
    Write-Host "✓ Config file exists: $configPath" -ForegroundColor Green
    
    # Validate JSON syntax
    try {
        $json = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Host "✓ JSON syntax is valid" -ForegroundColor Green
    } catch {
        Write-Host "✗ JSON syntax error: $_" -ForegroundColor Red
        Write-Host "Please fix the JSON syntax in $configPath" -ForegroundColor Yellow
        return
    }
} else {
    Write-Host "✗ Config file missing: $configPath" -ForegroundColor Red
    return
}

Write-Host "2. Checking current terminal settings..." -ForegroundColor Green
$terminalDir = Split-Path $terminalSettingsPath
if (Test-Path $terminalDir) {
    Write-Host "✓ Terminal directory exists: $terminalDir" -ForegroundColor Green
    
    if (Test-Path $terminalSettingsPath) {
        $item = Get-Item $terminalSettingsPath
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "✓ Symlink exists" -ForegroundColor Green
            $target = $item.Target
            Write-Host "  Target: $target" -ForegroundColor Green
            
            if ($target -eq $configPath) {
                Write-Host "✓ Symlink points to correct location" -ForegroundColor Green
            } else {
                Write-Host "✗ Symlink points to wrong location" -ForegroundColor Red
                Write-Host "  Expected: $configPath" -ForegroundColor Yellow
                Write-Host "  Actual: $target" -ForegroundColor Yellow
                $needsRelink = $true
            }
        } else {
            Write-Host "✗ Settings file exists but is not a symlink" -ForegroundColor Red
            $needsRelink = $true
        }
    } else {
        Write-Host "✗ Settings file does not exist" -ForegroundColor Red
        $needsRelink = $true
    }
} else {
    Write-Host "✗ Terminal directory does not exist: $terminalDir" -ForegroundColor Red
    Write-Host "Please install Windows Terminal from Microsoft Store" -ForegroundColor Yellow
    return
}

if ($needsRelink) {
    Write-Host "3. Recreating symlink..." -ForegroundColor Green
    
    # Remove existing file/symlink
    if (Test-Path $terminalSettingsPath) {
        Remove-Item $terminalSettingsPath -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Removed existing settings file" -ForegroundColor Green
    }
    
    # Create new symlink
    try {
        New-Item -ItemType SymbolicLink -Path $terminalSettingsPath -Target $configPath -Force
        Write-Host "✓ Created new symlink" -ForegroundColor Green
        Write-Host "  From: $terminalSettingsPath" -ForegroundColor Green
        Write-Host "  To: $configPath" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error creating symlink: $_" -ForegroundColor Red
        Write-Host "Please run as Administrator" -ForegroundColor Yellow
        return
    }
}

Write-Host "4. Final verification..." -ForegroundColor Green
if (Test-Path $terminalSettingsPath) {
    $item = Get-Item $terminalSettingsPath
    if ($item.LinkType -eq "SymbolicLink") {
        Write-Host "✓ Symlink verification successful" -ForegroundColor Green
        Write-Host "✓ Windows Terminal should now load your settings correctly" -ForegroundColor Green
    } else {
        Write-Host "✗ Symlink verification failed" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Settings file still missing" -ForegroundColor Red
}

Write-Host "=== Complete ===" -ForegroundColor Yellow
Write-Host "Please restart Windows Terminal to apply the changes." -ForegroundColor Green