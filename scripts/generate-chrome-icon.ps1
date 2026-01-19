$Desktop = [Environment]::GetFolderPath('Desktop')
$Lnk = Join-Path $Desktop 'Chrome (WSL).lnk'

$PowershellScript = Join-Path $env:USERPROFILE\winconf\scripts 'run-chrome-wsl.ps1'
$ScriptContent = "Start-Process -FilePath 'C:\Windows\System32\wsl.exe' -ArgumentList 'bash', '-l', '-c', 'export DISPLAY=:0; setsid /home/andrius/dotfiles/scripts/chrome-debug.sh' -WindowStyle Hidden"
[System.IO.File]::WriteAllText($PowershellScript, $ScriptContent)

$Wsh = New-Object -ComObject WScript.Shell
$S = $Wsh.CreateShortcut($Lnk)

$S.TargetPath = "powershell.exe"
$S.Arguments = "-WindowStyle Hidden -File `"$PowershellScript`""
$S.WindowStyle = 7

$ChromeIcon = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
if (Test-Path $ChromeIcon) { $S.IconLocation = "$ChromeIcon,0" }

$S.Save()
$Lnk
