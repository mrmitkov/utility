# 🧹 Script di Cleanup Log

Questo repository contiene uno script Bash per la pulizia automatica dei log applicativi in base all’età e a un pattern specifico.  
Include anche la configurazione per **crontab** e **logrotate**.

***

## 📄 Descrizione dello Script

Lo script `cleanup_logs.sh` rimuove automaticamente i file di log più vecchi di un certo numero di giorni.  
Inoltre registra ogni attività sia su un file di log dedicato sia tramite `logger` nel syslog.

### 🔧 Parametri configurabili

| Variabile | Descrizione                                  | Esempio                 |
| --------- | -------------------------------------------- | ----------------------- |
| `BD`      | Directory principale dei log da pulire       | `/opt/application/log`  |
| `LF`      | File di log dello script                     | `/var/log/cleanup.log`  |
| `PT`      | Pattern dei file da eliminare                | `*_[YYYY-MM-DD-HH].log` |
| `TM`      | Giorni oltre i quali un file viene eliminato | `3`                     |

***

## 📝 Script Bash

```bash
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
```

> **Nota**: il comando `rm -f` è commentato per sicurezza.  
> Rimuovi il commento quando sei sicuro del comportamento.

***

## ⏰ Esecuzione automatica con Crontab

Per eseguire lo script ogni ora:

```bash
crontab -e
```

Aggiungere:

```bash
0 * * * * /etc/scripts/cleanup_logs.sh
```

***

## 🔄 Gestione del log con Logrotate

Per evitare che il file `/var/log/cleanup.log` cresca troppo, aggiungi una regola:

`/etc/logrotate.d/cleanup`

```bash
/var/log/cleanup.log {
    size 100M               # ruota il file se supera 100MB
    rotate 5                # mantiene 5 file ruotati
    compress                # gzip automatico
    delaycompress           # comprime dalla rotazione successiva
    missingok               # nessun errore se il file manca
    notifempty              # non ruota se è vuoto
}
```

***

## ▶️ Installazione

```bash
sudo mkdir -p /etc/scripts
sudo cp cleanup_logs.sh /etc/scripts/
sudo chmod +x /etc/scripts/cleanup_logs.sh
```

***

## 🧪 Test manuale

Puoi eseguire lo script manualmente per verificare:

```bash
bash /etc/scripts/cleanup_logs.sh
```

Controlla:

*   `/var/log/cleanup.log`
*   `/var/log/syslog` (o `/var/log/messages` su altri sistemi)
