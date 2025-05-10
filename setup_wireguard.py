#!/usr/bin/env python3
import os
import subprocess
from config import (
    PUBLIC_IP, WG_PORT, WG_INTERFACE, WG_CONFIG_PATH,
    WG_MTU, WG_DNS
)
from database import init_db, get_server_config

def remove_existing_wg():
    """Remove existing WireGuard interface if it exists."""
    result = subprocess.run(['wg', 'show', WG_INTERFACE], capture_output=True, text=True)
    if result.returncode == 0:
        print(f"WireGuard interface {WG_INTERFACE} exists. Removing it...")
        subprocess.run(['wg-quick', 'down', WG_INTERFACE])
        subprocess.run(['systemctl', 'disable', f'wg-quick@{WG_INTERFACE}'])

def install_wireguard():
    """Install WireGuard if not already installed."""
    try:
        subprocess.run(['apt', 'update'], check=True)
        subprocess.run(['apt', 'install', '-y', 'wireguard'], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error installing WireGuard: {e}")
        exit(1)

def generate_private_key():
    """Generate a WireGuard private key."""
    try:
        private_key = subprocess.check_output(['wg', 'genkey']).decode('utf-8').strip()
        return private_key
    except subprocess.CalledProcessError as e:
        print(f"Error generating private key: {e}")
        exit(1)

def init_server():
    # Install WireGuard
    install_wireguard()

    # Initialize database
    init_db()
    
    # Remove existing WireGuard interface if it exists
    remove_existing_wg()

    # Generate private key automatically
    private_key = generate_private_key()

    # Get or create server config
    server_config = get_server_config()
    server_config['private_key'] = private_key  # Set the generated private key
    
    # Create WireGuard configuration
    config_content = f"""[Interface]
PrivateKey = {server_config['private_key']}
Address = 10.8.0.1/24
ListenPort = {WG_PORT}
MTU = {WG_MTU}

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
"""
    
    # Write the configuration
    with open(WG_CONFIG_PATH, 'w') as f:
        f.write(config_content)
    os.chmod(WG_CONFIG_PATH, 0o600)
    
    # Enable IP forwarding
    subprocess.run(['sysctl', '-w', 'net.ipv4.ip_forward=1'])
    with open('/etc/sysctl.d/99-wireguard.conf', 'w') as f:
        f.write('net.ipv4.ip_forward=1\n')
    
    # Set up iptables
    subprocess.run(['iptables', '-F'])
    subprocess.run(['iptables', '-t', 'nat', '-F'])
    subprocess.run(['iptables', '-A', 'INPUT', '-p', 'udp', '--dport', str(WG_PORT), '-j', 'ACCEPT'])
    subprocess.run(['iptables', '-A', 'FORWARD', '-i', WG_INTERFACE, '-j', 'ACCEPT'])
    subprocess.run(['iptables', '-A', 'FORWARD', '-o', WG_INTERFACE, '-j', 'ACCEPT'])
    subprocess.run(['iptables', '-t', 'nat', '-A', 'POSTROUTING', '-o', 'eth0', '-j', 'MASQUERADE'])
    
    # Restart WireGuard
    subprocess.run(['systemctl', 'enable', f'wg-quick@{WG_INTERFACE}'])
    subprocess.run(['systemctl', 'restart', f'wg-quick@{WG_INTERFACE}'])
    
    print(f"Server initialized with public key: {server_config['public_key']}")

if __name__ == "__main__":
    init_server()
