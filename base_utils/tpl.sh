#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
all_up=false

    for ip in $(cat $1); do
        if ! ping -c 1 -W 1 "$ip" &> /dev/null; then
            echo -e "${RED}$ip is DOWN${NC}"
        else
            echo -e "${GREEN}$ip is OK${NC}"
        fi
    done

    if $all_up; then
        echo -e "${GREEN}ALL IPs are UP${NC}"
        break
    fi

    if [ $iteration -lt $max_iterations ]; then
        echo "Ripetizione $iteration. Attendere 5 secondi..."
        sleep 5  # Attendi 5 secondi prima di ripetere il controllo
    else
        echo "Numero massimo di iterazioni raggiunto."
    fi
