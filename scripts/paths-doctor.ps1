[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepMissing
)

$ErrorActionPreference = 'Stop'

$backupDir = Join-Path $env:USERPROFILE 'winconf\tmp\path-backups'
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Get-SortedPath {
    param(
        [string]$Raw,
        [string[]]$ExcludeFromMachine = @(),
        [switch]$KeepMissing
    )

    $entries = @()
    if ($Raw) {
        $entries = $Raw -split ';' |
            ForEach-Object { $_.Trim().TrimEnd('\') } |
            Where-Object { $_ }
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

    $result = Get-SortedPath -Raw $raw -ExcludeFromMachine $ExcludeFromMachine -KeepMissing:$script:KeepMissing
    Write-Host ("  Entries - {0} kept, {1} dupes, {2} cross-scope, {3} missing" -f $result.Count, $result.Dupes, $result.CrossDupes, $result.Missing) -ForegroundColor DarkGray

    if ($result.Joined -eq $raw) {
        Write-Host "  Already clean" -ForegroundColor Green
        return $result.Entries
    }

    if ($PSCmdlet.ShouldProcess("$Scope PATH", 'Rewrite')) {
        [Environment]::SetEnvironmentVariable('Path', $result.Joined, $Scope)
        Write-Host "  Updated" -ForegroundColor Green
    }
    return $result.Entries
}

if ($MyInvocation.InvocationName -eq '.') { return }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$machineEntries = @()
if (-not $isAdmin) {
    Write-Warning 'Not elevated — Machine PATH will be skipped (cross-scope dedup disabled).'
} else {
    $machineEntries = @(Update-PathScope -Scope Machine)
}

[void](Update-PathScope -Scope User -ExcludeFromMachine $machineEntries)

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
Write-Host 'Session PATH refreshed.' -ForegroundColor Cyan
