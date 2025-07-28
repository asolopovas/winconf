$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\"
$registryValue = "DisabledComponents"
if (Test-Path -Path $registryPath) {
    $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValue -ErrorAction SilentlyContinue
    if ($currentValue.$registryValue -ne 0xFFFFFFFF) {
        Write-Host "IPv6 is currently enabled. Disabling IPv6..."
        Set-ItemProperty -Path $registryPath -Name $registryValue -Value 0xFFFFFFFF
    } else {
        Write-Host "IPv6 is currently disabled. Enabling IPv6..."
        Remove-ItemProperty -Path $registryPath -Name $registryValue
    }
} else {
    Write-Host "Registry path does not exist."
}
Write-Host "You may need to restart your computer for the changes to take effect. Would you like to restart now? (Y/N)"
$response = Read-Host
if ($response -eq 'Y') {
    Restart-Computer
}
