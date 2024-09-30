function Get-DevtoolDevices {
    param (
        [string]$ChromeConfigPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences",
        [string]$DevtoolsDevicesConfig = "./devtools-devices.json"
    )

    $sourceContent = Get-Content -Path $ChromeConfigPath -Raw | ConvertFrom-Json
    $customDeviceList = $sourceContent.devtools.preferences.'custom-emulated-device-list'
    $standardDeviceList = $sourceContent.devtools.preferences.'standard-emulated-device-list'

    $deviceData = @{
        customDevices = $customDeviceList
        standardDevices = $standardDeviceList
    }

    if ($null -ne $deviceData.customDevices -or $null -ne $deviceData.standardDevices) {
        $deviceData | ConvertTo-Json -Depth 100 | Set-Content -Path $DevtoolsDevicesConfig
    }
}

function Set-DevtoolDevices {
    param (
        [string]$ChromeConfigPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences",
        [string]$DevtoolsDevicesConfig = "./devtools-devices.json"
    )

    $inputContent = Get-Content -Path $DevtoolsDevicesConfig -Raw | ConvertFrom-Json
    $targetContent = Get-Content -Path $ChromeConfigPath -Raw | ConvertFrom-Json

    if ($null -ne $inputContent) {
        if ($null -eq $targetContent.devtools) {
            $targetContent | Add-Member -Type NoteProperty -Name "devtools" -Value @{ }
        }
        if ($null -eq $targetContent.devtools.preferences) {
            $targetContent.devtools | Add-Member -Type NoteProperty -Name "preferences" -Value @{ }
        }
        if ($null -eq $targetContent.devtools.preferences.'custom-emulated-device-list') {
            $targetContent.devtools.preferences | Add-Member -Type NoteProperty -Name 'custom-emulated-device-list' -Value @()
        }
        if ($null -eq $targetContent.devtools.preferences.'standard-emulated-device-list') {
            $targetContent.devtools.preferences | Add-Member -Type NoteProperty -Name 'standard-emulated-device-list' -Value @()
        }

        $targetContent.devtools.preferences.'custom-emulated-device-list' = $inputContent.customDevices
        $targetContent.devtools.preferences.'standard-emulated-device-list' = $inputContent.standardDevices

        $targetContent | ConvertTo-Json -Depth 100 | Set-Content -Path $ChromeConfigPath
    }
}

