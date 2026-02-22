BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    . "$root\functions.ps1"
}

Describe "Test-CommandExists" {
    It "true for built-in command" {
        Test-CommandExists "Get-Process" | Should -BeTrue
    }
    It "false for fake command" {
        Test-CommandExists "Invoke-NoSuchThing999" | Should -BeFalse
    }
}

Describe "CreateSymLink" {
    It "creates working symlink" {
        $target = Join-Path $TestDrive "target.txt"
        $link = Join-Path $TestDrive "link.txt"
        Set-Content $target "data"
        CreateSymLink $link $target
        Get-Content $link | Should -Be "data"
    }

    It "overwrites existing file" {
        $target = Join-Path $TestDrive "t2.txt"
        $link = Join-Path $TestDrive "l2.txt"
        Set-Content $target "new"
        Set-Content $link "old"
        CreateSymLink $link $target
        Get-Content $link | Should -Be "new"
    }
}
