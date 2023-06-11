
Start-Transcript $ENV:TEMP\winconf.log -Append
$root = "$env:userprofile\winconf"
$scripts_dir = "$root\powershell\scripts"
$repoUrl = 'git@github.com:asolopovas/winconf.git'

function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try { if (Get-Command $command) { return $true } }
    Catch { return $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

if (!(Test-CommandExists git)) {
    Write-Host "`nGit is not installed. Installing Git..." -ForegroundColor DarkCyan
    winget install --id Git.Git
}

if (!(Test-Path -Path $root)) {
    Write-Host "Cloning repository into $root..." -ForegroundColor DarkCyan
    git clone $repoUrl $root
} else {
    Write-Host "$root already exists. Pulling the latest changes..." -ForegroundColor DarkCyan
    Set-Location -Path $root
    git pull
}

. $root\functions.ps1

$source_files = @(
    'Bloatware-Removal'
    'Set-Environment-Paths'
    'Install-Nerd-Fonts'
    'Sync-Powershell'
    'Sync-Terminal'
    'Sync-Autohotkey'
    'Sync-GPT'
    'Sync-DirectoryOpus'
    # 'Sync-Mirc'
    'Sync-OpenSSH'
)

if ($args[0] -eq '--software') {
    $source_files += 'Install-Software'
}

function SourceFile {
    param($file)
    # write-host in green color
    Write-Host "`n"
    Write-Host "Sourcing $file ..." -ForegroundColor DarkCyan
    . "$scripts_dir\$file.ps1"
}

foreach($file in $source_files) {
    SourceFile $file
}
