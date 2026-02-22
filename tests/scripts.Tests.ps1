BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:scripts = Join-Path $script:root "scripts"
}

Describe "inst-ssh.ps1 generate" {
    BeforeAll {
        $script:path = Join-Path $script:scripts "inst-ssh.ps1"
        $script:origProfile = $env:USERPROFILE
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory $script:tmpHome | Out-Null
        $env:USERPROFILE = $script:tmpHome
        Mock Write-Host { }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
    }

    It "creates .ssh dir and calls ssh-keygen" {
        Mock ssh-keygen { $global:LASTEXITCODE = 0 }
        & $script:path -Action generate
        Test-Path "$($script:tmpHome)\.ssh" | Should -BeTrue
        Should -Invoke ssh-keygen -Exactly 2
    }

    It "skips when key exists without -Force" {
        $sshDir = Join-Path $script:tmpHome ".ssh"
        New-Item -ItemType Directory $sshDir | Out-Null
        Set-Content "$sshDir\id_ed25519" "key"
        Mock ssh-keygen { }
        & $script:path -Action generate
        Should -Invoke ssh-keygen -Exactly 0
    }
}

Describe "inst-ssh.ps1 copy-id" {
    BeforeAll {
        $script:path = Join-Path $script:scripts "inst-ssh.ps1"
        $script:origProfile = $env:USERPROFILE
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        $script:sshDir = Join-Path $script:tmpHome ".ssh"
        New-Item -ItemType Directory $script:sshDir -Force | Out-Null
        $env:USERPROFILE = $script:tmpHome
        Mock Write-Host { }
        Mock ssh { $global:LASTEXITCODE = 0 }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
    }

    It "copies ed25519 key to host" {
        Set-Content "$($script:sshDir)\id_ed25519.pub" "ssh-ed25519 AAAA test@host"
        & $script:path -Action copy-id -Target "srv"
        Should -Invoke ssh -Exactly 1
    }

    It "falls back to rsa when ed25519 missing" {
        Set-Content "$($script:sshDir)\id_rsa.pub" "ssh-rsa AAAA test@host"
        & $script:path -Action copy-id -Target "srv"
        Should -Invoke ssh -Exactly 1
    }

    It "does nothing when no key exists" {
        & $script:path -Action copy-id -Target "srv"
        Should -Invoke ssh -Exactly 0
    }
}

Describe "init.ps1 references" {
    BeforeAll {
        $script:content = Get-Content (Join-Path $script:root "init.ps1") -Raw
    }

    It "SOURCE_FILES use current names" {
        $script:content | Should -Match "'cleanup'"
        $script:content | Should -Match "'inst-paths'"
        $script:content | Should -Match "'inst-fonts'"
        $script:content | Should -Match "'inst-pwsh'"
        $script:content | Should -Match "'inst-terminal'"
        $script:content | Should -Match "'inst-ahk'"
        $script:content | Should -Match "'inst-ssh'"
    }

    It "no stale Setup- references" {
        $script:content | Should -Not -Match "Setup-"
    }

    It "SourceFile dispatches inst-ahk with version param" {
        $script:content | Should -Match "inst-ahk"
        $script:content | Should -Match "AUTOHOTKEYVERSION"
    }
}

Describe "all scripts exist" {
    It "<name> exists" -ForEach @(
        @{ name = "cleanup.ps1" }
        @{ name = "inst-ahk.ps1" }
        @{ name = "inst-fonts.ps1" }
        @{ name = "inst-paths.ps1" }
        @{ name = "inst-pwsh.ps1" }
        @{ name = "inst-ssh.ps1" }
        @{ name = "inst-terminal.ps1" }
        @{ name = "wsl-exclusions.ps1" }
        @{ name = "inst-software.ps1" }
        @{ name = "inst-software-choco.ps1" }
        @{ name = "inst-base.ps1" }
    ) {
        Test-Path (Join-Path $script:scripts $name) | Should -BeTrue
    }
}

Describe "no stale references across repo" {
    BeforeAll {
        $script:allScripts = Get-ChildItem (Join-Path $script:scripts "*.ps1") -File
    }

    It "no script references old Setup- names" {
        foreach ($file in $script:allScripts) {
            $c = Get-Content $file.FullName -Raw
            $c | Should -Not -Match 'Setup-(Base|Software|Powershell|Terminal|Autohotkey|NerdFonts|EnvironmentPaths)\.ps1'
        }
    }

    It "no script references deleted files" {
        foreach ($file in $script:allScripts) {
            $c = Get-Content $file.FullName -Raw
            $c | Should -Not -Match 'Bloatware-Removal\.ps1'
            $c | Should -Not -Match 'run-chrome-wsl\.ps1'
        }
    }
}
