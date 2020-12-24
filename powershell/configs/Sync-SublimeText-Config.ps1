$src = "$HOME\AppData\Roaming\Sublime Text 3\Packages\User"
$target = "$HOME\winconf\sublime-text\User"


$exe="C:\Program Files\Sublime Text 3\sublime_text.exe"

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
$dirReg = "HKCR:\Directory\Background\shell"
$fileReg = "HKCR:\``*\shell"

if (Test-Path "$fileReg\Open with Sublime Text") {
    Remove-Item -Path "$fileReg\Open with Sublime Text" -Force -Confirm:$false
}

if (Test-Path "$dirReg\Open with Sublime Text") {
    Remove-Item -Path "$dirReg\Open with Sublime Text" -Force -Confirm:$false
}

Add-ShellContext "Sublime" $exe
Add-ShellContext "Sublime" $exe "file"

Sync-Config $src $target
