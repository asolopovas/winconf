$configSrc = "$env:userprofile\AppData\Roaming\ConEmu.xml"
if (Test-Path $configSrc) {
  Remove-Item $configSrc
}
$configTarget = "$PSScriptRoot\..\..\..\ConEmu.xml"

$dirConEmuRegPath = "registry::HKEY_CLASSES_ROOT\Directory\shell\ConEmu"
$dirConEmuCmd = "`"C:\Program Files\ConEmu\ConEmu64.exe`" -here -dir `"%1`" -run {PowerShell (Admin)} -cur_console:n"
$bgConEmuRegPath = "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ConEmu"
$bgConEmuCmd ="`"C:\Program Files\ConEmu\ConEmu64.exe`" -here -run {PowerShell (Admin)} -cur_console:n"

function Install-ConEmu($path, $cmd) {
  New-Item -Path $path -Value "ConEmu Here" | Out-Null
  New-ItemProperty -Path $path -Name "Icon" -Value "C:\Program Files\ConEmu\ConEmu64.exe,0" | Out-Null
  New-Item -Path $path\command -Value $cmd | Out-Null
}

Install-ConEmu $dirConEmuRegPath $dirConEmuCmd
Install-ConEmu $bgConEmuRegPath $bgConEmuCmd

Sync-Config $configSrc $configTarget

