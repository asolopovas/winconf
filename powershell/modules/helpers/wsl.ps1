function DistroRemove($name) {
    wsl.exe -t $name
    wsl.exe --unregister $name
}

function DistroImport ($name, $path) {
    $mydocs = [Environment]::GetFolderPath("MyDocuments")
    if (-Not (Test-Path "$mydocs\WSLDATA")) {
        New-Item -Path $mydocs -Name "WSLDATA" -ItemType "directory"
    }
    if (-Not (Test-Path "$mydocs\WSLDATA\$name") ) {
        New-Item -Path "$mydocs\WSLDATA" -Name $name -ItemType "directory"
    }
    wsl.exe --import $name "$mydocs\WSLDATA\$name" $path
}
