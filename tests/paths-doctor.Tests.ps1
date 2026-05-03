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
}
