# Network Utilities

Questa cartella contiene script per test di rete, ping e verifiche DNS.

## Script disponibili

- `ping_list.sh` - esegue un ping su una lista di host/indirizzi IP fornita come argomento.
- `DNS_check.sh` - verifica la raggiungibilità di indirizzi IP specificati.
- `list_fqdn.sh` - risolve un file di input usando `nslookup` e scrive i FQDN in un file di destinazione.

## Uso

### Ping su lista

```bash
cd base_utils/network
bash ping_list.sh hosts.txt
```

### Controllo DNS

```bash
bash DNS_check.sh
```

### Risoluzione FQDN

```bash
bash list_fqdn.sh -s input.txt -d output.txt
```

## Note

- `ping_list.sh` richiede un file di testo con un host o IP per riga.
- `list_fqdn.sh` richiede che il file sorgente esista e che il sistema possa effettuare la risoluzione DNS.
