
$userPathsFile = "$env:USERPROFILE\winconf\.user-paths"

if (!(Test-Path $userPathsFile)) { return }

$additionalPaths = Get-Content $userPathsFile | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) }
$currentPaths = ($env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') })

$newPaths = $additionalPaths | Where-Object { $_.TrimEnd('\') -notin $currentPaths }

if (-not $newPaths) {
    Write-Host "  All custom paths already configured" -ForegroundColor DarkGray
    return
}

foreach ($path in $newPaths) {
    Write-Host "  Adding Path - $path" -ForegroundColor Green
}

$updatedPath = ($currentPaths + $newPaths) -join ';'
[Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
