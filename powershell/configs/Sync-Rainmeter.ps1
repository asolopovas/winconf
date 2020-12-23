$document = [Environment]::GetFolderPath("MyDocuments")
$src = "$document\Rainmeter"
$target = "$HOME\winconf\rainmeter"

Sync-Config  $src $target
