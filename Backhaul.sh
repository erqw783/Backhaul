#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;37m'

# Function to install Binary
install_backhaul() {
    if ! [ -f /usr/local/bin/backhaul ]; then
        echo -e "${YELLOW}Downloading Backhaul Binary...${NC}"
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            URL="https://github.com/Musonius/backhaul/releases/latest/download/backhaul_linux_amd64.tar.gz"
        elif [ "$ARCH" = "aarch64" ]; then
            URL="https://github.com/Musonius/backhaul/releases/latest/download/backhaul_linux_arm64.tar.gz"
        fi
        wget -qO- $URL | tar -xzvf - -C /usr/local/bin/ backhaul &> /dev/null
        chmod +x /usr/local/bin/backhaul
    fi
}

# Function to create a new tunnel
create_new_tunnel() {
    clear
    echo -e "${GREEN}══ Create New Tunnel ══${NC}"
    read -p "Enter Bind Port (default 3080): " BPORT
    BPORT=${BPORT:-3080}
    read -p "Enter Secret Token: " TOKEN
    
    SVC_NAME="backhaul-iran-wssmux-${BPORT}.service"
    CONF_FILE="/etc/backhaul/iran-wssmux-${BPORT}.toml"
    
    mkdir -p /etc/backhaul
    cat <<EOF > $CONF_FILE
[server]
bind_addr = "0.0.0.0:$BPORT"
transport = "mux"
token = "$TOKEN"
EOF

    cat <<EOF > /etc/systemd/system/$SVC_NAME
[Unit]
Description=Backhaul Tunnel Service Port $BPORT
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/backhaul -c $CONF_FILE
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SVC_NAME &> /dev/null
    systemctl start $SVC_NAME
    echo -e "${GREEN}New Tunnel on port $BPORT created and started successfully!${NC}"
    sleep 2
}

# GLOBAL MAIN LOOP
while true; do
    clear
    echo -e "${CYAN}██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     "
    echo -e "██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     "
    echo -e "██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     "
    echo -e "██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     "
    echo -e "██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗"
    echo -e "╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}"
    echo -e "${GREEN}  Backhaul Free Tunnel Manager v1.1.0 by علیرضا لاله (اصلاح شده)${NC}"
    echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    IP=$(curl -s https://api.ipify.org || echo "Unknown")
    echo -e "  IP   : ${YELLOW}$IP${NC}   Role : ${GREEN}IRAN (Server)${NC}"
    echo -e "  Binary: v0.7.x   Path : /usr/local/bin/backhaul"
    echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${PURPLE}══ Manage Tunnels ══${NC}"
    echo "  Select a tunnel to manage or create a new one:"
    echo ""

    # Find existing Backhaul services
    SERVICES=$(systemctl list-units --type=service --all | grep backhaul | awk '{print $1}')

    count=1
    declare -A service_map
    if [ -n "$SERVICES" ]; then
        for svc in $SERVICES; do
            STATUS=$(systemctl is-active $svc)
            if [ "$STATUS" = "active" ]; then
                STAT_STR="${GREEN}● RUNNING${NC}"
            else
                STAT_STR="${RED}● STOPPED${NC}"
            fi
            echo -e "  [$count]  $svc  $STAT_STR"
            service_map[$count]=$svc
            count=$((count+1))
        done
    else
        echo -e "  ${RED}No active tunnels found.${NC}"
    fi

    echo ""
    echo -e "  [n]  Create New Tunnel ➕"
    echo -e "  [0]  Exit"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    read -p "› Choice: " CHOICE

    if [ "$CHOICE" = "0" ] || [ -z "$CHOICE" ]; then
        exit 0
    fi

    if [ "$CHOICE" = "n" ] || [ "$CHOICE" = "N" ]; then
        install_backhaul
        create_new_tunnel
        continue
    fi

    SELECTED_SVC=${service_map[$CHOICE]}
    if [ -z "$SELECTED_SVC" ]; then
        echo -e "${RED}Invalid Choice!${NC}"
        sleep 1
        continue
    fi

    CONFIG_NAME=$(echo $SELECTED_SVC | sed 's/backhaul-//' | sed 's/\.service//')
    CONFIG_FILE="/etc/backhaul/${CONFIG_NAME}.toml"

    # Sub-menu Loop
    while true; do
        clear
        CPU=$(ps -C backhaul -o %cpu= | awk '{s+=$1} END {print s"%"}')
        MEM=$(ps -C backhaul -o %mem= | awk '{s+=$1} END {print s"%"}')
        UPTIME=$(systemctl show -p ActiveEnterTimestamp $SELECTED_SVC | cut -d= -f2)
        
        echo -e "${CYAN}██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     "
        echo -e "██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     "
        echo -e "██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     "
        echo -e "██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     "
        echo -e "██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗"
        echo -e "╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}"
        echo -e "  Tunnel: ${YELLOW}$SELECTED_SVC${NC}"
        echo -e "  Config : ${YELLOW}$CONFIG_FILE${NC}"
        echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
        echo -e "  Service : ${GREEN}● RUNNING${NC}   CPU: $CPU   Mem: $MEM   Uptime: $UPTIME"
        echo -e "  Tunnel  : ${GREEN}✔ CONNECTED (listener active)${NC}"
        echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  [1]  Start"
        echo -e "  [2]  Stop"
        echo -e "  [3]  Restart"
        echo -e "  [4]  View Logs  (live)"
        echo -e "  [5]  Edit Config"
        echo -e "  [6]  Delete Tunnel"
        echo -e "  [0]  Back"
        echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
        read -p "› Choice: " SUB_CHOICE
        
        case $SUB_CHOICE in
            1) systemctl start $SELECTED_SVC ;;
            2) systemctl stop $SELECTED_SVC ;;
            3) systemctl restart $SELECTED_SVC ;;
            4) journalctl -u $SELECTED_SVC -f ;;
            5) nano $CONFIG_FILE ;;
            6) 
                systemctl stop $SELECTED_SVC
                systemctl disable $SELECTED_SVC
                rm -f /etc/systemd/system/$SELECTED_SVC
                rm -f $CONFIG_FILE
                systemctl daemon-reload
                echo -e "${RED}Tunnel deleted.${NC}"
                sleep 2
                break 2
                ;;
            0) break ;; # Breaks sub-menu, returns to global main loop
        esac
    done
done
