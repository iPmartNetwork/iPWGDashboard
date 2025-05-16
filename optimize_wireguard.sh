#!/bin/bash

read -p "📡 Please enter your WireGuard port (default: 22490): " WG_PORT
WG_PORT=${WG_PORT:-22490}

read -p "📶 Please enter your WireGuard interface name (default: wg0): " WG_INTERFACE
WG_INTERFACE=${WG_INTERFACE:-wg0}

echo "✅ Applying optimizations for WireGuard on port $WG_PORT and interface $WG_INTERFACE..."

# Enable BBR and FQ
modprobe tcp_bbr
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf

# Network Buffer and Low Latency Optimizations
cat <<EOF >> /etc/sysctl.conf
net.core.rmem_max = 2500000
net.core.wmem_max = 2500000
net.ipv4.tcp_rmem = 10240 87380 2500000
net.ipv4.tcp_wmem = 10240 87380 2500000
net.ipv4.tcp_low_latency = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p

echo "✅ Kernel optimizations applied."

# Optimize CPU Governor
if command -v cpupower &> /dev/null; then
    cpupower frequency-set -g performance
else
    apt update && apt install -y linux-tools-common linux-tools-$(uname -r)
    cpupower frequency-set -g performance
fi
echo "✅ CPU Governor set to performance mode."

# Apply QoS for WireGuard Traffic
echo "✅ Applying QoS for WireGuard traffic on port $WG_PORT..."
iptables -t mangle -A OUTPUT -p udp --dport $WG_PORT -j TOS --set-tos 0x10

# Calculate Optimal MTU
echo "📡 Calculating optimal MTU value..."
MTU=$(ping -M do -s 1472 8.8.8.8 -c 1 | grep 'Frag needed' | awk -F' ' '{print $NF}' | cut -d= -f2)
if [ -z "$MTU" ]; then
    MTU=1420  # Default safe value
fi
echo "✅ Suggested MTU: $MTU"

# Apply MTU to WireGuard Interface if Active
if ip link show $WG_INTERFACE &> /dev/null; then
    ip link set mtu $MTU dev $WG_INTERFACE
    echo "✅ MTU set to $MTU on interface $WG_INTERFACE."
else
    echo "⚠️ Interface $WG_INTERFACE is not active. Please configure MTU after activation."
fi

echo "🎉 Optimization Complete! Restart WireGuard service using:"
echo "sudo systemctl restart wg-quick@$WG_INTERFACE"
