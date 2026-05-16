BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:completionPath = Join-Path $script:root "powershell\completions\just.ps1"
    . $script:completionPath
}

Describe "just completion" {
    BeforeEach {
        $global:__justCompletionCache = @{}
    }

    It "finds justfile in current or parent directory" {
        $justfile = Join-Path $TestDrive "justfile"
        Set-Content -Path $justfile -Value "build:"
        $child = Join-Path $TestDrive "child"
        New-Item -ItemType Directory -Path $child | Out-Null

        Find-JustCompletionFile -Path $child | Should -Be $justfile
    }

    It "parses recipes and aliases" {
        $justfile = Join-Path $TestDrive "justfile"
        Set-Content -Path $justfile -Value @(
            "set shell := ['pwsh']",
            "FOO := 'http://example.test'",
            "alias b := build",
            "build target='dev':",
            "@deploy:",
            "test-all +args:",
            "_hidden:",
            "    echo http://example.test",
            "# ignored:"
        )

        $names = @(Get-JustCompletionNames -JustfilePath $justfile)

        $names | Should -Contain "b"
        $names | Should -Contain "build"
        $names | Should -Contain "deploy"
        $names | Should -Contain "test-all"
        $names | Should -Contain "_hidden"
        $names | Should -Not -Contain "set"
        $names | Should -Not -Contain "FOO"
        $names | Should -Not -Contain "echo"
        $names | Should -Not -Contain "ignored"
    }

    It "refreshes cached recipes when justfile changes" {
        $justfile = Join-Path $TestDrive "justfile"
        Set-Content -Path $justfile -Value "build:"
        @(Get-JustCompletionNames -JustfilePath $justfile) | Should -Contain "build"
        Start-Sleep -Milliseconds 20
        Set-Content -Path $justfile -Value "test:"

        $names = @(Get-JustCompletionNames -JustfilePath $justfile)

        $names | Should -Contain "test"
        $names | Should -Not -Contain "build"
    }

    It "keeps simple names unquoted" {
        Get-JustCompletionText -Name "build-all" | Should -Be "build-all"
    }
}
