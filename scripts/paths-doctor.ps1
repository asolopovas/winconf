[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepMissing,
    [ValidateSet('All', 'Machine', 'User')]
    [string]$Scope = 'All'
)

$ErrorActionPreference = 'Stop'

$backupDir = Join-Path $env:USERPROFILE 'winconf\tmp\path-backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$windowsRoot = [Environment]::GetFolderPath('Windows').TrimEnd('\')

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Format-PathEntry {
    param([string]$Path)
    $entry = $Path.Trim().TrimEnd('\')
    $expanded = [Environment]::ExpandEnvironmentVariables($entry)
    if ($expanded -match '\.\.' -and $expanded -match '^[A-Za-z]:') {
        try { return ([System.IO.Path]::GetFullPath($expanded)).TrimEnd('\') } catch { }
    }
    return $entry
}

function Get-PathEntries {
    param([AllowNull()][string]$Raw)
    if (-not $Raw) { return }
    $Raw -split ';' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        ForEach-Object { Format-PathEntry $_ }
}

function New-PathSet {
    param([string[]]$Items = @())
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in $Items) { if ($item) { [void]$set.Add($item) } }
    return ,$set
}

function Select-UniquePath {
    param([string[]]$Entries = @())
    $seen = New-PathSet
    foreach ($entry in $Entries) {
        if ($seen.Add($entry)) { $entry }
    }
}

function Test-UserScopedPath {
    param([string]$Path)
    $expanded = [Environment]::ExpandEnvironmentVariables($Path).TrimEnd('\')
    $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
    $usersRoot = Split-Path $userRoot -Parent
    return ($expanded -like "$userRoot\*") -or ($expanded -like "$usersRoot\*\AppData\*")
}

function Test-SystemPath {
    param([string]$Path)
    $expanded = [Environment]::ExpandEnvironmentVariables($Path).TrimEnd('\')
    return ($expanded -like "$windowsRoot*") -or ($Path -like '%SystemRoot%*') -or ($Path -like '%windir%*')
}

function Save-PathBackup {
    param(
        [ValidateSet('Machine', 'User')][string]$Scope,
        [AllowNull()][string]$Raw
    )
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $backup = Join-Path $backupDir "$Scope-$stamp.txt"
    Set-Content -LiteralPath $backup -Value $Raw -NoNewline -Encoding UTF8
    Write-Host "  Backup  - $backup" -ForegroundColor DarkGray
}

function Get-SortedPath {
    param(
        [AllowNull()][string]$Raw,
        [string[]]$ExcludeFromMachine = @(),
        [string[]]$RequiredEntries = @(),
        [switch]$KeepMissing,
        [switch]$RelocateUserScoped,
        [switch]$Quiet
    )

    $entries = @(Get-PathEntries -Raw $Raw)
    $entrySet = New-PathSet -Items $entries
    foreach ($required in $RequiredEntries) {
        $entry = Format-PathEntry $required
        if ($entrySet.Add($entry)) {
            if (-not $Quiet) { Write-Host "  Adding required - $entry" -ForegroundColor DarkYellow }
            $entries += $entry
        }
    }

    $relocated = @()
    if ($RelocateUserScoped) {
        $machineEntries = @()
        foreach ($entry in $entries) {
            if (Test-UserScopedPath $entry) {
                if (-not $Quiet) { Write-Host "  Relocating user-scoped - $entry" -ForegroundColor DarkYellow }
                $relocated += $entry
            } else {
                $machineEntries += $entry
            }
        }
        $entries = $machineEntries
    }

    $unique = @(Select-UniquePath -Entries $entries)
    $machineSet = New-PathSet -Items $ExcludeFromMachine
    $crossDupes = 0

    $kept = @(
        foreach ($entry in $unique) {
            if ($machineSet.Contains($entry)) {
                if (-not $Quiet) { Write-Host "  Removing cross-scope - $entry" -ForegroundColor DarkYellow }
                $crossDupes++
                continue
            }
            if (-not $KeepMissing) {
                $expanded = [Environment]::ExpandEnvironmentVariables($entry)
                if (-not (Test-Path -LiteralPath $expanded)) {
                    if (-not $Quiet) { Write-Host "  Removing missing - $entry" -ForegroundColor DarkYellow }
                    continue
                }
            }
            $entry
        }
    )

    $ordered = @($kept | Where-Object { Test-SystemPath $_ } | Sort-Object) +
        @($kept | Where-Object { -not (Test-SystemPath $_) } | Sort-Object)

    [pscustomobject]@{
        Joined     = $ordered -join ';'
        Missing    = $unique.Count - $crossDupes - $kept.Count
        Dupes      = $entries.Count - $unique.Count
        CrossDupes = $crossDupes
        Count      = $kept.Count
        Entries    = @($kept)
        Relocated  = @($relocated)
    }
}

function Update-PathScope {
    param(
        [ValidateSet('Machine', 'User')][string]$Scope,
        [string[]]$ExcludeFromMachine = @(),
        [string[]]$RequiredEntries = @(),
        [switch]$ReadOnly
    )

    Write-Host "[$Scope PATH]" -ForegroundColor Cyan
    $raw = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $result = Get-SortedPath -Raw $raw -ExcludeFromMachine $ExcludeFromMachine -RequiredEntries $RequiredEntries -KeepMissing:$KeepMissing -RelocateUserScoped:($Scope -eq 'Machine')

    Write-Host ("  Entries - {0} kept, {1} dupes, {2} cross-scope, {3} missing, {4} relocated" -f $result.Count, $result.Dupes, $result.CrossDupes, $result.Missing, $result.Relocated.Count) -ForegroundColor DarkGray

    if ($Scope -eq 'User') {
        $machineScoped = $result.Entries | Where-Object { $_ -like 'C:\Program Files*' -or $_ -like 'C:\ProgramData*' }
        foreach ($entry in $machineScoped) { Write-Host "  Note machine-scoped in User - $entry" -ForegroundColor DarkCyan }
    }

    if ($ReadOnly) {
        Write-Host '  Inspect only' -ForegroundColor DarkGray
    } elseif ($result.Joined -eq $raw -and $result.Relocated.Count -eq 0) {
        Write-Host '  Already clean' -ForegroundColor Green
    } elseif ($PSCmdlet.ShouldProcess("$Scope PATH", 'Rewrite')) {
        Save-PathBackup -Scope $Scope -Raw $raw
        [Environment]::SetEnvironmentVariable('Path', $result.Joined, $Scope)
        Write-Host '  Updated' -ForegroundColor Green
    }

    [pscustomobject]@{ Entries = @($result.Entries); Relocated = @($result.Relocated) }
}

function Set-SessionPathFromRegistry {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    Write-Host 'Session PATH refreshed.' -ForegroundColor Cyan
}

function Get-AdbPathEntry {
    Set-SessionPathFromRegistry 6>$null
    if (Get-Command adb -ErrorAction SilentlyContinue) { return }

    $candidates = @(
        if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME 'platform-tools' }
        if ($env:ANDROID_SDK_ROOT) { Join-Path $env:ANDROID_SDK_ROOT 'platform-tools' }
        if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools' }
    )

    $wingetRoot = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages' }
    if ($wingetRoot -and (Test-Path -LiteralPath $wingetRoot)) {
        $candidates += Get-ChildItem -LiteralPath $wingetRoot -Directory -Filter 'Google.PlatformTools*' -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'platform-tools' }
    }

    Select-UniquePath -Entries @($candidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'adb.exe') }) |
        Select-Object -First 1
}

function Write-AdbStatus {
    $command = Get-Command adb -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        Write-Host "adb resolved - $($command.Source)" -ForegroundColor Green
    } elseif ($Scope -in @('All', 'User')) {
        Write-Warning 'adb is not on PATH and no local Android platform-tools install was found.'
    } else {
        Write-Warning 'adb is not on PATH; run with -Scope All or -Scope User to add Android platform-tools.'
    }
}

if ($MyInvocation.InvocationName -eq '.') { return }

$isAdmin = Test-Admin
$machineEntries = @()
$requiredUserEntries = @()

if ($Scope -in @('All', 'Machine')) {
    if ($isAdmin) {
        $machineResult = Update-PathScope -Scope Machine
        $machineEntries = @($machineResult.Entries)
        $requiredUserEntries += @($machineResult.Relocated)
    } else {
        Write-Warning 'Not elevated - Machine PATH will be inspected only.'
        $machineResult = Update-PathScope -Scope Machine -ReadOnly
        $machineEntries = @($machineResult.Entries)
    }
} else {
    $machineRaw = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $machineResult = Get-SortedPath -Raw $machineRaw -KeepMissing:$KeepMissing -Quiet
    $machineEntries = @($machineResult.Entries)
}

if ($Scope -in @('All', 'User')) {
    $requiredUserEntries += @(Get-AdbPathEntry)
    [void](Update-PathScope -Scope User -ExcludeFromMachine $machineEntries -RequiredEntries $requiredUserEntries)
}

if ($Scope -ne 'User' -and -not $isAdmin) {
    Write-Warning 'Run elevated to let this script rewrite Machine PATH.'
}

Set-SessionPathFromRegistry
Write-AdbStatus
