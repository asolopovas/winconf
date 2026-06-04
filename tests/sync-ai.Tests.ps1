BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:scriptPath = Join-Path $script:root "scripts" "sync-ai.ps1"
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
            $claudeDir = Join-Path $script:tmpHome ".claude"
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
            $script:claudeDir = Join-Path $script:tmpHome ".claude"
            New-Item -ItemType Directory $script:claudeDir | Out-Null
            $creds = @{
                claudeAiOauth = @{
                    accessToken  = "test-access-token-123"
                    refreshToken = "test-refresh-token-456"
                    expiresAt    = 1700000000
                }
            }
            Set-Content (Join-Path $script:claudeDir ".credentials.json") ($creds | ConvertTo-Json -Depth 5)

            $script:opencodeDir = Join-Path $script:tmpHome ".local" "share" "opencode"
            New-Item -ItemType Directory $script:opencodeDir -Force | Out-Null
        }

        It "creates Windows opencode auth file with correct tokens" {
            & $script:scriptPath -SkipMcp -SkipSkills
            $authPath = Join-Path $script:opencodeDir "auth.json"
            Test-Path $authPath | Should -BeTrue
            $auth = Get-Content $authPath -Raw | ConvertFrom-Json
            $auth.anthropic.type | Should -Be "oauth"
            $auth.anthropic.access | Should -Be "test-access-token-123"
            $auth.anthropic.refresh | Should -Be "test-refresh-token-456"
            $auth.anthropic.expires | Should -Be 1700000000
        }

        It "merges into existing opencode auth file" {
            $authPath = Join-Path $script:opencodeDir "auth.json"
            Set-Content $authPath '{"openai": {"key": "sk-existing"}}'
            & $script:scriptPath -SkipMcp -SkipSkills
            $auth = Get-Content $authPath -Raw | ConvertFrom-Json
            $auth.openai.key | Should -Be "sk-existing"
            $auth.anthropic.access | Should -Be "test-access-token-123"
        }

        It "creates Claude settings with no attribution" {
            & $script:scriptPath -SkipMcp -SkipSkills
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            Test-Path $settingsPath | Should -BeTrue
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            $settings.includeCoAuthoredBy | Should -BeFalse
            $settings.includeGitInstructions | Should -BeFalse
            $settings.attribution.commit | Should -Be ""
            $settings.attribution.pr | Should -Be ""
        }

        It "merges settings into existing Claude settings file" {
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            Set-Content $settingsPath '{"model": "opus", "customSetting": true}'
            & $script:scriptPath -SkipMcp -SkipSkills
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            $settings.model | Should -Be "opus"
            $settings.customSetting | Should -BeTrue
            $settings.includeCoAuthoredBy | Should -BeFalse
            $settings.attribution.commit | Should -Be ""
        }

        It "creates .claude directory if it does not exist" {
            Remove-Item $script:claudeDir -Recurse -Force
            $credsDir = Join-Path $script:tmpHome ".claude"
            New-Item -ItemType Directory $credsDir | Out-Null
            $creds = @{
                claudeAiOauth = @{
                    accessToken  = "test-access-token-123"
                    refreshToken = "test-refresh-token-456"
                    expiresAt    = 1700000000
                }
            }
            Set-Content (Join-Path $credsDir ".credentials.json") ($creds | ConvertTo-Json -Depth 5)
            & $script:scriptPath -SkipMcp -SkipSkills
            Test-Path (Join-Path $credsDir "settings.json") | Should -BeTrue
        }

        It "writes auth file with unix line endings" {
            & $script:scriptPath -SkipMcp -SkipSkills
            $authPath = Join-Path $script:opencodeDir "auth.json"
            $raw = [System.IO.File]::ReadAllText($authPath)
            $raw | Should -Not -Match "`r`n"
        }

        It "writes settings file with unix line endings" {
            & $script:scriptPath -SkipMcp -SkipSkills
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            $raw = [System.IO.File]::ReadAllText($settingsPath)
            $raw | Should -Not -Match "`r`n"
        }

        It "handles missing WSL" {
            & $script:scriptPath -SkipMcp -SkipSkills
            Should -Invoke wsl -Exactly 1
        }
    }

    Context "with central Windows agent config" {
        BeforeEach {
            $script:winconfDir = Join-Path $script:tmpHome "winconf"
            $script:agentsDir = Join-Path $script:winconfDir ".agents"
            $script:promptDir = Join-Path $script:agentsDir "prompts"
            $script:npmDir = Join-Path $script:agentsDir "pi\npm"
            New-Item -ItemType Directory (Join-Path $script:agentsDir "skills\powershell-windows") -Force | Out-Null
            New-Item -ItemType Directory (Join-Path $script:agentsDir "agents\codex") -Force | Out-Null
            New-Item -ItemType Directory (Join-Path $script:agentsDir "agents\claude") -Force | Out-Null
            New-Item -ItemType Directory (Join-Path $script:agentsDir "agents\opencode") -Force | Out-Null
            New-Item -ItemType Directory $script:promptDir -Force | Out-Null
            New-Item -ItemType Directory $script:npmDir -Force | Out-Null
            Set-Content (Join-Path $script:agentsDir "skills\powershell-windows\SKILL.md") "---`nname: powershell-windows`n---`n"
            Set-Content (Join-Path $script:agentsDir "agents\codex\review.toml") 'name = "review"'
            Set-Content (Join-Path $script:agentsDir "agents\claude\review.md") "---`nname: review`n---`n"
            Set-Content (Join-Path $script:agentsDir "agents\opencode\review.md") "---`ndescription: review`n---`n"
            Set-Content (Join-Path $script:promptDir "gw.md") "---`ndescription: Commit and push`n---`ncommit and push`n"
            Set-Content (Join-Path $script:agentsDir "pi\settings.json") '{"packages":["npm:pi-subagents"]}'
            Set-Content (Join-Path $script:npmDir "package.json") '{"dependencies":{"pi-subagents":"^0.27.0"}}'
        }

        It "links shared agent and prompt directories" {
            & $script:scriptPath -SkipAuth -SkipMcp
            Test-Path (Join-Path $script:tmpHome ".agents\skills\powershell-windows\SKILL.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".pi\agent\prompts\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".codex\prompts\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".codex\commands\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".claude\commands\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".config\opencode\commands\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".opencode\commands\gw.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".agents\skills\powershell-windows\SKILL.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".codex\agents\review.toml") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".claude\agents\review.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".config\opencode\agents\review.md") | Should -BeTrue
            Test-Path (Join-Path $script:tmpHome ".config\opencode\agent\review.md") | Should -BeTrue
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".agents") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".codex\prompts\gw.md") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".codex\commands\gw.md") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".claude\commands") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".config\opencode\commands") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".codex\agents") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".claude\agents") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".config\opencode\agents") -Force).LinkType | Should -Not -BeNullOrEmpty
        }

        It "links Pi settings and npm package from winconf" {
            & $script:scriptPath -SkipAuth -SkipMcp
            Get-Content (Join-Path $script:tmpHome ".pi\agent\settings.json") -Raw | Should -Match 'pi-subagents'
            Get-Content (Join-Path $script:tmpHome ".pi\agent\npm\package.json") -Raw | Should -Match 'pi-subagents'
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".pi\agent\settings.json") -Force).LinkType | Should -Not -BeNullOrEmpty
            (Get-Item -LiteralPath (Join-Path $script:tmpHome ".pi\agent\npm\package.json") -Force).LinkType | Should -Not -BeNullOrEmpty
        }
    }
}
