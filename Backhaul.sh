#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;37m'

# Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

clear
echo -e "${CYAN}█████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     "
echo -e "██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     "
echo -e "██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     "
echo -e "██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     "
echo -e "██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗"
echo -e "╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}"
echo -e "${GREEN}  Backhaul Free Tunnel Manager v1.1.0 by علیرضا لاله${NC}"
echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Which server is this?${NC}"
echo -e "  This setting applies to all tunnel operations in this session."
echo ""
echo -e "  [1] IRAN   — Server inside Iran   (acts as listener / server side)"
echo -e "  [2] KHAREJ — Server outside Iran  (acts as connector / client side)"
echo ""
# Auto detect role (Defaults to iran if not set, or reads config)
ROLE="iran"
echo -e "  Auto-detected from existing services: ${GREEN}$ROLE${NC}"
echo -e "    Press Enter to accept auto-detected role."
echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -p "› Choice [1/2]: " CHOICE

if [ -z "$CHOICE" ]; then
    CHOICE=1
fi

# Function to install Binary
install_backhaul() {
    if ! command -v backhaul &> /dev/null; then
        echo -e "${YELLOW}Downloading Backhaul Binary...${NC}"
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            URL="https://github.com/Musonius/backhaul/releases/latest/download/backhaul_linux_amd64.tar.gz"
        elif [ "$ARCH" = "aarch64" ]; then
            URL="https://github.com/Musonius/backhaul/releases/latest/download/backhaul_linux_arm64.tar.gz"
        fi
        wget -qO- $URL | tar -xzvf - -C /usr/bin/ backhaul &> /dev/null
        chmod +x /usr/bin/backhaul
    fi
}

# Configuration and Service creation based on choice
if [ "$CHOICE" -eq 1 ]; then
    echo -e "${GREEN}Configuring IRAN Server...${NC}"
    install_backhaul
    
    read -p "Enter Bind Port (default 3080): " BPORT
    BPORT=${BPORT:-3080}
    read -p "Enter Secret Token: " TOKEN
    
    mkdir -p /etc/backhaul
    cat <<EOF > /etc/backhaul/config.toml
[server]
bind_addr = "0.0.0.0:$BPORT"
transport = "mux"
token = "$TOKEN"
EOF

elif [ "$CHOICE" -eq 2 ]; then
    echo -e "${GREEN}Configuring KHAREJ Server...${NC}"
    install_backhaul
    
    read -p "Enter IRAN Server IP: " IRAN_IP
    read -p "Enter IRAN Bind Port (default 3080): " BPORT
    BPORT=${BPORT:-3080}
    read -p "Enter Secret Token: " TOKEN
    read -p "Enter Ports to Tunnel (e.g. 443=443,80=80): " PORTS
    
    mkdir -p /etc/backhaul
    cat <<EOF > /etc/backhaul/config.toml
[client]
remote_addr = "$IRAN_IP:$BPORT"
transport = "mux"
token = "$TOKEN"

[client.ports]
$PORTS
EOF
fi

# Create Systemd Service
cat <<EOF > /etc/systemd/system/backhaul.service
[Unit]
Description=Backhaul Tunnel Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/backhaul -c /etc/backhaul/config.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable backhaul &> /dev/null
systemctl restart backhaul

echo -e "${GREEN}Backhaul service configured and started successfully!${NC}"
systemctl status backhaul --no-pager
