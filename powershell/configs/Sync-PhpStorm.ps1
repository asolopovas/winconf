$exe = (Get-ChildItem 'C:\Program Files\JetBrains\' -recurse  -include  "phpstorm64.exe").FullName

Add-ShellContext "PhpStorm" $exe
Add-ShellContext "PhpStorm" $exe "file"
