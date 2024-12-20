# Function to check if running as Administrator
function Ensure-RunAsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Script is not running as Administrator. Attempting to relaunch..." -ForegroundColor Yellow
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Function to pause before exit
function Pause-BeforeExit {
    Write-Host "Press any key to close this window..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Ensure the script is running as Administrator
Ensure-RunAsAdmin

# Get the current user's .ssh directory
$sshDir = "$env:USERPROFILE\.ssh"
$userName = (whoami)

# Check if the .ssh directory exists
if (-Not (Test-Path $sshDir)) {
    Write-Host "The .ssh directory does not exist at $sshDir" -ForegroundColor Red
    Pause-BeforeExit
    exit 1
}

# Take ownership of the .ssh directory
Write-Host "Taking ownership of $sshDir..." -ForegroundColor Green
try {
    Start-Process -FilePath "icacls" -ArgumentList "`"$sshDir`" /setowner `"$userName`" /T /C" -NoNewWindow -Wait
    Write-Host "Ownership successfully updated for $sshDir." -ForegroundColor Green
} catch {
    Write-Host "Failed to take ownership of the .ssh directory: $($_.Exception.Message)" -ForegroundColor Red
    Pause-BeforeExit
    exit 1
}

# Fix permissions for the .ssh directory
Write-Host "Fixing permissions for $sshDir..." -ForegroundColor Green
try {
    icacls $sshDir /inheritance:r | Out-Null
    icacls $sshDir /grant "`"$userName`":F" | Out-Null
    icacls $sshDir /remove:g "Authenticated Users" | Out-Null
    icacls $sshDir /remove:g "Users" | Out-Null
} catch {
    Write-Host "Failed to fix permissions for the .ssh directory: $($_.Exception.Message)" -ForegroundColor Red
    Pause-BeforeExit
    exit 1
}

# Fix permissions for all files in the .ssh directory
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
    Pause-BeforeExit
    exit 1
}

Write-Host "Permissions for $sshDir and its contents have been successfully fixed." -ForegroundColor Green
Pause-BeforeExit
