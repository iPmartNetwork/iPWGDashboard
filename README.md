
# iPWGDasboard

A powerful and easy-to-use web-based WireGuard management dashboard. Manage clients, monitor traffic, and configure WireGuard servers through a modern and responsive panel.

## 🌐 Project Repository
[🔗 GitHub Project Link](https://github.com/iPmartNetwork/iPWGDashboard)

## 🚀 Features
- Fully Automated WireGuard Installation & Configuration
- Web-based Dashboard (Admin Panel)
- Traffic Monitoring & Client Management
- Auto-start via systemd Service
- Secure Authentication with Admin Panel

## 📦 Prerequisites
- Linux Server (Ubuntu LTS Recommended)
- Root or Sudo Privileges
- WireGuard Installed (`wg` and `wg-quick`)
- Python 3.9+
- Git

## 📖 Quick Installation Guide



### 1️⃣ Run the Auto-Installer Script
```bash
bash <(curl -Ls https://raw.githubusercontent.com/iPmartNetwork/iPWGDashboard/master/install.sh)

```

> 🛡️ The script will:
> - Install all dependencies.
> - Configure WireGuard.
> - Update `config.py` with server details.
> - Create a systemd service to auto-start the panel after reboot.

### 3️⃣ Manual Installation (Optional)
```bash
sudo apt update
sudo apt install -y wireguard python3-pip git
pip3 install -r requirements.txt
```




### 1️⃣ Clone the Repository
```bash
git clone https://github.com/iPmartNetwork/iPWGDashboard.git
cd iPWGDasboard
```

### 2️⃣ Manual Configuration

Edit `config.py` and update the following:
```python
PUBLIC_IP = "YOUR_SERVER_IP"
SECRET_KEY = "your-secret-key"
ADMIN_PASSWORD = "your-secure-admin-password"
```

### 3️⃣ Setup WireGuard
```bash
python3 setup_wireguard.py
```

### 4️⃣ Launch the Application
```bash
python3 app.py
```

## 🔧 Systemd Service Control
```bash
# Enable and start the dashboard service
sudo systemctl enable ipwgd
sudo systemctl start ipwgd

# Check service status
sudo systemctl status ipwgd
```

## 📌 Access the Dashboard
- URL: `http://YOUR_SERVER_IP:5000`
- Default Admin Password: Generated during install (`install.sh` will display it).

## ✅ Security Recommendations
- Immediately change the `ADMIN_PASSWORD` after the first login.
- Use a secure reverse proxy like NGINX with SSL for production environments.
