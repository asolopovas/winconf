[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepMissing
)

$ErrorActionPreference = 'Stop'

$backupDir = Join-Path $env:USERPROFILE 'winconf\tmp\path-backups'
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Test-UserScopedPath {
    param([string]$Path)
    $userRoot = [Environment]::GetFolderPath('UserProfile').TrimEnd('\')
    $usersRoot = Split-Path $userRoot -Parent
    return ($Path -like "$userRoot\*") -or ($Path -like "$usersRoot\*\AppData\*")
}

function Format-PathEntry {
    param([string]$Path)
    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    if ($expanded -match '\.\.' -and $expanded -match '^[A-Za-z]:') {
        try { return ([System.IO.Path]::GetFullPath($expanded)).TrimEnd('\') } catch { }
    }
    return $Path.TrimEnd('\')
}

function Get-SortedPath {
    param(
        [string]$Raw,
        [string[]]$ExcludeFromMachine = @(),
        [switch]$KeepMissing,
        [switch]$RelocateUserScoped
    )

    $entries = @()
    $relocated = @()
    if ($Raw) {
        $entries = $Raw -split ';' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ } |
            ForEach-Object { Format-PathEntry $_ }
        if ($RelocateUserScoped) {
            $entries = $entries | ForEach-Object {
                if (Test-UserScopedPath $_) {
                    Write-Host "  Relocating user-scoped - $_" -ForegroundColor DarkYellow
                    $relocated += $_
                } else { $_ }
            }
        }
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $unique = foreach ($e in $entries) { if ($seen.Add($e)) { $e } }

    $machineSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($m in $ExcludeFromMachine) { [void]$machineSet.Add($m) }

    $sysRoot = [Environment]::GetFolderPath('Windows').TrimEnd('\')
    $isSystem = { param($p) $p -like "$sysRoot*" -or $p -like '%SystemRoot%*' -or $p -like '%windir%*' }

    $crossDupes = 0
    $kept = foreach ($p in $unique) {
        if ($machineSet.Contains($p)) {
            Write-Host "  Removing cross-scope - $p" -ForegroundColor DarkYellow
            $crossDupes++
            continue
        }
        if (-not $KeepMissing) {
            $expanded = [Environment]::ExpandEnvironmentVariables($p)
            if (-not (Test-Path -LiteralPath $expanded)) {
                Write-Host "  Removing missing - $p" -ForegroundColor DarkYellow
                continue
            }
        }
        $p
    }

    $system = @($kept | Where-Object { & $isSystem $_ } | Sort-Object)
    $rest   = @($kept | Where-Object { -not (& $isSystem $_) } | Sort-Object)

    [pscustomobject]@{
        Joined     = (@($system) + @($rest)) -join ';'
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
        [string[]]$ExcludeFromMachine = @()
    )

    Write-Host "[$Scope PATH]" -ForegroundColor Cyan
    $raw = [Environment]::GetEnvironmentVariable('Path', $Scope)

    $backup = Join-Path $backupDir "$Scope-$stamp.txt"
    Set-Content -LiteralPath $backup -Value $raw -NoNewline -Encoding UTF8
    Write-Host "  Backup  - $backup" -ForegroundColor DarkGray

    $result = Get-SortedPath -Raw $raw -ExcludeFromMachine $ExcludeFromMachine -KeepMissing:$script:KeepMissing -RelocateUserScoped:($Scope -eq 'Machine')
    Write-Host ("  Entries - {0} kept, {1} dupes, {2} cross-scope, {3} missing, {4} relocated" -f $result.Count, $result.Dupes, $result.CrossDupes, $result.Missing, $result.Relocated.Count) -ForegroundColor DarkGray

    if ($Scope -eq 'User') {
        $sysIndicator = $result.Entries | Where-Object { $_ -like 'C:\Program Files*' -or $_ -like 'C:\ProgramData*' }
        foreach ($p in $sysIndicator) { Write-Host "  Note machine-scoped in User - $p" -ForegroundColor DarkCyan }
    }

    if ($result.Joined -eq $raw -and $result.Relocated.Count -eq 0) {
        Write-Host "  Already clean" -ForegroundColor Green
        return [pscustomobject]@{ Entries = $result.Entries; Relocated = $result.Relocated }
    }

    if ($PSCmdlet.ShouldProcess("$Scope PATH", 'Rewrite')) {
        [Environment]::SetEnvironmentVariable('Path', $result.Joined, $Scope)
        Write-Host "  Updated" -ForegroundColor Green
    }
    return [pscustomobject]@{ Entries = $result.Entries; Relocated = $result.Relocated }
}

if ($MyInvocation.InvocationName -eq '.') { return }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$machineEntries = @()
$relocatedToUser = @()
if (-not $isAdmin) {
    Write-Warning 'Not elevated — Machine PATH will be skipped (cross-scope dedup disabled).'
} else {
    $machineResult = Update-PathScope -Scope Machine
    $machineEntries = @($machineResult.Entries)
    $relocatedToUser = @($machineResult.Relocated)
}

if ($relocatedToUser.Count -gt 0) {
    $userRaw = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userParts = if ($userRaw) { $userRaw -split ';' | Where-Object { $_ } } else { @() }
    $newUserRaw = (@($userParts) + @($relocatedToUser)) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newUserRaw, 'User')
    Write-Host ("  Merged {0} relocated entries into User PATH" -f $relocatedToUser.Count) -ForegroundColor Green
}

[void](Update-PathScope -Scope User -ExcludeFromMachine $machineEntries)

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
Write-Host 'Session PATH refreshed.' -ForegroundColor Cyan
