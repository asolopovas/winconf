param(
    [string]$Branch = 'main',
    [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$winconfDir = Split-Path $PSScriptRoot -Parent
$agentsDir = Join-Path $winconfDir 'agents'

function Out-Status([string]$Message) { Write-Information $Message -InformationAction Continue }
function Invoke-Git { git @args; if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') failed ($LASTEXITCODE)" } }

# 1. Ensure the submodule is initialized and checked out on a real branch (not detached HEAD).
Invoke-Git -C $winconfDir submodule update --init agents
$current = (git -C $agentsDir rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) { Invoke-Git -C $agentsDir checkout $Branch }

# 2. Commit any local edits made in the canonical skills tree.
$dirty = @(git -C $agentsDir status --porcelain)
if ($dirty) {
    $files = ($dirty | ForEach-Object { ($_ -replace '^.{3}', '').Trim() }) -join ', '
    Invoke-Git -C $agentsDir add -A
    Invoke-Git -C $agentsDir commit -m "sync: update $files"
    Out-Status "Committed local agents changes: $files"
}

# 3. Pull the latest remote, replaying local commits on top.
Invoke-Git -C $agentsDir fetch origin $Branch
Invoke-Git -C $agentsDir pull --rebase origin $Branch

# 4. Push local commits upstream.
if (-not $NoPush) {
    Invoke-Git -C $agentsDir push origin $Branch
    Out-Status "Pushed agents to origin/$Branch"
}

# 5. Record the (possibly new) submodule commit in the parent repo, leaving nothing dirty.
Invoke-Git -C $winconfDir add agents
git -C $winconfDir diff --cached --quiet -- agents
if ($LASTEXITCODE -ne 0) {
    $sha = (git -C $agentsDir rev-parse --short HEAD).Trim()
    Invoke-Git -C $winconfDir commit -m "agents: bump to $sha" -- agents
    Out-Status "Bumped agents pointer to $sha"
}
