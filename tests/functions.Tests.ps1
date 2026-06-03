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

Describe "repo" {
    BeforeEach {
        $script:GitArgs = $null
        $script:OldRepoOwner = $env:REPO_OWNER
        $script:OldXdgCacheHome = $env:XDG_CACHE_HOME
        $env:REPO_OWNER = $null
        $env:XDG_CACHE_HOME = $null
        function global:git { $script:GitArgs = $args; $global:LASTEXITCODE = 0 }
    }

    AfterEach {
        if ($script:OldRepoOwner) { $env:REPO_OWNER = $script:OldRepoOwner } else { $env:REPO_OWNER = $null }
        if ($script:OldXdgCacheHome) { $env:XDG_CACHE_HOME = $script:OldXdgCacheHome } else { $env:XDG_CACHE_HOME = $null }
        Remove-Item Function:\git -ErrorAction SilentlyContinue
    }

    It "clones owner repo over ssh by default" {
        Push-Location $TestDrive
        try { repo dotfiles } finally { Pop-Location }
        $script:GitArgs -join ' ' | Should -Be 'clone git@github.com:asolopovas/dotfiles.git'
    }

    It "clones owner repo over https when requested" {
        Push-Location $TestDrive
        try { repo --https asolopovas/winconf } finally { Pop-Location }
        $script:GitArgs -join ' ' | Should -Be 'clone https://github.com/asolopovas/winconf.git'
    }

    It "lists cached repositories" {
        $env:XDG_CACHE_HOME = Join-Path $TestDrive 'cache'
        $cacheDir = Join-Path $env:XDG_CACHE_HOME 'dotfiles'
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        Set-Content -Path (Join-Path $cacheDir 'repos-asolopovas') -Value "winconf`tWindows config"
        repo --list | Should -Be "winconf`tWindows config"
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
