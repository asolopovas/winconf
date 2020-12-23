$configSrc = "$Env:userprofile\AppData\Roaming\mIRC"
$configTarget = "$Env:userprofile\Google Drive\configs\mIRC"

Sync-Config $configSrc $configTarget
