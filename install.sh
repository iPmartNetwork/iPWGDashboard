#!/bin/bash

set -e

# Variables
GIT_REPO="https://github.com/iPmartNetwork/iPWGDasboard.git"
INSTALL_DIR="/opt/iPWGDasboard"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_NAME="ipwgd"
WG_CONFIG_DIR="/etc/wireguard"
SECRET_KEY=$(openssl rand -hex 16)
ADMIN_PASSWORD=$(openssl rand -hex 8)

# Ask for Domain
read -rp "Enter your server domain or public IP: " DOMAIN

# Install Prerequisites
echo "[+] Installing dependencies..."
apt update && apt install -y wireguard python3-pip python3-venv git

# Clone Repository
echo "[+] Cloning repository..."
rm -rf "$INSTALL_DIR"
git clone "$GIT_REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# Create Virtual Environment
echo "[+] Creating virtual environment..."
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Install Python Dependencies in venv
echo "[+] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# Auto-configure config.py
echo "[+] Configuring application..."
sed -i "s|PUBLIC_IP = .*|PUBLIC_IP = \"$DOMAIN\"|g" config.py
sed -i "s|SECRET_KEY = .*|SECRET_KEY = '$SECRET_KEY'|g" config.py
sed -i "s|ADMIN_PASSWORD = .*|ADMIN_PASSWORD = \"$ADMIN_PASSWORD\"|g" config.py

# Setup WireGuard
echo "[+] Setting up WireGuard..."
"$VENV_DIR/bin/python" setup_wireguard.py

# Create systemd service using venv Python
echo "[+] Creating systemd service..."
cat <<EOF > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=iPWG Dashboard Service
After=network.target

[Service]
WorkingDirectory=$INSTALL_DIR
ExecStart=$VENV_DIR/bin/python $INSTALL_DIR/app.py
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
echo "Admin Panel URL: https://$DOMAIN:5000"
echo "Admin Password: $ADMIN_PASSWORD"
echo "======================================="
