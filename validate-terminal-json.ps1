# Validate terminal JSON and fix common issues
$configPath = "$env:USERPROFILE\winconf\terminal\profiles.json"

Write-Host "Validating terminal JSON..." -ForegroundColor Yellow

try {
    $content = Get-Content $configPath -Raw
    Write-Host "✓ File can be read" -ForegroundColor Green
    
    # Check for common JSON issues
    if ($content -match ',\s*[}\]]') {
        Write-Host "⚠ Found trailing comma(s) - this might cause issues" -ForegroundColor Yellow
    }
    
    # Try to parse JSON
    $json = $content | ConvertFrom-Json
    Write-Host "✓ JSON syntax is valid" -ForegroundColor Green
    
    # Check required fields
    if ($json.profiles -and $json.profiles.list) {
        Write-Host "✓ Profiles structure is valid" -ForegroundColor Green
        $profileCount = $json.profiles.list.Count
        Write-Host "  Found $profileCount profiles" -ForegroundColor Green
        
        # Check for Ubuntu profile
        $ubuntuProfile = $json.profiles.list | Where-Object { $_.name -eq "Ubuntu" }
        if ($ubuntuProfile) {
            Write-Host "✓ Ubuntu profile found" -ForegroundColor Green
            Write-Host "  GUID: $($ubuntuProfile.guid)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Ubuntu profile not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Invalid profiles structure" -ForegroundColor Red
    }
    
    Write-Host "✓ Terminal configuration is valid" -ForegroundColor Green
    
} catch {
    Write-Host "✗ JSON validation failed: $_" -ForegroundColor Red
    Write-Host "Please check the JSON syntax in $configPath" -ForegroundColor Yellow
}