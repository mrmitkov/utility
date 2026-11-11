# Bash Network Utilities

Script Bash per controlli di base sulla rete.

## Script disponibili

- `ping_list.sh` - esegue un ping su una lista di host o indirizzi IP.
- `DNS_check.sh` - verifica la raggiungibilità di indirizzi IP specificati.
- `list_fqdn.sh` - risolve un file di input con `nslookup` e scrive i FQDN in un file di destinazione.
- `ad_inventory_check.sh` - verifica host tramite DNS, ICMP, SSH, RDP e Active Directory.

## Esempi

```bash
bash ping_list.sh hosts.txt
bash DNS_check.sh
bash list_fqdn.sh -s input.txt -d output.txt
```

## Note

- `ping_list.sh` richiede un file di testo con un host o IP per riga.
- `list_fqdn.sh` richiede che il file sorgente esista e che il sistema possa effettuare la risoluzione DNS.
- `ad_inventory_check.sh` richiede un ticket Kerberos valido e consente di selezionare un Domain Controller tra quelli pubblicati nei record SRV LDAP; il Base DN viene letto direttamente dal controller selezionato.
- `ad_inventory_check.sh` analizza fino a 10 host in parallelo per impostazione predefinita; nel terminale mostra dinamicamente gli host attivi e una barra effimera in fondo, adattata alla larghezza disponibile. Il limite si può cambiare, ad esempio: `MAX_PARALLEL=5 bash ad_inventory_check.sh inventory.ini`.
- `ad_inventory_check.sh` verifica RDP controllando la raggiungibilità TCP della porta 3389.