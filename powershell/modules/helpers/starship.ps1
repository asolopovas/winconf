
if (Test-CommandExists starship) {
    try {
        Invoke-Expression (&starship init powershell)
    }
    catch {
        Write-Host "Warning: Starship initialization failed" -ForegroundColor Yellow
    }
}
