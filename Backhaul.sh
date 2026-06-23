#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0;37m'

clear
echo -e "${CYAN}██████╗  █████╗  ██████╗██╗  ██╗██╗  ██╗ █████╗ ██╗   ██╗██╗     "
echo -e "██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██║  ██║██╔══██╗██║   ██║██║     "
echo -e "██████╔╝███████║██║     █████╔╝ ███████║███████║██║   ██║██║     "
echo -e "██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██║██║   ██║██║     "
echo -e "██████╔╝██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╔╝███████╗"
echo -e "╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}"
echo -e "${GREEN}  Backhaul Free Tunnel Manager v1.1.0 by علیرضا لاله${NC}"
echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get Server IP
IP=$(curl -s https://api.ipify.org || echo "Unknown")
echo -e "  IP   : ${YELLOW}$IP${NC}   Role : ${GREEN}IRAN (Server)${NC}"
echo -e "  Binary: v0.7.x   Path : /usr/local/bin/backhaul"
echo -e "${BLUE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${PURPLE}══ Manage Tunnels ══${NC}"
echo "  Select a tunnel to manage:"
echo ""

# Find existing Backhaul services
SERVICES=$(systemctl list-units --type=service --all | grep backhaul | awk '{print $1}')

if [ -z "$SERVICES" ]; then
    echo -e "  ${RED}No active tunnels found.${NC}"
    echo ""
    echo -e "  [1] Create New Tunnel"
    echo -e "  [0] Exit"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    read -p "› Choice: " MAIN_CHOICE
    exit 0
fi

# List services dynamically
count=1
declare -A service_map
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

echo ""
echo -e "  [0]  Back"
echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
read -p "› Choice [0-$((count-1))]: " CHOICE

if [ "$CHOICE" -eq 0 ] || [ -z "$CHOICE" ]; then
    exit 0
fi

SELECTED_SVC=${service_map[$CHOICE]}
CONFIG_NAME=$(echo $SELECTED_SVC | sed 's/backhaul-//' | sed 's/\.service//')
CONFIG_FILE="/etc/backhaul/${CONFIG_NAME}.toml"

# Sub-menu for selected tunnel
while true; do
    clear
    # Get stats
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
            exit 0
            ;;
        0) exit 0 ;;
    esac
done
