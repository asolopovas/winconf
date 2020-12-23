$confSrc = "$Env:userprofile\AppData\Roaming\Sublime Text 3\Packages\User"
$confTarget = "$PSScriptRoot\..\..\..\sublime-text\User"

Sync-Config $confSrc $confTarget
