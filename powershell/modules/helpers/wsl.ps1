function DistroRemove($name) {
    try {
        wsl.exe -t $name
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to terminate distro $name"
            return
        }
        wsl.exe --unregister $name
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to unregister distro $name"
        } else {
            Write-Output "Distro $name removed successfully"
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}

function DistroImport ($name, $path) {
    try {
        $wslDataDir = "C:\WSL"

        if (-Not (Test-Path $wslDataDir)) {
            New-Item -Path $wslDataDir -ItemType "directory"
        }

        $distroDir = Join-Path -Path $wslDataDir -ChildPath $name
        if (-Not (Test-Path $distroDir)) {
            New-Item -Path $wslDataDir -Name $name -ItemType "directory"
        }

        wsl.exe --import $name $distroDir $path
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to import distro $name"
        }
        else {
            Write-Output "Distro $name imported successfully"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}


function DistroExport($name, $path) {
    try {
        wsl.exe --export $name $path
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to export distro $name"
        } else {
            Write-Output "Distro $name exported successfully"
        }
    } catch {
        Write-Error $_.Exception.Message
    }
}
