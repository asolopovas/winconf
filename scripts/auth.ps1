$ErrorActionPreference = "Stop"

$sshFolder = Join-Path $env:USERPROFILE ".ssh"
$sshKey = Join-Path $sshFolder "id_ed25519"
$repoPath = Join-Path $env:USERPROFILE "winconf"
$githubUser = "asolopovas"
$repoSsh = "git@github.com:$githubUser/winconf.git"

New-Item -ItemType Directory -Path $sshFolder -Force | Out-Null

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing GitHub CLI"
    winget install --id GitHub.cli --exact --silent --accept-source-agreements --accept-package-agreements
    $env:Path = @($env:Path, (Join-Path $env:ProgramFiles "GitHub CLI")) -join ";"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI not found" }
if (-not (Test-Path -LiteralPath $sshKey)) { ssh-keygen -t ed25519 -C "$env:USERNAME@$env:COMPUTERNAME" -f $sshKey -N "" }

gh auth login --web --git-protocol ssh
gh auth setup-git

if (-not (Test-Path -LiteralPath $repoPath)) { git clone "https://github.com/$githubUser/winconf.git" $repoPath }

Set-Location -Path $repoPath
if ((git remote get-url origin) -match '^https://') { git remote set-url origin $repoSsh }

Write-Host "GitHub SSH auth configured" -ForegroundColor Green
