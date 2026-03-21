$scoopShims = "$env:USERPROFILE\scoop\shims"

$scoopApps = @(
    'cwrsync'
)

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing scoop..." -ForegroundColor Cyan
    $installerUrl = "https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1"
    $installerPath = Join-Path $env:TEMP "scoop-install.ps1"
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    & $installerPath
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    $env:PATH = "$scoopShims;$env:PATH"
    Write-Host "  Scoop installed" -ForegroundColor Green
} else {
    Write-Host "  Scoop already installed" -ForegroundColor DarkGray
    scoop update
}

foreach ($app in $scoopApps) {
    $installed = scoop list $app 2>$null | Select-String $app
    if ($installed) {
        Write-Host "  $app already installed" -ForegroundColor DarkGray
    } else {
        Write-Host "  Installing $app..." -ForegroundColor Cyan
        scoop install $app
        Write-Host "  $app installed" -ForegroundColor Green
    }
}
