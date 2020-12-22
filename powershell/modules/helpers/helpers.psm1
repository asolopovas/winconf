function Gen-Password([int] $length = 20) {
  $characters = 'abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ0123456789'
  for ($i = 0; $i -le $length; $i++) {
    $random = Get-Random -Maximum $characters.length
    $password += $characters[$random]
  }
  return $password
}

function IIf($If, $Then, $Else) {
  If ($If -IsNot "Boolean") { $_ = $If }
  If ($If) { If ($Then -is "ScriptBlock") { &$Then } Else { $Then } }
  Else { If ($Else -is "ScriptBlock") { &$Else } Else { $Else } }
}

function Feature-Enable($features) {
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

function Tail-Content($path, [string]$length = 10) {
  Get-Content $path -Wait -Tail $length
}

function EnvPath-Add($path) {
  $env:Path = $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  if (!(EnvPath-Exist $path)) {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$path", [EnvironmentVariableTarget]::Machine)
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Output "$path added"
  }
}

function EnvPath-Exist($path) {
  $env:Path = $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  return $envPath.Contains($path)
}

function EventLogs-Clear {
  wevtutil el | Foreach-Object { wevtutil cl "$_" }
}

function Remove-Alias ([string] $AliasName) {
  while (Test-Path Alias:$AliasName) {
    Remove-Item Alias:$AliasName -Force 2> $null
  }
}

function Get-RootName($name) {
  return [io.path]::GetFileNameWithoutExtension($name)
}

function Add-StartupItem($progValue, $progName) {
  $name = Get-RootName $progName

  # Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run
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

function Repair-Windows() {
  sfc /scannow
  Dism /Online /Cleanup-Image /RestoreHealth
  sfc /scannow
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

Function FindLockingProcess {
  Param
  (
    [Parameter(Mandatory = $true)]
    [String] $FileOrFolderPath
  )
  IF ((Test-Path -Path $FileOrFolderPath) -eq $false) {
    Write-Warning "File or directory does not exist."
  }
  Else {
    $LockingProcess = CMD /C "openfiles /query /fo table | find /I ""$FileOrFolderPath"""
    Write-Host $LockingProcess
  }

}



. $PSScriptRoot\sub\rm-pattern.ps1
. $PSScriptRoot\sub\git.ps1
. $PSScriptRoot\sub\convertions.ps1
. $PSScriptRoot\sub\files.ps1
. $PSScriptRoot\sub\security.ps1


Export-ModuleMember -Function *
