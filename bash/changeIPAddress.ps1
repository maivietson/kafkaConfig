$WslDistribution = "Ubuntu-20.04"
$Subnet = "192.168.0" # /24
$HostAddress = "$Subnet.1"
$WslAddress = "$Subnet.2"
$BroadcastAddress = "$Subnet.255"

Start-Process powershell -Verb RunAs -Wait -ArgumentList "-ExecutionPolicy Bypass", "-Command `"& { netsh interface ip add address \`"vEthernet (WSL)\`" $HostAddress 255.255.255.0; Write-Host -NoNewLine \`"Press any key to continue...\`"; `$Host.UI.RawUI.ReadKey(\`"NoEcho,IncludeKeyDown\`"); }`""
echo "Finished configuring host network"

wsl --distribution $WslDistribution /bin/bash -c "sudo ip addr add $WslAddress/24 broadcast $BroadcastAddress dev eth0 label eth0:1;"
echo "Finished configuring WSL2 network"