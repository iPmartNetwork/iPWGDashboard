#!/bin/bash

set -e

# Variables
GIT_REPO="https://github.com/iPmartNetwork/iPWGDasboard.git"
INSTALL_DIR="/opt/iPWGDasboard"
SERVICE_NAME="ipwgd"
WG_CONFIG_DIR="/etc/wireguard"
DOMAIN=""
SECRET_KEY=$(openssl rand -hex 16)
ADMIN_PASSWORD=$(openssl rand -hex 8)

# Ask for Domain (For Public IP/SSL Config)
read -rp "Enter your server domain or public IP: " DOMAIN

# Install Prerequisites
echo "[+] Installing dependencies..."
apt update && apt install -y wireguard python3-pip git

# Clone Repository
echo "[+] Cloning repository..."
rm -rf "$INSTALL_DIR"
git clone "$GIT_REPO" "$INSTALL_DIR"

cd "$INSTALL_DIR" || exit 1

# Install Python Dependencies
pip3 install -r requirements.txt

# Auto-configure config.py
echo "[+] Configuring application..."
sed -i "s|PUBLIC_IP = .*|PUBLIC_IP = \"$DOMAIN\"|g" config.py
sed -i "s|SECRET_KEY = .*|SECRET_KEY = '$SECRET_KEY'|g" config.py
sed -i "s|ADMIN_PASSWORD = .*|ADMIN_PASSWORD = \"$ADMIN_PASSWORD\"|g" config.py

# Setup WireGuard
echo "[+] Setting up WireGuard..."
python3 setup_wireguard.py

# Create systemd service
echo "[+] Creating systemd service..."
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=iPWG Dashboard Service
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/app.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "[✔] Installation Completed!"
echo "======================================="
echo "Admin Panel URL: http://$DOMAIN:5000"
echo "Admin Password: $ADMIN_PASSWORD"
echo "======================================="
