$ErrorActionPreference = "Stop"
if (-not $env:PNPM_HOME) { $env:PNPM_HOME = Join-Path $env:LOCALAPPDATA "pnpm" }
$pnpmGlobalBin = Join-Path $env:PNPM_HOME "bin"
New-Item -ItemType Directory -Path $env:PNPM_HOME -Force | Out-Null
New-Item -ItemType Directory -Path $pnpmGlobalBin -Force | Out-Null
$env:Path = @($pnpmGlobalBin, $env:PNPM_HOME, (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"), $env:Path) -join ";"

if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }
    winget install --id pnpm.pnpm --exact --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) { throw "pnpm unavailable" }
}

pnpm add -g --ignore-scripts @earendil-works/pi-coding-agent
if ($LASTEXITCODE) { exit $LASTEXITCODE }
