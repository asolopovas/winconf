
$userPathsFile = "$env:USERPROFILE\winconf\.user-paths"

if (!(Test-Path $userPathsFile)) { return }

$additionalPaths = Get-Content $userPathsFile |
    Where-Object { $_ -and -not $_.StartsWith('#') } |
    ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_.Trim()) } |
    Where-Object { $_ }

# Operate on the User PATH scope only — not the merged process $env:Path,
# otherwise Machine entries leak into User and entries already in Machine
# are wrongly skipped.
$userPathRaw = [Environment]::GetEnvironmentVariable('Path', 'User')
$userPaths = @()
if ($userPathRaw) {
    $userPaths = $userPathRaw -split ';' |
        Where-Object { $_ } |
        ForEach-Object { $_.TrimEnd('\') }
}

# Deduplicate existing User PATH (case-insensitive) while preserving order.
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$dedupedUser = foreach ($p in $userPaths) { if ($seen.Add($p)) { $p } }

$newPaths = foreach ($p in $additionalPaths) {
    $trimmed = $p.TrimEnd('\')
    if ($seen.Add($trimmed)) { $trimmed }
}

if (-not $newPaths -and ($dedupedUser.Count -eq $userPaths.Count)) {
    Write-Host "  All custom paths already configured" -ForegroundColor DarkGray
    return
}

foreach ($path in $newPaths) {
    Write-Host "  Adding Path - $path" -ForegroundColor Green
}

if ($dedupedUser.Count -ne $userPaths.Count) {
    Write-Host ("  Removing {0} duplicate User PATH entries" -f ($userPaths.Count - $dedupedUser.Count)) -ForegroundColor DarkYellow
}

$updatedPath = (@($dedupedUser) + @($newPaths)) -join ';'
[Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')

# Refresh current session so subsequent scripts in this run see the change.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $updatedPath
