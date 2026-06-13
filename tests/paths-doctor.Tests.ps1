BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:path = Join-Path $script:root 'scripts\paths-doctor.ps1'
    Mock -CommandName Write-Host -MockWith { } -ModuleName ([string]::Empty) -ErrorAction SilentlyContinue
    . $script:path
    $script:sysRoot = [Environment]::GetFolderPath('Windows').TrimEnd('\')
}

Describe 'Get-CleanPath' {
    BeforeEach { Mock Write-Host { } }

    It 'returns empty result for null/empty input' {
        $r = Get-CleanPath -Raw ''
        $r.Entries.Count   | Should -Be 0
        $r.Joined          | Should -BeNullOrEmpty
        $r.Relocated.Count | Should -Be 0
    }

    It 'puts Windows system paths before everything else' {
        $raw = "C:\Tools;$sysRoot\system32;$sysRoot;C:\Apps"
        $r = Get-CleanPath -Raw $raw -KeepMissing
        $entries = $r.Joined -split ';'
        $entries[0] | Should -Be $sysRoot
        $entries[1] | Should -Be "$sysRoot\system32"
    }

    It 'sorts non-system paths alphabetically' {
        $r = Get-CleanPath -Raw 'C:\Zeta;C:\Alpha;C:\Mike' -KeepMissing
        $r.Joined | Should -Be 'C:\Alpha;C:\Mike;C:\Zeta'
    }

    It 'deduplicates case-insensitively' {
        $r = Get-CleanPath -Raw 'C:\Foo;c:\foo;C:\FOO\;C:\Bar' -KeepMissing
        $r.Entries.Count | Should -Be 2
    }

    It 'trims whitespace and trailing backslashes' {
        $r = Get-CleanPath -Raw '  C:\Foo\  ;C:\Bar\' -KeepMissing
        $r.Entries | Should -Contain 'C:\Foo'
        $r.Entries | Should -Contain 'C:\Bar'
    }

    It 'drops empty entries from double semicolons' {
        $r = Get-CleanPath -Raw 'C:\Foo;;;C:\Bar' -KeepMissing
        $r.Entries.Count | Should -Be 2
    }

    It 'eliminates dead paths by default' {
        $alive = $TestDrive
        $dead  = Join-Path $TestDrive 'does-not-exist'
        $r = Get-CleanPath -Raw "$alive;$dead"
        $r.Entries.Count | Should -Be 1
        $r.Entries       | Should -Contain ([string]$alive).TrimEnd('\')
    }

    It 'keeps dead paths with -KeepMissing' {
        $dead = Join-Path $TestDrive 'nope'
        $r = Get-CleanPath -Raw $dead -KeepMissing
        $r.Entries.Count | Should -Be 1
    }

    It 'removes entries listed in -Exclude' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'a')).FullName
        $b = (New-Item -ItemType Directory (Join-Path $TestDrive 'b')).FullName
        $r = Get-CleanPath -Raw "$a;$b" -Exclude @($a)
        $r.Entries | Should -Not -Contain $a
        $r.Entries | Should -Contain $b
    }

    It 'adds -Require entries that are not present yet' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'req-a')).FullName
        $b = (New-Item -ItemType Directory (Join-Path $TestDrive 'req-b')).FullName
        $r = Get-CleanPath -Raw $a -Require @($b, $a)
        $r.Entries | Should -Contain $a
        $r.Entries | Should -Contain $b
        $r.Entries.Count | Should -Be 2
    }

    It 'ignores null and empty -Require entries' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'req-c')).FullName
        $r = Get-CleanPath -Raw $a -Require @($null, '')
        $r.Entries.Count | Should -Be 1
    }

    It 'produces a stable result that is idempotent under a second pass' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'idem-a')).FullName
        $b = (New-Item -ItemType Directory (Join-Path $TestDrive 'idem-b')).FullName
        $first  = Get-CleanPath -Raw "$b;$a;$a" -KeepMissing
        $second = Get-CleanPath -Raw $first.Joined -KeepMissing
        $second.Joined | Should -Be $first.Joined
    }

    It 'normalizes path traversal segments' {
        $r = Get-CleanPath -Raw 'C:\Program Files\Foo\..\Bar' -KeepMissing
        $r.Entries | Should -Contain 'C:\Program Files\Bar'
    }

    It 'relocates user-scoped entries when -Relocate is set' {
        $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
        $r = Get-CleanPath -Raw "C:\Tools;$userRoot\AppData\Local\Foo" -KeepMissing -Relocate
        $r.Relocated.Count | Should -Be 1
        $r.Entries | Should -Not -Contain "$userRoot\AppData\Local\Foo"
    }

    It 'does not relocate without -Relocate' {
        $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
        $r = Get-CleanPath -Raw "$userRoot\AppData\Local\Foo" -KeepMissing
        $r.Relocated.Count | Should -Be 0
    }
}

Describe 'Test-UserScopedPath' {
    It 'flags paths under the user profile' {
        $u = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
        Test-UserScopedPath "$u\bin"             | Should -BeTrue
        Test-UserScopedPath "$u\AppData\Local\x" | Should -BeTrue
    }

    It 'does not flag Program Files or Windows paths' {
        Test-UserScopedPath 'C:\Program Files\Foo' | Should -BeFalse
        Test-UserScopedPath 'C:\Windows\system32'  | Should -BeFalse
    }
}

Describe 'Format-PathEntry' {
    It 'resolves .. segments' {
        Format-PathEntry 'C:\Program Files\Foo\..\Bar' | Should -Be 'C:\Program Files\Bar'
    }

    It 'trims trailing backslashes' {
        Format-PathEntry 'C:\Foo\' | Should -Be 'C:\Foo'
    }

    It 'leaves clean paths untouched' {
        Format-PathEntry 'C:\Foo\Bar' | Should -Be 'C:\Foo\Bar'
    }
}

Describe 'Get-DesiredUserPath' {
    BeforeEach {
        $script:upFile = Join-Path $TestDrive 'user-paths'
        $script:upDir = (New-Item -ItemType Directory (Join-Path $TestDrive "up-$([IO.Path]::GetRandomFileName())")).FullName
        $env:WINCONF_TEST_DIR = $script:upDir
    }

    AfterEach { $env:WINCONF_TEST_DIR = $null }

    It 'returns nothing when the file is absent' {
        Get-DesiredUserPath -File (Join-Path $TestDrive 'absent') | Should -BeNullOrEmpty
    }

    It 'expands env vars and skips comments, blanks, and missing dirs' {
        Set-Content $upFile @"
# comment

`$env:WINCONF_TEST_DIR
$TestDrive\not-there
"@
        $r = @(Get-DesiredUserPath -File $upFile)
        $r | Should -Be @($script:upDir)
    }

    It 'resolves glob lines to existing directories' {
        $pkg = New-Item -ItemType Directory (Join-Path $script:upDir 'Tool.Name_abc123\bin')
        Set-Content $upFile "$script:upDir\Tool.Name*\bin"
        $r = @(Get-DesiredUserPath -File $upFile)
        $r | Should -Be @($pkg.FullName)
    }

    It 'returns nothing for globs with no match' {
        Set-Content $upFile "$script:upDir\NoSuch*\bin"
        Get-DesiredUserPath -File $upFile | Should -BeNullOrEmpty
    }
}

Describe 'Final invariants' {
    BeforeEach { Mock Write-Host { } }

    It 'final output has no duplicates and no dead entries' {
        $live = (New-Item -ItemType Directory (Join-Path $TestDrive 'live')).FullName
        $dead = Join-Path $TestDrive 'ghost'
        $r = Get-CleanPath -Raw "$live;$live;$dead;$sysRoot"
        $entries = $r.Joined -split ';'
        ($entries | Group-Object | Where-Object Count -gt 1).Count | Should -Be 0
        foreach ($e in $entries) {
            Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($e)) | Should -BeTrue
        }
    }
}

Describe 'paths-doctor.ps1 script invocation' {
    It 'parses without errors' {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($script:path, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'supports -WhatIf via SupportsShouldProcess' {
        (Get-Command $script:path).Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'exposes -KeepMissing switch' {
        (Get-Command $script:path).Parameters.Keys | Should -Contain 'KeepMissing'
    }

    It 'exposes -Scope selector' {
        $command = Get-Command $script:path
        $command.Parameters.Keys | Should -Contain 'Scope'
        $values = $command.Parameters.Scope.Attributes |
            Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
            Select-Object -ExpandProperty ValidValues
        $values | Should -Be @('All', 'Machine', 'User')
    }
}
