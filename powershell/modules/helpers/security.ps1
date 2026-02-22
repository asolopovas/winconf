function Add-FirewallRule ([string] $programName, [string]$prefix, [switch]$allow = $false) {
    $displayName = Format-String snakecase (Get-RootName $programName)
    $name = [string]::Concat($prefix, "_$displayName")
    $exist = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
    if ($exist.Count -gt 0 ) { return "Rule $displayName already present" }
    $action = IIf $allow "Allow" "Block"
    New-NetFirewallRule -DisplayName $name -Direction Inbound -Program $programName -Action $action | Select-Object DisplayName, PrimaryStatus, Direction
    New-NetFirewallRule -DisplayName $name -Direction Outbound -Program $programName -Action $action | Select-Object DisplayName, PrimaryStatus, Direction
}

function Remove-FirewallRule ([string] $programName, [string]$prefix) {
    $displayName = Format-String snakecase (Get-RootName $programName)
    $name = [string]::Concat($prefix, "_$displayName")
    $exist = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
    Write-Output "Removing rule: $name"
    if ($exist.Count -eq 0 ) { return "Rule $displayName not present" }
    Remove-NetFirewallRule -DisplayName $name | Select-Object DisplayName, PrimaryStatus, Direction
}

function Add-DefenderExclusion($path) {
    Add-MpPreference -ExclusionPath $path
}

function Clear-DefenderHistory() {
    Remove-Item -Recurse "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service"
}

function DefenderMode {
    param (
        [switch]$on,
        [switch]$off
    )

    $settingsToToggle = @(
        'DisableRealtimeMonitoring',
        'DisableBehaviorMonitoring',
        'DisableBlockAtFirstSeen',
        'DisableIOAVProtection',
        'DisablePrivacyMode',
        'DisableArchiveScanning',
        'DisableScriptScanning',
        'DisableIntrusionPreventionSystem',
        'DisableAutoExclusion',
        'DisableNetworkProtection'
    )

    $status = (Get-MpPreference).DisableRealtimeMonitoring
    $targetValue = if ($off) { $true } elseif ($on) { $false } else { -not $status }
    $message = if ($targetValue) { "Windows Defender Settings Disabled." } else { "Windows Defender Settings Enabled." }

    foreach ($setting in $settingsToToggle) {
        $params = @{
            $setting = $targetValue
        }
        try {
            Set-MpPreference @params
        } catch {
            Write-Warning "Failed to set $setting due to: $_"
        }
    }

    Write-Output $message
}


