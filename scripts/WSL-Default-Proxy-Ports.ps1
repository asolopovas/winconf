function Test-ScheduledTask($name) {
    $tasks = @()
    foreach ($task in Get-ScheduledTask) {
        $tasks += @($task.TaskName)
    }
    if ($tasks.Contains($name)) {
        return $true
    }
    else {
        return $false
    }
}

$taskName = "PortProxy-$env:UserName"

function taskCreate(
    [string]$taskName,
    [string]$workDir = "$env:USERPROFILE"
) {
    $domain = (Get-CimInstance -ClassName Win32_ComputerSystem  | Select-Object Name, Domain).name
    $cmd = "C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe "
    $A = New-ScheduledTaskAction -Execute  $cmd -WorkingDirectory $workDir -Argument "-WindowStyle hidden $PSCommandPath"
    $T = New-ScheduledTaskTrigger -AtLogon -User "$domain\$env:UserName"
    $P = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    $S = New-ScheduledTaskSettingsSet `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T -Settings $S
    Register-ScheduledTask -TaskName $taskName -InputObject $D
    Start-ScheduledTask -TaskName $taskName
}

if (!(Test-ScheduledTask $taskName)) {
    taskCreate $taskName
}

. $env:USERPROFILE\winconf\powershell\modules\helpers\wsl.ps1
PortProxy -ports 3000, 9003, 35729
