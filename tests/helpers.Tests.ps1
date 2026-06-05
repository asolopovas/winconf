BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    $modulePath = Join-Path $root "powershell\modules\helpers"
    Import-Module $modulePath -Force

    function Set-UserPath($Value) { [Environment]::SetEnvironmentVariable("Path", $Value, "User") }
    function Get-UserPath { [Environment]::GetEnvironmentVariable("Path", "User") }
    function New-HelloFile($Name) {
        $file = Join-Path $TestDrive $Name
        Set-Content -Path $file -Value "hello" -NoNewline
        $file
    }
    function New-ShaFile($Name, $Hash, $FileName) {
        $shaFile = Join-Path $TestDrive $Name
        Set-Content -Path $shaFile -Value "$Hash  $FileName" -NoNewline
        $shaFile
    }
}

Describe "Get-RootName" {
    It "returns <Expected> for <Path>" -TestCases @(
        @{ Path = "setup.exe"; Expected = "setup" },
        @{ Path = "readme"; Expected = "readme" },
        @{ Path = "C:\tools\app.msi"; Expected = "app" },
        @{ Path = "archive.tar.gz"; Expected = "archive.tar" }
    ) {
        param($Path, $Expected)

        Get-RootName $Path | Should -Be $Expected
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
    It "formats <Text> as <Style>" -TestCases @(
        @{ Style = "snakecase"; Text = "Hello World"; Expected = "hello_world" },
        @{ Style = "camelcase"; Text = "HelloWorld"; Expected = "helloWorld" },
        @{ Style = "pascalcase"; Text = "helloWorld"; Expected = "HelloWorld" }
    ) {
        param($Style, $Text, $Expected)

        Format-String $Style $Text | Should -Be $Expected
    }

    It "returns null for unsupported input" -TestCases @(
        @{ Style = "snakecase"; Text = "" },
        @{ Style = "kebabcase"; Text = "test" }
    ) {
        param($Style, $Text)

        Format-String $Style $Text -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}

Describe "Test-EnvPath" {
    BeforeEach { $script:origPath = Get-UserPath }
    AfterEach { Set-UserPath $script:origPath }

    It "returns true for exact match" {
        Set-UserPath "C:\bin;C:\tools"
        Test-EnvPath -Path "C:\bin" | Should -BeTrue
    }

    It "returns false for substring that is not an exact path entry" {
        Set-UserPath "C:\binary;C:\tools"
        Test-EnvPath -Path "C:\bin" | Should -BeFalse
    }

    It "returns false for empty path" {
        Test-EnvPath -Path "" | Should -BeFalse
    }

    It "matches ignoring trailing backslash" {
        Set-UserPath "C:\bin\;C:\tools"
        Test-EnvPath -Path "C:\bin" | Should -BeTrue
    }
}

Describe "SortEnvPaths" {
    BeforeEach { $script:origPath = Get-UserPath }
    AfterEach { Set-UserPath $script:origPath }

    It "sorts paths alphabetically" {
        Set-UserPath "C:\zebra;C:\alpha;C:\middle"
        SortEnvPaths
        Get-UserPath | Should -Be "C:\alpha;C:\middle;C:\zebra"
    }

    It "removes empty entries" {
        Set-UserPath "C:\beta;;C:\alpha;"
        SortEnvPaths
        Get-UserPath | Should -Be "C:\alpha;C:\beta"
    }
}

Describe "Test-Sha" {
    BeforeAll {
        $script:knownHash = "2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824"
    }

    BeforeEach {
        Mock Write-Host { }
    }

    It "matches correct hash" {
        $file = New-HelloFile "test.bin"
        $shaFile = New-ShaFile "test.sha256" $script:knownHash "test.bin"
        Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file | Should -Be "Hash matches!"
    }

    It "detects mismatched hash" {
        $file = New-HelloFile "test2.bin"
        $shaFile = New-ShaFile "test2.sha256" ("0" * 64) "test2.bin"
        Test-Sha -ShaOrFilePath $shaFile -FileToCheck $file | Should -Be "Hash doesn't match!"
    }

    It "accepts raw hash string instead of file" {
        $file = New-HelloFile "test3.bin"
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
