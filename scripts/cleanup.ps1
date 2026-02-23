$bloatwarePackages = @(
    "*Microsoft.3dbuilder*",
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*",
    "*Microsoft.WindowsAlarms*",
    "*Microsoft.Asphalt8Airborne*",
    "*microsoft.windowscommunicationsapps*",
    "*Microsoft.WindowsCamera*",
    "*king.com.CandyCrushSodaSaga*",
    "*Microsoft.DrawboardPDF*",
    "*Facebook*",
    "*Microsoft.OneDriveSync*",
    "*BethesdaSoftworks.FalloutShelter*",
    "*FarmVille2CountryEscape*",
    "*Microsoft.WindowsFeedbackHub*",
    "*Microsoft.GetHelp*",
    "*Microsoft.Getstarted*",
    "*Microsoft.ZuneMusic*",
    "*Microsoft.WindowsMaps*",
    "*Microsoft.Messaging*",
    "*Microsoft.Wallet*",
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*ConnectivityStore*",
    "*MinecraftUWP*",
    "*Microsoft.OneConnect*",
    "*Microsoft.BingFinance*",
    "*Microsoft.ZuneVideo*",
    "*Microsoft.BingNews*",
    "*Microsoft.MicrosoftOfficeHub*",
    "*Netflix*",
    "*OneNote*",
    "*Microsoft.MSPaint*",
    "*PandoraMediaInc*",
    "*Microsoft.People*",
    "*CommsPhone*",
    "*windowsphone*",
    "*Microsoft.Print3D*",
    "*flaregamesGmbH.RoyalRevolt2*",
    "*WindowsScan*",
    "*MixedReality*",
    "*AutodeskSketchBook*",
    "*Microsoft.SkypeApp*",
    "*bingsports*",
    "*YourPhone*",
    "*Office.Sway*",
    "*MicrosoftStickyNotes*",
    "*Twitter*",
    "*ScreenSketch*",
    "*Microsoft3DViewer*",
    "*Microsoft.WindowsSoundRecorder*",
    "*Microsoft.BingWeather*"
)

$installedApps = Get-AppxPackage -ErrorAction SilentlyContinue
$removed = 0

foreach ($pattern in $bloatwarePackages) {
    $matches = $installedApps | Where-Object { $_.Name -like $pattern }
    foreach ($app in $matches) {
        Write-Host "  Removing $($app.Name)..." -ForegroundColor Yellow
        $app | Remove-AppxPackage -ErrorAction SilentlyContinue
        $removed++
    }
}

if ($removed -eq 0) {
    Write-Host "  No bloatware found to remove" -ForegroundColor DarkGray
}

$telemetryServices = @(
    @{ Name = "ESRV_SVC_QUEENCREEK"; Display = "Intel Energy Server" },
    @{ Name = "SystemUsageReportSvc_QUEENCREEK"; Display = "Intel System Usage Report" },
    @{ Name = "IntelGraphicsSoftwareService"; Display = "Intel Graphics Software Service" },
    @{ Name = "DiagTrack"; Display = "Connected User Experiences and Telemetry" },
    @{ Name = "SysMain"; Display = "Superfetch" },
    @{ Name = "Bonjour Service"; Display = "Bonjour Service" }
)

foreach ($svc in $telemetryServices) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service -and $service.StartType -ne 'Manual' -and $service.StartType -ne 'Disabled') {
        Set-Service -Name $svc.Name -StartupType Manual
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Write-Host "  Disabled $($svc.Display)" -ForegroundColor Yellow
    } elseif (-not $service) {
        Write-Host "  $($svc.Display) not found, skipping" -ForegroundColor DarkGray
    } else {
        Write-Host "  $($svc.Display) already disabled" -ForegroundColor DarkGray
    }
}

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR -ErrorAction SilentlyContinue | Out-Null

$registryKeys = @(
    "HKCR:\Directory\Background\shell\git_shell"
    "HKCR:\Directory\Background\shell\git_gui"
    "HKCR:\Directory\shell\git_shell"
    "HKCR:\Directory\shell\git_gui"
    "HKCR:\Directory\shell\ShareX"
    "HKCR:\Directory\shell\CaptureOne"
)

foreach ($key in $registryKeys) {
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force -Verbose
    }
}
