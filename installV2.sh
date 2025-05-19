#!/bin/bash

# Coler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
cat <<'EOF'
 __        __ _                            _   _                 _   
  ____________________________________________________________________________
      ____                             _     _
 ,   /    )                           /|   /                                 
-----/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__--
 /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) 
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/____

EOF
echo -e "${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Welcome to WireGuard & AmneziaWG Professional Installer!${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# نمایش منو
echo -e "${BLUE}Select what you want to install:${NC}"
echo -e "${CYAN} 1) WireGuard + iPWGDashboard (Recommended)"
echo -e " 2) AmneziaWG (Advanced WireGuard by Amnezia)"
echo -e " 3) Exit${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -p "Choose an option [1-3]: " main_choice

case "$main_choice" in
  1)
    echo -e "${GREEN}You selected: WireGuard + Dashboard${NC}"
    sleep 1
    ;;
  2)
    echo -e "${GREEN}You selected: AmneziaWG${NC}"
    # اجرای نصب AmneziaWG
    if [ ! -f ./amneziawg-install.sh ]; then
      echo -e "${YELLOW}Downloading AmneziaWG installer...${NC}"
      wget -q https://raw.githubusercontent.com/iPmartnetwork/iPWGDashboard/master/amneziawg.sh -O ./amneziawg.sh
      chmod +x ./amneziawg.sh
    fi
    bash ./amneziawg-install.sh
    exit 0
    ;;
  3)
    echo -e "${RED}Exiting. Bye!${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid option!${NC}"
    exit 1
    ;;
esac

#########################################################
###  WireGuard + iPWGDashboard ###
#########################################################

# Function to check if a package is installed
check_package_installed() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    else
        return 0
    fi
}
check_dpkg_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}
# Function to validate the port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
        return 0
    else
        return 1
    fi
}

if ! check_dpkg_package_installed curl; then
    echo "Installing curl..."
    apt update -y 
    apt install -y curl >/dev/null 2>&1
fi
if ! check_dpkg_package_installed wget; then
    echo "Installing wget..."
    apt update -y 
    apt install -y wget >/dev/null 2>&1
fi
if ! check_dpkg_package_installed git; then
    echo "Installing git..."
    apt update -y 
    apt install -y git >/dev/null 2>&1
fi
if ! check_dpkg_package_installed sudo; then
    echo "Installing sudo..."
    apt update -y 
    apt install -y sudo >/dev/null 2>&1
fi

clear
interface=$(ip route list default | awk '$1 == "default" {print $5}')

echo "                                  WireGuard Panel & Server"
echo ""
echo -e "\e[1;31mWARNING ! Install only in Ubuntu 20.04, Ubuntu 22.04, Ubuntu 24.02 & Debian 11 & 12 system ONLY\e[0m"
echo -e "\e[32mRECOMMENDED ==> Ubuntu 22.04 \e[0m"
echo ""
echo "The following software will be installed on your system:"
echo "   - Wire Guard Server"
echo "   - WireGuard-Tools"
echo "   - WGDashboard by donaldzou"
echo "   - Gunicorn WSGI Server"
echo "   - Python3-pip"
echo "   - Git"
echo "   - UFW - firewall"
echo "   - inotifywait"
echo ""

if [ -f "/etc/centos-release" ]; then
    centos_version=$(rpm -q --queryformat '%{VERSION}' centos-release)
    printf "Detected CentOS %s...\n" "$centos_version"
    pkg_manager="yum"
    ufw_package="ufw"
elif [ -f "/etc/debian_version" ]; then
    if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
        if [ "$ID" = "debian" ]; then
            debian_version=$(cat /etc/debian_version)
            printf "Detected Debian %s...\n" "$debian_version"
        elif [ "$ID" = "ubuntu" ]; then
            ubuntu_version=$(lsb_release -rs)
            printf "Detected Ubuntu %s...\n" "$ubuntu_version"
        else
            printf "Unsupported distribution.\n"
            exit 1
        fi
    else
        printf "Unsupported distribution.\n"
        exit 1
    fi
    pkg_manager="apt"
    ufw_package="ufw"
else
    printf "Unsupported distribution.\n"
    exit 1
fi

printf "\n\n"
read -p "Would you like to continue now ? [y/n]: " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then

validate_hostname() {
    local hostname="$1"
        if [[ "$hostname" =~ ^[a-zA-Z0-9\.\-_]+$ ]]; then
        return 0
    else
        return 1
    fi
}
while true; do
    read -p "Please enter FQDN hostname [eg. localhost]: " hostname
    if [[ -z "$hostname" ]]; then
        hostname="localhost"
        break
    elif validate_hostname "$hostname"; then
        break
    else
        echo "Invalid hostname. Please enter a valid hostname."
    fi
done
while true; do
    read -p "Specify a Username Login for WGDashboard: " username
    if [[ -n "$username" ]]; then
        break
    else
        echo "Username cannot be empty. Please specify a username."
    fi
done
while true; do
    read -s -p "Specify a Password: " password
    echo ""
    read -s -p "Confirm Password: " confirm_password
    echo ""
    if [ "$password" != "$confirm_password" ]; then
        echo -e "\e[1;31mError: Passwords do not match. Please try again.\e[0m"
    elif [ -z "$password" ]; then
        echo "Password cannot be empty. Please specify a password."
    else
        break
    fi
done
read -p "Please Specify new DNS [eg. 8.8.8.8, 1.1.1.1]: " dns
dns="${dns:-1.1.1.1,8.8.8.8}"

while true; do
    read -p "Please enter Wireguard Port [eg. 51820]: " wg_port
    wg_port="${wg_port:-51820}"
    if validate_port "$wg_port"; then
        break
    else
        echo "Error: Invalid port. Please enter a number between 1 and 65535."
    fi
done
read -p "Please enter Admin Dashboard Port [eg. 8080]: " dashboard_port
dashboard_port="${dashboard_port:-8080}"
echo ""

ipv6_available() {
if ip -6 addr show $interface | grep -q inet6 && ip -6 addr show $interface | grep -qv fe80; then
        return 0
    else
        return 1
    fi
}

convert_ipv4_format() {
    local ipv4_address=$1
    local subnet_mask=$2
    local network=$(echo "$ipv4_address" | cut -d'/' -f1 | cut -d'.' -f1-3)
    local converted_ipv4="$network.0/24"
    echo "$converted_ipv4"
}

is_global_ipv6() {
    local ipv6_address=$1
    if [[ $ipv6_address != fe80:* && $ipv6_address == *::* ]]; then
        return 0
    else
        return 1
    fi
}

if ipv6_available; then
    ipv6_available=true
else
    ipv6_available=false
fi

generate_ipv4() {
    local range_type=$1
    case $range_type in
       1)
            ipv4_address_pvt="10.$((RANDOM%256)).$((RANDOM%256)).1/24"
            ;;
        2)
            ipv4_address_pvt="172.$((RANDOM%16+16)).$((RANDOM%256)).1/24"
            ;;
        3)
            ipv4_address_pvt="110.20.0.1/24"
            ;;
        4)
            read -p "Enter custom Private IPv4 address: " ipv4_address_pvt
            ;;
        *)
            echo "Invalid option for IPv4 range."
            exit 1
            ;;
    esac
    echo "$ipv4_address_pvt"
}

generate_ipv6() {
    local range_type=$1
    case $range_type in
        1)
            ipv6_address_pvt=$(printf "FC00:%04x:%04x::1/64" $((RANDOM % 65536)) $((RANDOM % 65536)))
            ;;
        2)
            ipv6_address_pvt=$(printf "FD86:EA04:%04x::1/64" $((RANDOM % 65536)))
            ;;
        3)
            read -p "Enter custom Private IPv6 address: " ipv6_address_pvt
            ;;
        *)
            echo "Invalid option for IPv6 range."
            exit 1
            ;;
    esac
    echo "$ipv6_address_pvt"
}

validate_input() {
    local input=$1
    local min=$2
    local max=$3
    if (( input < min || input > max )); then
        echo "Invalid option. Please choose an option between $min and $max."
        return 1
    fi
    return 0
}

while true; do
    echo "Choose IP range type for IPv4:"
    echo "1) Class A: 10.0.0.0 to 10.255.255.255"
    echo "2) Class B: 172.16.0.0 to 172.31.255.255"
    echo "3) Class C: 192.168.0.0 to 192.168.255.255"
    echo "4) Specify custom Private IPv4"
    read -p "Enter your choice (1-4): " ipv4_option
    case $ipv4_option in
        1|2|3|4)
            ipv4_address_pvt=$(generate_ipv4 $ipv4_option)
            break
            ;;
        *)
            echo "Invalid option for IPv4 range."
            ;;
    esac
done
ipv6_option=""
if $ipv6_available; then
    while true; do
        echo "Choose IP range type for IPv6:"
        echo "1) FC00::/7"
        echo "2) FD00::/7"
        echo "3) Specify custom Private IPv6"
        read -p "Enter your choice (1-3): " ipv6_option
        case $ipv6_option in
            1|2|3)
                ipv6_address_pvt=$(generate_ipv6 $ipv6_option)
                break
                ;;
            *)
                echo "Invalid option for IPv6 range."
                ;;
        esac
    done
fi
echo "IPv4 Address: $ipv4_address_pvt"
if [ -n "$ipv6_address_pvt" ]; then
    echo "IPv6 Address: $ipv6_address_pvt"
fi
echo ""
read -p "Specify a Peer Endpoint Allowed IPs OR [press enter to use - 0.0.0.0/0,::/0]: " allowed_ip
allowed_ip="${allowed_ip:-0.0.0.0/0,::/0}"
echo ""

get_ipv4_addresses() {
    ip -o -4 addr show $interface | awk '$4 !~ /^127\.0\.0\.1/ {print $4}' | cut -d'/' -f1
}
get_ipv6_addresses() {
    ip -o -6 addr show $interface | awk '$4 !~ /^fe80:/ && $4 !~ /^::1/ {print $4}' | cut -d'/' -f1
}

read -p "Enter the internet interface OR (press Enter for detected: $interface)" net_interface
interface="${net_interface:-$interface}"
echo ""

if ipv6_available; then
    ipv6_available=true
else
    ipv6_available=false
fi

echo "Select an option for preferred IP version: "
PS3="Select an option: "
options=("Public IPv4")
if [ "$ipv6_available" = true ]; then
    options+=("Public IPv6")
fi
select opt in "${options[@]}"; do
    case $REPLY in
        1)
            echo "Available Public IPv4 addresses:"
            ipv4_addresses=$(get_ipv4_addresses)
            select ipv4_address in $ipv4_addresses; do
                if validate_input $REPLY 1 $(wc -w <<< "$ipv4_addresses"); then
                    break
                fi
            done
            echo "Selected Public IPv4 Address: $ipv4_address"
            if [ "$ipv6_available" = true ]; then
                echo "Choose a Public IPv6 address:"
                ipv6_addresses=$(get_ipv6_addresses)
                select ipv6_address in $ipv6_addresses; do
                    if validate_input $REPLY 1 $(wc -w <<< "$ipv6_addresses"); then
                        break
                    fi
                done
                echo "Selected Public IPv6 Address: $ipv6_address"
            fi
            break
            ;;
        2)
            if [ "$ipv6_available" = true ]; then
                echo "Available Public IPv6 addresses (excluding link-local addresses):"
                ipv6_addresses=$(get_ipv6_addresses)
                select ipv6_address in $ipv6_addresses; do
                    if validate_input $REPLY 1 $(wc -w <<< "$ipv6_addresses"); then
                        break
                    fi
                done
                echo "Selected Public IPv6 Address: $ipv6_address"
            else
                echo "Public IPv6 is not available."
            fi
            break
            ;;
        *)
            echo "Invalid option. Please select again."
            ;;
    esac
done
echo ""
clear
    echo "Starting with installation..."
    echo ""
echo "$hostname" | tee /etc/hostname > /dev/null
hostnamectl set-hostname "$hostname"
echo "Updating Repo & System..."
echo "Please wait to complete process..."
apt update -y  >/dev/null 2>&1

if ! command -v lsb_release &> /dev/null; then
     apt update
     apt install -y lsb-release >/dev/null 2>&1
fi

distro=$(lsb_release -is)
version=$(lsb_release -rs)

if [[ "$distro" == "Ubuntu" && "$version" == "20.04" ]]; then
    echo "Detected Ubuntu 20.04 LTS. Installing Python 3.10 and WireGuard dependencies..."
     add-apt-repository ppa:deadsnakes/ppa -y >/dev/null 2>&1
     apt-get update -y >/dev/null 2>&1
     apt-get install -y python3.10 python3.10-distutils wireguard-tools net-tools --no-install-recommends >/dev/null 2>&1

elif [[ ( "$distro" == "Ubuntu" && ( "$version" == "22.04" || "$version" == "24.02" ) ) || ( "$distro" == "Debian" && "$version" == "12" ) ]]; then
    echo "Detected $distro $version. Proceeding with installation..."
        if ! check_dpkg_package_installed python3; then
            echo "Python 3 is not installed. Installing Python 3..."
            apt install -y python3 >/dev/null 2>&1
            update-alternatives --install /usr/bin/python python /usr/bin/python3 1
        fi
        get_python_version() {
            python3 --version | awk '{print $2}'
        }
        python_version=$(get_python_version)
        if [[ "$(echo "$python_version" | cut -d. -f1)" -lt 3 || ( "$(echo "$python_version" | cut -d. -f1)" -eq 3 && "$(echo "$python_version" | cut -d. -f2)" -lt 10 ) ]]; then
            echo "Python version is below 3.10. Upgrading Python..."
            apt update -y  >/dev/null 2>&1
            apt install -y python3 >/dev/null 2>&1
        else
            echo "Python version is 3.10 or above."
        fi

elif [[ "$distro" == "Debian" && "$version" == "11" ]]; then
    echo "Detected Debian 11. Installing Python 3.10 and WireGuard dependencies..."
    echo "Please wait."
     apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
    libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev wireguard-tools \
    net-tools >/dev/null 2>&1
    echo "Please wait.."
    wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz -q
    echo "Please wait..."
    tar -xvf Python-3.10.0.tgz >/dev/null 2>&1
    cd Python-3.10.0
    echo "Please wait...."
     ./configure --enable-optimizations >/dev/null 2>&1
    echo "Please wait....."
     make >/dev/null 2>&1
    echo "Please wait......"
    echo "Please wait...... Upgrading Python to v3.10 could take a while"
    echo "Please wait......"
     make altinstall >/dev/null 2>&1
    echo "Python installation...... success"
else

    echo "This script supports only Ubuntu 20.04 LTS, 22.04, 24.02, and Debian 11 & 12."
    echo "Your version, $distro $version, is not supported at this time."
    exit 1
fi

if ! command -v pip &> /dev/null; then
    echo "pip is not installed. Installing pip..."
    apt update >/dev/null 2>&1
    apt install -y python3-pip >/dev/null 2>&1
fi

if ! python3 -c "import bcrypt" &> /dev/null; then
    echo "bcrypt is not installed. Installing bcrypt..."
    pip install bcrypt >/dev/null 2>&1
else
    echo "bcrypt is already installed."
fi
if ! check_dpkg_package_installed wireguard-tools; then
    echo "Installing WireGuard dependencies..."
    apt install -y wireguard-tools >/dev/null 2>&1
fi
if ! check_package_installed git; then
    echo "Installing git..."
    apt install -y git >/dev/null 2>&1
fi
if ! check_package_installed ufw; then
    echo "Installing ufw..."
    apt install -y ufw >/dev/null 2>&1
fi
if ! check_package_installed inotifywait ; then
    echo "Installing inotifywait..."
    apt install -y inotify-tools >/dev/null 2>&1
fi
if ! check_package_installed cron ; then
    echo "Cron is not installed. Installing..."
    apt install -y cron >/dev/null 2>&1
fi
echo "Installing WireGuard..."
apt install -y wireguard >/dev/null 2>&1
private_key=$(wg genkey 2>/dev/null)
echo "$private_key" | tee /etc/wireguard/private.key >/dev/null
public_key=$(echo "$private_key" | wg pubkey 2>/dev/null)

if ! grep -q '^#net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
elif grep -q '^#net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf >/dev/null
fi
if ! grep -q '^#net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
elif grep -q '^#net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf; then
    sed -i '/^#net.ipv6.conf.all.forwarding=1/s/^#//' /etc/sysctl.conf >/dev/null
fi
sysctl -p >/dev/null
ssh_port=$(ss -tlnp | grep 'sshd' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -u)
echo "Configuring firewall (UFW) ....."
ufw disable
ufw allow 10086/tcp
ufw allow $ssh_port/tcp
ufw allow $dashboard_port/tcp
ufw allow 10086/tcp
ufw allow $wg_port/udp
ufw allow 53/udp
ufw allow OpenSSH
ufw --force enable
mkdir -p /etc/wireguard/network
iptables_script="/etc/wireguard/network/iptables.sh"
if [[ -n $ipv6_address ]]; then
cat <<EOF | tee -a /etc/wireguard/wg0.conf >/dev/null
[Interface]
PrivateKey = $private_key
Address = $ipv4_address_pvt, $ipv6_address_pvt
ListenPort = $wg_port
EOF
else
cat <<EOF | tee -a /etc/wireguard/wg0.conf >/dev/null
[Interface]
PrivateKey = $private_key
Address = $ipv4_address_pvt
ListenPort = $wg_port
EOF
fi
echo "Setting up Wireguard configuration ....."
ipv4_address_pvt0=$(convert_ipv4_format "$ipv4_address_pvt")
cat <<EOF | tee -a "$iptables_script" >/dev/null
#!/bin/bash
while ! ip link show dev $interface up; do
    sleep 1
done
iptables -t nat -I POSTROUTING --source $ipv4_address_pvt0 -o $interface -j SNAT --to $ipv4_address
iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
ip route add default dev wg0
ufw route allow in on wg0 out on $interface
EOF
cat <<EOF | tee -a /etc/systemd/system/wireguard-iptables.service >/dev/null
[Unit]
Description=Setup iptables rules for WireGuard
After=network-online.target
[Service]
Type=oneshot
ExecStart=$iptables_script
[Install]
WantedBy=multi-user.target
EOF
chmod +x $iptables_script
systemctl enable wireguard-iptables.service --quiet
echo "Enabling Wireguard Service ....."
systemctl enable wg-quick@wg0.service --quiet
systemctl start wg-quick@wg0.service

cd /etc || exit
if [ ! -d "Easy-WGDashboard" ]; then
    mkdir Easy-WGDashboard
    mkdir /etc/Easy-WGDashboard/monitor
fi
cd Easy-WGDashboard || exit
echo "Installing WGDashboard ....."
git clone  -q https://github.com/iPmartNetwork/iPWGDashboard.git iPWGDashboard
cd iPWGDashboard/src
apt install python3-pip -y >/dev/null 2>&1 && pip install gunicorn >/dev/null 2>&1 && pip install -r requirements.txt --ignore-installed >/dev/null 2>&1
chmod u+x wgd.sh
./wgd.sh install >/dev/null 2>&1
chmod -R 755 /etc/wireguard
./wgd.sh start >/dev/null 2>&1
DASHBOARD_DIR=$(pwd)
SERVICE_FILE="$DASHBOARD_DIR/wg-dashboard.service"
PYTHON_PATH=$(which python3)
sed -i "s|<absolute_path_of_wgdashboard_src>|$DASHBOARD_DIR|g" "$SERVICE_FILE" >/dev/null
sed -i "/Environment=\"VIRTUAL_ENV={{VIRTUAL_ENV}}\"/d" "$SERVICE_FILE" >/dev/null
sed -i "s|{{VIRTUAL_ENV}}/bin/python3|$PYTHON_PATH|g" "$SERVICE_FILE" >/dev/null
cp "$SERVICE_FILE" /etc/systemd/system/wg-dashboard.service
chmod 664 /etc/systemd/system/wg-dashboard.service
systemctl enable wg-dashboard.service --quiet
systemctl restart wg-dashboard.service

hashed_password=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$password', bcrypt.gensalt(12)).decode())")
sed -i "s|^app_port =.*|app_port = $dashboard_port|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^peer_global_dns =.*|peer_global_dns = $dns|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^peer_endpoint_allowed_ip =.*|peer_endpoint_allowed_ip = $allowed_ip|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^password =.*|password = $hashed_password|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^username =.*|username = $username|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^welcome_session =.*|welcome_session = false|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^dashboard_theme =.*|dashboard_theme = dark|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
systemctl restart wg-dashboard.service

echo "Restarting Wireguard & WGDashboard services ....."

wg_status=$(systemctl is-active wg-quick@wg0.service)
dashboard_status=$(systemctl is-active wg-dashboard.service)
echo ""
echo "Wireguard Status: $wg_status"
echo "WGDashboard Status: $dashboard_status"
echo ""

if [ "$wg_status" = "active" ] && [ "$dashboard_status" = "active" ]; then
    server_ip=$(curl -s4 ifconfig.me)
    echo -e "\e[32mGreat! Installation was successful!"
    echo "You can access Wireguard Dashboard now:"
    echo 'URL: http://'"$server_ip:$dashboard_port"
    echo "Username: $username"
    echo "Password: ***(hidden)***"
    echo ""
    echo "System will reboot now and after that Go ahead and create your first peers"
    echo -e "\e[0m"
    reboot
else
    echo "Error: Installation failed. Please check the services and try again."
fi
else
    echo "Installation aborted."
    exit 0
fi

