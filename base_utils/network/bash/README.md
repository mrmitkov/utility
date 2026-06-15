# Bash Network Utilities

Script Bash per controlli di base sulla rete.

## Script disponibili

- `ping_list.sh` - esegue un ping su una lista di host o indirizzi IP.
- `DNS_check.sh` - verifica la raggiungibilità di indirizzi IP specificati.
- `list_fqdn.sh` - risolve un file di input con `nslookup` e scrive i FQDN in un file di destinazione.

## Esempi

```bash
bash ping_list.sh hosts.txt
bash DNS_check.sh
bash list_fqdn.sh -s input.txt -d output.txt
```

## Note

- `ping_list.sh` richiede un file di testo con un host o IP per riga.
- `list_fqdn.sh` richiede che il file sorgente esista e che il sistema possa effettuare la risoluzione DNS.