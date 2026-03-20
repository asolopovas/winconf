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
            $out = pwsh -NoProfile -File $script:scriptPath 2>&1
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
            $out = pwsh -NoProfile -File $script:scriptPath 2>&1
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
            & $script:scriptPath
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
            & $script:scriptPath
            $auth = Get-Content $authPath -Raw | ConvertFrom-Json
            $auth.openai.key | Should -Be "sk-existing"
            $auth.anthropic.access | Should -Be "test-access-token-123"
        }

        It "creates Claude settings with no attribution" {
            & $script:scriptPath
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
            & $script:scriptPath
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
            & $script:scriptPath
            Test-Path (Join-Path $credsDir "settings.json") | Should -BeTrue
        }

        It "writes auth file with unix line endings" {
            & $script:scriptPath
            $authPath = Join-Path $script:opencodeDir "auth.json"
            $raw = [System.IO.File]::ReadAllText($authPath)
            $raw | Should -Not -Match "`r`n"
        }

        It "writes settings file with unix line endings" {
            & $script:scriptPath
            $settingsPath = Join-Path $script:claudeDir "settings.json"
            $raw = [System.IO.File]::ReadAllText($settingsPath)
            $raw | Should -Not -Match "`r`n"
        }

        It "skips WSL when opencode directory not found" {
            Mock wsl { return $null } -ParameterFilter { $args -match "test -d" }
            & $script:scriptPath
            Should -Invoke wsl -Exactly 1
        }
    }
}
