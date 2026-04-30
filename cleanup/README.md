# 🧹 Script di Cleanup

Questo directory contiene script Bash per la pulizia automatica di log e mailbox.  
Include configurazione per **crontab** e **logrotate**.

***

## 📄 Script disponibili

### `cleanup_logs.sh`

Rimuove automaticamente i file di log applicativi più vecchi di un certo numero di giorni.  
Registra ogni attività sia su un file di log dedicato sia tramite `logger` nel syslog.

#### Parametri configurabili

| Variabile | Descrizione                                  | Valore di default       |
| --------- | -------------------------------------------- | ----------------------- |
| `BD`      | Directory principale dei log da pulire       | `/opt/application/log`  |
| `LF`      | File di log dello script                     | `/var/log/cleanup.log`  |
| `PT`      | Pattern dei file da eliminare                | `*_[0-9...].log`        |
| `TM`      | Giorni oltre i quali un file viene eliminato | `3`                     |

#### Funzionamento

- Scandisce la directory `BD` e trova file con pattern `PT` modificati da più di `TM` giorni
- Registra tutte le operazioni nel file di log e nel syslog
- I comandi di eliminazione sono **commentati** per sicurezza (decommentare quando sicuri)

---

### `cleanup_mail.sh`

Gestisce la pulizia automatica della mailbox di sistema riducendone le dimensioni.

#### Parametri configurabili

| Variabile | Descrizione | Valore di default |
| --------- | ---------------------------------------- | ----------------------- |
| `MAIL_DIR` | Directory dei file mail | `/var/spool/mail` |
| `OLD_DIR` | Directory archivi compressi | `/var/spool/mail/old` |
| `THRESHOLD` | Soglia di dimensione in MB | `100` |
| `RETENTION_DAYS` | Giorni di conservazione archivi | `90` |
| `LOG_FILE` | File di log dello script | `/var/log/mail_cleanup.log` |

#### Funzionamento

- Monitora la dimensione dei file mail in `MAIL_DIR`
- Quando un file supera `THRESHOLD` MB:
  1. Comprime il file con gzip (-9, massima compressione)
  2. Sposta l'archivio in `OLD_DIR` con timestamp
  3. Tronca il file mail originale
- Elimina gli archivi compressi più vecchi di `RETENTION_DAYS` giorni
- Registra tutte le operazioni in `LOG_FILE`

***

## ⏰ Esecuzione automatica con Crontab

### Pulizia log

Per eseguire `cleanup_logs.sh` ogni ora:

```bash
crontab -e
```

Aggiungere:

```bash
0 * * * * /etc/scripts/cleanup_logs.sh
```

### Pulizia mailbox

Per eseguire `cleanup_mail.sh` ogni giorno alle 3:00 AM:

```bash
0 3 * * * /etc/scripts/cleanup_mail.sh
```

***

## 🔄 Gestione dei log con Logrotate

Le configurazioni logrotate sono contenute nel file `logrotate_cleanup` e devono essere copiate in `/etc/logrotate.d/`.

### Configurazione per `/var/log/cleanup.log`

```
/var/log/cleanup.log {
    size 100M               # ruota il file se supera 100MB
    rotate 5                # mantiene 5 file ruotati
    compress                # gzip automatico
    delaycompress           # comprime dalla rotazione successiva
    missingok               # nessun errore se il file manca
    notifempty              # non ruota se è vuoto
}
```

> **Nota**: è possibile aggiungere altre configurazioni per `/var/log/mail_cleanup.log` seguendo lo stesso pattern.

## ▶️ Installazione

```bash
# Creare la directory per gli script
sudo mkdir -p /etc/scripts

# Copiare gli script di cleanup
sudo cp cleanup_logs.sh /etc/scripts/
sudo cp cleanup_mail.sh /etc/scripts/
sudo chmod +x /etc/scripts/cleanup_logs.sh
sudo chmod +x /etc/scripts/cleanup_mail.sh

# Copiare la configurazione logrotate
sudo cp logrotate_cleanup /etc/logrotate.d/cleanup

# Verificare le configurazioni logrotate (test)
sudo logrotate -d /etc/logrotate.conf
```

### Note importanti

- I comandi di eliminazione in `cleanup_logs.sh` sono **commentati per sicurezza**
- Testare gli script in ambiente di sviluppo prima di attivarli in produzione
- Assicurarsi di avere i permessi di `root` o di sudoer per eseguire i comandi `sudo`
- I directory di output devono esistere e avere permessi di scrittura corretti

***

## 🧪 Test manuale

Puoi eseguire lo script manualmente per verificare:

```bash
bash /etc/scripts/cleanup_logs.sh
```

Controlla:

*   `/var/log/cleanup.log`
*   `/var/log/syslog` (o `/var/log/messages` su altri sistemi)
