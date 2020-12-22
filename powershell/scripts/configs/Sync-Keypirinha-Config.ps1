$configSrc = "$Env:userprofile\AppData\Roaming\Keypirinha\User"
$configTarget = "$PSScriptRoot\..\..\..\keypirinha"

Sync-Config  $configSrc $configTarget

$keypirinhaPath = "C:\ProgramData\chocolatey\lib\keypirinha\tools\Keypirinha\bin\x64\keypirinha-x64.exe"

Start-Process $keypirinhaPath
