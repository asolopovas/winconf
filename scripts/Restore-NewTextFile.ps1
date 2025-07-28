# Set the registry path
$registryPath = "HKCU:\Software\Classes\CLSID"

# Create the first key with the given GUID
$guidKey = "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
New-Item -Path "$registryPath\$guidKey" -Force

# Create the InprocServer32 key
New-Item -Path "$registryPath\$guidKey\InprocServer32" -Force

# Set the default value of the InprocServer32 key to null
Set-ItemProperty -Path "$registryPath\$guidKey\InprocServer32" -Name "(Default)" -Value ""

# Reboot the computer
# Restart-Computer -Force
