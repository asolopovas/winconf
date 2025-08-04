#!/usr/bin/env pwsh
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$PublicKey
)

$ErrorActionPreference = "Stop"

# Validate SSH key format
if (-not ($PublicKey -match '^ssh-(rsa|ed25519|ecdsa|dss)\s+[\w+/=]+(\s+.+)?$')) {
    Write-Error "Invalid SSH public key format"
    exit 1
}

$sshDir = "C:\ProgramData\ssh"
$authKeysFile = Join-Path $sshDir "administrators_authorized_keys"

# Create SSH directory if it doesn't exist
if (-not (Test-Path $sshDir)) {
    Write-Host "Creating SSH directory: $sshDir"
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# Add the public key to authorized_keys file
Write-Host "Adding SSH key to: $authKeysFile"
Add-Content -Path $authKeysFile -Value $PublicKey -Encoding UTF8

# Set proper permissions using icacls
Write-Host "Setting proper permissions..."
$icaclsCmd = @(
    "`"$authKeysFile`"",
    "/inheritance:r",
    "/grant", "`"Administrators:F`"",
    "/grant", "`"SYSTEM:F`""
)

$result = & icacls.exe $icaclsCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set permissions on $authKeysFile"
    exit 1
}

Write-Host "Successfully added SSH key and configured permissions"
Write-Host "Permissions set:"
Write-Host "  - NT AUTHORITY\SYSTEM: Full Control"
Write-Host "  - BUILTIN\Administrators: Full Control"
