$ipAddress = wsl ip addr show dev eth0 | wsl sed -u -n 3p | wsl awk '{print \$2}' | wsl cut -d / -f1
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=22 connectaddress=$ipAddress connectport=22
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=3000 connectaddress=$ipAddress connectport=3000
