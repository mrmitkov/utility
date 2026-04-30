#!/bin/bash

MAIL_DIR="/var/spool/mail"
OLD_DIR="/var/spool/mail/old"
THRESHOLD=100   # soglia per il file in MB
RETENTION_DAYS=90
LOG_FILE="/var/log/mail_cleanup.log"
# Crea OLD_DIR se non esiste
mkdir -p "$OLD_DIR"

echo "=== Pulizia avviata: $(date +%Y-%m-%d\ %H:%M:%S) ===" | tee -a "$LOG_FILE"

# Trova file più grandi della soglia
for file in "$MAIL_DIR"/*; do
    if [ -f "$file" ]; then
        size_mb=$(du -m "$file" | cut -f1)
        if [ "$size_mb" -gt "$THRESHOLD" ]; then
            base=$(basename "$file")
            echo "$(date +%Y-%m-%d\ %H:%M:%S) File grande trovato: $file ($size_mb MB)" | tee -a "$LOG_FILE"
            # Sposta e comprime

            timestamp=$(date +%Y-%m-%d_%H:%M:%S)
            gzip -c -9 "$MAIL_DIR/$base" > "$OLD_DIR/${base}_${timestamp}.gz"
            > "$MAIL_DIR/$base"
            echo "$(date +%Y-%m-%d\ %H:%M:%S)Compresso e spostato come $OLD_DIR/${base}_${timestamp}.gz" | tee -a "$LOG_FILE"
        fi
    fi
done

# Elimina file compressi più vecchi di RETENTION_DAYS
echo "$(date +%Y-%m-%d\ %H:%M:%S) Elimina file compressi più vecchi di $RETENTION_DAYS giorni" | tee -a "$LOG_FILE"
find "$OLD_DIR" -type f -name "*.gz" -mtime +$RETENTION_DAYS -exec rm {} \; -exec echo "$(date +%Y-%m-%d\ %H:%M:%S) Eliminato: {}" \; | tee -a "$LOG_FILE"

echo "=== Pulizia completata: $(date +%Y-%m-%d\ %H:%M:%S) ===" | tee -a "$LOG_FILE"