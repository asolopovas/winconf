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

    It "regenerates when -Force is set" {
        $sshDir = Join-Path $script:tmpHome ".ssh"
        New-Item -ItemType Directory $sshDir | Out-Null
        Set-Content "$sshDir\id_ed25519" "key"
        Mock ssh-keygen { $global:LASTEXITCODE = 0 }
        & $script:path -Action generate -Force
        Should -Invoke ssh-keygen -Exactly 2
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

Describe "inst-pi.ps1" {
    BeforeAll {
        $script:path = Join-Path $script:scripts "inst-pi.ps1"
        $script:origProfile = $env:USERPROFILE
        $script:origPath = $env:Path
        $script:origLocalAppData = $env:LOCALAPPDATA
        $script:origPnpmHome = $env:PNPM_HOME
        $script:origPnpmTestLog = $env:PNPM_TEST_LOG
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory $script:tmpHome | Out-Null
        $env:USERPROFILE = $script:tmpHome
        $env:LOCALAPPDATA = $script:tmpHome
        $env:PNPM_HOME = $null
        $env:PNPM_TEST_LOG = Join-Path $script:tmpHome "pnpm.log"
        $env:Path = $script:origPath
        $script:getCommandCalls = 0
        $pnpmBin = Join-Path $script:tmpHome "pnpm\bin"
        New-Item -ItemType Directory $pnpmBin -Force | Out-Null
        Set-Content -Path (Join-Path $pnpmBin "pnpm.ps1") -Value '$args -join " " | Add-Content -LiteralPath $env:PNPM_TEST_LOG; $global:LASTEXITCODE = 0'
        Mock Write-Host { }
        Mock winget { $global:LASTEXITCODE = 0 }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
        $env:LOCALAPPDATA = $script:origLocalAppData
        $env:PNPM_HOME = $script:origPnpmHome
        $env:PNPM_TEST_LOG = $script:origPnpmTestLog
        $env:Path = $script:origPath
    }

    It "installs pnpm first when missing and installs pi" {
        Mock Get-Command {
            param([string]$Name)

            if ($Name -eq "pnpm") {
                $script:getCommandCalls++
                if ($script:getCommandCalls -eq 1) { return $null }
                return [pscustomobject]@{ Name = "pnpm" }
            }

            if ($Name -eq "winget") {
                return [pscustomobject]@{ Name = "winget" }
            }

            return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
        }

        & $script:path

        Should -Invoke winget -Exactly 1 -ParameterFilter { $args -contains "pnpm.pnpm" }
        Get-Content -Path $env:PNPM_TEST_LOG | Should -Be @("add -g --ignore-scripts @earendil-works/pi-coding-agent")
        ($env:Path -split ";")[0] | Should -Be (Join-Path $script:tmpHome "pnpm\bin")
    }

    It "updates pi on every run when pnpm is already installed" {
        Mock Get-Command {
            param([string]$Name)

            if ($Name -eq "pnpm") {
                return [pscustomobject]@{ Name = "pnpm" }
            }

            if ($Name -eq "winget") {
                return [pscustomobject]@{ Name = "winget" }
            }

            return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
        }

        & $script:path
        & $script:path

        Should -Invoke winget -Exactly 0
        Get-Content -Path $env:PNPM_TEST_LOG | Should -Be @("add -g --ignore-scripts @earendil-works/pi-coding-agent", "add -g --ignore-scripts @earendil-works/pi-coding-agent")
    }
}

Describe "inst-bun.ps1" {
    BeforeAll {
        $script:path = Join-Path $script:scripts "inst-bun.ps1"
        $script:origProfile = $env:USERPROFILE
        $script:origUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $script:origProcessPath = $env:Path
        $script:linkDir = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        $script:bunBin = Join-Path $script:tmpHome ".bun\bin"
        New-Item -ItemType Directory (Join-Path $script:tmpHome ".bun") | Out-Null
        $env:USERPROFILE = $script:tmpHome
        [Environment]::SetEnvironmentVariable("Path", $script:bunBin, "User")
        Mock winget { $global:LASTEXITCODE = 0 }
        Mock Get-Command {
            param([string]$Name)

            if ($Name -eq "winget") {
                return [pscustomobject]@{ Name = "winget" }
            }

            return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
        }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
        [Environment]::SetEnvironmentVariable("Path", $script:origUserPath, "User")
        $env:Path = $script:origProcessPath
    }

    It "removes bun with <Flag>" -TestCases @(@{ Flag = "--uninstall" }, @{ Flag = "--remove" }, @{ Flag = "-rm" }) {
        param($Flag)

        & $script:path $Flag

        Should -Invoke winget -Exactly 1 -ParameterFilter { ($args -join " ") -eq "list --id Oven-sh.Bun --exact" }
        Should -Invoke winget -Exactly 1 -ParameterFilter { ($args -join " ") -eq "uninstall --id Oven-sh.Bun --exact --silent --accept-source-agreements" }
        Test-Path (Join-Path $script:tmpHome ".bun") | Should -BeFalse
        ([Environment]::GetEnvironmentVariable("Path", "User") -split ";") -contains $script:bunBin | Should -BeFalse
        ($env:Path -split ";") -contains $script:bunBin | Should -BeFalse
    }

    It "installs winget bun when requested" {
        Mock winget {
            if (($args -join " ") -eq "list --id Oven-sh.Bun --exact") {
                $global:LASTEXITCODE = 1
            } else {
                $global:LASTEXITCODE = 0
            }
        }

        & $script:path

        Should -Invoke winget -Exactly 1 -ParameterFilter { ($args -join " ") -eq "list --id Oven-sh.Bun --exact" }
        Should -Invoke winget -Exactly 1 -ParameterFilter { ($args -join " ") -eq "install --id Oven-sh.Bun --exact --silent --accept-source-agreements --accept-package-agreements" }
        Test-Path (Join-Path $script:tmpHome ".bun") | Should -BeTrue
        ([Environment]::GetEnvironmentVariable("Path", "User") -split ";") -contains $script:linkDir | Should -BeTrue
        ($env:Path -split ";") -contains $script:linkDir | Should -BeTrue
        ([Environment]::GetEnvironmentVariable("Path", "User") -split ";") -contains $script:bunBin | Should -BeFalse
    }
}
