#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}=== iPWGDashboard & WireGuard Auto Installer ===${NC}"

# Root Check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root.${NC}"
    exit 1
fi

# Get Domain and DNS Info
read -p "Enter your domain name (FQDN): " DOMAIN
while [[ -z "$DOMAIN" ]]; do
    echo -e "${RED}Domain cannot be empty.${NC}"
    read -p "Enter your domain name (FQDN): " DOMAIN
done

read -p "Enter custom DNS servers (Default: 8.8.8.8,1.1.1.1): " DNS
DNS=${DNS:-8.8.8.8,1.1.1.1}

# Update & Install Dependencies
apt update && apt upgrade -y
apt install -y curl wget git sudo ufw nginx certbot python3 python3-pip python3-venv wireguard wireguard-tools

# Install WireGuard Service
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.10.10.1/24
PrivateKey = $(wg genkey | tee /etc/wireguard/privatekey)
ListenPort = 51820
SaveConfig = true
PostUp = ufw route allow in on wg0 out on eth0; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# [Peer] Add peers using dashboard
EOF

chmod 600 /etc/wireguard/privatekey
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Enable IP Forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Clone iPWGDashboard
cd /opt
git clone https://github.com/iPmartNetwork/iPWGDasboard.git iPWGDashboard
cd iPWGDashboard

# Python Virtual Environment Setup
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Nginx Reverse Proxy Config
cat > /etc/nginx/sites-available/ipwgdashboard <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/ipwgdashboard /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# SSL Certificate
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# Create Dashboard systemd Service
cat > /etc/systemd/system/ipwgdashboard.service <<EOF
[Unit]
Description=iPWGDashboard Service
After=network.target

[Service]
User=root
WorkingDirectory=/opt/iPWGDashboard
ExecStart=/opt/iPWGDashboard/venv/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ipwgdashboard
systemctl start ipwgdashboard

# UFW Configuration
ufw allow 51820/udp
ufw allow 80,443/tcp
ufw --force enable

echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo "Access your dashboard at: https://$DOMAIN"
echo "WireGuard is running on port 51820/udp"








