[CmdletBinding(SupportsShouldProcess)]
param(
    # By default entries whose directory is currently missing are KEPT (a dir may
    # be on a removable/network drive or mid-update). Pass -PruneMissing to remove them.
    [switch]$PruneMissing,
    [ValidateSet('All', 'Machine', 'User')]
    [string]$Scope = 'All'
)

$ErrorActionPreference = 'Stop'
$backupDir = Join-Path $env:USERPROFILE 'winconf\tmp\path-backups'
$userPathsFile = Join-Path $env:USERPROFILE 'winconf\.user-paths'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$windowsRoot = [Environment]::GetFolderPath('Windows').TrimEnd('\')
$userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
$usersRoot = Split-Path $userRoot -Parent

# Canonical form used for BOTH storage and comparison: env vars are expanded so dedup
# treats %LOCALAPPDATA%\X and C:\Users\..\X as one entry and the persisted REG_SZ value
# holds a literal path (no %VAR% left to rot). Pure function - no side effects.
function Format-PathEntry([string]$Path) {
    $entry = [Environment]::ExpandEnvironmentVariables($Path.Trim()).TrimEnd('\')
    if (-not $entry) { return }
    # Resolve '.'/'..' segments ONLY for a drive-rooted absolute path with no leftover
    # %VAR% (an undefined var stays literal). [IO.Path]::GetFullPath would otherwise
    # re-root a bare drive ('C:'), UNC ('\\srv\s'), or relative ('foo') entry against
    # the process working directory and corrupt it - so leave every other form verbatim.
    if ($entry -notmatch '%[^%]+%' -and
        $entry -match '^[A-Za-z]:[\\/]' -and $entry -match '(^|[\\/])\.\.?([\\/]|$)') {
        try { return [IO.Path]::GetFullPath($entry).TrimEnd('\') } catch { return $entry }
    }
    $entry
}

function Test-SystemPath([string]$Path) {
    ([Environment]::ExpandEnvironmentVariables($Path) -like "$windowsRoot*") -or
    ($Path -like '%SystemRoot%*') -or ($Path -like '%windir%*')
}

function Test-UserScopedPath([string]$Path) {
    $expanded = [Environment]::ExpandEnvironmentVariables($Path).TrimEnd('\')
    ($expanded -like "$userRoot\*") -or ($expanded -like "$usersRoot\*\AppData\*")
}

# Desired User PATH entries from .user-paths: one per line, $env: vars and
# * globs allowed, # comments; lines whose directory does not exist are skipped.
function Get-DesiredUserPath([string]$File = $userPathsFile) {
    if (-not (Test-Path -LiteralPath $File)) { return }
    foreach ($line in Get-Content -LiteralPath $File) {
        $line = $line.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }
        $expanded = $ExecutionContext.InvokeCommand.ExpandString($line).TrimEnd('\')
        if ($expanded.Contains('*')) {
            Resolve-Path -Path $expanded -ErrorAction SilentlyContinue |
                Where-Object { Test-Path -LiteralPath $_.Path -PathType Container } |
                ForEach-Object { $_.Path.TrimEnd('\') } | Sort-Object
        } elseif ($expanded -and (Test-Path -LiteralPath $expanded -PathType Container)) {
            $expanded
        }
    }
}

function Get-CleanPath {
    param(
        [AllowNull()][string]$Raw,
        [string[]]$Exclude = @(),
        [string[]]$Require = @(),
        [switch]$Relocate,
        [switch]$PruneMissing,
        [switch]$Quiet
    )

    $entries = @($Raw -split ';' | Where-Object { $_.Trim() } | ForEach-Object { Format-PathEntry $_ } | Where-Object { $_ })
    foreach ($required in @($Require | Where-Object { $_ } | ForEach-Object { Format-PathEntry $_ } | Where-Object { $_ })) {
        if ($entries -notcontains $required) {
            if (-not $Quiet) { Write-Host "  Adding required - $required" -ForegroundColor DarkYellow }
            $entries += $required
        }
    }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $excludeSet = [Collections.Generic.HashSet[string]]::new(
        [string[]]@($Exclude | Where-Object { $_ } | ForEach-Object { Format-PathEntry $_ } | Where-Object { $_ }),
        [StringComparer]::OrdinalIgnoreCase)
    $relocated = [Collections.Generic.List[string]]::new()

    $kept = @(foreach ($entry in $entries) {
        if (-not $seen.Add($entry)) { continue }
        if ($Relocate -and (Test-UserScopedPath $entry)) {
            if (-not $Quiet) { Write-Host "  Relocating user-scoped - $entry" -ForegroundColor DarkYellow }
            $relocated.Add($entry); continue
        }
        if ($excludeSet.Contains($entry)) {
            if (-not $Quiet) { Write-Host "  Removing cross-scope - $entry" -ForegroundColor DarkYellow }
            continue
        }
        if ($PruneMissing) {
            # Test-Path -LiteralPath throws on illegal-char entries under EAP=Stop
            # (PS 5.1); treat any failure as "cannot prove missing" and keep the entry.
            $missing = $false
            try { $missing = -not (Test-Path -LiteralPath $entry) } catch { $missing = $false }
            if ($missing) {
                if (-not $Quiet) { Write-Host "  Removing missing - $entry" -ForegroundColor DarkYellow }
                continue
            }
        }
        $entry
    })

    # Group system paths ahead of the rest for hardening, but preserve each entry's
    # ORIGINAL relative order within its group (stable partition) - never alphabetize,
    # because earlier-on-PATH wins and reordering silently changes which binary resolves.
    [pscustomobject]@{
        Joined    = (@($kept | Where-Object { Test-SystemPath $_ }) +
                     @($kept | Where-Object { -not (Test-SystemPath $_) })) -join ';'
        Entries   = $kept
        Relocated = @($relocated)
    }
}

function Update-PathScope {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('Machine', 'User')][string]$Target,
        [string[]]$Exclude = @(),
        [string[]]$Require = @(),
        [switch]$ReadOnly
    )

    Write-Host "[$Target PATH]" -ForegroundColor Cyan
    $raw = [Environment]::GetEnvironmentVariable('Path', $Target)
    $result = Get-CleanPath -Raw $raw -Exclude $Exclude -Require $Require -PruneMissing:$PruneMissing -Relocate:($Target -eq 'Machine')

    if ($Target -eq 'User') {
        foreach ($entry in @($result.Entries | Where-Object { $_ -like 'C:\Program Files*' -or $_ -like 'C:\ProgramData*' })) {
            Write-Host "  Note machine-scoped in User - $entry" -ForegroundColor DarkCyan
        }
    }

    if ($ReadOnly) {
        Write-Host '  Inspect only' -ForegroundColor DarkGray
    } elseif ($result.Joined -eq $raw) {
        Write-Host '  Already clean' -ForegroundColor Green
    } elseif (-not $result.Joined -and $raw) {
        Write-Warning "  Refusing to write an empty $Target PATH (raw had content) - skipped"
    } elseif ($PSCmdlet.ShouldProcess("$Target PATH", 'Rewrite')) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $backup = Join-Path $backupDir "$Target-$stamp.txt"
        # UTF-8 without BOM: a BOM would otherwise glue onto the first entry if the
        # backup is ever piped back into PATH.
        [IO.File]::WriteAllText($backup, $raw, [Text.UTF8Encoding]::new($false))
        Write-Host "  Backup - $backup" -ForegroundColor DarkGray
        [Environment]::SetEnvironmentVariable('Path', $result.Joined, $Target)
        Write-Host '  Updated' -ForegroundColor Green
    }

    $result
}

function Sync-SessionPath {
    $env:Path = ([Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';'
}

if ($MyInvocation.InvocationName -eq '.') { return }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Sync-SessionPath

$machine = if ($Scope -eq 'User') {
    Get-CleanPath -Raw ([Environment]::GetEnvironmentVariable('Path', 'Machine')) -PruneMissing:$PruneMissing -Quiet
} else {
    if (-not $isAdmin) { Write-Warning 'Not elevated - Machine PATH inspected only; run elevated to rewrite it.' }
    Update-PathScope -Target Machine -ReadOnly:(-not $isAdmin)
}

if ($Scope -ne 'Machine') {
    $require = @(@(if ($isAdmin) { $machine.Relocated }) + @(Get-DesiredUserPath) | Where-Object { $_ })
    [void](Update-PathScope -Target User -Exclude $machine.Entries -Require $require)
}

Sync-SessionPath
