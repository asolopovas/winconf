# Define the folders to exclude
$excludeFolders = @(
    "C:\Programm Files\Docker",
    "\\wsl$\Ubuntu\home\andrius\src",
    "\\wsl$\Ubuntu\home\andrius\www",
    "\\wsl.localhost\Ubuntu\home\andrius\src"
)

# Define the file types to exclude
$excludeFileTypes = @(
    "vhd",
    "vhdx"
)

# Define the processes to exclude
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

# Iterate over each folder and exclude
foreach ($folder in $excludeFolders) {
    Add-MpPreference -ExclusionPath $folder
}

# Iterate over each file type and exclude
foreach ($fileType in $excludeFileTypes) {
    Add-MpPreference -ExclusionExtension $fileType
}

# Iterate over each process and exclude
foreach ($process in $excludeProcesses) {
    Add-MpPreference -ExclusionProcess $process
}
