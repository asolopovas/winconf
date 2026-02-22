$hostname = $env:COMPUTERNAME
$username = $env:USERNAME
$sshFolder = "$env:USERPROFILE\.ssh"
$sshKeyRSA = "$sshFolder\id_rsa"
$repoPath = "$env:USERPROFILE\winconf"
$githubUser = "asolopovas"
$repoSSH = "git@github.com:$githubUser/winconf.git"

if (!(Test-Path $sshFolder)) { New-Item -ItemType Directory -Path $sshFolder | Out-Null }

if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing GitHub CLI..."
    winget install --id GitHub.cli -e --silent
    $env:Path += ";$env:ProgramFiles\GitHub CLI"
}

if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI not recognized. Restart PowerShell and rerun."; exit 1
}

if (!(Test-Path $sshKeyRSA)) { ssh-keygen -t rsa -b 4096 -C "$username@$hostname" -f $sshKeyRSA -N "" }

gh auth login --web --git-protocol ssh
gh auth setup-git

if (!(Test-Path $repoPath)) { git clone "https://github.com/$githubUser/winconf.git" $repoPath }

Set-Location $repoPath
if ((git remote get-url origin) -match "^https://") { git remote set-url origin $repoSSH }

Write-Host "Setup complete! You can now use SSH for GitHub."
