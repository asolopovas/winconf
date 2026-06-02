$ErrorActionPreference = "Stop"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }

winget list --id Oven-sh.Bun --exact
if (-not $LASTEXITCODE) {
    winget uninstall --id Oven-sh.Bun --exact --silent --accept-source-agreements
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

$bunHome = Join-Path $env:USERPROFILE ".bun"
if (Test-Path $bunHome) { Remove-Item -LiteralPath $bunHome -Recurse -Force }
