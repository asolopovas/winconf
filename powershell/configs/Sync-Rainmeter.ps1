$document = [Environment]::GetFolderPath("MyDocuments")
$src = "$document\Rainmeter"
$target = "$PSScriptRoot\..\..\..\rainmeter"

Sync-Config  $configSrc $configTarget
