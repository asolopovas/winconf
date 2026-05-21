[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$pluginName = "winconf_aimp_delete_helper"
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root "plugins\aimp-delete-helper\Plugin.cs"
$buildDir = Join-Path $root "tmp\aimp-delete-helper"
$dest = Join-Path $env:APPDATA "AIMP\Plugins\$pluginName"
$coreDll = Join-Path $dest "$pluginName.dll"
$sdkDll = Join-Path $dest "AIMP.SDK.dll"
$pluginDll = Join-Path $dest "${pluginName}_plugin.dll"

if ((Test-Path $coreDll) -and (Test-Path $sdkDll) -and (Test-Path $pluginDll) -and -not $Force) {
    Write-Host "AIMP delete helper already installed" -ForegroundColor Green
    return
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$package = Join-Path $buildDir "AimpSDK-x64.nupkg"
$extractDir = Join-Path $buildDir "sdk"
if ((-not (Test-Path $package)) -or $Force) {
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/AimpSDK-x64/5.03.2394.5" -OutFile $package
}

if ((Test-Path $extractDir) -and $Force) {
    Remove-Item -Recurse -Force $extractDir
}

if (-not (Test-Path $extractDir)) {
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $package -DestinationPath $extractDir -Force
}

$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) {
    throw "csc.exe not found"
}

$packageLib = Join-Path $extractDir "lib\net48"
$buildDll = Join-Path $buildDir "$pluginName.dll"
$args = @(
    "/nologo",
    "/target:library",
    "/platform:x64",
    "/out:$buildDll",
    "/reference:$(Join-Path $packageLib 'AIMP.SDK.dll')",
    "/reference:System.Windows.Forms.dll",
    "/reference:System.dll",
    $source
)
& $csc @args
if ($LASTEXITCODE -ne 0) {
    throw "AIMP delete helper build failed"
}

Copy-Item (Join-Path $packageLib "aimp_dotnet.dll") $coreDll -Force
Copy-Item (Join-Path $packageLib "AIMP.SDK.dll") $sdkDll -Force
Copy-Item $buildDll $pluginDll -Force
Write-Host "AIMP delete helper installed" -ForegroundColor Green
