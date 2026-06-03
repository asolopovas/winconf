param(
    [switch]$SkipAuth,
    [switch]$SkipMcp,
    [switch]$SkipSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


$claudeCredPath     = Join-Path $env:USERPROFILE ".claude\.credentials.json"
$claudeSettingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
$winAuthPath        = Join-Path $env:USERPROFILE ".local\share\opencode\auth.json"

$claudeSettings = @{
    includeCoAuthoredBy      = $false
    includeGitInstructions   = $false
    attribution              = @{ commit = ""; pr = "" }
}

$mcpServers = [ordered]@{
    context7 = @("cmd", "/c", "npx", "@upstash/context7-mcp")
}

$agentsSkillsDir = Join-Path $env:USERPROFILE ".agents\skills"

$claudeSkillsDir   = Join-Path $env:USERPROFILE ".claude\skills"
$opencodeSkillsDir = Join-Path $env:USERPROFILE ".config\opencode\skills"

$opencodeConfigPath = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"


function Write-JsonFile {
    param([string]$Path, [string]$Json)
    $Json = $Json -replace "`r`n", "`n"
    if (-not $Json.EndsWith("`n")) { $Json += "`n" }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
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


function Sync-Auth {
    Write-Host "--- Auth + Settings ---" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $claudeCredPath)) {
        Write-Host "Claude Code credentials not found at $claudeCredPath" -ForegroundColor Red
        Write-Host "Run 'claude' and authenticate first." -ForegroundColor Yellow
        return $false
    }

    $claude = Get-Content $claudeCredPath -Raw | ConvertFrom-Json
    $oauth = $claude.claudeAiOauth

    if (-not $oauth) {
        Write-Host "No claudeAiOauth found in credentials file." -ForegroundColor Red
        return $false
    }

    Write-Host "Read Claude Code credentials (expires $($oauth.expiresAt))" -ForegroundColor Green

    Write-Host "Syncing Claude settings (Windows)..." -ForegroundColor Cyan
    Sync-ClaudeSettings -Path $claudeSettingsPath
    Write-Host "  $claudeSettingsPath" -ForegroundColor DarkGray

    Write-Host "Updating Windows opencode auth..." -ForegroundColor Cyan
    Update-AuthFile -Path $winAuthPath -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
    Write-Host "  $winAuthPath" -ForegroundColor DarkGray

    Write-Host "Updating WSL (opencode auth + Claude settings)..." -ForegroundColor Cyan
    $wslHome = wsl bash -c 'echo $HOME' 2>$null
    if ($wslHome) {
        $wslHome = ("$wslHome" -replace "`r", "").Trim()
        $release = wsl bash -c 'cat /etc/os-release' 2>$null | Select-String '^ID=(.+)' | Select-Object -First 1
        if (-not $release) {
            Write-Host "  Could not detect WSL distro, skipping WSL sync." -ForegroundColor Yellow
            return $true
        }
        $wslDistro = $release.Matches[0].Groups[1].Value.Trim('"')
        $wslRoot = "\\wsl.localhost\$wslDistro"
        $wslAuthFile = Join-Path $wslRoot "$wslHome/.local/share/opencode/auth.json"
        $wslSettingsFile = Join-Path $wslRoot "$wslHome/.claude/settings.json"

        if (Test-Path -LiteralPath (Split-Path $wslAuthFile -Parent)) {
            Update-AuthFile -Path $wslAuthFile -AccessToken $oauth.accessToken -RefreshToken $oauth.refreshToken -ExpiresAt $oauth.expiresAt
            Write-Host "  $wslAuthFile" -ForegroundColor DarkGray
        } else {
            Write-Host "  WSL opencode directory not found, skipping auth." -ForegroundColor Yellow
        }

        Sync-ClaudeSettings -Path $wslSettingsFile
        Write-Host "  $wslSettingsFile" -ForegroundColor DarkGray
    } else {
        Write-Host "  WSL not available, skipping WSL sync." -ForegroundColor Yellow
    }

    Write-Host "Auth and settings synced." -ForegroundColor Green
    return $true
}


function Sync-McpClaude {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "  claude CLI not found, skipping." -ForegroundColor Yellow
        return
    }

    $installed = @()
    $lines = claude mcp list 2>$null | Where-Object { $_ -match '^\S.*:' }
    foreach ($line in $lines) {
        $name = ($line -split ':')[0].Trim()
        if ($name) { $installed += $name }
    }

    foreach ($name in $installed) {
        if (-not $mcpServers.Contains($name)) {
            claude mcp remove $name -s user 2>$null | Out-Null
            Write-Host "  Removed $name from claude" -ForegroundColor DarkGray
        }
    }

    foreach ($name in $mcpServers.Keys) {
        $cmd = $mcpServers[$name]
        claude mcp remove $name -s user 2>$null | Out-Null
        claude mcp add -s user -t stdio $name -- @cmd 2>$null | Out-Null
        Write-Host "  -> $name added to claude" -ForegroundColor DarkGray
    }
}

function Sync-McpOpenCode {
    param([string]$ConfigPath)

    if (-not (Test-Path -LiteralPath $ConfigPath)) { return }

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

    if (-not ($config.PSObject.Properties.Name -contains 'mcp')) {
        $config | Add-Member -NotePropertyName 'mcp' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    $existingNames = @($config.mcp.PSObject.Properties.Name)
    foreach ($name in $existingNames) {
        if (-not $mcpServers.Contains($name)) {
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


function Get-WslDotfilesSkillsPath {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $null }

    $path = wsl.exe bash -lc 'if [ -d "$HOME/dotfiles/.agents/skills" ]; then wslpath -w "$HOME/dotfiles/.agents/skills"; fi' 2>$null |
        Where-Object { $_ -and $_.Trim() } |
        Select-Object -Last 1
    if (-not $path) { return $null }
    return $path.Trim()
}

function Sync-Skills {
    Write-Host "--- Skills ---" -ForegroundColor Cyan

    $sourceDir = Get-WslDotfilesSkillsPath
    if (-not $sourceDir -or -not (Test-Path -LiteralPath $sourceDir)) {
        Write-Host "  WSL ~/dotfiles/.agents/skills not found, skipping." -ForegroundColor Yellow
        return
    }

    $sourceSkills = @(Get-ChildItem -LiteralPath $sourceDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md") })
    if (-not $sourceSkills -or $sourceSkills.Count -eq 0) {
        Write-Host "  No WSL skills found in $sourceDir" -ForegroundColor Yellow
        return
    }

    $agentsRoot = Split-Path $agentsSkillsDir -Parent
    if (-not (Test-Path -LiteralPath $agentsRoot)) {
        New-Item -ItemType Directory -Path $agentsRoot -Force | Out-Null
    }

    $tempDir = Join-Path $agentsRoot "skills.tmp.$PID"
    if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        foreach ($skill in $sourceSkills) {
            Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $tempDir $skill.Name) -Recurse -Force
        }

        if (Test-Path -LiteralPath $agentsSkillsDir) {
            Remove-Item -LiteralPath $agentsSkillsDir -Recurse -Force
        }
        Move-Item -LiteralPath $tempDir -Destination $agentsSkillsDir
    } finally {
        if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "  Synced $($sourceSkills.Count) WSL skill(s) from $sourceDir" -ForegroundColor Green

    foreach ($targetDir in @($claudeSkillsDir, $opencodeSkillsDir)) {
        $item = Get-Item -LiteralPath $targetDir -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -and (@($item.Target) -contains $agentsSkillsDir)) {
            Write-Host "  -> $targetDir already linked" -ForegroundColor DarkGray
            continue
        }

        if (Test-Path -LiteralPath $targetDir) { Remove-Item -LiteralPath $targetDir -Recurse -Force }
        $parentDir = Split-Path $targetDir -Parent
        if (-not (Test-Path -LiteralPath $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }

        New-Item -ItemType Junction -Path $targetDir -Target $agentsSkillsDir | Out-Null
        Write-Host "  -> junction: $targetDir -> $agentsSkillsDir" -ForegroundColor DarkGray
    }

    Write-Host "Skills synced." -ForegroundColor Green
}


$authOk = $true
if (-not $SkipAuth) {
    if (-not (Sync-Auth)) { $authOk = $false }
}
if (-not $SkipMcp) { Sync-Mcp }
if (-not $SkipSkills) { Sync-Skills }

Write-Host ""
Write-Host "Done. Restart Claude and OpenCode to pick up changes." -ForegroundColor Green

if (-not $authOk) { exit 1 }
