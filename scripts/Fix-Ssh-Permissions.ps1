function Test-RunAsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Script is not running as Administrator. Attempting to relaunch..." -ForegroundColor Yellow
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

function Wait-BeforeExit {
    Write-Host "Press any key to close this window..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Test-RunAsAdmin

$sshDir = "$env:USERPROFILE\.ssh"
$userName = (whoami)

if (-Not (Test-Path $sshDir)) {
    Write-Host "The .ssh directory does not exist at $sshDir" -ForegroundColor Red
    Wait-BeforeExit
    exit 1
}

Write-Host "Taking ownership of $sshDir..." -ForegroundColor Green
try {
    Start-Process -FilePath "icacls" -ArgumentList "`"$sshDir`" /setowner `"$userName`" /T /C" -NoNewWindow -Wait
    Write-Host "Ownership successfully updated for $sshDir." -ForegroundColor Green
} catch {
    Write-Host "Failed to take ownership of the .ssh directory: $($_.Exception.Message)" -ForegroundColor Red
    Wait-BeforeExit
    exit 1
}

Write-Host "Fixing permissions for $sshDir..." -ForegroundColor Green
try {
    icacls $sshDir /inheritance:r | Out-Null
    icacls $sshDir /grant "`"$userName`":F" | Out-Null
    icacls $sshDir /remove:g "Authenticated Users" | Out-Null
    icacls $sshDir /remove:g "Users" | Out-Null
} catch {
    Write-Host "Failed to fix permissions for the .ssh directory: $($_.Exception.Message)" -ForegroundColor Red
    Wait-BeforeExit
    exit 1
}

Write-Host "Fixing permissions for files in $sshDir..." -ForegroundColor Green
try {
    Get-ChildItem -Path $sshDir -Recurse -ErrorAction Stop | ForEach-Object {
        icacls $_.FullName /inheritance:r | Out-Null
        icacls $_.FullName /grant "`"$userName`":F" | Out-Null
        icacls $_.FullName /remove:g "Authenticated Users" | Out-Null
        icacls $_.FullName /remove:g "Users" | Out-Null
    }
} catch {
    Write-Host "Failed to fix permissions for files in the .ssh directory: $($_.Exception.Message)" -ForegroundColor Red
    Wait-BeforeExit
    exit 1
}

Write-Host "Permissions for $sshDir and its contents have been successfully fixed." -ForegroundColor Green
Wait-BeforeExit
