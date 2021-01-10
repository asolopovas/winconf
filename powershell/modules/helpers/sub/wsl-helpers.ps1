function PortProxy($task = $false, $ports = 22) {
    $ipAddress = wsl ip addr show dev eth0 | wsl sed -u -n 3p | wsl awk '{print \$2}' | wsl cut -d / -f1
    $ports = 22,3000,35729
    $ports_string = $ports -join ','

    if (!$task) {
        # Reset Old Port Proxies
        netsh int portproxy reset all | Out-Null
        foreach ($port in $ports) {
            netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$port connectaddress=$ipAddress connectport=$port | Out-Null
        }
        # Add Firewall Rule if not present
        $exist = Get-NetFirewallRule -DisplayName "Open Ports $ports_string" -ErrorAction SilentlyContinue
        if ($exist.Count -gt 0) {
            iex "New-NetFirewallRule -DisplayName `"Open Ports $ports_string`" -Direction Inbound -LocalPort $ports_string -Protocol TCP -Action Allow | Out-Null"
        }
        # Disable TCPIP6
        Get-NetAdapterBinding -ComponentID ms_tcpip6 | foreach  { Disable-NetAdapterBinding $_.Name -ComponentID ms_tcpip6 }
        netsh interface portproxy show v4tov4
    }

    if ($task -eq "show") {
        netsh interface portproxy show v4tov4
    }

    if ($task -eq "reset") {
        netsh int portproxy reset all | Out-Null
        Remove-NetFirewallRule -DisplayName "Open Ports $ports_string" | Out-Null
    }

}

function Remove-Distro($name) {
    wsl.exe -t $name
}

function Import-Distro($name, $path) {
    if (-Not (Test-Path "C:\Data")) {
        New-Item -Path "C:\" -Name "Data" -ItemType "directory"
    }
    if (-Not (Test-Path "C:\Data\$name") ) {
        New-Item -Path "C:\Data" -Name $name -ItemType "directory"
    }
    wsl.exe --import $name "C:\Data\$name" $path
}

Export-ModuleMember -Function wslPortProxy, Remove-Distro, Import-Distro
