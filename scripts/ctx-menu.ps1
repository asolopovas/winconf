$registryPath = "HKCU:\Software\Classes\CLSID"
$guidKey = "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
New-Item -Path "$registryPath\$guidKey" -Force
New-Item -Path "$registryPath\$guidKey\InprocServer32" -Force
Set-ItemProperty -Path "$registryPath\$guidKey\InprocServer32" -Name "(Default)" -Value ""
