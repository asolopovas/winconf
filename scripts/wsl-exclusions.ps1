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

foreach ($folder in $excludeFolders) {
    Add-MpPreference -ExclusionPath $folder
}

foreach ($fileType in $excludeFileTypes) {
    Add-MpPreference -ExclusionExtension $fileType
}

foreach ($process in $excludeProcesses) {
    Add-MpPreference -ExclusionProcess $process
}
