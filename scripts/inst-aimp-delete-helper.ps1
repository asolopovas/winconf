[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$pluginName = "winconf_aimp_delete_helper"
$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root "plugins\aimp-delete-helper\Plugin.cpp"
$buildDir = Join-Path $root "tmp\aimp-delete-helper"
$oldDest = Join-Path $env:APPDATA "AIMP\Plugins\$pluginName"
$aimpExe = Join-Path $env:ProgramFiles "AIMP\AIMP.exe"

if (-not (Test-Path $aimpExe)) {
    $process = Get-Process AIMP -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($process -and $process.Path) {
        $aimpExe = $process.Path
    }
}

if ((-not (Test-Path $aimpExe)) -and ${env:ProgramFiles(x86)}) {
    $x86AimpExe = Join-Path ${env:ProgramFiles(x86)} "AIMP\AIMP.exe"
    if (Test-Path $x86AimpExe) {
        $aimpExe = $x86AimpExe
    }
}

if (-not (Test-Path $aimpExe)) {
    Write-Host "AIMP is not installed, skipping delete helper" -ForegroundColor DarkGray
    return
}

$aimpRoot = Split-Path $aimpExe -Parent
$dest = Join-Path $aimpRoot "Plugins\$pluginName"
$pluginDll = Join-Path $dest "$pluginName.dll"
$oldSdkDll = Join-Path $dest "AIMP.SDK.dll"
$oldManagedDll = Join-Path $dest "${pluginName}_plugin.dll"
$hasOldManagedInstall = (Test-Path $oldSdkDll) -or (Test-Path $oldManagedDll)

if ((Test-Path $pluginDll) -and -not $hasOldManagedInstall -and -not $Force) {
    if (Test-Path $oldDest) {
        Remove-Item -Recurse -Force $oldDest
    }
    Write-Host "AIMP delete helper already installed" -ForegroundColor Green
    return
}

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "AIMP delete helper must be installed from an elevated PowerShell" -ForegroundColor Yellow
    return
}

$clang = Get-Command clang-cl.exe -ErrorAction SilentlyContinue
if (-not $clang) {
    $clangPath = Join-Path $env:ProgramFiles "LLVM\bin\clang-cl.exe"
    if (Test-Path $clangPath) {
        $clang = Get-Item $clangPath
    }
}

if (-not $clang) {
    throw "clang-cl.exe not found"
}

$runningAimp = Get-Process AIMP -ErrorAction SilentlyContinue
if ($runningAimp) {
    Write-Host "Close AIMP before installing the delete helper" -ForegroundColor Yellow
    return
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$package = Join-Path $buildDir "aimp-sdk.zip"
$extractDir = Join-Path $buildDir "sdk"
if ((-not (Test-Path $package)) -or $Force) {
    Invoke-WebRequest -Uri "https://aimp.ru/?do=download.file&id=35" -OutFile $package
}

if ((Test-Path $extractDir) -and $Force) {
    Remove-Item -Recurse -Force $extractDir
}

if (-not (Test-Path $extractDir)) {
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $package -DestinationPath $extractDir -Force
}

$includeDir = Join-Path $extractDir "Sources\Cpp"
$buildDll = Join-Path $buildDir "$pluginName.dll"
$args = @(
    "/nologo",
    "/LD",
    "/EHsc",
    "/O2",
    "/DUNICODE",
    "/D_UNICODE",
    "/I",
    $includeDir,
    $source,
    "/Fe:$buildDll",
    "/link",
    "/NOLOGO",
    "/DLL",
    "/MACHINE:X64",
    "user32.lib",
    "kernel32.lib"
)
& $clang.Source @args
if ($LASTEXITCODE -ne 0) {
    throw "AIMP delete helper build failed"
}

Remove-Item $oldSdkDll, $oldManagedDll -Force -ErrorAction SilentlyContinue
Copy-Item $buildDll $pluginDll -Force
if (Test-Path $oldDest) {
    Remove-Item -Recurse -Force $oldDest
}
Write-Host "AIMP delete helper installed" -ForegroundColor Green
