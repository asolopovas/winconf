BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    $modulePath = Join-Path $root "powershell\modules\helpers"
    Import-Module $modulePath -Force
}

Describe "Get-RootName" {
    It "strips extension from filename" {
        Get-RootName "setup.exe" | Should -Be "setup"
    }

    It "returns name when no extension" {
        Get-RootName "readme" | Should -Be "readme"
    }

    It "handles path with directory" {
        Get-RootName "C:\tools\app.msi" | Should -Be "app"
    }
}

Describe "IIf" {
    It "returns Then when condition is true" {
        IIf $true "yes" "no" | Should -Be "yes"
    }

    It "returns Else when condition is false" {
        IIf $false "yes" "no" | Should -Be "no"
    }

    It "evaluates ScriptBlock for Then" {
        IIf $true { "computed" } "fallback" | Should -Be "computed"
    }

    It "evaluates ScriptBlock for Else" {
        IIf $false "fallback" { "computed" } | Should -Be "computed"
    }
}

Describe "Format-String" {
    It "converts to snakecase" {
        Format-String "snakecase" "Hello World" | Should -Be "hello_world"
    }

    It "converts to camelcase" {
        Format-String "camelcase" "HelloWorld" | Should -Be "helloWorld"
    }

    It "converts to pascalcase" {
        Format-String "pascalcase" "helloWorld" | Should -Be "HelloWorld"
    }

    It "returns null on empty string" {
        $result = Format-String "snakecase" "" 2>$null
        $result | Should -BeNullOrEmpty
    }

    It "returns null on invalid case" {
        $result = Format-String "kebabcase" "test" 2>$null
        $result | Should -BeNullOrEmpty
    }
}

Describe "Test-EnvPath" {
    BeforeEach {
        $script:origPath = [Environment]::GetEnvironmentVariable("Path", "User")
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable("Path", $script:origPath, "User")
    }

    It "returns true for exact match" {
        [Environment]::SetEnvironmentVariable("Path", "C:\bin;C:\tools", "User")
        Test-EnvPath -Path "C:\bin" | Should -BeTrue
    }

    It "returns false for substring that is not an exact path entry" {
        [Environment]::SetEnvironmentVariable("Path", "C:\binary;C:\tools", "User")
        Test-EnvPath -Path "C:\bin" | Should -BeFalse
    }

    It "returns false for empty path" {
        Test-EnvPath -Path "" | Should -BeFalse
    }

    It "matches ignoring trailing backslash" {
        [Environment]::SetEnvironmentVariable("Path", "C:\bin\;C:\tools", "User")
        Test-EnvPath -Path "C:\bin" | Should -BeTrue
    }
}

Describe "SortEnvPaths" {
    BeforeEach {
        $script:origPath = [Environment]::GetEnvironmentVariable("Path", "User")
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable("Path", $script:origPath, "User")
    }

    It "sorts paths alphabetically" {
        [Environment]::SetEnvironmentVariable("Path", "C:\zebra;C:\alpha;C:\middle", "User")
        SortEnvPaths
        $result = [Environment]::GetEnvironmentVariable("Path", "User")
        $result | Should -Be "C:\alpha;C:\middle;C:\zebra"
    }

    It "removes empty entries" {
        [Environment]::SetEnvironmentVariable("Path", "C:\beta;;C:\alpha;", "User")
        SortEnvPaths
        $result = [Environment]::GetEnvironmentVariable("Path", "User")
        $result | Should -Be "C:\alpha;C:\beta"
    }
}

Describe "Test-Sha" {
    It "matches correct hash" {
        $file = Join-Path $TestDrive "test.bin"
        Set-Content -Path $file -Value "hello" -NoNewline
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $expectedHash = -join ($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("X2") })

        $shaFile = Join-Path $TestDrive "test.sha256"
        Set-Content -Path $shaFile -Value "$expectedHash  test.bin" -NoNewline

        Mock Write-Host { }
        $result = Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file
        $result | Should -Be "Hash matches!"
    }

    It "detects mismatched hash" {
        $file = Join-Path $TestDrive "test2.bin"
        Set-Content -Path $file -Value "hello" -NoNewline

        $shaFile = Join-Path $TestDrive "test2.sha256"
        Set-Content -Path $shaFile -Value "0000000000000000000000000000000000000000000000000000000000000000  test2.bin" -NoNewline

        Mock Write-Host { }
        $result = Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file
        $result | Should -Be "Hash doesn't match!"
    }
}
