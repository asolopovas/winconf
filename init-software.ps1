# Download init.ps1 if it doesn't exist
$initScript = "$env:TEMP\init.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/asolopovas/winconf/refs/heads/main/init.ps1" -OutFile $initScript

# Execute init.ps1 with the --Software flag
powershell -ExecutionPolicy Bypass -File $initScript -Software
