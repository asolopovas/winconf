function RenameWithTimestamp($path) {
    $creationTime = (Get-Item $path).CreationTime
    $timestamp = $creationTime.ToString('yyyy-MM-dd-HHmm')
    $directory = [System.IO.Path]::GetDirectoryName($path)
    $extension = [System.IO.Path]::GetExtension($path)
    $filenameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($path)
    $newFilename = "$timestamp - $filenameWithoutExtension$extension"
    $newPath = Join-Path -Path $directory -ChildPath $newFilename
    Rename-Item -Path $path -NewName $newPath | Out-Null
}


function EnsureWSLDir {
    $wslDataDir = "C:\WSL"
    if (-Not (Test-Path $wslDataDir)) {
        New-Item -Path $wslDataDir -ItemType "directory"
    }
    return $wslDataDir
}

function WslRemove($name) {
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

function WslImport($name) {
    try {
        $wslDataDir = EnsureWSLDir
        $backupDir = Join-Path -Path $wslDataDir -ChildPath "backups"

        $namePattern = "*$name*.tar.gz"
        $backups = Get-ChildItem -Path $backupDir -Filter $namePattern

        if ($backups.Count -eq 0) {
            Write-Error "No backups found for distro $name in $backupDir"
            return
        }

        $selectedBackup = $backups |
        Select-Object Name |
        Out-GridView -Title "Select a backup to import" -OutputMode Single

        if ($null -eq $selectedBackup) {
            Write-Output "No backup selected. Import operation cancelled."
            return
        }

        $backupFile = Join-Path -Path $backupDir -ChildPath $selectedBackup.Name

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

function WslExport($name) {
    try {
        $wslDataDir = EnsureWSLDir
        $backupDir = Join-Path -Path $wslDataDir -ChildPath "backups"
        if (-Not (Test-Path $backupDir)) {
            New-Item -Path $wslDataDir -Name "backups" -ItemType "directory"
        }
        $backupFile = Join-Path -Path $backupDir -ChildPath "${name}.tar.gz"

        if (Test-Path $backupFile) {
            RenameWithTimestamp $backupFile
        }

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
