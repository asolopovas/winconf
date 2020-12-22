$ipAddress = wsl ip addr show dev eth0 | wsl sed -u -n 3p | wsl awk '{print \$2}' | wsl cut -d / -f1
$ports = 22,80,443,3000
$arg=$args[0]

if ($arg -eq "reset") {
    Write-Output "Resetting portproxy configuration"
    netsh int portproxy reset all
    foreach ($port in $ports) {
        Write-Output "Removing WSL firewall rule `"Port $port`""
        Remove-NetFirewallRule -DisplayName "Port $port"
    }
}

if ($arg -eq "show") {
    netsh interface portproxy show v4tov4
}

if ($arg -eq "setup") {
    foreach ($port in $ports) {
        netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$port connectaddress=$ipAddress connectport=$port
        New-NetFirewallRule -DisplayName "Port $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -Profile Private
    }
}
