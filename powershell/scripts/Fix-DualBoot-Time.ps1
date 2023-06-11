# Set UTC Time Zone
$registryPath = "registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"
$name = "RealTimeIsUniversal"
$value = "1"
if (!(Test-RegistryValue -Path $registryPath -Value $name)) {
    New-ItemProperty -Path $registryPath -Name $name -Value $value `
                 -PropertyType DWORD -Force | Out-Null
}
