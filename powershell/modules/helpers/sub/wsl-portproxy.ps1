function wslPortProxy ($task = $false, $ports = 22) {
    $ipAddress = wsl ip addr show dev eth0 | wsl sed -u -n 3p | wsl awk '{print \$2}' | wsl cut -d / -f1
    $ports = 22,3000
    $ports_string = $ports -join ','

    if (!$task) {
        foreach ($port in $ports) {
            netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$port connectaddress=$ipAddress connectport=$port | Out-Null
        }
        iex "New-NetFirewallRule -DisplayName `"Open Ports $ports_string`" -Direction Inbound -LocalPort $ports_string -Protocol TCP -Action Allow | Out-Null"
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

Export-ModuleMember -Function wslPortProxy
