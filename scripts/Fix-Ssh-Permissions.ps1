# Get the current user's .ssh directory
$sshDir = "$env:USERPROFILE\.ssh"

# Check if the .ssh directory exists
if (-Not (Test-Path $sshDir)) {
    Write-Host "The .ssh directory does not exist at $sshDir" -ForegroundColor Red
    exit 1
}

# Fix permissions for the .ssh directory
icacls $sshDir /inheritance:r | Out-Null
icacls $sshDir /grant:r $env:USERNAME:(F) | Out-Null
icacls $sshDir /remove:g "Authenticated Users" | Out-Null
icacls $sshDir /remove:g "Users" | Out-Null

# Fix permissions for all files in the .ssh directory
Get-ChildItem -Path $sshDir -Recurse | ForEach-Object {
    icacls $_.FullName /inheritance:r | Out-Null
    icacls $_.FullName /grant:r $env:USERNAME:(F) | Out-Null
    icacls $_.FullName /remove:g "Authenticated Users" | Out-Null
    icacls $_.FullName /remove:g "Users" | Out-Null
}

Write-Host "Permissions for $sshDir and its contents have been successfully fixed." -ForegroundColor Green
