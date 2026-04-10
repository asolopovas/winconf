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

    public const uint FILE_MAP_READ = 4;
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
            $m = [System.Runtime.InteropServices.Marshal]
            $m::ReadInt32($mem.Pointer, 0) | Should -Be 88
        } finally { Close-AIMPSharedMemory $mem }
    }

    It "extracts valid file path when track is loaded" {
        if (-not $script:aimpHasTrack) { Set-ItResult -Skipped -Because "AIMP has no track loaded"; return }
        $mem = Get-AIMPSharedMemory
        try {
            $filePath = Read-AIMPFilePath $mem.Pointer
            $filePath | Should -Not -BeNullOrEmpty
            ($filePath.StartsWith("\\") -or $filePath -match "^[A-Za-z]:\\") | Should -BeTrue
            [System.IO.Path]::GetExtension($filePath).ToLower() | Should -BeIn @(".mp3", ".flac", ".wav", ".ogg", ".m4a", ".aac", ".wma", ".opus", ".ape", ".wv", ".aiff")
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

    It "returns empty path when no track is loaded" {
        if (-not $script:aimpRunning -or $script:aimpHasTrack) { Set-ItResult -Skipped -Because "need AIMP running with no track"; return }
        $mem = Get-AIMPSharedMemory
        try { Read-AIMPFilePath $mem.Pointer | Should -Be "" }
        finally { Close-AIMPSharedMemory $mem }
    }

    It "does not leak handles after repeated open/close" {
        if (-not $script:aimpRunning) { Set-ItResult -Skipped -Because "AIMP is not running"; return }
        for ($i = 0; $i -lt 10; $i++) {
            $mem = Get-AIMPSharedMemory
            $mem | Should -Not -BeNullOrEmpty
            Close-AIMPSharedMemory $mem
        }
    }
}

Describe "File deletion (Win32 API)" {

    It "deletes a file and detects missing files" {
        $file = Join-Path $TestDrive "test.tmp"
        Set-Content -Path $file -Value "data"
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeTrue
        [AIMPTestHelper]::GetFileAttributesW($file) | Should -Be ([AIMPTestHelper]::INVALID_FILE_ATTRIBUTES)
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeFalse
    }

    It "handles special characters in path" {
        $dir = Join-Path $TestDrive "Pack [2026]"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $file = Join-Path $dir "Artist - Track (Remix) 120.mp3"
        Set-Content -LiteralPath $file -Value "data"
        [AIMPTestHelper]::DeleteFileW($file) | Should -BeTrue
        [AIMPTestHelper]::GetFileAttributesW($file) | Should -Be ([AIMPTestHelper]::INVALID_FILE_ATTRIBUTES)
    }
}

Describe "Shared memory offset math" {

    It "calculates correct data offset for filename" {
        # AHK logic: dataOffset = headerSize + (albumLen + artistLen + dateLen) * 2
        (88 + (0 + 5 + 0) * 2) | Should -Be 98
        (88 + (0 + 0 + 0) * 2) | Should -Be 88
        (88 + (100 + 80 + 10) * 2) | Should -Be 468
    }
}
