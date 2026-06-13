param([switch]$Software)

Start-Transcript -Path "$ENV:TEMP\winconf.log" -Append

$DOTFILES = "$env:userprofile\winconf"
$SCRIPTS_DIR = "$DOTFILES\scripts"
$REPO_URL = 'https://github.com/asolopovas/winconf.git'
$USER = $env:USERNAME
$PINNED_SOFTWARE = @(
    'ScreamingFrog.SEOSpider'
    'Adobe.Acrobat.Reader.64-bit'
    'Nvidia.CUDA'
    'GPSoftware.DirectoryOpus'
)
$ESSENTIAL_SOFTWARE = @(
    'AutoHotkey.AutoHotkey'
    'Git.Git'
    'junegunn.fzf'
    "Microsoft.PowerToys"
    'Microsoft.PowerShell'
    'voidtools.Everything'
    'Starship.Starship'
    "sharkdp.fd"
    "VideoLAN.VLC"
    'WinSCP.WinSCP'
)

$SOURCE_FILES = @(
    'cleanup'
    'paths-doctor'
    'inst-fonts'
    'inst-pwsh'
    'inst-terminal'
    'inst-ahk'
    'wsl-exclusions'
    'inst-modules'
    'inst-scoop'
)

if ($Software) {
    $SOURCE_FILES += 'inst-software'
}
$SOURCE_FILES += 'inst-aimp-delete-helper'

function Write-Status {
    param(
        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]$Message = '',

        [ConsoleColor]$ForegroundColor
    )

    $null = $ForegroundColor
    Write-Information $Message -InformationAction Continue
}

Write-Status "Setting execution policy to RemoteSigned..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
} catch {
    Write-Status "Warning: Could not set execution policy. Continuing..." -ForegroundColor Yellow
}

function Test-Command {
    Param ($command)
    return [bool](Get-Command $command -ErrorAction SilentlyContinue)
}

# Registry PATH is owned by paths-doctor.ps1; here we only need git resolvable
# in the current session (the Git installer writes Machine PATH itself).
function Add-GitToSessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Test-Command git) -and (Test-Path "$env:ProgramFiles\Git\cmd")) {
        $env:Path += ";$env:ProgramFiles\Git\cmd"
    }
}

function SourceFile {
    param ($file)
    Write-Status "`nSourcing $file ..." -ForegroundColor DarkCyan
    if ($file -eq 'inst-modules' -and $isUpdate) {
        & "$SCRIPTS_DIR\$file.ps1" -Update
    } else {
        & "$SCRIPTS_DIR\$file.ps1"
    }
}

$isUpdate = Test-Path -Path $DOTFILES
if ($isUpdate) {
    Write-Status "`n========================================" -ForegroundColor Cyan
    Write-Status "  winconf is already installed." -ForegroundColor Cyan
    Write-Status "  Running in UPDATE mode." -ForegroundColor Cyan
    Write-Status "========================================" -ForegroundColor Cyan
    Write-Status "`nThis will:" -ForegroundColor Yellow
    Write-Status "  - Pull latest winconf changes from git" -ForegroundColor DarkGray
    Write-Status "  - Upgrade essential software via winget" -ForegroundColor DarkGray
    Write-Status "  - Update PowerShell modules" -ForegroundColor DarkGray
    Write-Status "  - Re-run all setup scripts (idempotent)" -ForegroundColor DarkGray
    if ($Software) {
        Write-Status "  - Install/upgrade extended software" -ForegroundColor DarkGray
    }

    $confirm = Read-Host "`nProceed? (Y/n)"
    if ($confirm -and $confirm -notmatch '^[Yy]') {
        Write-Status "Cancelled." -ForegroundColor Yellow
        Stop-Transcript
        exit 0
    }

    Add-GitToSessionPath

    Write-Status "`nPulling latest changes..." -ForegroundColor Green
    Set-Location -Path $DOTFILES
    git pull
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Warning: git pull failed. Continuing with local version..." -ForegroundColor Yellow
    }

    Write-Status "`nChecking for software upgrades..." -ForegroundColor Green
    $upgradeOutput = winget upgrade --accept-source-agreements 2>$null | Out-String
    $toUpgrade = $ESSENTIAL_SOFTWARE | Where-Object { $upgradeOutput -match [regex]::Escape($_) }

    if ($toUpgrade) {
        Write-Status "  Upgrades available: $($toUpgrade -join ', ')" -ForegroundColor Yellow
        $jobs = @()
        foreach ($soft in $toUpgrade) {
            Write-Status "  Upgrading $soft..." -ForegroundColor DarkGray
            $jobs += Start-Job -ScriptBlock {
                winget upgrade --id $using:soft -h --disable-interactivity --accept-source-agreements --accept-package-agreements 2>$null
            }
        }
        $jobs | Wait-Job | ForEach-Object {
            Receive-Job $_ -ErrorAction SilentlyContinue
            Remove-Job $_
        }
    } else {
        Write-Status "  All essential software is up to date" -ForegroundColor DarkGray
    }
} else {
    Write-Status "`n========================================" -ForegroundColor Cyan
    Write-Status "  winconf FRESH INSTALL" -ForegroundColor Cyan
    Write-Status "========================================" -ForegroundColor Cyan
    Write-Status "`nThis will:" -ForegroundColor Yellow
    Write-Status "  - Install essential software via winget" -ForegroundColor DarkGray
    Write-Status "  - Clone winconf repository" -ForegroundColor DarkGray
    Write-Status "  - Install PowerShell modules" -ForegroundColor DarkGray
    Write-Status "  - Run all setup scripts" -ForegroundColor DarkGray

    Write-Status "`nResetting and updating winget sources..." -ForegroundColor Green
    winget source reset --force
    winget source update

    Write-Status "`nInstalling Git first (required for clone)..." -ForegroundColor Green
    winget install --id Git.Git -h --disable-interactivity --accept-source-agreements --accept-package-agreements --force

    $remainingSoftware = $ESSENTIAL_SOFTWARE | Where-Object { $_ -ne 'Git.Git' }
    Write-Status "`nInstalling remaining software in parallel..." -ForegroundColor Green
    $jobs = @()
    foreach ($soft in $remainingSoftware) {
        Write-Status "  Queuing $soft..." -ForegroundColor DarkGray
        $jobs += Start-Job -ScriptBlock {
            winget install --id $using:soft -h --disable-interactivity --accept-source-agreements --accept-package-agreements --force 2>$null
        }
    }
    $jobs | Wait-Job | ForEach-Object {
        Receive-Job $_ -ErrorAction SilentlyContinue
        Remove-Job $_
    }
    Write-Status "  Software installation complete" -ForegroundColor Green

    Add-GitToSessionPath

    if (-not (Test-Command git)) {
        Write-Status "git still not resolvable on PATH after wiring. Aborting." -ForegroundColor Red
        exit 1
    }

    git config --global --add safe.directory "$DOTFILES"
    Write-Status "`nCloning repository into $DOTFILES..." -ForegroundColor Green
    git clone $REPO_URL $DOTFILES
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Failed to clone the repository. Exiting..." -ForegroundColor Red
        exit 1
    }

    Write-Status "Fixing repository ownership for $USER..." -ForegroundColor Yellow
    takeown /F $DOTFILES /R /D Y
    icacls $DOTFILES /grant "${USER}:(OI)(CI)F" /T /C
}

$modulePath = "$env:USERPROFILE\winconf\powershell\modules"
if (Test-Path $modulePath) {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Write-Status "Added $modulePath to PSModulePath." -ForegroundColor Green
}

if (-not (Test-Path -Path $SCRIPTS_DIR)) {
    Write-Status "Scripts directory not found. Cloning might have failed." -ForegroundColor Red
    exit 1
}

Write-Status "`nRunning setup scripts..." -ForegroundColor Green
foreach ($file in $SOURCE_FILES) {
    SourceFile $file
}

Write-Status "`nApplying winget pins..." -ForegroundColor Green
$existingPins = winget pin list 2>$null | Out-String
foreach ($pin in $PINNED_SOFTWARE) {
    if ($existingPins -match [regex]::Escape($pin)) {
        Write-Status "  Already pinned: $pin" -ForegroundColor DarkGray
    } else {
        Write-Status "  Pinning $pin..." -ForegroundColor DarkGray
        winget pin add --id $pin --accept-source-agreements 2>$null
    }
}

Write-Status "`n========================================" -ForegroundColor Green
if ($isUpdate) {
    Write-Status "  Update complete!" -ForegroundColor Green
} else {
    Write-Status "  Installation complete!" -ForegroundColor Green
}
Write-Status "========================================`n" -ForegroundColor Green
Stop-Transcript
