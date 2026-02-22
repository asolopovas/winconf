function Set-DevtoolDevices {
    $configPath = "Z:\My Drive\configs\Preferences"
    if (-not (Test-Path $configPath)) {
        Write-Error "Source config not found: $configPath"
        return
    }

    $source = Get-Content $configPath -Raw | ConvertFrom-Json
    $custom = $source.devtools.preferences.'custom-emulated-device-list'

    if (-not $custom) {
        Write-Warning "No custom device list found in source config."
        return
    }

    $browsers = @(
        @{ Name = "Brave";  Process = "brave";  Path = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences" }
        @{ Name = "Chrome"; Process = "chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences" }
        @{ Name = "Edge";   Process = "msedge"; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Preferences" }
    )

    $running = @()
    foreach ($browser in $browsers) {
        if (-not (Test-Path $browser.Path)) { continue }
        if (Get-Process $browser.Process -ErrorAction SilentlyContinue) {
            $running += $browser
        }
    }

    if ($running.Count -gt 0) {
        Write-Host "Closing browsers: $($running.Name -join ', ')" -ForegroundColor Yellow
        foreach ($browser in $running) {
            Stop-Process -Name $browser.Process -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }

    foreach ($browser in $browsers) {
        if (-not (Test-Path $browser.Path)) { continue }

        $prefs = Get-Content $browser.Path -Raw | ConvertFrom-Json

        if ($null -eq $prefs.devtools) {
            $prefs | Add-Member -NotePropertyName "devtools" -NotePropertyValue ([PSCustomObject]@{})
        }
        if ($null -eq $prefs.devtools.preferences) {
            $prefs.devtools | Add-Member -NotePropertyName "preferences" -NotePropertyValue ([PSCustomObject]@{})
        }

        $p = $prefs.devtools.preferences
        if ($null -eq $p.'custom-emulated-device-list') {
            $p | Add-Member -NotePropertyName 'custom-emulated-device-list' -NotePropertyValue ""
        }

        $p.'custom-emulated-device-list' = $custom

        $std = $p.'standard-emulated-device-list'
        if ($std) {
            $stdDevices = $std | ConvertFrom-Json
            $seen = @{}
            $deduped = @()
            foreach ($device in $stdDevices) {
                if (-not $seen.ContainsKey($device.title)) {
                    $seen[$device.title] = $true
                    $deduped += $device
                }
            }
            if ($deduped.Count -ne $stdDevices.Count) {
                $p.'standard-emulated-device-list' = $deduped | ConvertTo-Json -Depth 50 -Compress
            }
        }

        $prefs | ConvertTo-Json -Depth 100 | Set-Content $browser.Path
        Write-Host "Updated $($browser.Name)" -ForegroundColor Green
    }

    foreach ($browser in $running) {
        Start-Process $browser.Process
    }
}
