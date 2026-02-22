param([switch]$Software)

Start-Transcript -Path "$ENV:TEMP\winconf.log" -Append

$DOTFILES = "$env:userprofile\winconf"
$SCRIPTS_DIR = "$DOTFILES\scripts"
$REPO_URL = 'https://github.com/asolopovas/winconf.git'
$AUTOHOTKEYVERSION = 2
$USER = $env:USERNAME
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
    'inst-paths'
    'inst-fonts'
    'inst-pwsh'
    'inst-terminal'
    'inst-ahk'
    'inst-ssh'
    'wsl-exclusions'
    'inst-modules'
)

if ($Software) {
    $SOURCE_FILES += 'inst-software'
}

Write-Host "Setting execution policy to RemoteSigned..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
} catch {
    Write-Host "Warning: Could not set execution policy. Continuing..." -ForegroundColor Yellow
}

function Test-CommandExists {
    Param ($command)
    try { return [bool](Get-Command $command -ErrorAction Stop) }
    Catch { return $false }
}

function SourceFile {
    param ($file)
    Write-Host "`nSourcing $file ..." -ForegroundColor DarkCyan
    if ($file -eq 'inst-ahk') {
        & "$SCRIPTS_DIR\$file.ps1" -version $AUTOHOTKEYVERSION
    } elseif ($file -eq 'inst-modules' -and $isUpdate) {
        & "$SCRIPTS_DIR\$file.ps1" -Update
    } else {
        & "$SCRIPTS_DIR\$file.ps1"
    }
}

$isUpdate = Test-Path -Path $DOTFILES
if ($isUpdate) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  winconf is already installed." -ForegroundColor Cyan
    Write-Host "  Running in UPDATE mode." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`nThis will:" -ForegroundColor Yellow
    Write-Host "  - Pull latest winconf changes from git" -ForegroundColor DarkGray
    Write-Host "  - Upgrade essential software via winget" -ForegroundColor DarkGray
    Write-Host "  - Update PowerShell modules" -ForegroundColor DarkGray
    Write-Host "  - Re-run all setup scripts (idempotent)" -ForegroundColor DarkGray
    if ($Software) {
        Write-Host "  - Install/upgrade extended software" -ForegroundColor DarkGray
    }

    $confirm = Read-Host "`nProceed? (Y/n)"
    if ($confirm -and $confirm -notmatch '^[Yy]') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Stop-Transcript
        exit 0
    }

    Write-Host "`nPulling latest changes..." -ForegroundColor Green
    Set-Location -Path $DOTFILES
    git pull
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: git pull failed. Continuing with local version..." -ForegroundColor Yellow
    }

    Write-Host "`nUpgrading essential software..." -ForegroundColor Green
    foreach ($soft in $ESSENTIAL_SOFTWARE) {
        Write-Host "  Upgrading $soft... " -ForegroundColor DarkGray
        winget upgrade --id $soft -h --disable-interactivity --accept-source-agreements --accept-package-agreements 2>$null
    }
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  winconf FRESH INSTALL" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "`nThis will:" -ForegroundColor Yellow
    Write-Host "  - Install essential software via winget" -ForegroundColor DarkGray
    Write-Host "  - Clone winconf repository" -ForegroundColor DarkGray
    Write-Host "  - Install PowerShell modules" -ForegroundColor DarkGray
    Write-Host "  - Run all setup scripts" -ForegroundColor DarkGray

    Write-Host "`nResetting and updating winget sources..." -ForegroundColor Green
    winget source reset --force
    winget source update

    Write-Host "`nInstalling essential software..." -ForegroundColor Green
    foreach ($soft in $ESSENTIAL_SOFTWARE) {
        Write-Host "  Installing $soft... " -ForegroundColor DarkGray
        winget install --id $soft -h --disable-interactivity --accept-source-agreements --accept-package-agreements --force
    }

    if (!(Test-CommandExists git)) {
        Write-Host "Adding git to Path" -ForegroundColor Yellow
        $gitPath = "$env:ProgramFiles\Git\cmd"
        if (Test-Path $gitPath) {
            [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$gitPath", [System.EnvironmentVariableTarget]::Machine)
            $env:PATH += ";$gitPath"
            Write-Host "Git added to PATH." -ForegroundColor Green
        } else {
            Write-Host "Git not found. Please install Git manually." -ForegroundColor Red
            exit 1
        }
    }

    git config --global --add safe.directory "$DOTFILES"
    Write-Host "`nCloning repository into $DOTFILES..." -ForegroundColor Green
    git clone $REPO_URL $DOTFILES
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone the repository. Exiting..." -ForegroundColor Red
        exit 1
    }

    Write-Host "Fixing repository ownership for $USER..." -ForegroundColor Yellow
    takeown /F $DOTFILES /R /D Y
    icacls $DOTFILES /grant "${USER}:(OI)(CI)F" /T /C
}

$modulePath = "$env:USERPROFILE\winconf\powershell\modules"
if (Test-Path $modulePath) {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Write-Host "Added $modulePath to PSModulePath." -ForegroundColor Green
}

if (!(Test-Path -Path $SCRIPTS_DIR)) {
    Write-Host "Scripts directory not found. Cloning might have failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nRunning setup scripts..." -ForegroundColor Green
foreach ($file in $SOURCE_FILES) {
    SourceFile $file
}

Write-Host "`n========================================" -ForegroundColor Green
if ($isUpdate) {
    Write-Host "  Update complete!" -ForegroundColor Green
} else {
    Write-Host "  Installation complete!" -ForegroundColor Green
}
Write-Host "========================================`n" -ForegroundColor Green
Stop-Transcript
