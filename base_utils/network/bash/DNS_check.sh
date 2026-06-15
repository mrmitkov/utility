#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

ip_addresses=("0.0.0.0" "1.1.1.1")

while true; do
    all_up=true

    for ip in "${ip_addresses[@]}"; do
        if ! ping -c 1 -W 1 "$ip" &> /dev/null; then
            all_up=false
            echo -e "${RED}$ip is DOWN${NC}"
        else
            echo -e "${GREEN}$ip is OK${NC}"
        fi
    done

    if "$all_up"; then
        echo -e "${BLUE}*** Both IPs are UP ***${NC}"
        break
    fi

    sleep 5  # Attendi 5 secondi prima di ripetere il controllo
done