$initScript = Join-Path $env:TEMP "winconf-init.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/asolopovas/winconf/main/init.ps1" -OutFile $initScript
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& powershell -NoProfile -ExecutionPolicy Bypass -File $initScript -Software
exit $LASTEXITCODE
