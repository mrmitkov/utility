# Network Utilities

Questa cartella raccoglie gli script di rete divisi per shell.

## Struttura

- `bash/` - script Bash per ping e controlli DNS.
- `powershell/` - script PowerShell per verifiche WinRM e connettività remota.

## Uso

Gli script Bash si trovano in `bash/` e si eseguono da lì.

```bash
cd base_utils/network/bash
bash ping_list.sh hosts.txt
```

Per lo script PowerShell:

```powershell
cd base_utils/network/powershell
.\remote_tnc.ps1
```

## Note

- `ping_list.sh` richiede un file di testo con un host o IP per riga.
- `list_fqdn.sh` richiede che il file sorgente esista e che il sistema possa effettuare la risoluzione DNS.
- `remote_tnc.ps1` usa un file `hosts.ini` nella stessa cartella dello script.
