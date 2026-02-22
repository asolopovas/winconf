
$userPathsFile = "$env:USERPROFILE\winconf\.user-paths"

if (!(Test-Path $userPathsFile)) { return }

$additionalPaths = Get-Content $userPathsFile | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) }
$currentPaths = ($env:Path -split ';' | ForEach-Object { $_.TrimEnd('\') })

Write-Host "`nCurrent Paths:" -ForegroundColor Cyan
$currentPaths | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }


$newPaths = $additionalPaths | Where-Object { $_.TrimEnd('\') -notin $currentPaths }

foreach ($path in $newPaths) {
    Write-Host "Adding Path - $path" -ForegroundColor Green
}

if ($newPaths) {
    $updatedPath = ($currentPaths + $newPaths) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
}
