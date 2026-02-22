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
