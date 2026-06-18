BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:scriptPath = Join-Path $script:root "scripts" "sync-ai.ps1"

    function Join-Home($Path) { Join-Path $script:tmpHome $Path }
    function Invoke-SyncAiAuth { & $script:scriptPath -SkipMcp -SkipSkills }
    function Invoke-SyncAiConfig { & $script:scriptPath -SkipAuth -SkipMcp }
    function Read-Json($Path) { Get-Content -Path $Path -Raw | ConvertFrom-Json }
    function New-TestCredentials {
        param([string]$ClaudeDir = (Join-Home ".claude"))

        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
        @{
            claudeAiOauth = @{
                accessToken  = "test-access-token-123"
                refreshToken = "test-refresh-token-456"
                expiresAt    = 1700000000
            }
        } | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $ClaudeDir ".credentials.json")
    }
    function Assert-HomePath($Path) { Test-Path (Join-Home $Path) | Should -BeTrue }
    function Assert-HomeLink {
        param([string]$Path, [string]$LinkType)

        $actual = (Get-Item -LiteralPath (Join-Home $Path) -Force).LinkType
        if ($LinkType) { $actual | Should -Be $LinkType } else { $actual | Should -Not -BeNullOrEmpty }
    }
}

Describe "sync-ai.ps1" {
    BeforeAll {
        $script:origProfile = $env:USERPROFILE
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory $script:tmpHome | Out-Null
        $env:USERPROFILE = $script:tmpHome
        Mock Write-Host { }
        Mock wsl { } -ParameterFilter { $true }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
    }

    Context "when credentials file is missing" {
        It "exits with error" {
            $null = pwsh -NoProfile -File $script:scriptPath -SkipMcp -SkipSkills 2>&1
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context "when credentials file has no claudeAiOauth" {
        BeforeEach {
            $claudeDir = Join-Home ".claude"
            New-Item -ItemType Directory $claudeDir | Out-Null
            Set-Content (Join-Path $claudeDir ".credentials.json") '{"someOtherKey": true}'
        }

        It "exits with error" {
            $null = pwsh -NoProfile -File $script:scriptPath -SkipMcp -SkipSkills 2>&1
            $LASTEXITCODE | Should -Be 1
        }
    }

    Context "with valid credentials" {
        BeforeEach {
            $script:claudeDir = Join-Home ".claude"
            $script:opencodeDir = Join-Home ".local\share\opencode"
            New-TestCredentials $script:claudeDir
            New-Item -ItemType Directory $script:opencodeDir -Force | Out-Null
        }

        It "creates Windows opencode auth file with correct tokens" {
            Invoke-SyncAiAuth
            $authPath = Join-Path $script:opencodeDir "auth.json"
            Test-Path $authPath | Should -BeTrue
            $auth = Read-Json $authPath
            $auth.anthropic.type | Should -Be "oauth"
            $auth.anthropic.access | Should -Be "test-access-token-123"
            $auth.anthropic.refresh | Should -Be "test-refresh-token-456"
            $auth.anthropic.expires | Should -Be 1700000000
        }

        It "merges into existing opencode auth file" {
            $authPath = Join-Path $script:opencodeDir "auth.json"
            Set-Content $authPath '{"openai": {"key": "sk-existing"}}'
            Invoke-SyncAiAuth
            $auth = Read-Json $authPath
            $auth.openai.key | Should -Be "sk-existing"
            $auth.anthropic.access | Should -Be "test-access-token-123"
        }

        It "creates Claude settings with no attribution" {
            Invoke-SyncAiAuth
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            Test-Path $settingsPath | Should -BeTrue
            $settings = Read-Json $settingsPath
            $settings.includeCoAuthoredBy | Should -BeFalse
            $settings.includeGitInstructions | Should -BeFalse
            $settings.attribution.commit | Should -Be ""
            $settings.attribution.pr | Should -Be ""
        }

        It "merges settings into existing Claude settings file" {
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            Set-Content $settingsPath '{"model": "opus", "customSetting": true}'
            Invoke-SyncAiAuth
            $settings = Read-Json $settingsPath
            $settings.model | Should -Be "opus"
            $settings.customSetting | Should -BeTrue
            $settings.includeCoAuthoredBy | Should -BeFalse
            $settings.attribution.commit | Should -Be ""
        }

        It "creates settings next to credentials" {
            Remove-Item $script:claudeDir -Recurse -Force
            New-TestCredentials $script:claudeDir
            Invoke-SyncAiAuth
            Test-Path (Join-Path $script:claudeDir "settings.json") | Should -BeTrue
        }

        It "writes auth file with unix line endings" {
            Invoke-SyncAiAuth
            [System.IO.File]::ReadAllText((Join-Path $script:opencodeDir "auth.json")) | Should -Not -Match "`r`n"
        }

        It "writes settings file with unix line endings" {
            Invoke-SyncAiAuth
            [System.IO.File]::ReadAllText((Join-Path $script:claudeDir "settings.json")) | Should -Not -Match "`r`n"
        }

        It "handles missing WSL" {
            Invoke-SyncAiAuth
            Should -Invoke wsl -Exactly 1
        }
    }

    Context "with central Windows agent config" {
        BeforeEach {
            $script:winconfDir = Join-Home "winconf"
            $script:agentsDir = Join-Path $script:winconfDir ".agents"
            $script:promptDir = Join-Path $script:agentsDir "prompts"
            $script:npmDir = Join-Path $script:agentsDir "pi\npm"

            @(
                "skills\powershell-windows",
                "agents\codex",
                "agents\claude",
                "agents\opencode",
                "prompts",
                "pi\npm"
            ) | ForEach-Object { New-Item -ItemType Directory (Join-Path $script:agentsDir $_) -Force | Out-Null }

            Set-Content (Join-Path $script:agentsDir "skills\powershell-windows\SKILL.md") "---`nname: powershell-windows`n---`n"
            Set-Content (Join-Path $script:agentsDir "agents\codex\review.toml") 'name = "review"'
            Set-Content (Join-Path $script:agentsDir "agents\claude\review.md") "---`nname: review`n---`n"
            Set-Content (Join-Path $script:agentsDir "agents\opencode\review.md") "---`ndescription: review`n---`n"
            Set-Content (Join-Path $script:promptDir "gw.md") "---`ndescription: Commit and push`n---`ncommit and push`n"
            Set-Content (Join-Path $script:agentsDir "pi\settings.json") '{"packages":["npm:pi-subagents"]}'
            Set-Content (Join-Path $script:npmDir "package.json") '{"dependencies":{"pi-subagents":"^0.27.0"}}'
        }

        It "links shared agent and prompt directories" {
            Invoke-SyncAiConfig

            @(
                ".agents\skills\powershell-windows\SKILL.md",
                ".claude\skills\powershell-windows\SKILL.md",
                ".config\opencode\skills\powershell-windows\SKILL.md",
                ".copilot\skills\powershell-windows\SKILL.md",
                ".pi\agent\skills\powershell-windows\SKILL.md",
                ".pi\agent\prompts\gw.md",
                ".codex\prompts\gw.md",
                ".codex\commands\gw.md",
                ".claude\commands\gw.md",
                ".config\opencode\commands\gw.md",
                ".opencode\commands\gw.md",
                ".codex\agents\review.toml",
                ".claude\agents\review.md",
                ".config\opencode\agents\review.md",
                ".config\opencode\agent\review.md"
            ) | ForEach-Object { Assert-HomePath $_ }

            @{
                ".agents" = $null
                ".codex\prompts\gw.md" = "HardLink"
                ".codex\commands\gw.md" = "HardLink"
                ".claude\commands" = $null
                ".config\opencode\commands" = $null
                ".codex\agents" = $null
                ".claude\agents" = $null
                ".config\opencode\agents" = $null
            }.GetEnumerator() | ForEach-Object { Assert-HomeLink $_.Key $_.Value }
        }

        It "keeps Codex prompt hard links in sync with winconf prompts" {
            Invoke-SyncAiConfig
            Set-Content (Join-Path $script:promptDir "gw.md") "---`ndescription: updated`n---`nupdated`n"
            Get-Content (Join-Home ".codex\prompts\gw.md") -Raw | Should -Match "updated"
            Get-Content (Join-Home ".codex\commands\gw.md") -Raw | Should -Match "updated"
        }

        It "links Pi settings and npm package from winconf" {
            Invoke-SyncAiConfig
            Get-Content (Join-Home ".pi\agent\settings.json") -Raw | Should -Match 'pi-subagents'
            Get-Content (Join-Home ".pi\agent\npm\package.json") -Raw | Should -Match 'pi-subagents'
            Assert-HomeLink ".pi\agent\settings.json"
            Assert-HomeLink ".pi\agent\npm\package.json"
        }
    }
}
