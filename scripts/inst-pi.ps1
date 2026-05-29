$ErrorActionPreference = "Stop"

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }
    winget install --id Oven-sh.Bun --exact -h --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    $bunPath = Join-Path $env:USERPROFILE ".bun\bin"
    if (Test-Path $bunPath) { $env:Path = "$bunPath;$env:Path" }
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { throw "bun unavailable" }
}

bun add -g --ignore-scripts @earendil-works/pi-coding-agent
if ($LASTEXITCODE) { exit $LASTEXITCODE }
