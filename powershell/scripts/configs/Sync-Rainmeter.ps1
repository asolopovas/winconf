$document = [Environment]::GetFolderPath("MyDocuments")
$configSrc = "$document\Rainmeter"
$configTarget = "$PSScriptRoot\..\..\..\rainmeter"

Sync-Config  $configSrc $configTarget
