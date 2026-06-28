param(
    [switch]$SkipAuth,
    [switch]$SkipMcp,
    [switch]$SkipSkills
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$winconfDir = Join-Path $env:USERPROFILE 'winconf'
$claudeCredPath = Join-Path $env:USERPROFILE '.claude\.credentials.json'
$claudeSettingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$winAuthPath = Join-Path $env:USERPROFILE '.local\share\opencode\auth.json'
$opencodeConfigPath = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
$homeAgentsDir = Join-Path $env:USERPROFILE '.agents'
$winconfAgentsDir = Join-Path $winconfDir 'agents'
$agentsSkillsDir = Join-Path $winconfAgentsDir 'skills'
$agentsPromptsDir = Join-Path $winconfAgentsDir 'pi\prompts'
$agentsDefinitionsDir = $winconfAgentsDir
$agentsCodexDir = Join-Path $agentsDefinitionsDir 'codex'
$agentsClaudeDir = Join-Path $agentsDefinitionsDir 'claude'
$agentsOpenCodeDir = Join-Path $agentsDefinitionsDir 'opencode'
$agentsPiDir = Join-Path $winconfAgentsDir 'pi'
$agentsPiSettingsPath = Join-Path $agentsPiDir 'settings.json'
$agentsPiNpmPackagePath = Join-Path $agentsPiDir 'npm\package.json'
$piAgentDir = Join-Path $env:USERPROFILE '.pi\agent'
$piPromptsDir = Join-Path $piAgentDir 'prompts'
$piSkillsDir = Join-Path $piAgentDir 'skills'
$piSettingsPath = Join-Path $piAgentDir 'settings.json'
$piNpmPackagePath = Join-Path $piAgentDir 'npm\package.json'
$codexPromptsDir = Join-Path $env:USERPROFILE '.codex\prompts'
$codexCommandsDir = Join-Path $env:USERPROFILE '.codex\commands'
$claudeCommandsDir = Join-Path $env:USERPROFILE '.claude\commands'
$opencodeCommandsDir = Join-Path $env:USERPROFILE '.config\opencode\commands'
$homeOpenCodeCommandsDir = Join-Path $env:USERPROFILE '.opencode\commands'
$codexAgentsDir = Join-Path $env:USERPROFILE '.codex\agents'
$claudeAgentsDir = Join-Path $env:USERPROFILE '.claude\agents'
$opencodeAgentsDir = Join-Path $env:USERPROFILE '.config\opencode\agents'
$opencodeAgentDir = Join-Path $env:USERPROFILE '.config\opencode\agent'
$claudeSkillsDir = Join-Path $env:USERPROFILE '.claude\skills'
$codexSkillsDir = Join-Path $env:USERPROFILE '.codex\skills'
$opencodeSkillsDir = Join-Path $env:USERPROFILE '.config\opencode\skills'
$copilotSkillsDir = Join-Path $env:USERPROFILE '.copilot\skills'
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
function Set-Link {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target,
        [ValidateSet('Junction', 'SymbolicLink', 'HardLink')][string]$ItemType = 'Junction'
    )
    if (-not (Test-Path -LiteralPath $Target)) { return }
    if (-not $PSCmdlet.ShouldProcess($Path, "Link to $Target")) { return }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -and (@($item.Target) -contains $Target)) { return }
    if ($item) { Remove-Item -LiteralPath $Path -Recurse -Force }
    $parent = Split-Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    New-Item -ItemType $ItemType -Path $Path -Target $Target -Force | Out-Null
}
function New-Link($Path, $Target) { @{ Path = $Path; Target = $Target } }
function Set-LinkMap($Links, [string]$ItemType = 'Junction') {
    foreach ($link in $Links) { Set-Link -Path $link.Path -Target $link.Target -ItemType $ItemType }
}
function Set-MarkdownFileLinks($Path, $Target, [ValidateSet('SymbolicLink', 'HardLink')][string]$ItemType = 'SymbolicLink') {
    if (-not (Test-Path -LiteralPath $Target)) { return }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) { Remove-Item -LiteralPath $Path -Force }
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    Get-ChildItem -LiteralPath $Path -Filter '*.md' -File -ErrorAction SilentlyContinue | Where-Object LinkType | Remove-Item -Force
    foreach ($source in Get-ChildItem -LiteralPath $Target -Filter '*.md' -File) {
        Set-Link -Path (Join-Path $Path $source.Name) -Target $source.FullName -ItemType $ItemType
    }
}
function Remove-LinkToTarget($Path, $Target) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -and (@($item.Target) -contains $Target)) { Remove-Item -LiteralPath $Path -Force }
}
function Set-DirectoryLink($Path, $Target) { Set-Link -Path $Path -Target $Target -ItemType Junction }
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
    if (-not ($config.PSObject.Properties.Name -contains 'mcp') -or -not $config.mcp) { $config | Add-Member -NotePropertyName mcp -NotePropertyValue ([pscustomobject]@{}) -Force }
    $mcpNames = @($config.mcp.PSObject.Properties | ForEach-Object Name)
    foreach ($name in $mcpNames) { if (-not $mcpServers.Contains($name)) { $config.mcp.PSObject.Properties.Remove($name) } }
    foreach ($name in $mcpServers.Keys) { $config.mcp | Add-Member -NotePropertyName $name -NotePropertyValue ([pscustomobject]@{ type = 'local'; command = $mcpServers[$name]; enabled = $true }) -Force }
    Out-JsonFile $opencodeConfigPath $config
}
function Sync-Mcp { Sync-McpClaude; Sync-McpOpenCode }
function Sync-AgentConfig {
    Set-LinkMap @(
        (New-Link $homeAgentsDir $winconfAgentsDir)
        (New-Link $claudeSkillsDir $agentsSkillsDir)
        (New-Link $opencodeSkillsDir $agentsSkillsDir)
        (New-Link $copilotSkillsDir $agentsSkillsDir)
        (New-Link $piSkillsDir $agentsSkillsDir)
        (New-Link $piPromptsDir $agentsPromptsDir)
        (New-Link $claudeCommandsDir $agentsPromptsDir)
        (New-Link $opencodeCommandsDir $agentsPromptsDir)
        (New-Link $homeOpenCodeCommandsDir $agentsPromptsDir)
        (New-Link $codexAgentsDir $agentsCodexDir)
        (New-Link $claudeAgentsDir $agentsClaudeDir)
        (New-Link $opencodeAgentsDir $agentsOpenCodeDir)
        (New-Link $opencodeAgentDir $agentsOpenCodeDir)
    )
    Remove-LinkToTarget $codexSkillsDir $agentsSkillsDir
    Set-MarkdownFileLinks $codexPromptsDir $agentsPromptsDir HardLink
    Set-MarkdownFileLinks $codexCommandsDir $agentsPromptsDir HardLink
    Set-LinkMap @(
        (New-Link $piSettingsPath $agentsPiSettingsPath)
        (New-Link $piNpmPackagePath $agentsPiNpmPackagePath)
    ) SymbolicLink
}
function Sync-Skill {
    if (-not (Test-Path -LiteralPath $agentsSkillsDir)) { Out-Status 'No skills dir; run: git submodule update --init agents'; return }
    Set-DirectoryLink $homeAgentsDir $winconfAgentsDir
    Remove-LinkToTarget $codexSkillsDir $agentsSkillsDir
    foreach ($target in @($claudeSkillsDir, $opencodeSkillsDir, $copilotSkillsDir, $piSkillsDir)) {
        Set-DirectoryLink $target $agentsSkillsDir
    }
    $count = @(Get-ChildItem -LiteralPath $agentsSkillsDir -Directory).Count
    Out-Status ("Linked {0} canonical skill(s) to claude/opencode/copilot/pi" -f $count)
}

$ok = $true
if (-not $SkipAuth) { $ok = Sync-Auth }
if (-not $SkipMcp) { Sync-Mcp }
if (-not $SkipSkills) { Sync-Skill; Sync-AgentConfig }
if (-not $ok) { exit 1 }
