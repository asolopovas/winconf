$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Add-BunPath {
    $bunPath = Join-Path $env:USERPROFILE ".bun\bin"
    if ((Test-Path $bunPath) -and (($env:Path -split ";") -notcontains $bunPath)) {
        $env:Path = "$bunPath;$env:Path"
    }
}

function Install-Bun {
    if (Test-CommandExists "bun") {
        Write-Host "Bun already installed" -ForegroundColor Yellow
        return
    }

    if (-not (Test-CommandExists "winget")) {
        Write-Error "winget is required to install Bun"
        exit 1
    }

    Write-Host "Installing Bun" -ForegroundColor Cyan
    winget install --id Oven-sh.Bun --exact -h --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Bun install failed"
        exit $LASTEXITCODE
    }

    Add-BunPath

    if (-not (Test-CommandExists "bun")) {
        Write-Error "Bun was installed but is not available on PATH"
        exit 1
    }
}

Install-Bun

Write-Host "Installing or updating Pi Coding Agent" -ForegroundColor Cyan
bun add -g --ignore-scripts @earendil-works/pi-coding-agent
if ($LASTEXITCODE -ne 0) {
    Write-Error "Pi Coding Agent install or update failed"
    exit $LASTEXITCODE
}

Write-Host "Pi Coding Agent is installed and up to date" -ForegroundColor Green
