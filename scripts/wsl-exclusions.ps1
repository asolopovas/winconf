$excludeFolders = @(
    "C:\Program Files\Docker",
    "\\wsl$\Ubuntu\home\andrius\src",
    "\\wsl$\Ubuntu\home\andrius\www",
    "\\wsl.localhost\Ubuntu\home\andrius\src"
)

$excludeFileTypes = @(
    "vhd",
    "vhdx"
)

$excludeProcesses = @(
    "pycharm64.exe",
    "dataspell64.exe",
    "fsnotifier.exe",
    "jcef_helper.exe",
    "jetbrains-toolbox.exe",
    "docker.exe",
    "com.docker.*.*",
    "Desktop Docker.exe",
    "wsl.exe",
    "wslhost.exe",
    "vmmemWSL"
)

$prefs = Get-MpPreference -ErrorAction SilentlyContinue
if (-not $prefs) {
    Write-Host "  Could not read Defender preferences" -ForegroundColor Yellow
    return
}

$currentPaths = @($prefs.ExclusionPath)
$currentExts = @($prefs.ExclusionExtension)
$currentProcs = @($prefs.ExclusionProcess)

$newPaths = $excludeFolders | Where-Object { $_ -notin $currentPaths }
$newExts = $excludeFileTypes | Where-Object { $_ -notin $currentExts }
$newProcs = $excludeProcesses | Where-Object { $_ -notin $currentProcs }

if (-not $newPaths -and -not $newExts -and -not $newProcs) {
    Write-Host "  All Defender exclusions already configured" -ForegroundColor DarkGray
    return
}

foreach ($folder in $newPaths) {
    Write-Host "  Adding path exclusion: $folder" -ForegroundColor DarkGray
    Add-MpPreference -ExclusionPath $folder
}

foreach ($fileType in $newExts) {
    Write-Host "  Adding extension exclusion: $fileType" -ForegroundColor DarkGray
    Add-MpPreference -ExclusionExtension $fileType
}

foreach ($process in $newProcs) {
    Write-Host "  Adding process exclusion: $process" -ForegroundColor DarkGray
    Add-MpPreference -ExclusionProcess $process
}
