<#
.SYNOPSIS
    Sync AI CLI credentials, settings, MCP servers, and skills across Claude and OpenCode.

.DESCRIPTION
    - Reads Claude Code OAuth credentials and propagates to OpenCode (Windows + WSL)
    - Syncs Claude settings (Windows + WSL)
    - Syncs MCP servers to Claude (via `claude mcp`) and OpenCode (via config JSON)
    - Installs skills from GitHub to ~/.agents/skills and copies to Claude + OpenCode skill dirs

.PARAMETER SkipAuth
    Skip credential/auth sync.

.PARAMETER SkipMcp
    Skip MCP server sync.

.PARAMETER SkipSkills
    Skip skills sync.

.EXAMPLE
    .\sync-ai.ps1
    .\sync-ai.ps1 -SkipAuth
    .\sync-ai.ps1 -SkipSkills
#>
param(
    [switch]$SkipAuth,
    [switch]$SkipMcp,
    [switch]$SkipSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$claudeCredPath     = Join-Path $env:USERPROFILE ".claude\.credentials.json"
$claudeSettingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
$winAuthPath        = Join-Path $env:USERPROFILE ".local\share\opencode\auth.json"
$wslAuthPath        = "~/.local/share/opencode/auth.json"

$claudeSettings = @{
    includeCoAuthoredBy      = $false
    includeGitInstructions   = $false
    attribution              = @{ commit = ""; pr = "" }
}

# MCP servers — matches the bash sync-ai.sh MCP_SERVERS map
$mcpServers = [ordered]@{
    context7 = @("npx", "@upstash/context7-mcp")
}

# Canonical skill location
$agentsSkillsDir = Join-Path $env:USERPROFILE ".agents\skills"

# Skill dirs for each CLI — skills are copied from canonical location
$claudeSkillsDir   = Join-Path $env:USERPROFILE ".claude\skills"
$opencodeSkillsDir = Join-Path $env:USERPROFILE ".config\opencode\skills"

# Skill sources — mirrors SKILL_SOURCES in bash sync-ai.sh
$skillSources = @(
    # Core dev tools
    "https://github.com/github/awesome-copilot/tree/main/skills/chrome-devtools"
    "https://github.com/microsoft/playwright-cli/tree/main/skills/playwright-cli"
    "https://github.com/lackeyjb/playwright-skill/tree/main/skills/playwright-skill"
    "https://github.com/davila7/claude-code-templates/tree/main/cli-tool/components/skills/development/error-resolver"

    # Language & framework patterns
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/laravel-security"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/laravel-patterns"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/laravel-tdd"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/golang-testing"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/golang-patterns"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/docker-patterns"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/database-migrations"
    "https://github.com/affaan-m/everything-claude-code/tree/main/skills/verification-loop"

    # Scripting & web
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/bash-scripting"
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/progressive-web-app"

    # WordPress
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/wordpress"
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/wordpress-plugin-development"
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/wordpress-theme-development"
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/wordpress-woocommerce-development"
    "https://github.com/sickn33/antigravity-awesome-skills/tree/main/skills/wordpress-penetration-testing"
)

# OpenCode config file
$opencodeConfigPath = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-JsonFile {
    param([string]$Path, [string]$Json)
    $Json = $Json -replace "`r`n", "`n"
    if (!$Json.EndsWith("`n")) { $Json += "`n" }
    $dir = Split-Path $Path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Json)
}

function Sync-ClaudeSettings {
    param([string]$Path)

    if (Test-Path $Path) {
        $existing = Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        $existing = [PSCustomObject]@{}
    }

    foreach ($key in $claudeSettings.Keys) {
        $existing | Add-Member -NotePropertyName $key -NotePropertyValue $claudeSettings[$key] -Force
    }

    Write-JsonFile -Path $Path -Json ($existing | ConvertTo-Json -Depth 10)
}

function Update-AuthFile {
    param([string]$Path, [string]$AccessToken, [string]$RefreshToken, [long]$ExpiresAt)

    if (Test-Path $Path) {
        $auth = Get-Content $Path -Raw | ConvertFrom-Json
    } else {
        $auth = [PSCustomObject]@{}
    }

    $entry = [ordered]@{
        type    = "oauth"
        access  = $AccessToken
        refresh = $RefreshToken
        expires = $ExpiresAt
    }
    $auth | Add-Member -NotePropertyName "anthropic" -NotePropertyValue ([PSCustomObject]$entry) -Force
    Write-JsonFile -Path $Path -Json ($auth | ConvertTo-Json -Depth 10)
}

# ---------------------------------------------------------------------------
# Auth + settings sync
# ---------------------------------------------------------------------------

function Sync-Auth {
    Write-Host "--- Auth + Settings ---" -ForegroundColor Cyan

    if (!(Test-Path $claudeCredPath)) {
        Write-Host "Claude Code credentials not found at $claudeCredPath" -ForegroundColor Red
        Write-Host "Run 'claude' and authenticate first." -ForegroundColor Yellow
        return $false
    }

    $claude = Get-Content $claudeCredPath -Raw | ConvertFrom-Json
    $oauth = $claude.claudeAiOauth

    if (!$oauth) {
        Write-Host "No claudeAiOauth found in credentials file." -ForegroundColor Red
        return $false
    }

    Write-Host "Read Claude Code credentials (expires $($oauth.expiresAt))" -ForegroundColor Green

    # Claude settings (Windows)
    Write-Host "Syncing Claude settings (Windows)..." -ForegroundColor Cyan
    Sync-ClaudeSettings -Path $claudeSettingsPath
    Write-Host "  $claudeSettingsPath" -ForegroundColor DarkGray

    # OpenCode auth (Windows)
    Write-Host "Updating Windows opencode auth..." -ForegroundColor Cyan
    Update-AuthFile -Path $winAuthPath -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
    Write-Host "  $winAuthPath" -ForegroundColor DarkGray

    # WSL sync (auth + settings) — access WSL filesystem directly via \\wsl.localhost
    Write-Host "Updating WSL (opencode auth + Claude settings)..." -ForegroundColor Cyan
    $wslHome = wsl bash -c 'echo $HOME' 2>$null
    $wslHome = ($wslHome -replace "`r", "").Trim()
    $wslDistro = (wsl bash -c 'cat /etc/os-release' 2>$null | Select-String '^ID=(.+)').Matches[0].Groups[1].Value
    $wslRoot = "\\wsl.localhost\$wslDistro"
    $wslAuthFile     = Join-Path $wslRoot "$wslHome/.local/share/opencode/auth.json"
    $wslSettingsFile = Join-Path $wslRoot "$wslHome/.claude/settings.json"

    if (Test-Path (Split-Path $wslAuthFile -Parent)) {
        Update-AuthFile -Path $wslAuthFile -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
        Write-Host "  $wslAuthFile" -ForegroundColor DarkGray
    } else {
        Write-Host "  WSL opencode directory not found, skipping auth." -ForegroundColor Yellow
    }

    Sync-ClaudeSettings -Path $wslSettingsFile
    Write-Host "  $wslSettingsFile" -ForegroundColor DarkGray

    Write-Host "Auth and settings synced." -ForegroundColor Green
    return $true
}

# ---------------------------------------------------------------------------
# MCP server sync
# ---------------------------------------------------------------------------

function Sync-McpClaude {
    if (!(Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "  claude CLI not found, skipping." -ForegroundColor Yellow
        return
    }

    # Discover installed servers
    $installed = @()
    $lines = claude mcp list 2>$null | Where-Object { $_ -match '^\S.*:' }
    foreach ($line in $lines) {
        $name = ($line -split ':')[0].Trim()
        if ($name) { $installed += $name }
    }

    # Remove servers not in $mcpServers
    foreach ($name in $installed) {
        if (!$mcpServers.Contains($name)) {
            claude mcp remove $name -s user 2>$null | Out-Null
            Write-Host "  Removed $name from claude" -ForegroundColor DarkGray
        }
    }

    # Add/update servers
    foreach ($name in $mcpServers.Keys) {
        $cmd = $mcpServers[$name]
        claude mcp remove $name -s user 2>$null | Out-Null
        claude mcp add -s user -t stdio $name -- @cmd 2>$null | Out-Null
        Write-Host "  -> $name added to claude" -ForegroundColor DarkGray
    }
}

function Sync-McpOpenCode {
    param([string]$ConfigPath)

    if (!(Test-Path $ConfigPath)) { return }

    $raw = Get-Content $ConfigPath -Raw
    if ($ConfigPath -like "*.jsonc") {
        $raw = $raw -replace '//[^"]*$', '' -replace '/\*[\s\S]*?\*/', ''
    }
    try {
        $config = $raw | ConvertFrom-Json
    } catch {
        Write-Host "  Invalid JSON in $ConfigPath, skipping." -ForegroundColor Yellow
        return
    }

    if (!($config.PSObject.Properties.Name -contains 'mcp')) {
        $config | Add-Member -NotePropertyName 'mcp' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    $existingNames = @($config.mcp.PSObject.Properties.Name)
    foreach ($name in $existingNames) {
        if (!$mcpServers.Contains($name)) {
            $config.mcp.PSObject.Properties.Remove($name)
            Write-Host "  Removed $name from $ConfigPath" -ForegroundColor DarkGray
        }
    }

    foreach ($name in $mcpServers.Keys) {
        $entry = [PSCustomObject]@{
            type    = "local"
            command = $mcpServers[$name]
            enabled = $true
        }
        if ($config.mcp.PSObject.Properties.Name -contains $name) {
            $config.mcp.$name = $entry
        } else {
            $config.mcp | Add-Member -NotePropertyName $name -NotePropertyValue $entry -Force
        }
    }

    Write-JsonFile -Path $ConfigPath -Json ($config | ConvertTo-Json -Depth 10)
    Write-Host "  Synced MCP to $ConfigPath" -ForegroundColor DarkGray
}

function Sync-Mcp {
    Write-Host "--- MCP Servers ---" -ForegroundColor Cyan

    Sync-McpClaude

    if (Test-Path $opencodeConfigPath) {
        Sync-McpOpenCode -ConfigPath $opencodeConfigPath
    }

    Write-Host "MCP servers synced." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Skills sync
# ---------------------------------------------------------------------------

function Get-SkillNameFromUrl {
    param([string]$Url)
    # Extract the last path segment (skill name) from a GitHub tree URL
    $path = $Url -replace '^https://github\.com/[^/]+/[^/]+/tree/[^/]+/', ''
    $path = $path.TrimEnd('/')
    $path = $path -replace '/SKILL\.md$', '' -replace '/skill\.md$', ''
    return $path.Split('/')[-1]
}

function Install-SkillFromGitHub {
    param(
        [string]$Url,
        [string]$DestRoot,
        [string]$Name
    )

    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "  git not found, cannot install $Name" -ForegroundColor Red
        return $false
    }

    # Parse URL: https://github.com/{owner}/{repo}/tree/{ref}/{subpath}
    $path = $Url -replace '^https://github\.com/', ''
    $parts = $path -split '/'
    if ($parts.Count -lt 5) {
        Write-Host "  Invalid skill URL: $Url" -ForegroundColor Red
        return $false
    }

    $owner   = $parts[0]
    $repo    = $parts[1]
    # $parts[2] = "tree"
    $ref     = $parts[3]
    $subpath = ($parts[4..($parts.Count - 1)]) -join '/'

    $tmpDir  = Join-Path ([System.IO.Path]::GetTempPath()) "skill-$Name-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
    $destDir = Join-Path $DestRoot $Name

    try {
        $cloneOutput = git clone --depth 1 --filter=blob:none --sparse --branch $ref `
            "https://github.com/$owner/$repo.git" $tmpDir 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed to clone $owner/$repo : $cloneOutput" -ForegroundColor Red
            return $false
        }

        $sparseOutput = git -C $tmpDir sparse-checkout set $subpath 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Failed sparse-checkout for $subpath : $sparseOutput" -ForegroundColor Red
            return $false
        }

        $srcDir = Join-Path $tmpDir $subpath
        if (!(Test-Path $srcDir)) {
            Write-Host "  Skill path not found in repo: $subpath" -ForegroundColor Red
            return $false
        }

        if (Test-Path $destDir) { Remove-Item -Recurse -Force $destDir }
        Copy-Item -Recurse -Force $srcDir $destDir

        # Normalize skill.md -> SKILL.md
        $skillMdLower = Join-Path $destDir "skill.md"
        $skillMdUpper = Join-Path $destDir "SKILL.md"
        if ((Test-Path $skillMdLower) -and !(Test-Path $skillMdUpper)) {
            Move-Item $skillMdLower $skillMdUpper
        }

        if (!(Test-Path $skillMdUpper)) {
            Write-Host "  Warning: $Name missing SKILL.md" -ForegroundColor Yellow
        }

        return $true
    } finally {
        if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue }
    }
}

function Sync-Skills {
    Write-Host "--- Skills ---" -ForegroundColor Cyan

    # Build desired skill map
    $desired = [ordered]@{}
    foreach ($src in $skillSources) {
        $name = Get-SkillNameFromUrl $src
        if ($name) { $desired[$name] = $src }
    }

    # Install to canonical location (~/.agents/skills)
    if (!(Test-Path $agentsSkillsDir)) {
        New-Item -ItemType Directory -Path $agentsSkillsDir -Force | Out-Null
    }

    # Remove skills not in desired set
    $installedDirs = Get-ChildItem -Path $agentsSkillsDir -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $installedDirs) {
        if ($dir.Name.StartsWith('.')) { continue }
        if (!(Test-Path (Join-Path $dir.FullName "SKILL.md"))) { continue }
        if (!$desired.Contains($dir.Name)) {
            Remove-Item -Recurse -Force $dir.FullName
            Write-Host "  Removed $($dir.Name)" -ForegroundColor DarkGray
        }
    }

    # Install missing skills
    foreach ($name in $desired.Keys) {
        $destDir = Join-Path $agentsSkillsDir $name
        $skillMd = Join-Path $destDir "SKILL.md"
        if ((Test-Path $destDir) -and (Test-Path $skillMd)) {
            Write-Host "  -> $name already installed" -ForegroundColor DarkGray
            continue
        }

        Write-Host "  Installing $name..." -ForegroundColor White
        $ok = Install-SkillFromGitHub -Url $desired[$name] -DestRoot $agentsSkillsDir -Name $name
        if ($ok) {
            Write-Host "  -> $name installed" -ForegroundColor DarkGray
        }
    }

    # Symlink Claude and OpenCode skill dirs -> canonical location
    foreach ($targetDir in @($claudeSkillsDir, $opencodeSkillsDir)) {
        # Already a correct symlink/junction — skip
        $item = Get-Item $targetDir -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -and $item.Target -contains $agentsSkillsDir) {
            Write-Host "  -> $targetDir already linked" -ForegroundColor DarkGray
            continue
        }

        # Remove stale symlink, junction, or directory
        if (Test-Path $targetDir) { Remove-Item -Recurse -Force $targetDir }
        $parentDir = Split-Path $targetDir -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

        New-Item -ItemType Junction -Path $targetDir -Target $agentsSkillsDir | Out-Null
        Write-Host "  -> junction: $targetDir -> $agentsSkillsDir" -ForegroundColor DarkGray
    }

    Write-Host "Skills synced." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if (!$SkipAuth)   { Sync-Auth }
if (!$SkipMcp)    { Sync-Mcp }
if (!$SkipSkills) { Sync-Skills }

Write-Host ""
Write-Host "Done. Restart Claude and OpenCode to pick up changes." -ForegroundColor Green
