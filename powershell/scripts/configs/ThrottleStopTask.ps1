if (!(Test-ScheduledTask ThrottleStop)) {
  $ThrottleStopPath = "$env:USERPROFILE\Google Drive\programs\ThrottleStop"
  $A = New-ScheduledTaskAction -Execute "$env:USERPROFILE\Google Drive\programs\ThrottleStop\ThrottleStop.exe" -WorkingDirectory $ThrottleStopPath
  $T = new-scheduledtasktrigger -atlogon
  $P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
  $S = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
  $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
  Register-ScheduledTask -TaskName ThrottleStop -InputObject $D
  Start-ScheduledTask -TaskName ThrottleStop
}
