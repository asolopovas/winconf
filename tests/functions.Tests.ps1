BeforeAll {
    . "$env:USERPROFILE\winconf\functions.ps1"
}

Describe "Test-CommandExists" {
    It "true for built-in command" {
        Test-CommandExists "Get-Process" | Should -BeTrue
    }
    It "false for fake command" {
        Test-CommandExists "Invoke-NoSuchThing999" | Should -BeFalse
    }
}

Describe "Test-ReparsePoint" {
    It "false for non-existent path" {
        Test-ReparsePoint "C:\no_such_xyz" | Should -BeFalse
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

Describe "Clear-DebugLogs" {
    It "removes only .log files" {
        $dir = Join-Path $TestDrive "logs"
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content "$dir\a.log" "x"
        Set-Content "$dir\b.txt" "y"
        Clear-DebugLogs -LogDirectory $dir
        Test-Path "$dir\a.log" | Should -BeFalse
        Test-Path "$dir\b.txt" | Should -BeTrue
    }
}
