BeforeAll {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class AIMPTestHelper {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint GetFileAttributesW(string lpFileName);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool DeleteFileW(string lpFileName);

    public const uint INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF;
}
"@

}

Describe "File deletion (Win32 API)" {

    It "deletes a file and detects missing files" {
        $file = Join-Path $TestDrive "sample.tmp"
        Set-Content -Path $file -Value "data"
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeTrue
        [AIMPTestHelper]::GetFileAttributesW($file) | Should -Be ([AIMPTestHelper]::INVALID_FILE_ATTRIBUTES)
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeFalse
    }

    It "handles brackets, parens and spaces in path" {
        $dir = Join-Path $TestDrive "Outer [alpha] (beta)"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $file = Join-Path $dir "foo - bar (baz).mp3"
        Set-Content -LiteralPath $file -Value "data"
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeTrue
        [AIMPTestHelper]::GetFileAttributesW($file) | Should -Be ([AIMPTestHelper]::INVALID_FILE_ATTRIBUTES)
    }

    It "deletes via \\?\ long-path prefix" {
        $file = Join-Path $TestDrive "longpath.tmp"
        Set-Content -LiteralPath $file -Value "data"
        [AIMPTestHelper]::DeleteFileW("\\?\" + $file) | Should -BeTrue
        [AIMPTestHelper]::GetFileAttributesW($file) | Should -Be ([AIMPTestHelper]::INVALID_FILE_ATTRIBUTES)
    }
}

Describe "Long-path conversion" {
    BeforeAll {
        function ConvertTo-LongPath($path) {
            if ($path.StartsWith("\\?\")) { return $path }
            if ($path.StartsWith("\\"))  { return "\\?\UNC\" + $path.Substring(2) }
            if ($path -match "^[A-Za-z]:\\") { return "\\?\" + $path }
            return $path
        }
    }

    It "converts UNC path to \\?\UNC\ form" {
        ConvertTo-LongPath "\\server\share\dir\file.mp3" | Should -Be "\\?\UNC\server\share\dir\file.mp3"
    }

    It "converts drive path to \\?\ form" {
        ConvertTo-LongPath "C:\dir\file.mp3" | Should -Be "\\?\C:\dir\file.mp3"
    }

    It "leaves already-prefixed paths unchanged" {
        ConvertTo-LongPath "\\?\C:\dir\file.mp3" | Should -Be "\\?\C:\dir\file.mp3"
        ConvertTo-LongPath "\\?\UNC\server\share\file.mp3" | Should -Be "\\?\UNC\server\share\file.mp3"
    }

    It "leaves relative paths unchanged" {
        ConvertTo-LongPath "relative\file.mp3" | Should -Be "relative\file.mp3"
    }
}

Describe "Path trim" {
    It "trims surrounding whitespace only" {
        ("  \\server\share\file.mp3 `t").Trim(" `t`r`n".ToCharArray()) | Should -Be "\\server\share\file.mp3"
    }

    It "leaves inner content untouched" {
        $p = "\\server\share\Outer [alpha]\Sub\foo - bar (baz).mp3"
        $p.Trim(" `t`r`n".ToCharArray()) | Should -Be $p
    }
}

Describe "Debug log location" {
    It "log path lives under the temp folder" {
        $logPath = Join-Path $env:TEMP "aimp-delete-debug.log"
        [System.IO.Path]::GetFileName($logPath) | Should -Be "aimp-delete-debug.log"
        $expectedDir = (Get-Item -LiteralPath $env:TEMP).FullName.TrimEnd('\')
        $actualDir   = (Get-Item -LiteralPath ([System.IO.Path]::GetDirectoryName($logPath))).FullName.TrimEnd('\')
        $actualDir | Should -Be $expectedDir
    }
}
