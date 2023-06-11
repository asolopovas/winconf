. $env:userprofile\winconf\functions.ps1

$src = "$env:USERPROFILE\.chatgpt"
$target = "$env:USERPROFILE\Insync\andrius.solopovas@gmail.com\Google Drive\configs\GPT"

CreateSymLink  $src $target
