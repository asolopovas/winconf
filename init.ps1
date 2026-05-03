param([switch]$Software)

Start-Transcript -Path "$ENV:TEMP\winconf.log" -Append

$DOTFILES = "$env:userprofile\winconf"
$SCRIPTS_DIR = "$DOTFILES\scripts"
$REPO_URL = 'https://github.com/asolopovas/winconf.git'
$AUTOHOTKEYVERSION = 2
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
    'inst-paths'
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

Write-Host "Setting execution policy to RemoteSigned..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
} catch {
    Write-Host "Warning: Could not set execution policy. Continuing..." -ForegroundColor Yellow
}

function Test-CommandExists {
    Param ($command)
    return [bool](Get-Command $command -ErrorAction SilentlyContinue)
}

function Wire-GitIntoUserPath {
    Write-Host "Wiring Git into User PATH..." -ForegroundColor Yellow
    $gitCmd = "$env:ProgramFiles\Git\cmd"
    $gitUsrBin = "$env:ProgramFiles\Git\usr\bin"
    if (-not (Test-Path $gitCmd)) {
        Write-Host "  Git not found at $gitCmd, skipping" -ForegroundColor DarkYellow
        return
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $rawParts = @()
    if ($userPath) { $rawParts = $userPath -split ';' | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') } }
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $userParts = foreach ($p in $rawParts) { if ($seen.Add($p)) { $p } }
    $removed = $rawParts.Count - $userParts.Count
    $added = @()
    foreach ($p in @($gitCmd, $gitUsrBin)) {
        $t = $p.TrimEnd('\')
        if ($seen.Add($t)) {
            $userParts = @($userParts) + $t
            $added += $t
        }
    }
    foreach ($p in $added) { Write-Host "  + $p" -ForegroundColor Green }
    if ($removed -gt 0) { Write-Host "  Removed $removed duplicate User PATH entries" -ForegroundColor DarkYellow }
    if ($added.Count -or $removed -gt 0) {
        [Environment]::SetEnvironmentVariable('Path', ($userParts -join ';'), 'User')
    } else {
        Write-Host "  Already configured" -ForegroundColor DarkGray
    }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
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

    Wire-GitIntoUserPath

    Write-Host "`nPulling latest changes..." -ForegroundColor Green
    Set-Location -Path $DOTFILES
    git pull
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: git pull failed. Continuing with local version..." -ForegroundColor Yellow
    }

    Write-Host "`nChecking for software upgrades..." -ForegroundColor Green
    $upgradeOutput = winget upgrade --accept-source-agreements 2>$null | Out-String
    $toUpgrade = $ESSENTIAL_SOFTWARE | Where-Object { $upgradeOutput -match [regex]::Escape($_) }

    if ($toUpgrade) {
        Write-Host "  Upgrades available: $($toUpgrade -join ', ')" -ForegroundColor Yellow
        $jobs = @()
        foreach ($soft in $toUpgrade) {
            Write-Host "  Upgrading $soft..." -ForegroundColor DarkGray
            $jobs += Start-Job -ScriptBlock {
                param($id)
                winget upgrade --id $id -h --disable-interactivity --accept-source-agreements --accept-package-agreements 2>$null
            } -ArgumentList $soft
        }
        $jobs | Wait-Job | ForEach-Object {
            Receive-Job $_ -ErrorAction SilentlyContinue
            Remove-Job $_
        }
    } else {
        Write-Host "  All essential software is up to date" -ForegroundColor DarkGray
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

    Write-Host "`nInstalling Git first (required for clone)..." -ForegroundColor Green
    winget install --id Git.Git -h --disable-interactivity --accept-source-agreements --accept-package-agreements --force

    $remainingSoftware = $ESSENTIAL_SOFTWARE | Where-Object { $_ -ne 'Git.Git' }
    Write-Host "`nInstalling remaining software in parallel..." -ForegroundColor Green
    $jobs = @()
    foreach ($soft in $remainingSoftware) {
        Write-Host "  Queuing $soft..." -ForegroundColor DarkGray
        $jobs += Start-Job -ScriptBlock {
            param($id)
            winget install --id $id -h --disable-interactivity --accept-source-agreements --accept-package-agreements --force 2>$null
        } -ArgumentList $soft
    }
    $jobs | Wait-Job | ForEach-Object {
        Receive-Job $_ -ErrorAction SilentlyContinue
        Remove-Job $_
    }
    Write-Host "  Software installation complete" -ForegroundColor Green

    Wire-GitIntoUserPath

    if (-not (Test-CommandExists git)) {
        Write-Host "git still not resolvable on PATH after wiring. Aborting." -ForegroundColor Red
        exit 1
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

Write-Host "`nApplying winget pins..." -ForegroundColor Green
$existingPins = winget pin list 2>$null | Out-String
foreach ($pin in $PINNED_SOFTWARE) {
    if ($existingPins -match [regex]::Escape($pin)) {
        Write-Host "  Already pinned: $pin" -ForegroundColor DarkGray
    } else {
        Write-Host "  Pinning $pin..." -ForegroundColor DarkGray
        winget pin add --id $pin --accept-source-agreements 2>$null
    }
}

Write-Host "`n========================================" -ForegroundColor Green
if ($isUpdate) {
    Write-Host "  Update complete!" -ForegroundColor Green
} else {
    Write-Host "  Installation complete!" -ForegroundColor Green
}
Write-Host "========================================`n" -ForegroundColor Green
Stop-Transcript
