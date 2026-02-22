function Set-DevtoolDevices {
    $configPath = "Z:\My Drive\configs\Preferences"
    if (-not (Test-Path $configPath)) {
        Write-Error "Source config not found: $configPath"
        return
    }

    $source = Get-Content $configPath -Raw | ConvertFrom-Json
    $custom = $source.devtools.preferences.'custom-emulated-device-list'
    $standard = $source.devtools.preferences.'standard-emulated-device-list'

    if (-not $custom -and -not $standard) {
        Write-Warning "No device lists found in source config."
        return
    }

    $browsers = @{
        Brave  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences"
        Chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences"
        Edge   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Preferences"
    }

    foreach ($entry in $browsers.GetEnumerator()) {
        if (-not (Test-Path $entry.Value)) { continue }

        $prefs = Get-Content $entry.Value -Raw | ConvertFrom-Json

        if ($null -eq $prefs.devtools) {
            $prefs | Add-Member -NotePropertyName "devtools" -NotePropertyValue ([PSCustomObject]@{})
        }
        if ($null -eq $prefs.devtools.preferences) {
            $prefs.devtools | Add-Member -NotePropertyName "preferences" -NotePropertyValue ([PSCustomObject]@{})
        }

        $p = $prefs.devtools.preferences
        foreach ($key in @('custom-emulated-device-list', 'standard-emulated-device-list')) {
            if ($null -eq $p.$key) {
                $p | Add-Member -NotePropertyName $key -NotePropertyValue ""
            }
        }

        $p.'custom-emulated-device-list' = $custom
        $p.'standard-emulated-device-list' = $standard

        $prefs | ConvertTo-Json -Depth 100 | Set-Content $entry.Value
        Write-Host "Updated $($entry.Key)" -ForegroundColor Green
    }
}
