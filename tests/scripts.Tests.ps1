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
    }

    BeforeEach {
        $script:tmpHome = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory $script:tmpHome | Out-Null
        $env:USERPROFILE = $script:tmpHome
        $env:Path = $script:origPath
        $script:getCommandCalls = 0
        Mock Write-Host { }
        Mock winget { $global:LASTEXITCODE = 0 }
        Mock bun { $global:LASTEXITCODE = 0 }
    }

    AfterEach {
        $env:USERPROFILE = $script:origProfile
        $env:Path = $script:origPath
    }

    It "installs bun first when missing and installs pi" {
        Mock Get-Command {
            param([string]$Name)

            if ($Name -eq "bun") {
                $script:getCommandCalls++
                if ($script:getCommandCalls -eq 1) { return $null }
                return [pscustomobject]@{ Name = "bun" }
            }

            if ($Name -eq "winget") {
                return [pscustomobject]@{ Name = "winget" }
            }

            return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
        }

        & $script:path

        Should -Invoke winget -Exactly 1 -ParameterFilter { $args -contains "Oven-sh.Bun" }
        Should -Invoke bun -Exactly 1 -ParameterFilter { ($args -join " ") -eq "add -g --ignore-scripts @earendil-works/pi-coding-agent" }
    }

    It "updates pi on every run when bun is already installed" {
        Mock Get-Command {
            param([string]$Name)

            if ($Name -eq "bun") {
                return [pscustomobject]@{ Name = "bun" }
            }

            if ($Name -eq "winget") {
                return [pscustomobject]@{ Name = "winget" }
            }

            return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
        }

        & $script:path
        & $script:path

        Should -Invoke winget -Exactly 0
        Should -Invoke bun -Exactly 2 -ParameterFilter { ($args -join " ") -eq "add -g --ignore-scripts @earendil-works/pi-coding-agent" }
    }
}
