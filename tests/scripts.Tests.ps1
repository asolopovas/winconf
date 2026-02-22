Describe "cleanup.ps1" {
    BeforeAll {
        $script:path = "$env:USERPROFILE\winconf\scripts\cleanup.ps1"
        Mock Get-AppxPackage { }
        Mock Remove-AppxPackage { }
        Mock New-PSDrive { }
        Mock Remove-Item { }
    }

    It "calls Get-AppxPackage for every bloatware entry" {
        Mock Test-Path { $false }
        & $script:path
        Should -Invoke Get-AppxPackage -Exactly 50
    }

    It "removes existing registry keys" {
        Mock Test-Path { $true }
        & $script:path
        Should -Invoke Remove-Item -Exactly 6
    }

    It "skips missing registry keys" {
        Mock Test-Path { $false }
        & $script:path
        Should -Invoke Remove-Item -Exactly 0
    }
}

Describe "inst-ahk.ps1 task cleanup" {
    BeforeAll {
        $script:path = "$env:USERPROFILE\winconf\scripts\inst-ahk.ps1"
        function Test-RegistryValue { param($Path, $Value) $false }
        function Test-ScheduledTask { param($name) $false }
    }

    BeforeEach {
        Mock Get-CimInstance { [PSCustomObject]@{ Name = "PC"; Domain = "WG" } }
        Mock Test-RegistryValue { $false }
        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock New-ItemProperty { }
        Mock New-ScheduledTaskAction { }
        Mock New-ScheduledTaskTrigger { }
        Mock New-ScheduledTaskPrincipal { }
        Mock New-ScheduledTaskSettingsSet { }
        Mock New-ScheduledTask { }
        Mock Register-ScheduledTask { }
        Mock Start-ScheduledTask { }
        Mock Unregister-ScheduledTask { }
        Mock Write-Host { }
    }

    It "skips task creation when task already exists" {
        Mock Test-ScheduledTask { param($name)
            $name -match "AutoHotkey-Init"
        }
        & $script:path -version 2
        Should -Invoke Register-ScheduledTask -Exactly 0
    }

    It "unregisters legacy tasks" {
        Mock Test-ScheduledTask { $true }
        & $script:path -version 2
        Should -Invoke Unregister-ScheduledTask -ParameterFilter {
            $TaskName -match "^Autohotkey-"
        }
    }
}

Describe "inst-ahk.ps1 registry config" {
    BeforeAll {
        $script:path = "$env:USERPROFILE\winconf\scripts\inst-ahk.ps1"
        function Test-RegistryValue { param($Path, $Value) $false }
        function Test-ScheduledTask { param($name) $true }
    }

    BeforeEach {
        Mock Get-CimInstance { [PSCustomObject]@{ Name = "PC"; Domain = "WG" } }
        Mock Test-RegistryValue { $false }
        Mock Test-ScheduledTask { $true }
        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock New-ItemProperty { }
        Mock Unregister-ScheduledTask { }
        Mock Register-ScheduledTask { }
        Mock Start-ScheduledTask { }
        Mock Write-Host { }
    }

    It "sets DisableLockWorkstation" {
        & $script:path -version 2
        Should -Invoke New-ItemProperty -ParameterFilter {
            $Name -eq "DisableLockWorkstation" -and $Value -eq 1
        }
    }

    It "sets NoWinKeys" {
        & $script:path -version 2
        Should -Invoke New-ItemProperty -ParameterFilter {
            $Name -eq "NoWinKeys" -and $Value -eq 1
        }
    }
}

Describe "inst-ssh.ps1 generate" {
    BeforeAll {
        $script:path = "$env:USERPROFILE\winconf\scripts\inst-ssh.ps1"
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
        $script:path = "$env:USERPROFILE\winconf\scripts\inst-ssh.ps1"
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

Describe "wsl-exclusions.ps1" {
    BeforeAll {
        $script:path = "$env:USERPROFILE\winconf\scripts\wsl-exclusions.ps1"
    }

    BeforeEach {
        Mock Add-MpPreference { }
    }

    It "adds folder, extension, and process exclusions" {
        & $script:path
        Should -Invoke Add-MpPreference -ParameterFilter { $ExclusionPath } -Exactly 4
        Should -Invoke Add-MpPreference -ParameterFilter { $ExclusionExtension } -Exactly 2
        Should -Invoke Add-MpPreference -ParameterFilter { $ExclusionProcess } -Exactly 11
    }
}

Describe "init.ps1 references" {
    BeforeAll {
        $script:content = Get-Content "$env:USERPROFILE\winconf\init.ps1" -Raw
    }

    It "SOURCE_FILES use new names" {
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
        Test-Path "$env:USERPROFILE\winconf\scripts\$name" | Should -BeTrue
    }
}

Describe "no stale references across repo" {
    BeforeAll {
        $script:allScripts = Get-ChildItem "$env:USERPROFILE\winconf\scripts\*.ps1" -File
        $script:initContent = Get-Content "$env:USERPROFILE\winconf\init.ps1" -Raw
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
            $c | Should -Not -Match 'Cleanup\.ps1'
            $c | Should -Not -Match 'run-chrome-wsl\.ps1'
        }
    }
}
