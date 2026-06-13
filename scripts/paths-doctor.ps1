[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepMissing,
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

function Format-PathEntry([string]$Path) {
    $entry = $Path.Trim().TrimEnd('\')
    $expanded = [Environment]::ExpandEnvironmentVariables($entry)
    if ($expanded -match '\.\.' -and $expanded -match '^[A-Za-z]:') {
        try { return [IO.Path]::GetFullPath($expanded).TrimEnd('\') } catch { }
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
        [switch]$KeepMissing,
        [switch]$Quiet
    )

    $entries = @($Raw -split ';' | Where-Object { $_.Trim() } | ForEach-Object { Format-PathEntry $_ })
    foreach ($required in @($Require | Where-Object { $_ } | ForEach-Object { Format-PathEntry $_ })) {
        if ($entries -notcontains $required) {
            if (-not $Quiet) { Write-Host "  Adding required - $required" -ForegroundColor DarkYellow }
            $entries += $required
        }
    }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $excludeSet = [Collections.Generic.HashSet[string]]::new([string[]]$Exclude, [StringComparer]::OrdinalIgnoreCase)
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
        if (-not $KeepMissing -and -not (Test-Path -LiteralPath ([Environment]::ExpandEnvironmentVariables($entry)))) {
            if (-not $Quiet) { Write-Host "  Removing missing - $entry" -ForegroundColor DarkYellow }
            continue
        }
        $entry
    })

    [pscustomobject]@{
        Joined    = (@($kept | Where-Object { Test-SystemPath $_ } | Sort-Object) +
                     @($kept | Where-Object { -not (Test-SystemPath $_) } | Sort-Object)) -join ';'
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
    $result = Get-CleanPath -Raw $raw -Exclude $Exclude -Require $Require -KeepMissing:$KeepMissing -Relocate:($Target -eq 'Machine')

    if ($Target -eq 'User') {
        foreach ($entry in @($result.Entries | Where-Object { $_ -like 'C:\Program Files*' -or $_ -like 'C:\ProgramData*' })) {
            Write-Host "  Note machine-scoped in User - $entry" -ForegroundColor DarkCyan
        }
    }

    if ($ReadOnly) {
        Write-Host '  Inspect only' -ForegroundColor DarkGray
    } elseif ($result.Joined -eq $raw) {
        Write-Host '  Already clean' -ForegroundColor Green
    } elseif ($PSCmdlet.ShouldProcess("$Target PATH", 'Rewrite')) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $backup = Join-Path $backupDir "$Target-$stamp.txt"
        Set-Content -LiteralPath $backup -Value $raw -NoNewline -Encoding UTF8
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
    Get-CleanPath -Raw ([Environment]::GetEnvironmentVariable('Path', 'Machine')) -KeepMissing:$KeepMissing -Quiet
} else {
    if (-not $isAdmin) { Write-Warning 'Not elevated - Machine PATH inspected only; run elevated to rewrite it.' }
    Update-PathScope -Target Machine -ReadOnly:(-not $isAdmin)
}

if ($Scope -ne 'Machine') {
    $require = @(@(if ($isAdmin) { $machine.Relocated }) + @(Get-DesiredUserPath) | Where-Object { $_ })
    [void](Update-PathScope -Target User -Exclude $machine.Entries -Require $require)
}

Sync-SessionPath
