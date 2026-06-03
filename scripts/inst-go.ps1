$ErrorActionPreference = "Stop"
$id = "GoLang.Go"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }

winget list --id $id --exact --accept-source-agreements 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    winget install --id $id --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "Failed to install $id" }
    exit 0
}

$upgrade = winget upgrade --id $id --exact --accept-source-agreements 2>$null | Out-String
if (($LASTEXITCODE -ne 0) -or ($upgrade -notmatch [regex]::Escape($id))) { exit 0 }

winget upgrade --id $id --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { throw "Failed to upgrade $id" }
