function EnsureWSLDir {
    $wslDataDir = "C:\WSL"
    if (-Not (Test-Path $wslDataDir)) {
        New-Item -Path $wslDataDir -ItemType "directory"
    }
    return $wslDataDir
}

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
        }
        else {
            Write-Output "Distro $name removed successfully"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

function DistroImport($name) {
    try {
        $wslDataDir = EnsureWSLDir
        $backupDir = Join-Path -Path $wslDataDir -ChildPath "backups"
        $backupFile = Join-Path -Path $backupDir -ChildPath "${name}.tar.gz"

        if (-Not (Test-Path $backupFile)) {
            Write-Error "Backup not found for distro $name in $backupDir"
            return
        }

        $distroDir = Join-Path -Path $wslDataDir -ChildPath $name
        if (-Not (Test-Path $distroDir)) {
            New-Item -Path $wslDataDir -Name $name -ItemType "directory"
        }

        wsl.exe --import $name $distroDir $backupFile
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

function DistroExport($name) {
    try {
        $wslDataDir = EnsureWSLDir
        $backupDir = Join-Path -Path $wslDataDir -ChildPath "backups"
        if (-Not (Test-Path $backupDir)) {
            New-Item -Path $wslDataDir -Name "backups" -ItemType "directory"
        }
        $backupFile = Join-Path -Path $backupDir -ChildPath "${name}.tar.gz"

        wsl.exe --export $name $backupFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to export distro $name"
        }
        else {
            Write-Output "Distro $name exported successfully to $backupFile"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
