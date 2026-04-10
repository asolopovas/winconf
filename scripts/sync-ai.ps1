<#
.SYNOPSIS
    Sync AI CLI credentials, settings, and MCP servers across Claude and OpenCode.

.DESCRIPTION
    - Reads Claude Code OAuth credentials and propagates to OpenCode (Windows + WSL)
    - Syncs Claude settings (Windows + WSL)
    - Syncs MCP servers to Claude (via `claude mcp`) and OpenCode (via config JSON)

.PARAMETER SkipAuth
    Skip credential/auth sync.

.PARAMETER SkipMcp
    Skip MCP server sync.

.EXAMPLE
    .\sync-ai.ps1
    .\sync-ai.ps1 -SkipAuth
    .\sync-ai.ps1 -SkipMcp
#>
param(
    [switch]$SkipAuth,
    [switch]$SkipMcp
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

# OpenCode config files to sync MCP into
$opencodeConfigDir = Join-Path $env:USERPROFILE ".config\opencode"
$opencodeConfigs   = @(
    (Join-Path $opencodeConfigDir "opencode.json")
)

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

    # WSL sync (auth + settings)
    Write-Host "Updating WSL (opencode auth + Claude settings)..." -ForegroundColor Cyan
    $wslCheck = wsl bash -c "test -d ~/.local/share/opencode && echo exists" 2>$null
    if ($wslCheck -eq "exists") {
        $jsonPayload = "{""type"":""oauth"",""access"":""$($oauth.accessToken)"",""refresh"":""$($oauth.refreshToken)"",""expires"":$($oauth.expiresAt)}"
        $settingsJson = ($claudeSettings | ConvertTo-Json -Depth 10 -Compress) -replace '"', '\"'
        $tmpScript = [System.IO.Path]::GetTempFileName()
        $winPath = $tmpScript -replace '\\', '/'
        $wslTmpScript = wsl wslpath -u "$winPath"
        $scriptContent = @'
#!/bin/bash
authpath=~/.local/share/opencode/auth.json
claudedir=~/.claude
claudesettings="$claudedir/settings.json"
tmpfile=$(mktemp)
read -r jsonpayload
jsonpayload=$(echo "$jsonpayload" | tr -d '\r')
read -r settingspayload
settingspayload=$(echo "$settingspayload" | tr -d '\r')

# Sync opencode auth
if [ -f "$authpath" ]; then
    cp "$authpath" "$tmpfile"
else
    mkdir -p ~/.local/share/opencode
    echo '{}' > "$tmpfile"
fi
jq --argjson entry "$jsonpayload" '.anthropic = $entry' "$tmpfile" > "${tmpfile}.out" && mv "${tmpfile}.out" "$tmpfile"
mv "$tmpfile" "$authpath"
chmod 600 "$authpath"

# Sync Claude settings
mkdir -p "$claudedir"
if [ -f "$claudesettings" ]; then
    tmpset=$(mktemp)
    jq --argjson s "$settingspayload" '. * $s' "$claudesettings" > "$tmpset" && mv "$tmpset" "$claudesettings"
else
    echo "$settingspayload" | jq '.' > "$claudesettings"
fi
chmod 600 "$claudesettings"
'@
        [System.IO.File]::WriteAllText($tmpScript, ($scriptContent -replace "`r`n", "`n"))
        "$jsonPayload`n$settingsJson" | wsl bash $wslTmpScript
        Remove-Item $tmpScript -Force
        Write-Host "  $wslAuthPath" -ForegroundColor DarkGray
        Write-Host "  ~/.claude/settings.json" -ForegroundColor DarkGray
    } else {
        Write-Host "  WSL opencode directory not found, skipping." -ForegroundColor Yellow
    }

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
        # Remove first so we can re-add with current config
        claude mcp remove $name -s user 2>$null | Out-Null
        claude mcp add -s user -t stdio $name -- @cmd 2>$null | Out-Null
        Write-Host "  -> $name added to claude" -ForegroundColor DarkGray
    }
}

function Sync-McpOpenCode {
    param([string]$ConfigPath)

    if (!(Test-Path $ConfigPath)) { return }

    # Parse existing config
    $raw = Get-Content $ConfigPath -Raw
    # Strip JSONC comments for .jsonc files
    if ($ConfigPath -like "*.jsonc") {
        $raw = $raw -replace '//[^"]*$', '' -replace '/\*[\s\S]*?\*/', ''
    }
    try {
        $config = $raw | ConvertFrom-Json
    } catch {
        Write-Host "  Invalid JSON in $ConfigPath, skipping." -ForegroundColor Yellow
        return
    }

    # Ensure mcp key exists
    if (!($config.PSObject.Properties.Name -contains 'mcp')) {
        $config | Add-Member -NotePropertyName 'mcp' -NotePropertyValue ([PSCustomObject]@{}) -Force
    }

    # Remove servers not in $mcpServers
    $existingNames = @($config.mcp.PSObject.Properties.Name)
    foreach ($name in $existingNames) {
        if (!$mcpServers.Contains($name)) {
            $config.mcp.PSObject.Properties.Remove($name)
            Write-Host "  Removed $name from $ConfigPath" -ForegroundColor DarkGray
        }
    }

    # Add/update servers
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
    Write-Host "Syncing MCP servers..." -ForegroundColor Cyan

    Sync-McpClaude

    foreach ($cfg in $opencodeConfigs) {
        if (Test-Path $cfg) {
            Sync-McpOpenCode -ConfigPath $cfg
        }
    }

    Write-Host "MCP servers synced." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if (!$SkipAuth) { Sync-Auth }
if (!$SkipMcp)  { Sync-Mcp }
