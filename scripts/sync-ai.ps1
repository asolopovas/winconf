param(
    [switch]$SkipAuth,
    [switch]$SkipMcp,
    [switch]$SkipSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$claudeCredPath = Join-Path $env:USERPROFILE '.claude\.credentials.json'
$claudeSettingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$winAuthPath = Join-Path $env:USERPROFILE '.local\share\opencode\auth.json'
$opencodeConfigPath = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
$agentsSkillsDir = Join-Path $env:USERPROFILE '.agents\skills'
$claudeSkillsDir = Join-Path $env:USERPROFILE '.claude\skills'
$opencodeSkillsDir = Join-Path $env:USERPROFILE '.config\opencode\skills'
$copilotSkillsDir = Join-Path $env:USERPROFILE '.copilot\skills'
$windowsSkillNames = @(
    'chrome-devtools'
    'docker-expert'
    'docker-patterns'
    'go-patterns'
    'go-testing'
    'golang-patterns'
    'golang-testing'
    'justfile'
    'multi-stage-dockerfile'
    'playwright-cli'
    'powershell-windows'
    'windows-tmp-vhd-maintenance'
)
$mcpServers = [ordered]@{ context7 = @('cmd', '/c', 'npx', '@upstash/context7-mcp') }

function Out-Status([string]$Message) { Write-Information $Message -InformationAction Continue }
function Read-Json($Path) { if (Test-Path -LiteralPath $Path) { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json } else { [pscustomobject]@{} } }
function Out-JsonFile($Path, $Value) {
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = ($Value | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
    if (-not $json.EndsWith("`n")) { $json += "`n" }
    [IO.File]::WriteAllText($Path, $json)
}
function Sync-ClaudeSetting($Path) {
    $settings = Read-Json $Path
    $settings | Add-Member -NotePropertyName includeCoAuthoredBy -NotePropertyValue $false -Force
    $settings | Add-Member -NotePropertyName includeGitInstructions -NotePropertyValue $false -Force
    $settings | Add-Member -NotePropertyName attribution -NotePropertyValue ([pscustomobject]@{ commit = ''; pr = '' }) -Force
    Out-JsonFile $Path $settings
}
function Sync-OpenCodeAuth($Path, $Oauth) {
    $auth = Read-Json $Path
    $auth | Add-Member -NotePropertyName anthropic -NotePropertyValue ([pscustomobject][ordered]@{ type = 'oauth'; access = $Oauth.accessToken; refresh = $Oauth.refreshToken; expires = $Oauth.expiresAt }) -Force
    Out-JsonFile $Path $auth
}
function Get-WslWindowsPath {
    wsl.exe bash -lc 'wslpath -w ~/.local/share/opencode/auth.json; wslpath -w ~/.claude/settings.json' 2>$null |
        Where-Object { $_ -and $_.Trim() } |
        ForEach-Object { $_.Trim() }
}
function Sync-Auth {
    if (-not (Test-Path -LiteralPath $claudeCredPath)) { Out-Status "Claude credentials not found: $claudeCredPath"; return $false }
    $oauth = (Read-Json $claudeCredPath).claudeAiOauth
    if (-not $oauth) { Out-Status 'No claudeAiOauth found in credentials file'; return $false }

    Sync-ClaudeSetting $claudeSettingsPath
    Sync-OpenCodeAuth $winAuthPath $oauth

    $wsl = @(Get-WslWindowsPath)
    if ($wsl.Count -ge 2) {
        if (Test-Path -LiteralPath (Split-Path $wsl[0] -Parent)) { Sync-OpenCodeAuth $wsl[0] $oauth }
        Sync-ClaudeSetting $wsl[1]
    }
    return $true
}
function Sync-McpClaude {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { return }
    $installed = @(claude mcp list 2>$null | Where-Object { $_ -match '^\S.*:' } | ForEach-Object { ($_ -split ':')[0].Trim() })
    foreach ($name in $installed) { if (-not $mcpServers.Contains($name)) { claude mcp remove $name -s user 2>$null | Out-Null } }
    foreach ($name in $mcpServers.Keys) {
        $cmd = $mcpServers[$name]
        claude mcp remove $name -s user 2>$null | Out-Null
        claude mcp add -s user -t stdio $name -- @cmd 2>$null | Out-Null
    }
}
function Sync-McpOpenCode {
    if (-not (Test-Path -LiteralPath $opencodeConfigPath)) { return }
    try { $config = Get-Content -LiteralPath $opencodeConfigPath -Raw | ConvertFrom-Json } catch { return }
    if (-not ($config.PSObject.Properties.Name -contains 'mcp')) { $config | Add-Member -NotePropertyName mcp -NotePropertyValue ([pscustomobject]@{}) -Force }
    foreach ($name in @($config.mcp.PSObject.Properties.Name)) { if (-not $mcpServers.Contains($name)) { $config.mcp.PSObject.Properties.Remove($name) } }
    foreach ($name in $mcpServers.Keys) { $config.mcp | Add-Member -NotePropertyName $name -NotePropertyValue ([pscustomobject]@{ type = 'local'; command = $mcpServers[$name]; enabled = $true }) -Force }
    Out-JsonFile $opencodeConfigPath $config
}
function Sync-Mcp { Sync-McpClaude; Sync-McpOpenCode }
function Get-WslSkillsPath {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $null }
    wsl.exe bash -lc '[ -d ~/dotfiles/.agents/skills ] && wslpath -w ~/dotfiles/.agents/skills' 2>$null |
        Where-Object { $_ -and $_.Trim() } |
        Select-Object -Last 1 |
        ForEach-Object { $_.Trim() }
}
function Sync-Skill {
    $sourceDir = Get-WslSkillsPath
    if (-not $sourceDir -or -not (Test-Path -LiteralPath $sourceDir)) { Out-Status 'WSL ~/dotfiles/.agents/skills not found'; return }
    $skills = @(Get-ChildItem -LiteralPath $sourceDir -Directory | Where-Object { ($windowsSkillNames -contains $_.Name) -and (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md')) })
    if (-not $skills) { Out-Status 'No Windows-relevant WSL skills found'; return }

    $root = Split-Path $agentsSkillsDir -Parent
    $tmp = Join-Path $root "skills.tmp.$PID"
    if (-not (Test-Path -LiteralPath $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null }
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        foreach ($skill in $skills) { Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $tmp $skill.Name) -Recurse -Force }
        $item = Get-Item -LiteralPath $agentsSkillsDir -Force -ErrorAction SilentlyContinue
        if ($item) {
            if ($item.LinkType) { Remove-Item -LiteralPath $agentsSkillsDir -Force }
            else { Remove-Item -LiteralPath $agentsSkillsDir -Recurse -Force }
        }
        Move-Item -LiteralPath $tmp -Destination $agentsSkillsDir
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
    foreach ($target in @($claudeSkillsDir, $opencodeSkillsDir, $copilotSkillsDir)) {
        $item = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if ($item) {
            if ($item.LinkType) { Remove-Item -LiteralPath $target -Force }
            else { Remove-Item -LiteralPath $target -Recurse -Force }
        }
        $parent = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $agentsSkillsDir -Destination $target -Recurse -Force
    }
    Out-Status ("Synced {0} Windows skill(s)" -f $skills.Count)
}

$ok = $true
if (-not $SkipAuth) { $ok = Sync-Auth }
if (-not $SkipMcp) { Sync-Mcp }
if (-not $SkipSkills) { Sync-Skill }
if (-not $ok) { exit 1 }
