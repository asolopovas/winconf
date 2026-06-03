function Write-Status {
    param(
        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]$Message = '',

        [ConsoleColor]$ForegroundColor
    )

    $null = $ForegroundColor
    Write-Information $Message -InformationAction Continue
}

$userPathsFile = "$env:USERPROFILE\winconf\.user-paths"

if (-not (Test-Path -LiteralPath $userPathsFile)) { return }

$additionalPaths = Get-Content $userPathsFile |
    Where-Object { $_ -and -not $_.StartsWith('#') } |
    ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_.Trim()) } |
    Where-Object { $_ }

$userPathRaw = [Environment]::GetEnvironmentVariable('Path', 'User')
$userPaths = @()
if ($userPathRaw) {
    $userPaths = $userPathRaw -split ';' |
        Where-Object { $_ } |
        ForEach-Object { $_.TrimEnd('\') }
}

$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$dedupedUser = foreach ($p in $userPaths) { if ($seen.Add($p)) { $p } }

$newPaths = foreach ($p in $additionalPaths) {
    $trimmed = $p.TrimEnd('\')
    if ($seen.Add($trimmed)) { $trimmed }
}

if (-not $newPaths -and ($dedupedUser.Count -eq $userPaths.Count)) {
    Write-Status "  All custom paths already configured" -ForegroundColor DarkGray
    return
}

foreach ($path in $newPaths) {
    Write-Status "  Adding Path - $path" -ForegroundColor Green
}

if ($dedupedUser.Count -ne $userPaths.Count) {
    Write-Status ("  Removing {0} duplicate User PATH entries" -f ($userPaths.Count - $dedupedUser.Count)) -ForegroundColor DarkYellow
}

$updatedPath = (@($dedupedUser) + @($newPaths)) -join ';'
[Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $updatedPath
