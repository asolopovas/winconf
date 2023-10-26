
Start-Transcript $ENV:TEMP\winconf.log -Append
$root = "$env:userprofile\winconf"
$scripts_dir = "$root\scripts"
$repoUrl = 'git@github.com:asolopovas/winconf.git'
$autohotkeyVersion = 2
$essential_software = @(
    'Microsoft.Powershell'
    'voidtools.Everything'
    'junegunn.fzf'
    'Git.Git'
)
$source_files = @(
    'Bloatware-Removal'
    'Cleanup'
    'Setup-EnvironmentPaths'
    'Setup-NerdFonts'
    'Setup-Powershell'
    'Setup-Terminal'
    'Setup-Autohotkey'
    'Setup-DirectoryOpus'
    'Setup-OpenSSH'
)

if ($args[0] -eq '--software') {
    $source_files += 'Install-Software'
}

foreach ($file in $source_files) {
    SourceFile $file
}

$gitPath = "$env:ProgramFiles\Git\cmd"
$env:PATH += ";$gitPath"

function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "stop"

    try { if (Get-Command $command) { return $true } }
    Catch { return $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

function SourceFile {
    param($file)
    Write-Host "`nSourcing $file ..." -ForegroundColor DarkCyan
    if ($file -eq 'Setup-Autohotkey') {
        & "$scripts_dir\$file.ps1" -version $autohotkeyVersion
    }
    else {
        & "$scripts_dir\$file.ps1"
    }
}

foreach ($software in $essential_software) {
    if (!(Test-CommandExists $software)) {
        Write-Host "`nInstalling $software..." -ForegroundColor DarkGray
        winget install --id $software
    }
}


if (!(Test-Path -Path $root)) {
    Write-Host "Cloning repository into $root..." -ForegroundColor DarkGray
    git clone $repoUrl $root
}
else {
    Write-Host "$root already exists. Pulling the latest changes..." -ForegroundColor DarkGray
    Set-Location -Path $root
    git pull
}

