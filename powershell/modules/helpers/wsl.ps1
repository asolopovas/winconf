function PortProxy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('show', 'reset', 'disableTCP6')]
        [string] $task = 'off',

        [Parameter()]
        [System.Object[]] $ports = @()
    )

    $ports_string = $ports -join ','

    if ($ports -ne @()) {
        $ipAddress = wsl ip addr show dev eth0 | wsl sed -u -n 3p | wsl awk '{print \$2}' | wsl cut -d / -f1

        Write-Output "Forwarding ports $ports_string to $ipAddress"
        foreach ($port in $ports) {
            netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$port connectaddress=$ipAddress connectport=$port
        }

        # $exist = Get-NetFirewallRule -DisplayName "Proxy Ports $ports_string" -ErrorAction SilentlyContinue
        # if ($exist.Count -gt 0) {
        #     Remove-NetFirewallRule -DisplayName "Proxy Ports $ports_string"
        # }
        # New-NetFirewallRule `
        #     -DisplayName "Proxy Ports $ports_string" `
        #     -Direction Inbound `
        #     -LocalPort $ports `
        #     -Protocol TCP `
        #     -Action Allow

        if ($task -eq 'disableTCP6') {
            Get-NetAdapterBinding -ComponentID ms_tcpip6 | ForEach-Object { Disable-NetAdapterBinding $_.Name -ComponentID ms_tcpip6 }
        }
        netsh interface portproxy show v4tov4
    }

    if ($task -eq "show") {
        netsh interface portproxy show v4tov4
    }

    if ($task -eq "reset") {
        netsh int portproxy reset all | Out-Null
        # get all firewall rules
        $rules = Get-NetFirewallRule -DisplayName "Open Ports *"
        foreach ($rule in $rules) {
            # if $rule.DisplayName contains "Open Ports"
            if ($rule.DisplayName -match "Open Ports") {
                # remove the rule
                Remove-NetFirewallRule -DisplayName $rule.DisplayName
            }
        }
    }
}
function DistroRemove($name) {
    wsl.exe -t $name
    wsl.exe --unregister $name
}

function DistroImport ($name, $path) {
    $mydocs = [Environment]::GetFolderPath("MyDocuments")
    if (-Not (Test-Path "$mydocs\WSLDATA")) {
        New-Item -Path $mydocs -Name "WSLDATA" -ItemType "directory"
    }
    if (-Not (Test-Path "$mydocs\WSLDATA\$name") ) {
        New-Item -Path "$mydocs\WSLDATA" -Name $name -ItemType "directory"
    }
    wsl.exe --import $name "$mydocs\WSLDATA\$name" $path
}
