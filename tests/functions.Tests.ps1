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

    It "true for external executable" {
        Test-CommandExists "cmd" | Should -BeTrue
    }
}

Describe "SetPermissions" {
    It "sets ACL on existing directory" {
        $dir = Join-Path $TestDrive "perm-test"
        New-Item -ItemType Directory $dir | Out-Null
        { SetPermissions $dir } | Should -Not -Throw
    }

    It "errors on non-existent path" {
        SetPermissions "C:\no_such_dir_xyz_999" -ErrorVariable err -ErrorAction SilentlyContinue
        $err.Count | Should -BeGreaterThan 0
    }
}

Describe "CreateSymLink" {
    It "creates working symlink to file" {
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

    It "creates working symlink to directory" {
        $targetDir = Join-Path $TestDrive "target-dir"
        New-Item -ItemType Directory $targetDir | Out-Null
        Set-Content (Join-Path $targetDir "inner.txt") "inside"
        $link = Join-Path $TestDrive "link-dir"
        CreateSymLink $link $targetDir
        Get-Content (Join-Path $link "inner.txt") | Should -Be "inside"
    }
}
