function Build-WebConfig {
    Param(
        [String][Parameter(Mandatory = $False)] $Config = "\\wsl$\Ubuntu\home\andrius\www\web-hosts.json"
    )

    $config = Get-Content $Config
    $data = ConvertFrom-Json $config

    foreach ($host in $data.hosts) {
        New-HostnameMapping $host.name
    }

    wsl -d Ubuntu -- webconf-build
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

function Get-RootName($name) {
    return [io.path]::GetFileNameWithoutExtension($name)
}

function IIf($If, $Then, $Else) {
    If ($If -IsNot "Boolean") { $_ = $If }
    If ($If) { If ($Then -is "ScriptBlock") { &$Then } Else { $Then } }
    Else { If ($Else -is "ScriptBlock") { &$Else } Else { $Else } }
}

function New-Passowrd([int] $length = 20) {
    $characters = 'abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ0123456789'
    for ($i = 0; $i -le $length; $i++) {
        $random = Get-Random -Maximum $characters.length
        $password += $characters[$random]
    }
    return $password
}

function New-ShellContextItem($name, $reg, $exe) {
    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
    if (!(Test-Path $reg\$name )) {
        New-Item -Path $reg -Name "$name" -Value "Open in $name" | Out-Null
        New-ItemProperty -Path "$reg\$name" -Name "Icon" -Value $exe | Out-Null
        New-Item -Path "$reg\$name" -Name "command" -Value "$exe `"%V`"" | Out-Null
    }
}

function Remove-Alias ([string] $AliasName) {
    while (Test-Path Alias:$AliasName) {
        Remove-Item Alias:$AliasName -Force 2> $null
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

function Sync-Config ($src, $target) {
    if (Test-IsSymLink $src) {
        # Write-Output "Syncing `r`n src: $src `r`n target: $target `r`n"
        New-Item -ItemType SymbolicLink -Path $src -Target $target -Force | Out-Null
    }
    elseif (Test-Path $src) {
        Write-Output "Removing $src `r`n"
        Remove-Item -Recurse -Force $src
        New-Item -ItemType SymbolicLink -Path $src -Target $target -Force | Out-Null
    }
    else {
        Write-Output "Linking Config `r src: $src `r target: $target `r`n"

        if (!(Test-Path $target)) {
            Write-Output "$target does not exist"
        }

        New-Item -ItemType SymbolicLink -Path $src -Target $target -Force | Out-Null
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

function tail($path, [Boolean]$f = $false, [string]$n = 10) {
    # if $f is true, then Get-Content -Wait will be used
    if ($f) {
        Get-Content -Path $path -Wait -Tail $n
    }
    else {
        Get-Content -Path $path -Tail $n
    }
}

function sshCopyID($hostname) {
    Get-Content ~/.ssh/id_rsa.pub | ssh $hostname 'Add-Content | Out-File C:\ProgramData\ssh\administrators_authorized_keys; icacls.exe ""$env:ProgramData\ssh\administrators_authorized_keys"" /inheritance:r /grant ""Administrators:F"" /grant ""SYSTEM:F""'
}

function gitRmPreviousCommits {
    $yn = Read-Host -Prompt "This will delete all previous commits in the current repository. Are you sure you want to proceed? (yes/no)"
    switch -Wildcard ($yn) {
        "y*" {
            if (-not (Test-Path .git)) { return }
            $originUrl = git remote get-url origin
            if ([string]::IsNullOrEmpty($originUrl)) { return }
            Remove-Item .git -Recurse -Force
            git init
            git add .
            git commit -m 'initial commit'
            git remote add origin $originUrl
            git branch -M main
            git push --force -u origin main
        }
        "n*" { Write-Output "Exiting..."; exit }
        default { Write-Output "Invalid response."; exit 1 }
    }
}

function Clean-ShellContext {
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $removeRegistryKeys = @(
            "HKCR:\Directory\Background\shell\git_shell",
            "HKCR:\Directory\Background\shell\git_gui",
            "HKCR:\Directory\shell\git_shell",
            "HKCR:\Directory\shell\git_gui",
            "HKCR:\Directory\shell\PlayWithVLC",
            "HKCR:\Directory\shell\AddToPlaylistVLC",
            "HKCR:\Directory\shell\ShareX",
            "HKCR:\Directory\shell\CaptureOne"
        )
    )

    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR

    foreach ($key in $removeRegistryKeys) {
        if (Test-Path $key) {
            Remove-Item -Path $key -Recurse -Force -Verbose
        }
    }
}

function Set-TaskbarSize {
    param (
        [ValidateSet("0", "1", "2")]
        [string]$Size
    )

    $RegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $RegistryValueName = "TaskbarSi"

    if (-not (Test-Path -Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    Set-ItemProperty -Path $RegistryPath -Name $RegistryValueName -Value $Size
}

function DevHostMappings {
    $hosts= @(
        "redis",
        "mariadb",
        "phpmyadmin.test",
        "mailhog"
    )

    foreach ($host in $hosts) {
        New-HostnameMapping -Hostname $host
    }
}

. $PSScriptRoot\system.ps1
. $PSScriptRoot\convertions.ps1
. $PSScriptRoot\files.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\rm-pattern.ps1
. $PSScriptRoot\security.ps1
. $PSScriptRoot\firewall-blocker.ps1
. $PSScriptRoot\sync-configs.ps1
. $PSScriptRoot\wsl.ps1
. $PSScriptRoot\docker-compose
