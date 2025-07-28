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

function Add-StartupItem($progValue, $progName) {
    $name = Get-RootName $progName
    $registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"

    New-ItemProperty -Path $registryPath -Name $name -Value $progValue `
        -PropertyType String -Force | Out-Null
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

    $LOC = if ($Machine) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $LOC)
    $PATH = Resolve-Path $Path -ErrorAction SilentlyContinue
    $LOCATION = if ($Machine) { "System's" } else { "User's" }


    if (!(Test-EnvPath $PATH)) {
        if ($PATH) {
            [Environment]::SetEnvironmentVariable("Path", "$ENV_PATH;$PATH", $LOC)
            Write-Host "Added '$PATH' to $LOCATION path."
        }
    }
    else {
        Write-Host "Already '$PATH' in $LOCATION Path variable."
    }
}

function Clear-EventLogs {
    wevtutil el | Foreach-Object { wevtutil cl "$_" }
}

function Enable-Feature($features) {
    if ($features -is [system.array]) {
        foreach ($featureName in $features) {
            Write-Output "Enabling $featureName ..."
            $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName
            if ($feature.State -eq "Disabled") {
                Write-Output "Enabling $feature`n"
                Enable-WindowsOptionalFeature -Online -FeatureName $featureName
            }
        }
    }
    else {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $features
        if ($feature.State -eq "Disabled") {
            Write-Output "Enabling $features ...`n"
            Enable-WindowsOptionalFeature -Online -FeatureName $features
        }
    }
}

function Find-LockingProcess {
    Param
    (
        [Parameter(Mandatory = $true)]
        [String] $FileOrFolderPath
    )
    If ((Test-Path -Path $FileOrFolderPath) -eq $false) {
        Write-Warning "File or directory does not exist."
    }
    Else {
        $LockingProcess = CMD /C "openfiles /query /fo table | find /I ""$FileOrFolderPath"""
        Write-Host $LockingProcess
    }

}
function RefreshUserPath ($envFilePath = "$env:USERPROFILE\winconf\.user-paths") {
    $paths = Get-Content $envFilePath
    $currentPaths = $env:Path -split ';' | ForEach-Object { $_.TrimEnd('\').ToLower() }

    foreach ($path in $paths) {
        $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)
        $normalizedPath = $expandedPath.TrimEnd('\').ToLower()

        Add-ToPath -Path $expandedPath
    }
}

function Repair-Windows() {
    sfc /scannow
    Dism /Online /Cleanup-Image /RestoreHealth
    sfc /scannow
}

function Restart-Explorer {
    taskkill.exe /f /im explorer.exe
    Start-Process explorer.exe
}

function Start-AsAdmin($path) {
    if ($path) {
        Start-Process powershell -verb runas -ArgumentList ("-file " + (Get-ChildItem $path).fullname)
    }
}

function SortEnvPaths {
    param (
        [switch]$Machine
    )

    $target = if ($Machine) { "Machine" } else { "User" }

    $envPaths = [Environment]::GetEnvironmentVariable("PATH", $target)

    $sortedEnvPaths = $envPaths -split ";" | Where-Object { $_ } | Sort-Object

    $sortedEnvPaths = $sortedEnvPaths -join ";"

    [Environment]::SetEnvironmentVariable("PATH", $sortedEnvPaths, $target)
}

function Test-EnvPath {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Machine
    )

    if (!$Path) {
        return $false
    }

    $LOC = if ($Machine) { [EnvironmentVariableTarget]::Machine } else { [EnvironmentVariableTarget]::User }
    $ENV_PATH = [Environment]::GetEnvironmentVariable("Path", $LOC)

    return $ENV_PATH.Contains($Path)
}

function Test-RegistryValue {

    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    }

    catch {
        return $false
    }

}
function Test-ScheduledTask($name) {
    $tasks = @()
    foreach ($task in Get-ScheduledTask) {
        $tasks += @($task.TaskName)
    }
    if ($tasks.Contains($name)) {
        return $true
    }
    else {
        return $false
    }
}

function Update-UserPassword {
    [CmdletBinding()]
    param (
    )

    dynamicparam {
        $ParameterName = 'User'
        $ParameterValue = (Get-LocalUser).Name

        $Attributes = New-Object -Type `
            System.Management.Automation.ParameterAttribute
        $Attributes.ParameterSetName = 'User'
        $Attributes.Mandatory = $true
        $Attributes.Position = 0

        $ValidateSet = New-Object -Type `
            System.Management.Automation.ValidateSetAttribute -ArgumentList `
            $ParameterValue

        $Collection = New-Object -Type `
            System.Management.Automation.RuntimeDefinedParameter -ArgumentList `
            $ParameterName, [string], $Attributes

        $Collection.Attributes.Add($ValidateSet)

        $Parameter = New-Object -Type `
            System.Management.Automation.RuntimeDefinedParameterDictionary
        $Parameter.Add($ParameterName, $Collection)
        return $Parameter
    }

    process {
        $User = $PsBoundParameters[$ParameterName]
        $Password = Read-Host -Prompt "Provide your new account password" -AsSecureString
        Set-LocalUser -Name $User -Password $Password
        Clear-Variable "Password"
    }
}

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}
