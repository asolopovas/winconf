$initScript = "$env:TEMP\init.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init.ps1" -OutFile $initScript
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
powershell -ExecutionPolicy Bypass -File $initScript -Software $true
