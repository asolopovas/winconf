BeforeAll {
    $script:root = Split-Path $PSScriptRoot -Parent
    $script:path = Join-Path $script:root 'scripts\paths-doctor.ps1'
    Mock -CommandName Write-Host -MockWith { } -ModuleName ([string]::Empty) -ErrorAction SilentlyContinue
    . $script:path
    $script:sysRoot = [Environment]::GetFolderPath('Windows').TrimEnd('\')
}

Describe 'Get-SortedPath' {
    BeforeEach { Mock Write-Host { } }

    It 'returns empty result for null/empty input' {
        $r = Get-SortedPath -Raw ''
        $r.Count       | Should -Be 0
        $r.Joined      | Should -BeNullOrEmpty
        $r.Dupes       | Should -Be 0
        $r.Missing     | Should -Be 0
        $r.CrossDupes  | Should -Be 0
    }

    It 'puts Windows system paths before everything else' {
        $raw = "C:\Tools;$sysRoot\system32;$sysRoot;C:\Apps"
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true 2>$null
        $entries = $r.Joined -split ';'
        $entries[0] | Should -Be $sysRoot
        $entries[1] | Should -Be "$sysRoot\system32"
    }

    It 'sorts non-system paths alphabetically' {
        $raw = 'C:\Zeta;C:\Alpha;C:\Mike'
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true
        $r.Joined | Should -Be 'C:\Alpha;C:\Mike;C:\Zeta'
    }

    It 'deduplicates case-insensitively' {
        $raw = 'C:\Foo;c:\foo;C:\FOO\;C:\Bar'
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true
        $r.Count | Should -Be 2
        $r.Dupes | Should -Be 2
    }

    It 'trims whitespace and trailing backslashes' {
        $raw = '  C:\Foo\  ;C:\Bar\'
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true
        $r.Entries | Should -Contain 'C:\Foo'
        $r.Entries | Should -Contain 'C:\Bar'
    }

    It 'drops empty entries from double semicolons' {
        $raw = 'C:\Foo;;;C:\Bar'
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true
        $r.Count | Should -Be 2
    }

    It 'eliminates dead paths by default' {
        $alive = $TestDrive
        $dead  = Join-Path $TestDrive 'does-not-exist'
        $r = Get-SortedPath -Raw "$alive;$dead"
        $r.Count   | Should -Be 1
        $r.Missing | Should -Be 1
        $r.Entries | Should -Contain ([string]$alive).TrimEnd('\')
    }

    It 'keeps dead paths when -KeepMissing implied via param' {
        $dead = Join-Path $TestDrive 'nope'
        $r = Get-SortedPath -Raw $dead -KeepMissing:$true
        $r.Count   | Should -Be 1
        $r.Missing | Should -Be 0
    }

    It 'removes entries already present in Machine scope' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'a')).FullName
        $b = (New-Item -ItemType Directory (Join-Path $TestDrive 'b')).FullName
        $r = Get-SortedPath -Raw "$a;$b" -ExcludeFromMachine @($a)
        $r.CrossDupes | Should -Be 1
        $r.Entries    | Should -Not -Contain $a
        $r.Entries    | Should -Contain $b
    }

    It 'produces a stable result that is idempotent under a second pass' {
        $a = (New-Item -ItemType Directory (Join-Path $TestDrive 'idem-a')).FullName
        $b = (New-Item -ItemType Directory (Join-Path $TestDrive 'idem-b')).FullName
        $first  = Get-SortedPath -Raw "$b;$a;$a" -KeepMissing:$true
        $second = Get-SortedPath -Raw $first.Joined -KeepMissing:$true
        $second.Joined | Should -Be $first.Joined
        $second.Dupes  | Should -Be 0
    }

    It 'normalizes path traversal segments' {
        $r = Get-SortedPath -Raw 'C:\Program Files\Foo\..\Bar' -KeepMissing:$true
        $r.Entries | Should -Contain 'C:\Program Files\Bar'
    }

    It 'relocates user-scoped Machine entries when -RelocateUserScoped is set' {
        $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
        $raw = "C:\Tools;$userRoot\AppData\Local\Foo"
        $r = Get-SortedPath -Raw $raw -KeepMissing:$true -RelocateUserScoped
        $r.Relocated.Count | Should -Be 1
        $r.Entries | Should -Not -Contain "$userRoot\AppData\Local\Foo"
    }

    It 'does not relocate without -RelocateUserScoped' {
        $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
        $r = Get-SortedPath -Raw "$userRoot\AppData\Local\Foo" -KeepMissing:$true
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

Describe 'Final invariants' {
    BeforeEach { Mock Write-Host { } }

    It 'final output has no duplicates and no dead entries' {
        $live = (New-Item -ItemType Directory (Join-Path $TestDrive 'live')).FullName
        $dead = Join-Path $TestDrive 'ghost'
        $r = Get-SortedPath -Raw "$live;$live;$dead;$sysRoot"
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
        Get-Command $script:path | Select-Object -ExpandProperty Parameters | ForEach-Object {
            $_.Keys | Should -Contain 'WhatIf'
        }
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
