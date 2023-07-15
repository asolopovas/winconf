function Test-EnvPath() {

    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Machine
    )

    $LOC = $Machine ? [EnvironmentVariableTarget]::Machine : [EnvironmentVariableTarget]::User
    $ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $LOC)

    return $ENV_PATH.Contains($Path)
}

function Add-ShellContext($name, $exe, $context = 'dir') {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
    $direReg = "HKCR:\Directory\Background\shell"
    $fileReg = "HKCR:\``*\shell"
    if ($context -eq 'dir') {
        New-ShellContextItem $name $direReg $exe
    }
    else {
        New-ShellContextItem $name $fileReg $exe
    }
}

function Add-StartupItem($progValue, $progName) {
    $name = Get-RootName $progName
    $registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"

    New-ItemProperty -Path $registryPath -Name $name -Value $progValue `
        -PropertyType String -Force | Out-Null
}
function Add-AdminShortcut($targetPath, $shortcutPath) {
    $targetPath = (Resolve-Path $targetPath).Path
    $shortcutPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($shortcutPath)
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $targetPath
    $Shortcut.WorkingDirectory = Split-Path $targetPath
    $Shortcut.Save()

    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
}

function Add-ToPath {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($currentPath -notlike "*$Path*") {
        $newPath = $currentPath + ";" + $Path
        [Environment]::SetEnvironmentVariable("Path", $newPath, "user")
    }
    else {
        Write-Host "Path already exists in system path."
    }
}

function Add-ToPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Machine,
        [Parameter(Mandatory = $false)]
        [switch]$Remove
    )

    $LOC = $Machine ? [EnvironmentVariableTarget]::Machine : [EnvironmentVariableTarget]::User
    $ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $LOC)
    $PATH = Resolve-Path $Path
    $LOCATION = $Machine ? "System's" : "User's"

    if (!(Test-EnvPath $PATH)) {
        [Environment]::SetEnvironmentVariable("Path", "$ENV_PATH;$PATH", $LOC)
        Write-Host "Added '$PATH' to $LOCATION path."
    }
    else {
        Write-Host "Already '$PATH' in $LOCATION Path variable."
    }
}

function RefreshUserPath ($envFilePath = "$env:USERPROFILE\winconf\.sys-env") {
    $paths = Get-Content $envFilePath
    $currentPaths = $env:Path -split ';' | ForEach-Object { $_.TrimEnd('\').ToLower() }

    foreach ($path in $paths) {
        $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)
        $normalizedPath = $expandedPath.TrimEnd('\').ToLower()

        if ((Test-Path -Path $expandedPath) -and ($currentPaths -notcontains $normalizedPath)) {
            Add-ToPath -Path $expandedPath
        }
    }
}

function sysConf {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('save', 'pull')]
        [string]$action
    )

    $wsl_user = wsl whoami
    $win_user = [Environment]::UserName
    $WSLPaths = @("/home/$wsl_user/dotfiles", "/home/$wsl_user/www/dev")
    $WinPaths = @("C:/Users/$win_user/winconf")
    $message = "Save changes"

    switch ($action) {
        "save" {
            foreach ($path in $WSLPaths) {
                Write-Output "Saving to git: $path ..."
                wsl git -C $path add .
                wsl git -C $path commit -m $message
            }

            foreach ($winpath in $WinPaths) {
                Write-Output "Saving to git: $winpath ..."
                git -C $winpath add .
                git -C $winpath commit -m $message
            }
        }
        "pull" {
            foreach ($path in $WSLPaths) {
                Write-Output "Pulling from git: $path ..."
                wsl git -C $path pull
            }

            foreach ($winpath in $WinPaths) {
                Write-Output "Pulling from git: $winpath ..."
                git -C $winpath pull
            }
        }
    }

    # Usage:
    # Manage-Git save
    # Manage-Git pull

}
