import os

# WireGuard Configuration
PUBLIC_IP = ""  # Replace with your actual public IP
WG_PORT = 22490
WG_CONFIG_PATH = '/etc/wireguard/wg0.conf'
WG_INTERFACE = 'wg0'

# Network Configuration
WG_SUBNET = '172.16.0.0/24'
WG_DNS = '8.8.8.8, 1.1.1.1'
WG_MTU = 1280
WG_PERSISTENT_KEEPALIVE = 25

# Application Configuration
SECRET_KEY = 'your-secret-key-here' 
ADMIN_PASSWORD = "PASSWORD" # Change this to a secure random value
DATABASE_PATH = os.path.join('instance', 'clients.db')
DEBUG = True
