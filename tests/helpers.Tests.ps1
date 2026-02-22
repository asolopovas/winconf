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

    It "strips only last extension from double extension" {
        Get-RootName "archive.tar.gz" | Should -Be "archive.tar"
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

    It "returns null Then on false without Else" {
        IIf $false "yes" | Should -BeNullOrEmpty
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
    BeforeAll {
        $script:knownHash = "2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824"
    }

    It "matches correct hash" {
        $file = Join-Path $TestDrive "test.bin"
        Set-Content -Path $file -Value "hello" -NoNewline

        $shaFile = Join-Path $TestDrive "test.sha256"
        Set-Content -Path $shaFile -Value "$($script:knownHash)  test.bin" -NoNewline

        Mock Write-Host { }
        Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file | Should -Be "Hash matches!"
    }

    It "detects mismatched hash" {
        $file = Join-Path $TestDrive "test2.bin"
        Set-Content -Path $file -Value "hello" -NoNewline

        $shaFile = Join-Path $TestDrive "test2.sha256"
        $badHash = "0" * 64
        Set-Content -Path $shaFile -Value "$badHash  test2.bin" -NoNewline

        Mock Write-Host { }
        Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file | Should -Be "Hash doesn't match!"
    }

    It "accepts raw hash string instead of file" {
        $file = Join-Path $TestDrive "test3.bin"
        Set-Content -Path $file -Value "hello" -NoNewline

        Mock Write-Host { }
        Test-Sha -ShaOrFilePath $script:knownHash -FileToCheck $file | Should -Be "Hash matches!"
    }
}

Describe "Test-IsSymLink" {
    It "returns true for symlink" {
        $target = Join-Path $TestDrive "real.txt"
        $link = Join-Path $TestDrive "sym.txt"
        Set-Content $target "data"
        New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
        Test-IsSymLink $link | Should -BeTrue
    }

    It "returns false for regular file" {
        $file = Join-Path $TestDrive "normal.txt"
        Set-Content $file "data"
        Test-IsSymLink $file | Should -BeFalse
    }
}
