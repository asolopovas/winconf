. $env:userprofile\winconf\functions.ps1

$domain = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Name).Name

$pageantPaths = @(
    "$env:LOCALAPPDATA\Programs\WinSCP\PuTTY\pageant.exe"
    "$env:ProgramFiles\PuTTY\pageant.exe"
    "${env:ProgramFiles(x86)}\PuTTY\pageant.exe"
)
$pageantExe = $pageantPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (!$pageantExe) {
    Write-Host "Pageant not found. Skipping Setup-Pageant." -ForegroundColor Yellow
    return
}

$ppkFiles = Get-ChildItem "$env:USERPROFILE\.ssh\*.ppk" -ErrorAction SilentlyContinue
if (!$ppkFiles) {
    Write-Host "No PPK keys found in ~/.ssh/. Run gen-ssh-keys.cmd first." -ForegroundColor Yellow
    return
}

$ppkArgs = ($ppkFiles.FullName | ForEach-Object { "`"$_`"" }) -join ' '
$taskName = "Pageant-$env:UserName"

if (Test-ScheduledTask $taskName) {
    Write-Host "Removing existing task: $taskName" -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$A = New-ScheduledTaskAction -Execute $pageantExe -Argument $ppkArgs
$T = New-ScheduledTaskTrigger -AtLogon -User "$domain\$env:UserName"
$P = New-ScheduledTaskPrincipal -UserId "$domain\$env:UserName" -LogonType Interactive -RunLevel Limited
$S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
Register-ScheduledTask -TaskName $taskName -InputObject $D

if (!(Get-Process pageant -ErrorAction SilentlyContinue)) {
    Start-ScheduledTask -TaskName $taskName
}

Write-Host "Pageant scheduled task '$taskName' registered." -ForegroundColor Green
