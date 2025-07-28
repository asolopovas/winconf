$document = [Environment]::GetFolderPath("MyDocuments")
$src = "$document\Rainmeter"
$target = "$HOME\winconf\configs\rainmeter"

CreateSymLink  $src $target
