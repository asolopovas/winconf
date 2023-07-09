. $env:userprofile\winconf\functions.ps1

$src = "$env:USERPROFILE\.chatgpt\cache_prompts\user_custom.json"
$target = "$env:USERPROFILE\Insync\andrius.solopovas@gmail.com\Google Drive\configs\GPT\user_custom.json"

CreateSymLink  $src $target
