#!/bin/bash

# Directory base dei log: BD
# File di log dello script: LF
# Pattern dei file da eliminare: PT
# Trova e elimina i file più vecchi di TM giorni

BD="/opt/application/log"
LF="/var/log/cleanup.log"
PT='*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9].log'
TM="3"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Avvio cleanup Logs" | tee -a "$LF"
logger -t cleanup "Avvio cleanup Logs"

find "$BD" -type f -mtime +"$TM" -name "$PT" | while read FL; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Eliminato: $FL" | tee -a "$LF"
    logger -t cleanup "Eliminato: $FL"
    #rm -f "$FL"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleanup completato" | tee -a "$LF"
logger -t cleanup "Cleanup completato"