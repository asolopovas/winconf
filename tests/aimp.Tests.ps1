BeforeAll {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class AIMPTestHelper {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenFileMapping(uint dwDesiredAccess, bool bInheritHandle, string lpName);
    [DllImport("kernel32.dll")]
    public static extern IntPtr MapViewOfFile(IntPtr h, uint a, uint oh, uint ol, uint n);
    [DllImport("kernel32.dll")]
    public static extern bool UnmapViewOfFile(IntPtr lpBaseAddress);
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern uint GetFileAttributesW(string lpFileName);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool DeleteFileW(string lpFileName);

    public const uint INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF;
}
"@

    function Get-AIMPSharedMemory {
        $hMap = [AIMPTestHelper]::OpenFileMapping(4, $false, "AIMP2_RemoteInfo")
        if ($hMap -eq [IntPtr]::Zero) { return $null }
        $ptr = [AIMPTestHelper]::MapViewOfFile($hMap, 4, 0, 0, 0)
        if ($ptr -eq [IntPtr]::Zero) { [AIMPTestHelper]::CloseHandle($hMap); return $null }
        return @{ Handle = $hMap; Pointer = $ptr }
    }

    function Close-AIMPSharedMemory($mem) {
        if ($mem) {
            [void][AIMPTestHelper]::UnmapViewOfFile($mem.Pointer)
            [void][AIMPTestHelper]::CloseHandle($mem.Handle)
        }
    }

    function Read-AIMPFilePath($ptr) {
        $m = [System.Runtime.InteropServices.Marshal]
        $headerSize  = $m::ReadInt32($ptr, 0)
        $albumLen    = $m::ReadInt32($ptr, 40)
        $artistLen   = $m::ReadInt32($ptr, 44)
        $dateLen     = $m::ReadInt32($ptr, 48)
        $fileNameLen = $m::ReadInt32($ptr, 52)
        if ($fileNameLen -le 0) { return "" }
        $dataOffset = $headerSize + ($albumLen + $artistLen + $dateLen) * 2
        return $m::PtrToStringUni([IntPtr]::Add($ptr, $dataOffset), $fileNameLen)
    }

    $script:aimpRunning = $null -ne (Get-Process "AIMP" -ErrorAction SilentlyContinue)
    $script:aimpHasTrack = $false
    if ($script:aimpRunning) {
        $mem = Get-AIMPSharedMemory
        if ($mem) {
            $script:aimpHasTrack = [System.Runtime.InteropServices.Marshal]::ReadInt32($mem.Pointer, 52) -gt 0
            Close-AIMPSharedMemory $mem
        }
    }
}

Describe "AIMP shared memory" -Tag "RequiresAIMP" {

    It "reads shared memory with valid header" {
        if (-not $script:aimpRunning) { Set-ItResult -Skipped -Because "AIMP is not running"; return }
        $mem = Get-AIMPSharedMemory
        try {
            $mem | Should -Not -BeNullOrEmpty
            [System.Runtime.InteropServices.Marshal]::ReadInt32($mem.Pointer, 0) | Should -Be 88
        } finally { Close-AIMPSharedMemory $mem }
    }

    It "file exists on disk when track is loaded" {
        if (-not $script:aimpHasTrack) { Set-ItResult -Skipped -Because "AIMP has no track loaded"; return }
        $mem = Get-AIMPSharedMemory
        try {
            $filePath = Read-AIMPFilePath $mem.Pointer
            ([AIMPTestHelper]::GetFileAttributesW($filePath) -ne [AIMPTestHelper]::INVALID_FILE_ATTRIBUTES) | Should -BeTrue
        } finally { Close-AIMPSharedMemory $mem }
    }
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
        # Mirrors ToLongPath in autohotkey/helpers.ahk
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
    # Mirrors the Trim() in GetAIMPCurrentFile
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
        # Mirrors AIMPDebugLogPath in autohotkey/helpers.ahk
        $logPath = Join-Path $env:TEMP "aimp-delete-debug.log"
        [System.IO.Path]::GetFileName($logPath) | Should -Be "aimp-delete-debug.log"
        $expectedDir = (Get-Item -LiteralPath $env:TEMP).FullName.TrimEnd('\')
        $actualDir   = (Get-Item -LiteralPath ([System.IO.Path]::GetDirectoryName($logPath))).FullName.TrimEnd('\')
        $actualDir | Should -Be $expectedDir
    }
}
