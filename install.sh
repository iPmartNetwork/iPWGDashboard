#!/bin/bash

set -e

echo "Starting installation of iPWGDashboard ..."

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y wireguard python3 python3-pip git curl

# Clone the repository
echo "Cloning the repository..."
git clone https://github.com/iPmartNetwork/iPWGDasboard.git /opt/iPWGDasboard
cd /opt/iPWGDasboard

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Configure WireGuard
echo "Setting up WireGuard..."
python3 setup_wireguard.py

# Create a systemd service for the panel
echo "Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/iPWGD.service
[Unit]
Description=iPWGDasboard
After=network.target

[Service]
User=root
WorkingDirectory=/opt/iPWGD
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable iPWGD
sudo systemctl start iPWGD

echo "Installation complete!"
echo "Access the panel at http://<your-server-ip>:5000"
echo "Default credentials: admin / admin123"
