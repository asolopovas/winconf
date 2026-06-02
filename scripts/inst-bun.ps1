param([Alias("rm")][switch]$Remove, [switch]$Uninstall)

$ErrorActionPreference = "Stop"
$id = "Oven-sh.Bun"
$linkDir = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
$bunBin = Join-Path $env:USERPROFILE ".bun\bin"
$removeBun = $Uninstall -or $Remove -or [bool]($args -match "^(--|-)?(uninstall|remove|rm)$")
$action = if ($removeBun) { "uninstall" } else { "install" }

function Format-PathList($Raw, $Add, $Drop) {
    $dropPaths = @($Drop | ForEach-Object { $_.TrimEnd('\') })
    $paths = @($Raw -split ";" | Where-Object { $_ -and ($dropPaths -notcontains $_.TrimEnd('\')) })
    foreach ($path in $Add) { if ($paths -notcontains $path) { $paths += $path } }
    $paths -join ";"
}

function Set-UserPath($Add = @(), $Drop = @()) {
    $userPath = Format-PathList ([Environment]::GetEnvironmentVariable("Path", "User")) $Add $Drop
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
    $env:Path = Format-PathList $env:Path $Add $Drop
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget required" }
winget list --id $id --exact
$installed = -not $LASTEXITCODE

if ((($action -eq "install") -and (-not $installed)) -or (($action -eq "uninstall") -and $installed)) {
    $wingetArgs = @($action, "--id", $id, "--exact", "--silent", "--accept-source-agreements")
    if ($action -eq "install") { $wingetArgs += "--accept-package-agreements" }
    winget @wingetArgs
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}

if ($action -eq "install") { Set-UserPath @($linkDir) @($bunBin) } else { Remove-Item -LiteralPath (Join-Path $env:USERPROFILE ".bun") -Recurse -Force -ErrorAction SilentlyContinue; Set-UserPath @() @($bunBin) }
