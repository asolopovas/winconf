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
    'wez.wezterm'
    'WinSCP.WinSCP'
)

$SOURCE_FILES = @(
    'Bloatware-Removal'
    'Cleanup'
    'Setup-EnvironmentPaths'
    'Setup-NerdFonts'
    'Setup-Powershell'
    'Setup-Terminal'
    'Setup-Autohotkey'
    'Setup-Pageant'
    'Setup-Wezterm'
)

if ($Software) {
    $SOURCE_FILES += 'Setup-Software'
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
    if ($file -eq 'Setup-Autohotkey') {
        & "$SCRIPTS_DIR\$file.ps1" -version $AUTOHOTKEYVERSION
    } else {
        & "$SCRIPTS_DIR\$file.ps1"
    }
}

Write-Host "Resetting and updating winget sources..." -ForegroundColor Green
winget source reset --force
winget source update
Write-Host "Winget sources updated." -ForegroundColor Green

foreach ($soft in $ESSENTIAL_SOFTWARE) {
    Write-Host "Installing $soft... " -ForegroundColor DarkGray
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
        Write-Host "Git still not found. Please install Git manually." -ForegroundColor Red
        exit 1
    }
}

git config --global --add safe.directory "$DOTFILES"
if (!(Test-Path -Path $DOTFILES)) {
    Write-Host "Cloning repository into $DOTFILES..." -ForegroundColor DarkGray
    git clone $REPO_URL $DOTFILES
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to clone the repository. Exiting..." -ForegroundColor Red
        exit 1
    }

    Write-Host "Fixing repository ownership for $USER..." -ForegroundColor Yellow
    takeown /F $DOTFILES /R /D Y
    icacls $DOTFILES /grant "${USER}:(OI)(CI)F" /T /C
} else {
    Write-Host "$DOTFILES already exists. Pulling the latest changes..." -ForegroundColor DarkGray
    Set-Location -Path $DOTFILES
    git pull
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

foreach ($file in $SOURCE_FILES) {
    SourceFile $file
}

Write-Host "Initialization complete!" -ForegroundColor Green
Stop-Transcript
