[CmdletBinding()]
param([switch]$Diagnose)

$p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath)
    if ($Diagnose) { $a += '-Diagnose' }
    Start-Process pwsh -Verb RunAs -ArgumentList $a -Wait
    return
}

function Step($m) { Write-Host "  $m" -ForegroundColor Cyan }
function OK($m)   { Write-Host "    $m" -ForegroundColor Green }
function Note($m) { Write-Host "    $m" -ForegroundColor DarkGray }

Step "Lid close -> Sleep (AC and battery)"
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1 | Out-Null

Step "Disable wake timers"
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0 | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 0 | Out-Null

Step "Network connectivity in standby -> Disabled"
$net = 'f15576e8-98b7-4186-b944-eafa664402d9'
powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE $net 0 2>$null | Out-Null
powercfg /setdcvalueindex SCHEME_CURRENT SUB_NONE $net 0 2>$null | Out-Null

Step "Disarm wake-armed devices"
$wake = @(powercfg /devicequery wake_armed) | Where-Object { $_ -and $_.Trim() -and $_.Trim() -ne 'NONE' }
if (@($wake).Count -eq 0) {
    Note "none armed"
} else {
    foreach ($d in $wake) {
        powercfg /devicedisablewake "$d" | Out-Null
        OK "disarmed: $d"
    }
}

powercfg /setactive SCHEME_CURRENT | Out-Null

Step "Active power requests (anything blocking sleep right now):"
powercfg /requests | ForEach-Object { if ($_) { Note $_ } }

if ($Diagnose) {
    $out = Join-Path $env:USERPROFILE 'sleepstudy.html'
    Step "Generating sleep study -> $out"
    powercfg /sleepstudy /output $out /duration 3 | Out-Null
    Start-Process $out
}

Write-Host ""
Write-Host "  Done. Close lid to test. If it still heats up, re-run with -Diagnose" -ForegroundColor Green
